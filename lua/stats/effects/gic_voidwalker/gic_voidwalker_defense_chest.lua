function init()
  self.statModifierGroup = effect.addStatModifierGroup({

    {stat = "gic_voidwalker_defense_weakness_chestStatus", amount = 1.0},

    {stat = "fireResistance", amount = 0.15},
    {stat = "iceResistance", amount = 0.15},
    {stat = "poisonResistance", amount = 0.15},
    {stat = "electricResistance", amount = 0.15},
    {stat = "physicalResistance", amount = 0.15},
    {stat = "radioactiveResistance", amount = 0.15},
    {stat = "shadowResistance", amount = 0.15},
    {stat = "cosmicResistance", amount = 0.15},
	
    {stat = "ews_meleeResistance", amount = 0.15},
    {stat = "ews_smallarmsResistance", amount = 0.15},
    {stat = "ews_heavyarmsResistance", amount = 0.15},
    {stat = "ews_explosiveResistance", amount = 0.15},
    {stat = "ews_antitankResistance", amount = 0.15},	
    {stat = "ews_psychicResistance", amount = 0.15},	
	
    {stat = "novaResistance", amount = 0.15},
    {stat = "holyResistance", amount = 0.15},
    {stat = "demonicResistance", amount = 0.15},
    {stat = "bleedResistance", amount = 0.15},
    {stat = "shadowResistance", amount = 0.15},
    {stat = "cosmicResistance", amount = 0.15},
    {stat = "radioactiveResistance", amount = 0.15},
    {stat = "linerifleResistance", amount = 0.15},
    {stat = "centensianenergyResistance", amount = 0.15},
    {stat = "xanafianResistance", amount = 0.15},
    {stat = "akkimariacidResistance", amount = 0.15},
    {stat = "silverResistance", amount = 0.15}

  })
end

function update(dt)
  
end

function uninit()

	effect.removeStatModifierGroup(self.statModifierGroup)  
end
