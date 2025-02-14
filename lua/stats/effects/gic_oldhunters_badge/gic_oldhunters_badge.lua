function init()
  self.statModifierGroup = effect.addStatModifierGroup({
    {stat = "ews_bleedResistance", amount = 0.3}
  })
end

function update(dt)
  
end

function uninit()
	effect.removeStatModifierGroup(self.statModifierGroup)  
end
