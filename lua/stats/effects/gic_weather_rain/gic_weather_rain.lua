function init()
  self.statModifierGroup = effect.addStatModifierGroup({
    {stat = "fireResistance", amount = 0.20},
    {stat = "electricResistance", amount = -0.20}
  })
end

function update(dt)
  
end

function uninit()
	effect.removeStatModifierGroup(self.statModifierGroup)  
end
