--Modded version of original love.run
return function()
	if love.math then
		love.math.setRandomSeed(os.time())
	end

	if love.event then
		love.event.pump()
	end

	if love.load then xpcall(love.load, _Debug.handleError) end

	if love.timer then love.timer.step() end

	local lag = 0.0
	-- Main loop time.
	return function()
		while true do

			-- Process events. We don't touch this.
			if love.event then
				love.event.pump()
				for name, a,b,c,d,e,f in love.event.poll() do
					if name == "quit" then
						local quit = false
						--if love.quit then
						--	xpcall(function() quit = love.quit() end, _Debug.handleError)
						--end
						if not love.quit or not love.quit() then
							return a or 0
						end
					end
					local skipEvent = false
					if name == "textinput" then --Keypress
						skipEvent = true
						_Debug.handleKey(a)
						if not _Debug.drawOverlay then
							if love.textinput then love.textinput(a) end
						end
					end
					if name == "keypressed" then --Keypress
						skipEvent = true

						if string.len(a)>=2 or (love.keyboard.isDown('lctrl') and (a == 'c' or a == 'v')) then _Debug.handleKey(a) end
						if not _Debug.drawOverlay then
							if love.keypressed then love.keypressed(a,b) end
						end
					end
					if name == "keyreleased" then --Keyrelease
						skipEvent = true
						if not _Debug.drawOverlay then
							if love.keyreleased then love.keyreleased(a, b) end
						end
					end
					if name == "mousepressed" and _Debug.drawOverlay then --Mousepress
						skipEvent = true
						_Debug.handleMouse(a, b, c)
					end
					if not skipEvent then
						xpcall(function() love.handlers[name](a,b,c,d,e,f) end, _Debug.handleError)
					end
				end
			end
			if love.timer then
                lag = math.min(lag + love.timer.step(), TICK_RATE * MAX_FRAME_SKIP)
				love.timer.step()
				dt = love.timer.getDelta()
				_Debug.onTopUpdate(dt)
			end

			_Debug.tick = _Debug.tick - TICK_RATE
			if _Debug.tick <= 0 then
				_Debug.tick = _Debug.tickTime + _Debug.tick
				_Debug.drawTick = not _Debug.drawTick
			end

			if _Debug.drawOverlay then
				for key, d in pairs(_Debug.trackKeys) do
					local _key = key
					if type(key) == 'string' and key ~= " " then
						if not (_key == "{" or _key == "}") and
						 love.keyboard.isDown(key:lower()) then
							d.time = d.time + dt
							if d.time >= _Debug.keyRepeatInterval then
								d.time = 0
								_Debug.handleVirtualKey(_key)
							end
						else
						 	_Debug.trackKeys[key] = nil
						end
				 	else
						if love.keyboard.isDown('v') and love.keyboard.isDown('lctrl') then
							d.time = d.time + dt
							if d.time >= _Debug.keyRepeatInterval then
								d.time = 0
								_Debug.handleVirtualKey(key)
							end
						else
						 	_Debug.trackKeys[key] = nil
						end
					end
				end

            	-- Call love.update() if we are not to halt program execution
            	if _DebugSettings.HaltExecution == false then
                    -- Let the debug console halt execution, but still only tick with our tickrate
                    while lag >= TICK_RATE do
                        if love.update then
                            xpcall(function() love.update() end, _Debug.handleError)
                        end
                        lag = lag - TICK_RATE
                    end
                elseif _DebugSettings.HaltExecution == true then
                    lag = 0 -- Don't let frames accumulate till infinity
                end

            	-- Auto scroll the console if AutoScroll == true
            	if _DebugSettings.AutoScroll == true then
                	if _Debug.orderOffset < #_Debug.order - _Debug.lastRows + 1 then
                    	_Debug.orderOffset = #_Debug.order - _Debug.lastRows + 1
                	end
            	end
			end

			if love.update and not _Debug.drawOverlay then
				if _DebugSettings.LiveAuto and _Debug.liveCheckLastModified(_DebugSettings.LiveFile,_Debug.liveLastModified) then
					if type(_DebugSettings.LiveFile) == 'table' then
						for i=1,#_DebugSettings.LiveFile do
							if love.filesystem.getInfo(_DebugSettings.LiveFile[i]).modtime ~= _Debug.liveLastModified[i] then
								_Debug.hotSwapUpdate(dt,_DebugSettings.LiveFile[i])
								_Debug.liveLastModified[i] = love.filesystem.getInfo(_DebugSettings.LiveFile[i]).modtime
							end
						end
						if _DebugSettings.LiveReset then
							_Debug.hotSwapLoad()
						end
					else
						_Debug.hotSwapUpdate(dt,_DebugSettings.LiveFile)
						_Debug.liveLastModified = love.filesystem.getInfo(_DebugSettings.LiveFile).modtime
						if _DebugSettings.LiveReset then
							_Debug.hotSwapLoad()
						end
					end
				else
                    while lag >= TICK_RATE do
                        if love.update then
                            xpcall(function() love.update() end, _Debug.handleError)
                        end
                        lag = lag - TICK_RATE
                    end
				end
			elseif love.update and (_Debug.liveDo or (_DebugSettings.LiveAuto and _Debug.liveCheckLastModified(_DebugSettings.LiveFile,_Debug.liveLastModified))) then
				if type(_DebugSettings.LiveFile) == 'table' then
					for i=1,#_DebugSettings.LiveFile do
						if (_DebugSettings.LiveAuto and love.filesystem.getInfo(_DebugSettings.LiveFile[i]) ~= _Debug.liveLastModified[i]) or _Debug.liveDo then
							_Debug.hotSwapUpdate(dt,_DebugSettings.LiveFile[i])
							_Debug.liveLastModified[i] = love.filesystem.getInfo(_DebugSettings.LiveFile[i]).modtime
						end
					end
					if _DebugSettings.LiveReset then
						_Debug.hotSwapLoad()
					end
				else
					_Debug.hotSwapUpdate(dt,_DebugSettings.LiveFile)
					if _DebugSettings.LiveReset then
						_Debug.hotSwapLoad()
					end
					_Debug.liveLastModified = love.filesystem.getInfo(_DebugSettings.LiveFile).modtime
				end
			end -- will pass 0 if love.timer is disabled
			if love.graphics and love.graphics.isActive() then
				love.graphics.clear(love.graphics.getBackgroundColor())
				love.graphics.origin()
				if love.draw then if _Debug.liveDo then _Debug.hotSwapDraw() _Debug.liveDo=false end xpcall(love.draw, _Debug.handleError) end
				if _DebugSettings.DrawOnTop then _Debug.onTop() end
				if _Debug.drawOverlay then _Debug.overlay() end
				love.graphics.present()
			end
			if love.timer then love.timer.sleep(0.001) end
		end
	end
end
