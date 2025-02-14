function init()
end

local duration = 5
function update()
	if status.stat("gic_stunned") == 1 then
		status.addEphemeralEffect("gic_survivorsrune",3); -- this function can config effect duration
		--status.addEphemeralEffect("gic_oilburning"); -- if this function is specified w/o duration, will default to base duration of effect
		effect.expire(); --kills off primer effect. hopefully will avoid any crashes w primer running out of duration. Note from Med: Confirmed working. Doesn't cause crashes.
    end
end

function uninit()
end
