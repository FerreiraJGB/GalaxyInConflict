function init()
   self.statModifierGroup = effect.addStatModifierGroup({
   {stat = "ews_infammo", amount = 1}
   })

   script.setUpdateDelta(0)
end

function update(dt)

end

function uninit()
  effect.removeStatModifierGroup(self.statModifierGroup)
end
