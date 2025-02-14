require "/scripts/status.lua"

function init()
  self.listener = damageListener("damageTaken", function(notifications)
	for _,notification in pairs(notifications) do
      if not (notification.damageSourceKind == "hidden" or notification.damageSourceKind == "noDamage") then
		animator.setAnimationState("shield", "hit")
	  end
	end
  end)

  self.statModifierGroup = effect.addStatModifierGroup({


    {stat = "physicalResistance", amount = 0.2},
    {stat = "ews_meleeResistance", amount = 0.4}

  })
end

function update(dt)
  self.listener:update()
end

function uninit()
	effect.removeStatModifierGroup(self.statModifierGroup)
end