function init()
  self.statModifierGroup = effect.addStatModifierGroup({
    {stat = "fireResistance", amount = 0.30},
    {stat = "electricResistance", amount = -0.30}
  })
end

function update(dt)
  
end

function uninit()
	effect.removeStatModifierGroup(self.statModifierGroup)  
end
