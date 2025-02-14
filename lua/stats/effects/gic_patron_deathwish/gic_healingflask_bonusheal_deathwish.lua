function init()
  animator.setParticleEmitterOffsetRegion("healing", mcontroller.boundBox())
  animator.setParticleEmitterEmissionRate("healing", config.getParameter("emissionRate", 3))
  animator.setParticleEmitterActive("healing", true)

  script.setUpdateDelta(5)

  self.healingRate = config.getParameter("healAmount", 30) / effect.duration()
  
  
  self.statModifierGroup = effect.addStatModifierGroup({
    {stat = "protection", amount = 1.0},
    {stat = "fireResistance", amount = 0.15},
    {stat = "iceResistance", amount = 0.15},
    {stat = "poisonResistance", amount = 0.15},
    {stat = "electricResistance", amount = 0.15},
    {stat = "physicalResistance", amount = 0.15},
	
    {stat = "ews_meleeResistance", amount = 0.15},
    {stat = "ews_smallarmsResistance", amount = 0.15},
    {stat = "ews_heavyarmsResistance", amount = 0.15},
    {stat = "ews_explosiveResistance", amount = 0.15},	
    {stat = "ews_antitankResistance", amount = 0.15},	
	
    {stat = "powerMultiplier", amount = 1.0},
	
    {stat = "ews_misschance_mult", amount = -0.6},	
    {stat = "ews_inaccuracy_mult", amount = -0.6},	
	
    {stat = "novaResistance", amount = 0.15},
    {stat = "holyResistance", amount = 0.15},
    {stat = "demonicResistance", amount = 0.15},
    {stat = "bleedResistance", amount = 100.0},
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
  status.modifyResource("health", self.healingRate * dt)
  
end

function uninit()
	effect.removeStatModifierGroup(self.statModifierGroup)  
end
