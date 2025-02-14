function init()
   self.statModifierGroup = effect.addStatModifierGroup({
   
      {stat = "energyRegenPercentageRate", amount = 0.05},
      {stat = "energyRegenBlockTime", effectiveMultiplier = 20},   
   
   {stat = "gic_colonial_energyshieldBreak", amount = 1}
   
   
   })

   script.setUpdateDelta(0)
end

function update(dt)

end

function uninit()
  effect.removeStatModifierGroup(self.statModifierGroup)
end
