
local s = {}

function s.init()
end

function s.update()
end

-- Use WINDOW_W and WINDOW_H for actual
-- window size
function s.draw(alpha)
   LG.setColor(1, 0, 0)
   LG.rectangle("fill", 0, 0, WINDOW_W, WINDOW_H)
end

return s