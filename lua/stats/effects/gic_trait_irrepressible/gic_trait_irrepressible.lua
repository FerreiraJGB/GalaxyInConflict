function init()
  self.statModifierGroup = effect.addStatModifierGroup({
    {stat = "ews_psychicResistance", amount = 0.2},
    {stat = "gic_opiate_addictionProtection", amount = 1.0},
    {stat = "gic_opiate_withdrawalProtection", amount = 1.0}
  })
end

function update(dt)
  
end

function uninit()
	effect.removeStatModifierGroup(self.statModifierGroup)  
end
