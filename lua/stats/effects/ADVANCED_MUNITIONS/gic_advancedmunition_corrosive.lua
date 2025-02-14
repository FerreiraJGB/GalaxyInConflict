function init()
  script.setUpdateDelta(0)
  
  animator.setParticleEmitterOffsetRegion("drips", mcontroller.boundBox())
  animator.setParticleEmitterActive("drips", true)
  effect.setParentDirectives("fade=9FFF87=0.05") --0.8

  self.statModifierGroup = effect.addStatModifierGroup({
    {stat = "fireResistance", amount = -0.3},
    {stat = "iceResistance", amount = -0.3},
    {stat = "poisonResistance", amount = -0.3},
    {stat = "electricResistance", amount = -0.3},
    {stat = "physicalResistance", amount = -0.3},
	
    {stat = "ews_bleedResistance", amount = -0.3},
    {stat = "ews_meleeResistance", amount = -0.3},
    {stat = "ews_smallarmsResistance", amount = -0.3},
    {stat = "ews_heavyarmsResistance", amount = -0.3},
    {stat = "ews_explosiveResistance", amount = -0.3},	
    {stat = "ews_antitankResistance", amount = -0.3},	
	
	
    {stat = "novaResistance", amount = -0.3},
    {stat = "holyResistance", amount = -0.3},
    {stat = "demonicResistance", amount = -0.3},
    {stat = "bleedResistance", amount = -0.3},
    {stat = "shadowResistance", amount = -0.3},
    {stat = "cosmicResistance", amount = -0.3},
    {stat = "radioactiveResistance", amount = -0.3},
    {stat = "linerifleResistance", amount = -0.3},
    {stat = "centensianenergyResistance", amount = -0.3},
    {stat = "xanafianResistance", amount = -0.3},
    {stat = "akkimariacidResistance", amount = -0.3},
    {stat = "silverResistance", amount = -0.3},
	
    {stat = "protection", effectiveMultiplier = config.getParameter("protectionModifier", 0.01)}
  })
end

function update(dt)

end

function uninit()
	effect.removeStatModifierGroup(self.statModifierGroup)
end
