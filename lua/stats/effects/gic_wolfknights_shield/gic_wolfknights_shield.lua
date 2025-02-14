require "/scripts/status.lua"

function init()

  self.statModifierGroup = effect.addStatModifierGroup({
    {stat = "fireResistance", amount = -0.50},
    {stat = "iceResistance", amount = -0.50},
    {stat = "poisonResistance", amount = -0.50},
    {stat = "electricResistance", amount = -0.50},
    {stat = "physicalResistance", amount = -0.50},
    {stat = "radioactiveResistance", amount = -0.50},
    {stat = "shadowResistance", amount = -0.50},
    {stat = "cosmicResistance", amount = -0.50},
	
    {stat = "ews_meleeResistance", amount = -0.50},
    {stat = "ews_smallarmsResistance", amount = -0.50},
    {stat = "ews_heavyarmsResistance", amount = -0.50},
    {stat = "ews_explosiveResistance", amount = -0.50},
    {stat = "ews_antitankResistance", amount = -0.50},	
	
    {stat = "novaResistance", amount = -0.50},
    {stat = "holyResistance", amount = -0.50},
    {stat = "demonicResistance", amount = -0.50},
    {stat = "bleedResistance", amount = -0.50},
    {stat = "shadowResistance", amount = -0.50},
    {stat = "cosmicResistance", amount = -0.50},
    {stat = "radioactiveResistance", amount = -0.50},
    {stat = "linerifleResistance", amount = -0.50},
    {stat = "centensianenergyResistance", amount = -0.50},
    {stat = "xanafianResistance", amount = -0.50},
    {stat = "akkimariacidResistance", amount = -0.50},
    {stat = "silverResistance", amount = -0.50}	
  })
end

function update(dt)
end

function uninit()
	effect.removeStatModifierGroup(self.statModifierGroup)
end
