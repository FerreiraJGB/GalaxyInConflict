function init()
  --effect.addStatModifierGroup({{stat = config.getParameter("stat"), amount = 1}})
  --sb.logInfo("hit iframe: " .. status.statusProperty("hitInvulnerabilityTime",{}))
  --sb.logInfo("hit flash time: " .. status.statusProperty("hitInvulnerabilityFlash",{}))
  --sb.logInfo("hit threshhold: " .. status.statusProperty("hitInvulnerabilityThreshold",{}))
end

function update(dt)
	status.setStatusProperty("hitInvulnerabilityTime",0.0)
	status.setStatusProperty("hitInvulnerabilityFlash",0.0)
	status.setStatusProperty("hitInvulnerabilityThreshold",1.0)
end

function uninit()
end
