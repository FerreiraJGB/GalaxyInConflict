function init()
  self.statModifierGroup = effect.addStatModifierGroup({
    {stat = "powerMultiplier", amount = 0.1}
  })
end

function update(dt)
  
end

function uninit()
	effect.removeStatModifierGroup(self.statModifierGroup)  
end
