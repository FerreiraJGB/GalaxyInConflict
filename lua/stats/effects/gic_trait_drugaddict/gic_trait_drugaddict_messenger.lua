function init()
  self.statModifierGroup = effect.addStatModifierGroup({
    {stat = "gic_trait_drugaddict_messenger", amount = 1.0}
  })
end

function update(dt)
  
end

function uninit()
	effect.removeStatModifierGroup(self.statModifierGroup)  
end
