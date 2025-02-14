function init()
  self.statModifierGroup = effect.addStatModifierGroup({
    {stat = "grit", amount = 0.5}
  })
end

function update(dt)
  
end

function uninit()
	effect.removeStatModifierGroup(self.statModifierGroup)  
end
