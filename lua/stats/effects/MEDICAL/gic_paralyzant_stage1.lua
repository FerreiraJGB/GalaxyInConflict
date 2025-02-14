function init()
  --Health Scale
  -- optimize these stat modifier groups later, i'm lazy atm
  
  self.statModifierGroup = effect.addStatModifierGroup({
    {stat = "jumpModifier", amount = -0.2}
	})
  
  if entity.entityType() == "monster" then effect.expire() end
  
  effect.setParentDirectives("fade=808080=0.2")
end

function update(dt)
  mcontroller.controlModifiers({
      groundMovementModifier = 0.8,
      speedModifier = 0.8,
      airJumpModifier = 0.8
    })
end

function uninit()

	if effect.duration() and effect.duration() <= script.updateDt() then
	 status.addEphemeralEffect("gic_paralyzant_stage2", 30)
	end

	effect.removeStatModifierGroup(self.statModifierGroup)
end
