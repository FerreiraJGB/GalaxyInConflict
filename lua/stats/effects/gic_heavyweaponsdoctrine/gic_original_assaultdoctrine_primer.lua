function init()
end

local duration = 5
function update()
	if status.stat("gic_gunfirenoise") == 1 then
		status.addEphemeralEffect("gic_original_assaultdoctrine",1); -- this function can config effect duration
		effect.expire(); --kills off primer effect. hopefully will avoid any crashes w primer running out of duration. Note from Med: Confirmed working. Doesn't cause crashes.
    end
end

function uninit()
end
