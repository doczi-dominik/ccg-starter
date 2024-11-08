
if os.getenv("LOCAL_LUA_DEBUGGER_VSCODE") == "1" then
    require("lldebugger").start()
end

--[[
    Original Author: https://github.com/Leandros
    Updated Author: https://github.com/jakebesworth
        MIT License
        Copyright (c) 2018 Jake Besworth
    Original Gist: https://gist.github.com/Leandros/98624b9b9d9d26df18c4
    Love.run 11.X: https://love2d.org/wiki/love.run
    Original Article, 4th algorithm: https://gafferongames.com/post/fix_your_timestep/
    Forum Discussion: https://love2d.org/forums/viewtopic.php?f=3&t=85166&start=10
    Add this code to bottom of main.lua to override love.run() for Love2D 11.X
    Tickrate is how many frames your simulation happens per second (Timestep)
    Max Frame Skip is how many frames to allow skipped due to lag of simulation outpacing (on slow PCs) tickrate
---]]
-- 1 / Ticks Per Second
local TICK_RATE = 1 / 60
-- How many Frames are allowed to be skipped at once due to lag (no "spiral of death")
local MAX_FRAME_SKIP = 25
-- No configurable framerate cap currently, either max frames CPU can handle (up to 1000), or vsync'd if conf.lua
function love.run()
    ---@diagnostic disable-next-line: undefined-field
    if love.load then love.load(love.arg.parseGameArguments(arg), arg) end

    -- We don't want the first frame's dt to include time taken by love.load.
    if love.timer then love.timer.step() end
    local lag = 0.0
    -- Main loop time.
    return function()
        -- Process events.
        if love.event then
            love.event.pump()
            for name, a,b,c,d,e,f in love.event.poll() do
                if name == "quit" then
                    ---@diagnostic disable-next-line: undefined-field
                    if not love.quit or not love.quit() then
                        return a or 0
                    end
                end
                ---@diagnostic disable-next-line: undefined-field
                love.handlers[name](a,b,c,d,e,f)
            end
        end
        -- Cap number of Frames that can be skipped so lag doesn't accumulate
        if love.timer then lag = math.min(lag + love.timer.step(), TICK_RATE * MAX_FRAME_SKIP) end
        while lag >= TICK_RATE do
            if love.update then love.update() end
            lag = lag - TICK_RATE
        end
        if love.graphics and love.graphics.isActive() then
            love.graphics.origin()
            love.graphics.clear(love.graphics.getBackgroundColor())

            if love.draw then love.draw() end
            love.graphics.present()
        end
        -- Even though we limit tick rate and not frame rate, we might want to cap framerate at 1000 frame rate as mentioned https://love2d.org/forums/viewtopic.php?f=4&t=76998&p=198629&hilit=love.timer.sleep#p160881
        if love.timer then love.timer.sleep(0.001) end
    end
end

-- Shorthand Globals
require "love_aliases"

LG.setDefaultFilter("nearest", "nearest")


-- Resource Globals

require "resources"

-- State Management

---@class State
---@field init fun()
---@field update fun()
---@field draw fun(alpha: number)
---@field drawHUD nil | fun(alpha: number)
---@field mouseMoved nil | fun(x: number, y: number, dx: number, dy: number, isTouch: boolean)
---@field mousePressed nil | fun(x: number, y: number, button: number, isTouch: boolean)
---@field mouseReleased nil | fun(x: number, y: number, button: number, isTouch: boolean)
---@field keyPressed nil | fun(key: love.KeyConstant, scancode: love.Scancode, isRepeat: boolean)
---@field keyReleased nil | fun(key: love.KeyConstant, scancode: love.Scancode)

---@type State
local state

---@param s State
function ChangeState(s)
    s.init()

    state = s
end

--- Draws a sprite OR a red placeholder if the sprite cannot be found
---@param sprite love.Image|love.Quad If `SPRITESHEET` is defined, pass a `Quad`, otherwise pass the `Image` to draw
---@param x number? X coordinate. nil means center on x-axis.
---@param y number? Y coordinate. nil means center on y-axis.
---@param sx number? Scale X. nil means use the `SPR_SCALE` constant.
---@param sy number? Scale Y. nil means use the `SPR_SCALE` constant.
---@param r number? Rotation. nil means no rotation.
function love.graphics.spr(sprite, x, y, sx, sy, r)
    sx = sx or SPR_SCALE
    sy = sy or SPR_SCALE

    local w = RAW_SPR_SIZE * sx
    local h = RAW_SPR_SIZE * sy

    x = x or (DESIGN_W-w)/2
    y = y or (DESIGN_H-h)/2

    if SPRITESHEET then
        LG.draw(SPRITESHEET, sprite --[[@as love.Quad]], x, y, r, sx, sy)

        return
    end

    if not sprite then
        LG.setColor(1, 0, 0)
        LG.setLineWidth(2)

        LG.rectangle("line", x, y, w, h)

        LG.line(x + w/3, y + h/3, x + w*2/3, y + h*2/3)
        LG.line(x + w/3, y + h*2/3, x + w*2/3, y + h/3)

        LG.setColor(1, 1, 1)

        return
    end

    LG.draw(sprite --[[@as love.Image]], x, y, r or 0, sx, sy)
end


local fontCache = {}

---comment
---@param font string Font name, typically from the `FONTS` table. If the font cannot be loaded, the default font is used. 
---@param size number Font size
---@param value any Value to print.
---@param x? number X coordinate. nil means center the text on the X-axis.
---@param y? number Y coordinate. nil means center the text on the Y-axis. 
function love.graphics.text(font, size, value, x, y)
    value = tostring(value)

    local cacheKey = font..'+'..tostring(size)
    local inCache = fontCache[cacheKey]

    if not inCache then
        local success
        success, inCache = pcall(LG.newFont, font, size)

        if not success then
            inCache = LG.newFont(size)
            cacheKey = '@default+'..tostring(size)
        end

        fontCache[cacheKey] = inCache
    end

    x = x or (DESIGN_W - inCache:getWidth(value))/2
    y = y or (DESIGN_H - inCache:getHeight())/2

    LG.setFont(inCache)
    LG.print(tostring(value), x, y)
end

local emptyData = love.sound.newSoundData(1)
local emptySource = LA.newSource(emptyData)

--- Wraps a `love.Source` for graceful handling of missing audio.
---@param source love.Source The source to wrap.
function Audio(source)
    if source then
        return source
    end

    return emptySource
end

---@alias BoxColSecond fun(x2: number, y2: number, w2: number, h2: number): boolean

--- Collision check on two boxes.
---@param x1 number X coordinate of the first box.
---@param y1 number Y coordinate of the first box.
---@param w1 number Width of the first box.
---@param h1 number Height of the first box.
---@return BoxColSecond BoxColSecond A function which takes the second box and returns the result of the collision.
function BoxCol(x1, y1, w1, h1)
    local function boxColSecond(x2, y2, w2, h2)
        return not (
            x1 + w1 <= x2 or
            x1 >= x2 + w2 or

            y1 + h1 <= y2 or
            y1 >= y2 + h2
        )
    end

    return boxColSecond
end

---@class CollisionObject
---@field x number
---@field y number
---@field w number
---@field h number
---@field dx number?
---@field dy number?

---@alias ObjColSecond fun(o: CollisionObject, x2: number?, y2: number?, w2: number?, h2: number?, dx2: number?, dy2: number?)

--- Performs box collision on two `CollisionObject`-s that contain position and velocity information.
---@param t CollisionObject The first `CollisionObject`. 
---@param x1 number? The X coordinate of the first object. **Only used if `t == nil`.**
---@param y1 number? The Y coordinate of the first object. **Only used if `t == nil`.**
---@param w1 number? The width of the first object. **Only used if `t == nil`.**
---@param h1 number? The height of the first object. **Only used if `t == nil`.**
---@param dx1 number? The X velocity of the first object for better collision checking. If not passed, `0` is implied.
---@param dy1 number? The Y velocity of the first object for better collision checking. If not passed, `0` is implied.
---@return ObjColSecond ObjColSecond A function which takes the second object (or the manually specified parameters) and returns the result of the collision.
function ObjCol(t, x1, y1, w1, h1, dx1, dy1)
    t = t or {
        x = x1 + (dx1 or 0),
        y = y1 + (dy1 or 0),
        w = w1,
        h = h1
    }

    local colWithT = BoxCol(t.x + (t.dx or dx1), t.y + (t.dy or dy1), t.w, t.h)

    local function objColSecond(o, x2, y2, w2, h2, dx2, dy2)
        o = o or {
            x = x2 + (dx2 or 0),
            y = y2 + (dy2 or 0),
            w = w2,
            h = h2
        }

        return colWithT(o.x + (o.dx or dx2), o.y + (o.dy or dy2), o.w, o.h)
    end

    return objColSecond
end

---@alias EasingFunction fun(start: number, finish: number, progress: number)

--- Linear Interpolation
---@param start number The starting value.
---@param finish number The ending value.
---@param progress number The current progress or "percentage". `0 == start`, `1 == end`, `0.5` is halfway between `start` and `end`, etc.
---@return number value The resulting number in the range `[start, finish]`.
function Lerp(start, finish, progress)
    return start + (finish - start) * progress
end

--- Interpolation with exponential stopping. Starts very fast, slows down smoothly at the end.
---@param start number The starting value.
---@param finish number The ending value.
---@param progress number The current progress or "percentage". `0 == start`, `1 == end`, `0.5` is halfway between `start` and `end`, etc.
---@return number value The resulting number in the range `[start, finish]`.
function EaseOutExp(start, finish, progress)
    return start + (1 - 2^(-10 * progress)) * (finish - start)
end

local camX = 0
local camY = 0

local camStartX = 0
local camStartY = 0
local camTargetX = 0
local camTargetY = 0
local camTimer = 1
local camTimerIncr = 0

--- @type EasingFunction
local camEasing

local camTrackTarget
local camTrackBoundX
local camTrackBoundY
local camTrackBoundW
local camTrackBoundH

--- Immediately snap the camera to the given target.
---@param x number The X coordinate.
---@param y number The Y coordinate.
function CamSnapTo(x, y)
    camX, camY = x, y
    camTargetX, camTargetY = x, y
    camTimer = 1
end

--- Smoothly move to the camera to a target.
---@param x number The target X coordinate.
---@param y number The target Y coordinate.
---@param duration? number The duration **in frames** the transition should take. **Defaults to 25 frames**.
---@param easing EasingFunction An easing function to make the transition more smooth. **Defaults to `EaseOutExp`**.
function CamMoveTo(x, y, duration, easing)
    camStartX, camStartY = camX, camY
    camTargetX, camTargetY = x, y
    camTimer = 0
    camTimerIncr = 1/(duration or 25)
    camEasing = easing or EaseOutExp
end

---@class CameraTrackingObject
---@field x number
---@field y number
---@field w? number
---@field h? number

--- Set the camera to track a `CollisionObject`, pushing the camera if the object tries to step outside of the *camera bounding box*.
--- **Omit the `target` parameter to disable tracking.**
---@param target? CameraTrackingObject The object to track. If `w` and/or `h` are present, the object's center point is tracked on the respective axis, otherwise only `x` and `y` are used.
---@param width? number The width of the *camera bounding box*. If not provided, the whole screen if used.
---@param height? number The height of the *camera bounding box*. If ommited, the size of `width` is used.
---@overload fun(target: CameraTrackingObject, width: number)
---@overload fun(target: CameraTrackingObject)
---@overload fun()
function CamTrack(target, width, height)
    if not target then
        camTrackTarget = nil
        return
    end

    height = height or width

    if not width then
        width = DESIGN_W
        height = DESIGN_H
    end

    camTrackTarget = target

    camTrackBoundX = (DESIGN_W - width)/2
    camTrackBoundY = (DESIGN_H - height)/2
    camTrackBoundW = width
    camTrackBoundH = height
end
---@generic T
---@param list T[] Continous array to filter
---@param callback fun(element: T): boolean Function that gets called for every element. If `true` is returned, the element is removed
function table.filter(list, callback)
    local idx_old = 1
    local idx_new = 1

    local list_size_tmp = #list
    while idx_old <= list_size_tmp do
        local element = list[idx_old];
        if callback(element) then
            list[idx_old] = nil
            idx_old = idx_old + 1
        else
            if idx_old ~= idx_new then
                list[idx_new] = element;
                list[idx_old] = nil;
            end
            idx_old = idx_old + 1
            idx_new = idx_new + 1
        end
    end
end

---@class Updateable
---@field update fun(...)
---@field isDead? fun(): boolean

---@class Drawable
---@field draw fun(alpha: number)

---@param list Updateable[]
---@param ... any
function table.update(list, ...)
    table.filter(list, function(e)
        e.update(arg)

        if e.isDead then
            return e.isDead()
        end

        return false
    end)
end

---@param list Drawable[]
---@param alpha number
function table.draw(list, alpha)
    for i=1, #list do
        list[i].draw(alpha)
    end
end

require "states"

local canvas = LG.newCanvas(DESIGN_W, DESIGN_H)

function love.mousemoved(x, y, dx, dy, istouch)
    if state.mouseMoved then
        state.mouseMoved(x, y, dx, dy, istouch)
    end

    if BACKGROUND.mouseMoved then
        BACKGROUND.mouseMoved(x, y, dx, dy, istouch)
    end
end

function love.mousepressed(x, y, button, istouch)
    if state.mousePressed then
        state.mousePressed(x, y, button, istouch)
    end

    if BACKGROUND.mousePressed then
        BACKGROUND.mousePressed(x, y, button, istouch)
    end
end

function love.mousereleased(x, y, button, istouch)
    if state.mouseReleased then
        state.mouseReleased(x, y, button, istouch)
    end

    if BACKGROUND.mouseReleased then
        BACKGROUND.mouseReleased(x, y, button, istouch)
    end
end

function love.keypressed(key, scancode, isrepeat)
    if state.keyPressed then
        state.keyPressed(key, scancode, isrepeat)
    end

    if BACKGROUND.keyPressed then
        BACKGROUND.keyPressed(key, scancode, isrepeat)
    end
end

function love.keyreleased(key, scancode)
    if state.keyReleased then
        state.keyReleased(key, scancode)
    end
end

function love.update()
    state.update()

    if camTrackTarget then
        local xOffset = camTrackTarget.w and camTrackTarget.w/2 or 0
        local yOffset = camTrackTarget.h and camTrackTarget.h/2 or 0

        local x = camTrackTarget.x + xOffset - camX
        local y = camTrackTarget.y + yOffset - camY

        local endX = camTrackBoundX + camTrackBoundW
        local endY = camTrackBoundY + camTrackBoundH

        if x < camTrackBoundX then
            camX = camX - (camTrackBoundX - x)
        elseif x > endX then
            camX = camX + (x - endX)
        end

        if y < camTrackBoundY then
            camY = camY - (camTrackBoundY - y)
        elseif y > endY then
            camY = camY + (y - endY)
        end
    elseif camTimer < 1 then
        camX = camEasing(camStartX, camTargetX, camTimer)
        camY = camEasing(camStartY, camTargetY, camTimer)

        camTimer = camTimer + camTimerIncr
    end

end

function love.draw(alpha)
    WINDOW_W, WINDOW_H = LG.getDimensions()

    do
        LG.setCanvas(canvas)
        LG.push()
        LG.clear()

        LG.push()
        LG.translate(-camX, -camY)
        state.draw(alpha)
        LG.pop()

        if state.drawHUD then
            state.drawHUD(alpha)
        end

        LG.pop()
        LG.setCanvas()
    end

    BACKGROUND.draw(alpha)

    local scale = math.min(WINDOW_W / DESIGN_W, WINDOW_H / DESIGN_H)

    local x = (WINDOW_W - DESIGN_W * scale)/2
    local y = (WINDOW_H - DESIGN_H * scale)/2

    LG.setColor(0, 0, 0, 1)
    LG.rectangle("fill", x, y, DESIGN_W*scale, DESIGN_H*scale)
    LG.setColor(1, 1, 1, 1)
    LG.draw(canvas, x, y, 0, scale, scale)
end