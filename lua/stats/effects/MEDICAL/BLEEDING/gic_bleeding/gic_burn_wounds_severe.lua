function init()
  --Health Scale
  -- optimize these stat modifier groups later, i'm lazy atm
  self.healthModifier = config.getParameter("healthModifier", 0)
  self.statModifierGroup1 = effect.addStatModifierGroup({{stat = "maxHealth", effectiveMultiplier = self.healthModifier}})
  
  self.statModifierGroup2 = effect.addStatModifierGroup({
  {stat = "jumpModifier", amount = -0.2}  
  })
  
  if entity.entityType() == "monster" then effect.expire() end
end

function update(dt)
  mcontroller.controlModifiers({
      groundMovementModifier = 0.8,
      speedModifier = 0.8,
      airJumpModifier = 0.8
    })
end

function uninit()
	effect.removeStatModifierGroup(self.statModifierGroup1)
	effect.removeStatModifierGroup(self.statModifierGroup2)
end
