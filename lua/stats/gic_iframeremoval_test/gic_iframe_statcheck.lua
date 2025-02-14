require "/scripts/util.lua"
require "/scripts/status.lua"
require "/scripts/vec2.lua"

function init()
  --effect.addStatModifierGroup({{stat = config.getParameter("stat"), amount = 1}})
  --sb.logInfo("hit iframes: " .. status.statusProperty("hitInvulnerabilityTime",{}))
  --sb.logInfo("hit flash time: " .. status.statusProperty("hitInvulnerabilityFlash",{}))
  --sb.logInfo("hit threshhold: " .. status.statusProperty("hitInvulnerabilityThreshold",{}))
end

function update(dt)
	world.debugText("hit iframes: " .. status.statusProperty("hitInvulnerabilityTime",{}), vec2.add(mcontroller.position(), {0,2}), "blue")
	world.debugText("hit flash time: " .. status.statusProperty("hitInvulnerabilityFlash",{}), vec2.add(mcontroller.position(), {0,0}), "red")
	world.debugText("hit threshhold: " .. status.statusProperty("hitInvulnerabilityThreshold",{}), vec2.add(mcontroller.position(), {0,-2}), "yellow")
end

function uninit()
end
