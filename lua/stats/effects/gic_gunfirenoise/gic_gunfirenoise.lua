function init()
  --script.setUpdateDelta(0)
  self.statModifierGroup = effect.addStatModifierGroup({
    --{stat = "jumpModifier", amount = -0.4},
	{stat = "gic_gunfirenoise", amount = 1}
  })
end

function update(dt)
--  mcontroller.controlModifiers({
--      airJumpModifier = 0.6
--    })
end

function uninit()
	effect.removeStatModifierGroup(self.statModifierGroup)
end
