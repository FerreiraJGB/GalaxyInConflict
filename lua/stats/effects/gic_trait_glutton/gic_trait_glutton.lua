function init()
  self.statModifierGroup = effect.addStatModifierGroup({
    {stat = "foodDelta", amount = -0.0583} --0.0583
  })
end

function update(dt)
  
end

function uninit()
	effect.removeStatModifierGroup(self.statModifierGroup)  
end
