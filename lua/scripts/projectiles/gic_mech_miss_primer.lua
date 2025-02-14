require "/scripts/vec2.lua"

function init()
	local projectileSpawn = config.getParameter("hitProjectile")
	
	local missChanceRoll = math.random(0,100)
	local missChance = config.getParameter("missChance")
	
	--sb.logInfo(missChanceRoll)
	if missChanceRoll <= missChance then
		projectileSpawn = config.getParameter("missProjectile")
	end
	
	local params = {}
	--params.power = config.getParameter("power")
	
	--sb.logInfo(entity.id())
	local x = math.cos(mcontroller.rotation())
	local y = math.sin(mcontroller.rotation())
	world.spawnProjectile(projectileSpawn, mcontroller.position(), projectile.sourceEntity(), {x,y}, false, params)
end

function update(dt)
end

function uninit()
end