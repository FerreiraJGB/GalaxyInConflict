function init()
  self.statModifierGroup = effect.addStatModifierGroup({
    {stat = "grit", amount = 0.5},
    {stat = "gic_shadowsweat_slowStatusImmunity", amount = 1.0},
    {stat = "gic_shadowsweat_poisonStatusImmunity", amount = 1.0},
    {stat = "ews_psychicResistance", amount = 0.75}
  })
  
  effect.setParentDirectives("fade="..config.getParameter("color").."=0.05")
  script.setUpdateDelta(0)
  
  animator.setParticleEmitterOffsetRegion("embers", mcontroller.boundBox())
  animator.setParticleEmitterActive("embers", true)
  
end

function update(dt)
end

function uninit()
	effect.removeStatModifierGroup(self.statModifierGroup)
end
