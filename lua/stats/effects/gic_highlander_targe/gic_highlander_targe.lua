require "/scripts/status.lua"

function init()

  self.statModifierGroup = effect.addStatModifierGroup({
    {stat = "fireResistance", amount = 0.50},
    {stat = "ews_explosiveResistance", amount = 0.30}
  })
end

function update(dt)
end

function uninit()
	effect.removeStatModifierGroup(self.statModifierGroup)
end
