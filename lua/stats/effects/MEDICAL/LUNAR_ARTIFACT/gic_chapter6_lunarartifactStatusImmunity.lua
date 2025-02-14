function init()
   self.statModifierGroup = effect.addStatModifierGroup({{stat = "gic_chapter6_lunarartifactProtection", amount = 1}})

   script.setUpdateDelta(0)
end

function update(dt)

end

function uninit()
  effect.removeStatModifierGroup(self.statModifierGroup)
end
