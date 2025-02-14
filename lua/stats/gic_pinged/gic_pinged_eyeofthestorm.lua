function init()



  self.statModifierGroup1 = effect.addStatModifierGroup({
  
    {stat = "iceResistance", amount = -0.5}
	
	
  })
end

function update(dt)
end

function uninit()
	effect.removeStatModifierGroup(self.statModifierGroup1)
end
