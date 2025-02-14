function init()
  self.statModifierGroup = effect.addStatModifierGroup({
    {stat = "ews_heavyarmsResistance", amount = -0.5},
    {stat = "ews_bleedResistance", amount = 0.5}
  })
end

function update(dt)
  
end

function uninit()
	effect.removeStatModifierGroup(self.statModifierGroup)  
end
