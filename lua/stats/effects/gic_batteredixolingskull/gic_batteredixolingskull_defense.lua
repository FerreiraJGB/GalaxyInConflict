function init()
  self.statModifierGroup = effect.addStatModifierGroup({

    {stat = "fireResistance", amount = 0.5},
    {stat = "iceResistance", amount = 0.5},
    {stat = "poisonResistance", amount = 0.5},
    {stat = "electricResistance", amount = 0.5},
    {stat = "physicalResistance", amount = 0.5},
    {stat = "radioactiveResistance", amount = 0.5},
    {stat = "shadowResistance", amount = 0.5},
    {stat = "cosmicResistance", amount = 0.5},
	
    {stat = "ews_meleeResistance", amount = 0.5},
    {stat = "ews_smallarmsResistance", amount = 0.5},
    {stat = "ews_heavyarmsResistance", amount = 0.5},
    {stat = "ews_explosiveResistance", amount = 0.5},
    {stat = "ews_antitankResistance", amount = 0.5},	
    {stat = "ews_psychicResistance", amount = 0.5},	
	
    {stat = "novaResistance", amount = 0.5},
    {stat = "holyResistance", amount = 0.5},
    {stat = "demonicResistance", amount = 0.5},
    {stat = "bleedResistance", amount = 0.5},
    {stat = "shadowResistance", amount = 0.5},
    {stat = "cosmicResistance", amount = 0.5},
    {stat = "radioactiveResistance", amount = 0.5},
    {stat = "linerifleResistance", amount = 0.5},
    {stat = "centensianenergyResistance", amount = 0.5},
    {stat = "xanafianResistance", amount = 0.5},
    {stat = "akkimariacidResistance", amount = 0.5},
    {stat = "silverResistance", amount = 0.5}

  })
end

function update(dt)
  
end

function uninit()

	if effect.duration() and effect.duration() <= script.updateDt() then
	 status.addEphemeralEffect("gic_batteredixolingskull_weakness", 5)
	end

	effect.removeStatModifierGroup(self.statModifierGroup)  
end
