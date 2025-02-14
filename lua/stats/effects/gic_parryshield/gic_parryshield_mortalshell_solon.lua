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
	
    {stat = "ews_smallarmsResistance", amount = 100.0},
    {stat = "ews_heavyarmsResistance", amount = 0.5},
    {stat = "ews_explosiveResistance", amount = 100.0},
    {stat = "ews_antitankResistance", amount = 0.95},	
	
    {stat = "gic_dodge_stat", amount = -1.0},	
	
    {stat = "grit", amount = 1.0}
	
	
  })
end

function update(dt)
  self.listener:update()
end

function uninit()
	effect.removeStatModifierGroup(self.statModifierGroup)
end