
-- Nincs ötletem jelenleg ezt a kettőt hova rakjam szóval itt lesznek, nyugodtan pakold át
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
return function()
    ---@diagnostic disable-next-line: undefined-field
    if love.load then
        love.load(love.arg.parseGameArguments(arg), arg)
    end

    -- We don't want the first frame's dt to include time taken by love.load.
    if love.timer then
        love.timer.step()
    end
    local lag = 0.0
    -- Main loop time.
    return function()
        -- Process events.
        if love.event then
            love.event.pump()
            for name, a, b, c, d, e, f in love.event.poll() do
                if name == "quit" then
                    ---@diagnostic disable-next-line: undefined-field
                    if not love.quit or not love.quit() then
                        return a or 0
                    end
                end
                ---@diagnostic disable-next-line: undefined-field
                love.handlers[name](a, b, c, d, e, f)
            end
        end
        -- Cap number of Frames that can be skipped so lag doesn't accumulate
        if love.timer then
            lag = math.min(lag + love.timer.step(), TICK_RATE * MAX_FRAME_SKIP)
        end
        while lag >= TICK_RATE do
            if love.update then
                love.update()
            end
            lag = lag - TICK_RATE
        end
        if love.graphics and love.graphics.isActive() then
            love.graphics.origin()
            love.graphics.clear(love.graphics.getBackgroundColor())

            if love.draw then
                love.draw()



            end
            love.graphics.present()
        end
        -- Even though we limit tick rate and not frame rate, we might want to cap framerate at 1000 frame rate as mentioned https://love2d.org/forums/viewtopic.php?f=4&t=76998&p=198629&hilit=love.timer.sleep#p160881
        if love.timer then
            love.timer.sleep(0.001)
        end
    end
end
