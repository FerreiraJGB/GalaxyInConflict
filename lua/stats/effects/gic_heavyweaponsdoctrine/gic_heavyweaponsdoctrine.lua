function init()
  self.statModifierGroup = effect.addStatModifierGroup({
    {stat = "gic_antilightweight", amount = 1.0},
    {stat = "gic_antimediumweight", amount = 1.0},
    {stat = "gic_antiheavyweight", amount = 1.0}
  })
end

function update(dt)
  
end

function uninit()

	effect.removeStatModifierGroup(self.statModifierGroup)  
	
end
