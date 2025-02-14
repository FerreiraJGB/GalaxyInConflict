--Always active. Used to grant the actual bonus effects when needed. Also used to counter the resists of the Counter.

function init()
  self.statModifierGroup = effect.addStatModifierGroup({
  })
end

function update(dt)
  mcontroller.controlModifiers({
      groundMovementModifier = 1.25,
      speedModifier = 1.25,
      airJumpModifier = 1.25
    })
end

function uninit()
	effect.removeStatModifierGroup(self.statModifierGroup)
end
