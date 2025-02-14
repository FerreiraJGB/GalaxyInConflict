function init()
end

local duration = 5
function update()
	if status.stat("gic_medkit_use_messenger") == 1 then
		status.addEphemeralEffect("gic_healing_slowdown_1",0.1); -- this function can config effect duration
		status.addEphemeralEffect("gic_combatcasualtycare",0.1); -- this function can config effect duration
		effect.expire(); --kills off primer effect. hopefully will avoid any crashes w primer running out of duration. Note from Med: Confirmed working. Doesn't cause crashes.
    end
end

function uninit()
end
