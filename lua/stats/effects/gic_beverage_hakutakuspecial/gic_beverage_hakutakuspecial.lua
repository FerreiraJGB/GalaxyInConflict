function init()
  self.statModifierGroup = effect.addStatModifierGroup({
    {stat = "gic_secondChance_cooldownMod", amount = 0.05}
  })
end

function update(dt)
  
end

function uninit()
	effect.removeStatModifierGroup(self.statModifierGroup)  
end
