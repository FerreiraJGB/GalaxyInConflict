function init()
  effect.addStatModifierGroup({
      {stat = "energyRegenPercentageRate", amount = 0.05},
      {stat = "energyRegenBlockTime", effectiveMultiplier = 20},
    {stat = "ews_misschance_mult", amount = -0.25},
    {stat = "ews_inaccuracy_mult", amount = -0.25}
    })
end

function update(dt)

end

function uninit()

end