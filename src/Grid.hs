{-# LANGUAGE ScopedTypeVariables #-}

module Grid where

import Data.Function

type Region k = (k, k, k, k)

data Point k v = MkPoint k k [v] deriving (Show)

data Quad k v = MkQuad
    { qTopLeft     :: Grid k v
    , qTopRight    :: Grid k v
    , qBottomLeft  :: Grid k v
    , qBottomRight :: Grid k v
    } deriving (Show)

data Leaf k v = MkLeaf (Region k)
                       {-# UNPACK #-} !(Point k v)
                deriving (Show)

data Node k v = MkNode (Region k)
                       {-# UNPACK #-} !(Quad k v)
                deriving (Show)

data Grid k v = GridLeaf {-# UNPACK #-} !(Leaf k v)
              | GridNode {-# UNPACK #-} !(Node k v)
              | GridLeafEmpty (Region k)
              | GridEmpty
              deriving (Show)

empty :: Grid k v
empty = GridEmpty

emptyQuad :: (Integral k, Num k) => Region k -> Quad k v
emptyQuad r@(lx, ly, hx, hy) = MkQuad
    { qTopLeft     = GridLeafEmpty (lx, ly, cx, cy)
    , qTopRight    = GridLeafEmpty (cx, ly, hx, cy)
    , qBottomLeft  = GridLeafEmpty (lx, cy, cx, hy)
    , qBottomRight = GridLeafEmpty (cx, cy, hx, hy)
    }
    where
        (cx, cy) = centerRegion r

promoteLeafToNode :: (Integral k, Ord k) => Leaf k v -> Node k v
promoteLeafToNode (MkLeaf r@(lx, ly, hx, hy) p@(MkPoint x y _))
    | x <= cx && y <= cy = MkNode r $ (emptyQuad r) { qTopLeft     = newGridLeaf (lx, ly, cx, cy) }
    | x >  cx && y <= cy = MkNode r $ (emptyQuad r) { qTopRight    = newGridLeaf (cx, ly, hx, cy) }
    | x <= cx && y >  cy = MkNode r $ (emptyQuad r) { qBottomLeft  = newGridLeaf (lx, cy, cx, hy) }
    | x >  cx && y >  cy = MkNode r $ (emptyQuad r) { qBottomRight = newGridLeaf (cx, cy, hx, hy) }
    | otherwise = undefined
    where
        newGridLeaf nr = (GridLeaf $ MkLeaf nr p)
        (cx, cy) = centerRegion r

insert :: (Integral k, Num k, Ord k) => k -> k -> v -> Grid k v -> Grid k v
insert x y v GridEmpty = GridLeaf $ MkLeaf (negate npof, negate npof, npof, npof) (MkPoint x y [v])
    where
        npof = nearestPowerOfFour (max (abs x) (abs y))
insert x y v (GridLeaf leaf@(MkLeaf r (MkPoint px py pvs))) =
    if x == px && y == py
    then GridLeaf $ MkLeaf r $ MkPoint px py (v:pvs)
    else GridNode (promoteLeafToNode leaf) & insert x y v
insert x y v (GridLeafEmpty size) = GridLeaf $ MkLeaf size (MkPoint x y [v])
insert x y v (GridNode (MkNode r@(lx, ly, hx, hy) quad))
    | x >  hx || y >  hy = insert x y v $ GridNode $ MkNode (lx*2, ly*2, hx*2, hy*2) $ MkQuad
        { qTopLeft     = GridNode $ MkNode (lx*2, ly*2, cx,     cy) $ (emptyQuad (lx*2, ly*2, cx,     cy)) { qBottomRight = qTopLeft     quad }
        , qTopRight    = GridNode $ MkNode (cx,   ly*2, hx*2,   cy) $ (emptyQuad (cx,   ly*2, hx*2,   cy)) { qBottomLeft  = qTopRight    quad }
        , qBottomLeft  = GridNode $ MkNode (lx*2,   cy, cx,   hy*2) $ (emptyQuad (lx*2,   cy, cx,   hy*2)) { qTopRight    = qBottomLeft  quad }
        , qBottomRight = GridNode $ MkNode (cx,     cy, hx*2, hy*2) $ (emptyQuad (cx,     cy, hx*2, hy*2)) { qTopLeft     = qBottomRight quad }

        }
    | x <= cx && y <= cy = GridNode $ MkNode r $ quad { qTopLeft     = insert x y v $ qTopLeft     quad }
    | x >  cx && y <= cy = GridNode $ MkNode r $ quad { qTopRight    = insert x y v $ qTopRight    quad }
    | x <= cx && y >  cy = GridNode $ MkNode r $ quad { qBottomLeft  = insert x y v $ qBottomLeft  quad }
    | x >  cx && y >  cy = GridNode $ MkNode r $ quad { qBottomRight = insert x y v $ qBottomRight quad }
    | otherwise = undefined
    where
        (cx, cy) = centerRegion r

centerRegion :: (Integral k, Num k) => Region k -> (k, k)
centerRegion (lx, ly, hx, hy) = (cx, cy)
    where
        dx = hx - lx
        dy = hy - ly
        cx = lx + dx `div` 2
        cy = ly + dy `div` 2

nearestPowerOfFour :: forall k. (Integral k, Num k, Ord k) => k -> k
nearestPowerOfFour n = head $ dropWhile (<n) powers 
    where
        powers :: [k]
        powers = iterate (4*) 1
