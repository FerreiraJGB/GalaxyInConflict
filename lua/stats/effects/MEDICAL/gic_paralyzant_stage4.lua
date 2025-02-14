function init()
  --Health Scale
  -- optimize these stat modifier groups later, i'm lazy atm
  
  self.statModifierGroup = effect.addStatModifierGroup({
    {stat = "jumpModifier", amount = -0.3}
	})
  
  if entity.entityType() == "monster" then effect.expire() end
  
  effect.setParentDirectives("fade=808080=0.4")
end

function update(dt)
  mcontroller.controlModifiers({
      groundMovementModifier = 0.7,
      speedModifier = 0.7,
      airJumpModifier = 0.7
    })
end

function uninit()

	effect.removeStatModifierGroup(self.statModifierGroup)
end
