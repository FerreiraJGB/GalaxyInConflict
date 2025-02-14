function init()


  --Power
  self.powerModifier = config.getParameter("powerModifier", 0)
  self.statModifierGroup2 = effect.addStatModifierGroup({{stat = "powerMultiplier", effectiveMultiplier = self.powerModifier}})  

  self.statModifierGroup1 = effect.addStatModifierGroup({
  
  
     {stat = "ews_misschance_mult", amount = 0.2},   
     {stat = "ews_inaccuracy_mult", amount = 0.2},   
  
     {stat = "powerMultiplier", amount = -0.2}, 
  
    {stat = "protection", amount = -0.2},
    {stat = "fireResistance", amount = -0.2},
    {stat = "iceResistance", amount = -0.2},
    {stat = "poisonResistance", amount = -0.2},
    {stat = "electricResistance", amount = -0.2},
    {stat = "physicalResistance", amount = -0.2},
	
    {stat = "ews_meleeResistance", amount = -0.2},
    {stat = "ews_smallarmsResistance", amount = -0.2},
    {stat = "ews_heavyarmsResistance", amount = -0.2},
    {stat = "ews_explosiveResistance", amount = -0.2},	
    {stat = "ews_antitankResistance", amount = -0.2},	
    {stat = "ews_psychicResistance", amount = -0.2},		
    {stat = "ews_bleedResistance", amount = -0.25},		
	
    {stat = "novaResistance", amount = -0.2},
    {stat = "holyResistance", amount = -0.2},
    {stat = "demonicResistance", amount = -0.2},
    {stat = "bleedResistance", amount = -0.2},
    {stat = "shadowResistance", amount = -0.2},
    {stat = "cosmicResistance", amount = -0.2},
    {stat = "radioactiveResistance", amount = -0.2},
    {stat = "linerifleResistance", amount = -0.2},
    {stat = "centensianenergyResistance", amount = -0.2},
    {stat = "xanafianResistance", amount = -0.2},
    {stat = "akkimariacidResistance", amount = -0.2},
    {stat = "silverResistance", amount = -0.2}	
	
	
  })
end

function update(dt)
end

function uninit()
	effect.removeStatModifierGroup(self.statModifierGroup1)
	effect.removeStatModifierGroup(self.statModifierGroup2)
end
