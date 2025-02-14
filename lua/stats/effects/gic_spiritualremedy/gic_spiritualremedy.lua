require "/scripts/status.lua"

function init()

  self.statModifierGroup = effect.addStatModifierGroup({
    {stat = "ews_psychicResistance", amount = 0.80},
    {stat = "silverResistance", amount = 0.80}	
  })
end

function update(dt)
end

function uninit()
	effect.removeStatModifierGroup(self.statModifierGroup)
end
