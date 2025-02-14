function init()
  self.statModifierGroup = effect.addStatModifierGroup({
    {stat = "ews_bleedResistance", amount = 1.0}
  })
end

function update(dt)
  
end

function uninit()
	effect.removeStatModifierGroup(self.statModifierGroup)  
end
