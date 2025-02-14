function init()



  self.statModifierGroup1 = effect.addStatModifierGroup({
  
    {stat = "fireResistance", amount = -0.25}
	
	
  })
end

function update(dt)
end

function uninit()
	effect.removeStatModifierGroup(self.statModifierGroup1)
end
