--[[
this dynamically changes the playback speed of a video based on the size of the cache
]]--

KEYBIND = "ctrl+a"
MAX_SPEED = 2.5 -- speped multiplier
UPDATE_TIMER = 1 -- seconds

CACHE_LOWER = 20 -- seconds
CACHE_UPPER = 60 -- seconds
NORMAL_SPEED = 1 -- speped multiplier

local mp = require "mp"
local msg = require "mp.msg"

local function interpl(x0, x1, y0, y1, x)
	return (y1-y0)/(x1-x0)*(x-x0)+y0
end

local function setSpeedWithLog(speed, level, m)
	msg.log(level, m)
	mp.commandv("set", "speed", speed)
end

local function updateSpeed()
	if mp.get_property("paused-for-cache") == "yes" then
		setSpeedWithLog(NORMAL_SPEED, "debug", "Played paused for cache, setting to normal speed")
		return
	end
	if mp.get_property("core-idle") == "yes" then
		msg.debug("Played paused, returning")
		return
	end
	if mp.get_property("demuxer-cache-idle") == "yes" then
		setSpeedWithLog(MAX_SPEED, "debug", "Cached reached the end of the video, setting to max speed: " .. MAX_SPEED)
		return
	end
	local cache_duration = tonumber(mp.get_property("demuxer-cache-duration"))
	if cache_duration > CACHE_UPPER then
		setSpeedWithLog(MAX_SPEED, "debug", "Enough cache, setting to max speed: " .. MAX_SPEED)
	elseif cache_duration < CACHE_LOWER then
		setSpeedWithLog(NORMAL_SPEED, "debug", "Cache below minimum, setting to normal speed")
	else
		local speed = interpl(CACHE_LOWER, CACHE_UPPER, NORMAL_SPEED, MAX_SPEED, cache_duration)
		setSpeedWithLog(speed, "debug", "Not enough cache, dynamically setting speed to " .. speed)
	end
end

local timer
local function toggleDPBS()
	if timer then
		timer:kill()
		timer = nil
		local m = "Disabled dynamic playback speed, cap: " .. MAX_SPEED
		mp.osd_message(m)
		msg.info(m)
		return
	end
	local m = "Enabled dynamic playback speed, cap: " .. MAX_SPEED
	timer = mp.add_periodic_timer(UPDATE_TIMER, updateSpeed)
	mp.osd_message(m)
	msg.info(m)

end

mp.add_key_binding(KEYBIND, "toggle-adjust-playback-speed", toggleDPBS)