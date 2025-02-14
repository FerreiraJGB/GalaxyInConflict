function init()
  self.statModifierGroup = effect.addStatModifierGroup({
    {stat = "gic_dodge_stat", amount = 0.10}
  })
end

function update(dt)
  
end

function uninit()
	effect.removeStatModifierGroup(self.statModifierGroup)  
end
