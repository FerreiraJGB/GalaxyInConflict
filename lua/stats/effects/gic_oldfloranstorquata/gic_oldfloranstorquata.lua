function init()
  self.statModifierGroup = effect.addStatModifierGroup({
    {stat = "gic_shieldDefenseMult", amount = 0.25}
  })
end

function update(dt)
  
end

function uninit()
	effect.removeStatModifierGroup(self.statModifierGroup)  
end
