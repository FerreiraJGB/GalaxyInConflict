function init()
  self.statModifierGroup = effect.addStatModifierGroup({
    {stat = "gic_redsun_-50StatusImmunity", amount = 1}
  })
end

function update(dt)
  
end

function uninit()
	effect.removeStatModifierGroup(self.statModifierGroup)  
end
