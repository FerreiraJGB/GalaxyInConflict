function init()
   self.statModifierGroup = effect.addStatModifierGroup({
{stat = "gic_bruising_lightProtection", amount = 1},
{stat = "gic_bruising_mediumProtection", amount = 1},
{stat = "gic_bloodloss_heavyProtection", amount = 1} 
   })

   script.setUpdateDelta(0)
end

function update(dt)

end

function uninit()
  effect.removeStatModifierGroup(self.statModifierGroup)
end
