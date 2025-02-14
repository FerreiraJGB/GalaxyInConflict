require "/scripts/status.lua"

function init()

  script.setUpdateDelta(5)

  self.statModifierGroup = effect.addStatModifierGroup({

    {stat = "maxHealth", amount = config.getParameter("healthAmount", 0)},
    {stat = "maxHealth", baseMultiplier = config.getParameter("healthBaseMultiplier", 1.0)},
    {stat = "maxHealth", effectiveMultiplier = config.getParameter("healthEffectiveMultiplier", 1.0)},
    {stat = "powerMultiplier", amount = 0.25},
    {stat = "grit", amount = 0.5}
  })
end

function update(dt)
end

function uninit()
	effect.removeStatModifierGroup(self.statModifierGroup)
end
