function init()
   self.statModifierGroup = effect.addStatModifierGroup({
{stat = "gic_burn_woundsProtection", amount = 1},
{stat = "gic_burn_wounds_severeProtection", amount = 1}
   })

   script.setUpdateDelta(0)
end

function update(dt)

end

function uninit()
  effect.removeStatModifierGroup(self.statModifierGroup)
end
