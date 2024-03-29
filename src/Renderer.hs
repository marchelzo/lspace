{-# LANGUAGE TupleSections #-}

module Renderer
    ( renderGame
    ) where

import Camera
import Control.Lens
import Control.Monad.Reader
import Data.Hash (hashInt, asWord64)
import Data.List
-- import qualified Data.Map as M
-- import qualified Data.Set as S
-- import Data.Maybe
import qualified Data.Vector as V
import qualified Data.Vector.Storable as VS
import Linear (V2(V2), V4(V4), _y)
import Linear.Affine (Point(P))
import SDL
-- import qualified Ship as H
import qualified SDL.Raw.Types as Srt
import qualified SDL.TTF as Ttf
import Types.Coordinate
import Types.Environment
import Types.Game
import Types.Object
import Types.Ui
import Types.World
import Ui.Menu

import Foreign.C.Types

-- TODO: to refactor most of this, please
renderGame :: Game -> EnvironmentT IO ()
renderGame game = do
    renderer <- asks envRenderer
    -- Let's prepare a new fresh screen
    rendererDrawColor renderer $= V4 0 0 0 0 -- black
    clear renderer
    -- Render various things
    subRenderVoid game
    subRenderWorld game
    subRenderUi game
    -- Present to the screen
    present renderer

subRenderUi :: Game -> EnvironmentT IO ()
subRenderUi game = do
    -- Information needed to render
    renderer    <- asks envRenderer
    window      <- asks envWindow
    font        <- asks envFont
    V2 _ height <- SDL.get $ windowSize window
    
    forM_ (game ^. gameUi . uiVisible) $ \modalType -> do
        case modalType of
            (MkUiTypeMenu mt) -> do
                forM (zip [0..] $ reverse $ uiMenuOptions mt) $ \(row, text) -> do
                    surface <- Ttf.renderTextShaded font text (Srt.Color 255 255 255 0) (Srt.Color 0 0 0 0)
                    V2 surfaceWidth surfaceHeight <- surfaceDimensions surface
                    texture <- createTextureFromSurface renderer surface
                    freeSurface surface
                    let dst = Rectangle (P $ V2 0 (height - surfaceHeight - (row * 15))) (V2 surfaceWidth surfaceHeight)
                    copyEx renderer texture Nothing (Just dst) 0 Nothing (V2 False False)
                    destroyTexture texture
            -- _ -> return []

subRenderWorld :: Game -> EnvironmentT IO ()
subRenderWorld game = do
    -- Information needed to render
    renderer        <- asks envRenderer
    window          <- asks envWindow
    tileset         <- asks envTileset
    tileSize        <- asks envTileSize
    V2 width height <- SDL.get $ windowSize window
    
    let cameraCoordMaxX = (cameraX + (fromIntegral $ width `div` 32) + 1)
    let cameraCoordMaxY = (cameraY + (fromIntegral $ height `div` 32) + 1)           
    
    {-
    let chunksCoord = [ coordinate x y
                      | x <- [cameraX `div` 10..cameraCoordMaxX `div` 10]
                      , y <- [cameraY `div` 10..cameraCoordMaxY `div` 10]
                      ] :: [Coordinate]
    -}

    {-
    let things = catMaybes
               $ concatMap (\s -> map (\c -> (c,) <$> H.lookupChunk c s) chunksCoord)
               $ S.toList ships -- :: [(Coordinate, Data.Vector.Vector [Object])]
    -}

    -- let things = []

    -- Collect renderables, because of zIndex
    {-
    renderables <- concat <$> do
        forM things $ \(coord, vobj) -> do
            results <- flip V.imapM vobj $ \_ objs -> do
                forM objs $ \obj -> do
                    forM (objSprite obj) $ \(coordSpriteRel, coordSpriteTile, zIndex) -> do
                        -- Bunch of positions to calculate
                        let srcTileX    = fromInteger  $ coordSpriteTile ^. coordinateX
                        let srcTileY    = fromInteger  $ coordSpriteTile ^. coordinateY
                        let dstRelX     = fromInteger  $ coordSpriteRel  ^. coordinateX
                        let dstRelY     = fromInteger  $ coordSpriteRel  ^. coordinateY
                        let dstTileRelX = fromIntegral $ coord           ^. coordinateX - cameraX
                        let dstTileRelY = fromIntegral $ coord           ^. coordinateY - cameraY
                        
                        -- Final src and dst rectangles for SDL
                        let src = Rectangle (P $ (V2 srcTileX srcTileY) * svtile) svtile
                        let dst = Rectangle (P $ V2 (dstTileRelX + dstRelX) (dstTileRelY + dstRelY) * dvtile) dvtile
                        return (Just src, Just dst, zIndex)
            return $ concat $ concat $ V.toList results
    -}

    -- Render!
    {-
    forM_ (sortOn (\(_,_,a) -> a) renderables) $ \(src, dst, _) -> do
        copyEx renderer tileset src dst 0 Nothing (V2 False False)
    -}
    
    return ()
                
    where
        cameraX = game ^. gameCamera . cameraCoordinate . coordinateX
        cameraY = game ^. gameCamera . cameraCoordinate . coordinateY
        ships   = game ^. gameWorld  . worldShips

subRenderVoid :: Game -> EnvironmentT IO ()
subRenderVoid game = do
    renderer        <- asks envRenderer
    window          <- asks envWindow
    V2 width height <- SDL.get $ windowSize window

    let cameraX = game ^. gameCamera . cameraCoordinate . coordinateX
    let cameraY = game ^. gameCamera . cameraCoordinate . coordinateY
        
    -- TODO 67%
    let fixedRandomPoint prlx n = P $ V2
            (fromIntegral (fromIntegral (asWord64 . hashInt $ n+(1337*prlx)) + negate cameraX * fromIntegral prlx) `mod` width)
            (fromIntegral (fromIntegral (asWord64 . hashInt $ n+(7331*prlx)) + negate cameraY * fromIntegral prlx) `mod` height)

    let points1 = VS.generate 500 (fixedRandomPoint 1)
    let points2 = VS.generate 200 (fixedRandomPoint 2)
    let points3 = VS.generate 100 (fixedRandomPoint 3)

    rendererDrawColor renderer $= V4 85 85 85 255    -- white quite dark
    drawPoints renderer points1
    rendererDrawColor renderer $= V4 170 170 170 255 -- white kinda visible
    drawPoints renderer points2
    rendererDrawColor renderer $= V4 255 255 255 255 -- white too bright
    drawPoints renderer points3
