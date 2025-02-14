function init()
  --effect.addStatModifierGroup({{stat = config.getParameter("stat"), amount = 1}})
  --sb.logInfo("hit iframe: " .. status.statusProperty("hitInvulnerabilityTime",{}))
  --sb.logInfo("hit flash time: " .. status.statusProperty("hitInvulnerabilityFlash",{}))
  --sb.logInfo("hit threshhold: " .. status.statusProperty("hitInvulnerabilityThreshold",{}))
end

function update(dt)
	status.setStatusProperty("hitInvulnerabilityTime",0.1)
	status.setStatusProperty("hitInvulnerabilityFlash",0.15)
	status.setStatusProperty("hitInvulnerabilityThreshold",0.1)
end

function uninit()
end
