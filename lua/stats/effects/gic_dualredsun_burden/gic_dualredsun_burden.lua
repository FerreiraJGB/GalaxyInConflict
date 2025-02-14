function init()
  
  self.statModifierGroup = effect.addStatModifierGroup({
    {stat = "protection", amount = 1.0},
    {stat = "fireResistance", amount = -1.0},
    {stat = "iceResistance", amount = -1.0},
    {stat = "poisonResistance", amount = -1.0},
    {stat = "electricResistance", amount = -1.0},
    {stat = "physicalResistance", amount = -1.0},
	
    {stat = "ews_meleeResistance", amount = -1.0},
    {stat = "ews_smallarmsResistance", amount = -1.0},
    {stat = "ews_heavyarmsResistance", amount = -1.0},
    {stat = "ews_explosiveResistance", amount = -1.0},	
    {stat = "ews_antitankResistance", amount = -1.0},	
	
    {stat = "novaResistance", amount = -1.0},
    {stat = "holyResistance", amount = -1.0},
    {stat = "demonicResistance", amount = -1.0},
    {stat = "bleedResistance", amount = -1.0},
    {stat = "shadowResistance", amount = -1.0},
    {stat = "cosmicResistance", amount = -1.0},
    {stat = "radioactiveResistance", amount = -1.0},
    {stat = "linerifleResistance", amount = -1.0},
    {stat = "centensianenergyResistance", amount = -1.0},
    {stat = "xanafianResistance", amount = -1.0},
    {stat = "akkimariacidResistance", amount = -1.0},
    {stat = "silverResistance", amount = -1.0}	
	
  })
  
  
end

function update(dt)
  
end

function uninit()
	effect.removeStatModifierGroup(self.statModifierGroup)  
end
