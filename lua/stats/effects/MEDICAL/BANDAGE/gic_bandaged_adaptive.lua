function init()
  local bleedResist = config.getParameter("ews_bleedResistance", 1.0)
  local entitySpecies = world.entitySpecies(entity.id())
  if entitySpecies == config.getParameter("targetRace") then
	bleedResist = config.getParameter("adaptive_ews_bleedResistance")
	-- sb.logInfo("adaptive bandage triggered")
  end
  
  self.statModifierGroup = effect.addStatModifierGroup({
    {stat = "ews_bleedResistance", amount = bleedResist}
  })
  
  script.setUpdateDelta(0)
end

function update(dt)
end

function uninit()
  effect.removeStatModifierGroup(self.statModifierGroup)
end
