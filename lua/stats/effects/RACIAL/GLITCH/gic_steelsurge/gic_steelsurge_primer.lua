function init()

  self.statModifierGroup = effect.addStatModifierGroup({
    {stat = "ews_bleedResistance", amount = 0.20}
  })

end

local duration = 5
function update()
	if status.stat("gic_bleeding_medium") == 1 or status.stat("gic_bleeding_heavy") == 1 then
		status.addEphemeralEffect("gic_oil",1); -- this function can config effect duration
		effect.expire(); --kills off primer effect. hopefully will avoid any crashes w primer running out of duration. Note from Med: Confirmed working. Doesn't cause crashes.
    end
end

function uninit()
	effect.removeStatModifierGroup(self.statModifierGroup)
end
