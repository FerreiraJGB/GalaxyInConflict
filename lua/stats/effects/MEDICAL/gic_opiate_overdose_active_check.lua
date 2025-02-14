function init()

  self.statModifierGroup = effect.addStatModifierGroup({{stat = "gic_opiate_overdose_active_check", amount = 1}})


  if entity.entityType() == "monster" then effect.expire() end
end

function update(dt)
end

function uninit()

	effect.removeStatModifierGroup(self.statModifierGroup)

end
