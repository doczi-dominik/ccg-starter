local ldtk = require("lib.ldtk")
local s = {}


local teleports = {}
local current_layer = {}

local player = {
    x = 0,
    y = 0,
    w = 10,
    h = 10,
    color = {1, 1, 1, 1}
}

function s.init()
    LG.setDefaultFilter('nearest', "nearest")
    LG.setLineStyle('rough')

    ldtk:load("example_states/ldtk/map.ldtk")
    ldtk:level("Level0")
end

function s.update()
    if current_layer then
        local collided = false
        local player_col = BoxCol(player.x, player.y, player.w, player.h)
        for i = 1, #current_layer.tiles, 1 do
            local tile = current_layer.tiles[i]
            if player_col(tile.px[1], tile.px[2], current_layer.gridSize, current_layer.gridSize) then
                collided = true
            end
        end

        if collided then 
            player.color = {1, 0, 0, 1}
        else 
            player.color = {1, 1, 1, 1}
        end
    end

    if LK.isDown("a") then 
        player.x = player.x - 3
    end

    if LK.isDown("d") then 
        player.x = player.x + 3
    end

    if LK.isDown("w") then 
        player.y = player.y - 3
    end

    if LK.isDown("s") then 
        player.y = player.y + 3
    end
end

function s.draw()
    LG.setColor(1, 1, 1, 1)
    if current_layer then
        current_layer:draw()
    end

    LG.setColor(player.color)
    LG.rectangle("fill", player.x, player.y, player.w, player.h)
end

-- Override the callbacks with your game logic.
function ldtk.onEntity(entity)
    if entity.id == "Teleport" then
        table.insert(teleports, entity)
    end
end

function ldtk.onLayer(layer)
    current_layer = layer
end

function ldtk.onLevelLoaded(level)
    teleports = {}
end

function ldtk.onLevelCreated(level)
    print("done")
end

return s
