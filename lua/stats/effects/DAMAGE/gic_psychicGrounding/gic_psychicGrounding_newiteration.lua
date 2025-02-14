function init()
  self.psychicAnomaly = status.stat("gic_psychic_anomaly") -- can check once in the beginning; no reason, in normal circumstances, for entity to become anomalous and then suddenly *not* anomalous!
  
  if self.psychicAnomaly == 1 then
	effect.setParentDirectives("fade=bebebe=0.25")
	self.statModifierGroup = effect.addStatModifierGroup({
		{stat = "ews_meleeResistance", amount = -0.5},
		{stat = "ews_smallarmsResistance", amount = -0.5},
		{stat = "ews_heavyarmsResistance", amount = -0.5},
		{stat = "ews_explosiveResistance", amount = -0.5},
		{stat = "protection", amount = -9999}
	})
  else
	effect.expire()
  end

  script.setUpdateDelta(0)
end

function update(dt)
	if self.psychicAnomaly == 0 then
		effect.expire()
	end
end

function uninit()
	effect.removeStatModifierGroup(self.statModifierGroup)
end
