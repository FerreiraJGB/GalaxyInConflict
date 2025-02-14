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
    {stat = "protection", amount = 1.0},
    {stat = "fireResistance", amount = 0.95},
    {stat = "iceResistance", amount = 0.95},
    {stat = "poisonResistance", amount = 0.95},
    {stat = "electricResistance", amount = 0.95},
    {stat = "physicalResistance", amount = 0.8},
	
    {stat = "ews_meleeResistance", amount = 3.0},
    {stat = "ews_smallarmsResistance", amount = 0.7},
    {stat = "ews_heavyarmsResistance", amount = 0.7},
    {stat = "ews_explosiveResistance", amount = 0.9},	
    {stat = "ews_antitankResistance", amount = 0.0},	
	
	
	
    {stat = "novaResistance", amount = 0.8},
    {stat = "holyResistance", amount = 0.8},
    {stat = "demonicResistance", amount = 0.8},
    {stat = "bleedResistance", amount = 100.0},
    {stat = "shadowResistance", amount = 0.8},
    {stat = "cosmicResistance", amount = 0.8},
    {stat = "radioactiveResistance", amount = 0.8},
    {stat = "linerifleResistance", amount = 0.8},
    {stat = "centensianenergyResistance", amount = 0.8},
    {stat = "xanafianResistance", amount = 0.8},
    {stat = "akkimariacidResistance", amount = 0.8},
    {stat = "silverResistance", amount = 0.8}	
	
	
  })
end

function update(dt)
  self.listener:update()
end

function uninit()
	effect.removeStatModifierGroup(self.statModifierGroup)
end