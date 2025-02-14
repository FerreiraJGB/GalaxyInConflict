function init()
  self.statModifierGroup = effect.addStatModifierGroup({
    {stat = "ews_psychicResistance", amount = 0.1},
    {stat = "ews_bleedResistance", amount = 0.1}
  })
end

function update(dt)
  
end

function uninit()
	effect.removeStatModifierGroup(self.statModifierGroup)  
end
