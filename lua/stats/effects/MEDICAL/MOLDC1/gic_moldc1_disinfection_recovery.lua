function init()
   self.statModifierGroup = effect.addStatModifierGroup({
    {stat = "gic_moldc1_infectionProtection", amount = 1.0}
   })

   script.setUpdateDelta(0)
end

function update(dt)

end

function uninit()
  effect.removeStatModifierGroup(self.statModifierGroup)
end
