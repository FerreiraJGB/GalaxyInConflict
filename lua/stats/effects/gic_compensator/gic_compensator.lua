function init()
  self.statModifierGroup = effect.addStatModifierGroup({
    {stat = "ews_bleedResistance", amount = -0.25},
	
    {stat = "fireResistance", amount = -0.25},
    {stat = "iceResistance", amount = -0.25},
    {stat = "poisonResistance", amount = -0.25},
    {stat = "electricResistance", amount = -0.25},
    {stat = "physicalResistance", amount = -0.25},
	
    {stat = "ews_meleeResistance", amount = -0.25},
    {stat = "ews_smallarmsResistance", amount = -0.25},
    {stat = "ews_heavyarmsResistance", amount = -0.25},
    {stat = "ews_explosiveResistance", amount = -0.25},	
    {stat = "ews_antitankResistance", amount = -0.25},	
    {stat = "ews_bleedResistance", amount = -0.25},		
	
	
    {stat = "novaResistance", amount = -0.25},
    {stat = "holyResistance", amount = -0.25},
    {stat = "demonicResistance", amount = -0.25},
    {stat = "bleedResistance", amount = -0.25},
    {stat = "shadowResistance", amount = -0.25},
    {stat = "cosmicResistance", amount = -0.25},
    {stat = "radioactiveResistance", amount = -0.25},
    {stat = "linerifleResistance", amount = -0.25},
    {stat = "centensianenergyResistance", amount = -0.25},
    {stat = "xanafianResistance", amount = -0.25},
    {stat = "akkimariacidResistance", amount = -0.25},
    {stat = "silverResistance", amount = -0.25}	
	
  })
end

function update(dt)
  
end

function uninit()
	effect.removeStatModifierGroup(self.statModifierGroup)  
end
