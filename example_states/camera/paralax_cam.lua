
---@type State
local s = {}
local cam = Cam.new(300, 300, { x = 0, y = 0, offsetX = 0, offsetY = 0, center = true, resizable = true, maintainAspectRatio = true })
cam:addLayer("bg_1", 1, { relativeScale = 0.8 })
cam:addLayer("bg_2", 1, { relativeScale = 0.5 })
cam:addLayer("bg_3", 1, { relativeScale = 0.2 })


function s.init()
end

function s.update()
    cam:update()
    cam:setOffset(0,0)

    if LK.isDown("a") then
        cam:increaseTranslation(-1, 0)
    end

    if LK.isDown("w") then
        cam:increaseTranslation(0, -1)
    end

    if LK.isDown("s") then
        cam:increaseTranslation(0, 1)
    end

    if LK.isDown("d") then
        cam:increaseTranslation(1, 0)
    end

    if LK.isDown("q") then
        local x, y = cam:getWorldCoordinates(WINDOW_W/2, WINDOW_H/2)
        cam:scaleToPoint(1.1, x, y)
    end

    if LK.isDown("e") then
        local x, y = cam:getWorldCoordinates(WINDOW_W/2, WINDOW_H/2)
        cam:scaleToPoint(0.9, x, y)
    end
end

function s.draw()
    LG.setColor(0.5, 0.5, 0.5)
    cam:push("bg_3")
    LG.rectangle("fill", 100, 100, 200, 300)
    LG.rectangle("fill", 300, 100, 100, 200)
    LG.rectangle("fill", 500, 100, 100, 400)
    cam:pop("bg_3")

    LG.setColor(0.8, 0.8, 0.8)
    cam:push("bg_2")
    LG.rectangle("fill", 100, 100, 100, 200)
    LG.rectangle("fill", 300, 120, 100, 200)
    LG.rectangle("fill", 500, 140, 100, 200)
    cam:pop("bg_2")

    LG.setColor(1, 1, 1)
    cam:push("bg_1")
    LG.rectangle("fill", 100, 150, 100, 150)
    LG.rectangle("fill", 500, 150, 100, 150)
    cam:pop("bg_1")
end

return s
