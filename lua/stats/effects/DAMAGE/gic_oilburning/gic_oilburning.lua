function init()
  animator.setParticleEmitterOffsetRegion("flames", mcontroller.boundBox())
  animator.setParticleEmitterActive("flames", true)
  effect.setParentDirectives("fade=BF3300=0.05") --0.25
  animator.playSound("burn", -1)
  script.setUpdateDelta(5)

  self.statModifierGroup = effect.addStatModifierGroup({
    {stat = "ews_misschance_mult", amount = 0.5},
    {stat = "ews_npcfirerate", amount = 30.0},
    {stat = "ews_inaccuracy_mult", amount = 0.5}
    })

--  self.tickDamagePercentage = 0.02
  self.tickTime = 1.0
  self.tickTimer = self.tickTime
end

function update(dt)
  if effect.duration() and world.liquidAt({mcontroller.xPosition(), mcontroller.yPosition() - 1}) then
    effect.expire()
  end
  
  
--  if status.stat("gic_armor_beast") == 1 then            -- breaks the standard function. Needs to be mashed together, but I'm not skilled enough in this field, not yet. - Med 5-11-2021
--	effect.addStatModifierGroup({
--		{stat = "ews_meleeResistance", amount = -0.5},
--		{stat = "ews_smallarmsResistance", amount = -0.5},
--		{stat = "ews_heavyarmsResistance", amount = -0.5},
--		{stat = "ews_explosiveResistance", amount = -0.5},
--		{stat = "healthRegen", amount = -1.0}
--	})
-- else
--	effect.expire()
--  end
  

  self.tickTimer = self.tickTimer - dt
  if self.tickTimer <= 0 then
    self.tickTimer = self.tickTime
	status.addEphemeralEffect("gic_infantry_panic", 5)
    status.applySelfDamageRequest({
        damageType = "IgnoresDef",
        damage = 25, --100
        damageSourceKind = "fire",
        sourceEntityId = entity.id()
      })
  end
end

function uninit()

	if effect.duration() <= script.updateDt() then
	 status.addEphemeralEffect("gic_burn_wounds_severe", 600)
	end

  effect.removeStatModifierGroup(self.statModifierGroup)
end
