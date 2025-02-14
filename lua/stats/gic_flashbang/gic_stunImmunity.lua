require "/scripts/status.lua"

function init()
   --sb.logInfo("stunProtection")
   self.statModifierGroup = effect.addStatModifierGroup({
	{stat = "gic_stunProtection", amount = 1},
	
	{stat = "gic_dodge_stat", amount = -1.00}
	
  })
end

function update(dt)
end

function uninit()
  effect.removeStatModifierGroup(self.statModifierGroup)  
end
