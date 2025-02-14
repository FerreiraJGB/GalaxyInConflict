function init()
  self.statModifierGroup = effect.addStatModifierGroup({
    {stat = "protection", effectiveMultiplier = config.getParameter("protectionModifier", 0.01)}
  })
end

function update(dt)
end

function uninit()
	effect.removeStatModifierGroup(self.statModifierGroup)
end
