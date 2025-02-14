require "/scripts/util.lua"
require "/scripts/interp.lua"
require "/scripts/vec2.lua"

function init()
  effect.setParentDirectives("fade="..config.getParameter("color").."=0.75")
  self.spawnedProjectile = false
end

function update(dt)
   if not self.spawnedProjectile then
	self.spawnedProjectile = true
	
	local params = sb.jsonMerge(config.getParameter("projectileParams"), projectileParams or {})
	world.spawnProjectile("invisibleprojectile", mcontroller.position(), entity.id(), {0,0}, false, params)
   end
end

function uninit()

end
