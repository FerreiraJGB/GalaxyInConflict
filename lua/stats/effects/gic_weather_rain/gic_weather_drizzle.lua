function init()
  self.statModifierGroup = effect.addStatModifierGroup({
    {stat = "fireResistance", amount = 0.10},
    {stat = "electricResistance", amount = -0.10}
  })
end

function update(dt)
  
end

function uninit()
	effect.removeStatModifierGroup(self.statModifierGroup)  
end
