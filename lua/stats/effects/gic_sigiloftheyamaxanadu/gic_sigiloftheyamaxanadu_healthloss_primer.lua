function init()
end

local duration = 5
function update()
	if status.stat("gic_healingflask_medkitheal") == 1 then
		status.addEphemeralEffect("gic_sigiloftheyamaxanadu_healthloss",2); -- this function can config effect duration
		effect.expire(); --kills off primer effect. hopefully will avoid any crashes w primer running out of duration. Note from Med: Confirmed working. Doesn't cause crashes.
    end
end

function uninit()
end
