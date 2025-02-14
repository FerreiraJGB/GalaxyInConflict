function init()

--  if entity.entityType() == "monster" then effect.expire() end

end

local duration = 5
function update()
	if status.stat("gic_denizen_beast") == 1 then
		status.addEphemeralEffect("gic_denizenbane_poisoning",15); -- this function can config effect duration
		effect.expire(); --kills off primer effect. hopefully will avoid any crashes w primer running out of duration. Note from Med: Confirmed working. Doesn't cause crashes.
    end
end

function uninit()
end
