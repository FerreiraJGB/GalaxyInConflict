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
    {stat = "protection", amount = 100.0},
    {stat = "fireResistance", amount = 100.0},
    {stat = "iceResistance", amount = 100.0},
    {stat = "poisonResistance", amount = 100.0},
    {stat = "electricResistance", amount = 100.0},
    {stat = "physicalResistance", amount = 100.0},
    {stat = "radioactiveResistance", amount = 100.0},
    {stat = "shadowResistance", amount = 100.0},
    {stat = "cosmicResistance", amount = 100.0},
	
    {stat = "ews_meleeResistance", amount = 100.0},
    {stat = "ews_smallarmsResistance", amount = 100.0},
    {stat = "ews_heavyarmsResistance", amount = 100.0},
	
	
	
	
	
    {stat = "novaResistance", amount = 100.0},
    {stat = "holyResistance", amount = 100.0},
    {stat = "demonicResistance", amount = 100.0},
    {stat = "bleedResistance", amount = 100.0},
    {stat = "shadowResistance", amount = 100.0},
    {stat = "cosmicResistance", amount = 100.0},
    {stat = "radioactiveResistance", amount = 100.0},
    {stat = "linerifleResistance", amount = 100.0},
    {stat = "centensianenergyResistance", amount = 100.0},
    {stat = "xanafianResistance", amount = 100.0},
    {stat = "akkimariacidResistance", amount = 100.0},
    {stat = "silverResistance", amount = 100.0}	
	
	
  })
end

function update(dt)
  self.listener:update()
end

function uninit()
	effect.removeStatModifierGroup(self.statModifierGroup)
end