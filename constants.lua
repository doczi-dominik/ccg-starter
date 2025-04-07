DESIGN_W = 1024
DESIGN_H = 576

RAW_SPR_SIZE = 16
SPR_SCALE = 4
SPR_SIZE = RAW_SPR_SIZE * SPR_SCALE

-- 1 / Ticks Per Second
TICK_RATE = 1 / 60
-- How many Frames are allowed to be skipped at once due to lag (no "spiral of death")
MAX_FRAME_SKIP = 25
-- No configurable framerate cap currently, either max frames CPU can handle (up to 1000), or vsync'd if conf.lua
