function init()
  self.statModifierGroup = effect.addStatModifierGroup({
    {stat = "ews_npcfirerate", amount = -0.5},
    {stat = "gic_suppressedProtection", amount = 1.0}
  })
end

function update(dt)
  
end

function uninit()
	effect.removeStatModifierGroup(self.statModifierGroup)  
end
