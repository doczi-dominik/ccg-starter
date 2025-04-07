Cam = require("lib.Brady.camera")

if os.getenv("LOCAL_LUA_DEBUGGER_VSCODE") == "1" then
    require("lldebugger").start()
    require("lib.lovedebug")
    _G["love"].run = require("debug_run")
else 
    _G["love"].run = require("release_run")
end


-- Shorthand Globals
require("love_aliases")

LG.setDefaultFilter("nearest", "nearest")

-- Resource Globals

require("resources")

for k, v in pairs(SFX) do
    SFX[k] = LA.newSource(v, "static")
end

for k, v in pairs(BGM) do
    BGM[k] = LA.newSource(v, "stream")
end

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
---@field wheelMoved nil | fun(dx: number, dy: number)

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

    x = x or (DESIGN_W - w) / 2
    y = y or (DESIGN_H - h) / 2

    if SPRITESHEET then
        LG.draw(SPRITESHEET, sprite --[[@as love.Quad]], x, y, r, sx, sy)

        return
    end

    if not sprite then
        LG.setColor(1, 0, 0)
        LG.setLineWidth(2)

        LG.rectangle("line", x, y, w, h)

        LG.line(x + w / 3, y + h / 3, x + w * 2 / 3, y + h * 2 / 3)
        LG.line(x + w / 3, y + h * 2 / 3, x + w * 2 / 3, y + h / 3)

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

    local cacheKey = font .. "+" .. tostring(size)
    local inCache = fontCache[cacheKey]

    if not inCache then
        local success
        success, inCache = pcall(LG.newFont, font, size)

        if not success then
            inCache = LG.newFont(size)
            cacheKey = "@default+" .. tostring(size)
        end

        fontCache[cacheKey] = inCache
    end

    x = x or (DESIGN_W - inCache:getWidth(value)) / 2
    y = y or (DESIGN_H - inCache:getHeight()) / 2

    LG.setFont(inCache)
    LG.print(tostring(value), x, y)
end

local emptyData = love.sound.newSoundData(1)
local emptySource = LA.newSource(emptyData)

local placeholderSfx = LA.newSource("resources/placeholder-sfx.ogg", "static")

--- Wraps a `love.Source` for graceful handling of missing audio.
---@param source love.Source The source to wrap.
function Audio(source)
    if source then
        return source
    end

    return placeholderSfx
end

---@param id string The name of the SFX (defined in resources/audio.lua)
---@return love.Source love.Source The SFX in question, or the placeholder SFX if not found.
function GetSFX(id)
    local sfx = SFX[id]

    if sfx == nil then
        return placeholderSfx
    end

    ---@type love.Source
    return sfx
end

function GetBGM(id)
    local bgm = BGM[id]

    if bgm == nil then
        return emptySource
    end

    ---@type love.Source
    return bgm
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
        return not (x1 + w1 <= x2 or x1 >= x2 + w2 or y1 + h1 <= y2 or y1 >= y2 + h2)
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
        h = h1,
    }

    local colWithT = BoxCol(t.x + (t.dx or dx1), t.y + (t.dy or dy1), t.w, t.h)

    local function objColSecond(o, x2, y2, w2, h2, dx2, dy2)
        o = o or {
            x = x2 + (dx2 or 0),
            y = y2 + (dy2 or 0),
            w = w2,
            h = h2,
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
    return start + (1 - 2 ^ (-10 * progress)) * (finish - start)
end

---@class Spring
---@field x number The value of the spring
---@field target_x number The initial value to spring back to
---@field k number The current stiffness
---@field d number The current damping
---@field v number idk what this is exactly
---@field pull fun(self: Spring, f: number, k?: number, d?: number) Pull the spring with the specified value, optionally set new Stiffness or Damping
---@field update fun(self: Spring, dt: number) Function that is mandatory to call every frame

---@param x? number Initial value, **default: 0**
---@param k? number Stiffness, **default: 100**
---@param d? number Damping **default: 10**
---@return Spring
function Spring(x, k, d)
    local t = {}
    t.x = x or 0
    t.k = k or 100
    t.d = d or 10
    t.target_x = t.x
    t.v = 0

    t.update = function(self, dt)
        local a = -self.k * (self.x - self.target_x) - self.d * self.v
        self.v = self.v + a * dt
        self.x = self.x + self.v * dt
    end
    t.pull = function(self, f, k, d)
        if k then
            self.k = k
        end
        if d then
            self.d = d
        end
        self.x = self.x + f
    end

    return t
end

--- Filter elements from a table
---@generic T
---@param list T[] Continous array to filter
---@param callback fun(element: T): boolean Function that gets called for every element. If `true` is returned, the element is removed
function table.filter(list, callback)
    local idx_old = 1
    local idx_new = 1

    local list_size_tmp = #list
    while idx_old <= list_size_tmp do
        local element = list[idx_old]
        if callback(element) then
            list[idx_old] = nil
            idx_old = idx_old + 1
        else
            if idx_old ~= idx_new then
                list[idx_new] = element
                list[idx_old] = nil
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
---@param alpha number Interpolation value - must be multiplied with when things are in motion
function table.draw(list, alpha)
    for i = 1, #list do
        list[i].draw(alpha)
    end
end

require("states")

local canvas = LG.newCanvas(DESIGN_W, DESIGN_H)

function love.mousemoved(x, y, dx, dy, istouch)
    if state.mouseMoved then
        state.mouseMoved(x, y, dx, dy, istouch)
    end

    if BACKGROUND.mouseMoved then
        BACKGROUND.mouseMoved(x, y, dx, dy, istouch)
    end
end

function love.wheelmoved(dx, dy)
    if state.wheelMoved then
        state.wheelMoved(dx, dy)
    end

    if BACKGROUND.wheelMoved then
        BACKGROUND.wheelMoved(x, y)
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
end

function love.draw(alpha)
    WINDOW_W, WINDOW_H = LG.getDimensions()

    do
        LG.setCanvas(canvas)
        LG.push()
        LG.clear()

        LG.push()
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

    local x = (WINDOW_W - DESIGN_W * scale) / 2
    local y = (WINDOW_H - DESIGN_H * scale) / 2

    LG.setColor(0, 0, 0, 1)
    LG.rectangle("fill", x, y, DESIGN_W * scale, DESIGN_H * scale)
    LG.setColor(1, 1, 1, 1)
    LG.draw(canvas, x, y, 0, scale, scale)
end



