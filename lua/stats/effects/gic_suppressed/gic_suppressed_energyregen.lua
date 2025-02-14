function init()


  effect.addStatModifierGroup({
      {stat = "energyRegenPercentageRate", amount = config.getParameter("regenBonusAmount", -0.9)},
      {stat = "energyRegenBlockTime", effectiveMultiplier = 0}
    })
end

function update(dt)

end

function uninit()

end
