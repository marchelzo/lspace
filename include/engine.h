#ifndef ENGINE_H
#define ENGINE_H

#include "SDL.h"
#include "SDL_image.h"
#include "common.h"
#include "stage.h"

void engine_load(void);
void engine_init(void);
void engine_run(void);
void engine_reschedule(void);
void engine_stage(struct stage *stage);
void engine_unload(void);

bool            g_scheduled;
SDL_DisplayMode g_display;

#endif /* ENGINE_H */