function init()
  if entity.entityType() == "monster" then effect.expire() end
end

local duration = 5

function update()

	if status.stat("gic_opiate_overdose_active_check") == 1 then
		status.addEphemeralEffect("gic_drysap_cardiacarrest",50); -- this function can config effect duration
		effect.expire(); --kills off primer effect. hopefully will avoid any crashes w primer running out of duration. Note from Med: Confirmed working. Doesn't cause crashes.
    end

end

function uninit()

end
