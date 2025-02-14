function init()
  animator.setParticleEmitterOffsetRegion("healing", mcontroller.boundBox())
  animator.setParticleEmitterEmissionRate("healing", config.getParameter("emissionRate", 3))
  animator.setParticleEmitterActive("healing", true)

  script.setUpdateDelta(5)

  self.healingRate = config.getParameter("healAmount", 30) / effect.duration()
  
  
  self.statModifierGroup = effect.addStatModifierGroup({
    {stat = "protection", amount = 1.0},
    {stat = "fireResistance", amount = 0.9},
    {stat = "iceResistance", amount = 0.9},
    {stat = "poisonResistance", amount = 0.9},
    {stat = "electricResistance", amount = 0.9},
    {stat = "physicalResistance", amount = 0.9},
	
    {stat = "ews_meleeResistance", amount = 0.9},
    {stat = "ews_smallarmsResistance", amount = 0.9},
    {stat = "ews_heavyarmsResistance", amount = 0.9},
    {stat = "ews_explosiveResistance", amount = 0.9},	
    {stat = "ews_antitankResistance", amount = 0.9},	
	
    {stat = "novaResistance", amount = 0.9},
    {stat = "holyResistance", amount = 0.9},
    {stat = "demonicResistance", amount = 0.9},
    {stat = "bleedResistance", amount = 100.0},
    {stat = "shadowResistance", amount = 0.9},
    {stat = "cosmicResistance", amount = 0.9},
    {stat = "radioactiveResistance", amount = 0.9},
    {stat = "linerifleResistance", amount = 0.9},
    {stat = "centensianenergyResistance", amount = 0.9},
    {stat = "xanafianResistance", amount = 0.9},
    {stat = "akkimariacidResistance", amount = 0.9},
    {stat = "silverResistance", amount = 0.9}	
	
	
  })
  
  
end

function update(dt)
  status.modifyResource("health", self.healingRate * dt)
  
end

function uninit()
	effect.removeStatModifierGroup(self.statModifierGroup)  
end
