require "/scripts/vec2.lua"
require "/scripts/util.lua"

function init()
  --local startingVelocity = config.getParameter("startingVelocity")
  --if startingVelocity then
	--sb.logInfo(sb.printJson(startingVelocity))
	--mcontroller.setVelocity(startingVelocity)
  --end
  self.sourceEntity = entity.id()
  self.ownerCoin = config.getParameter("ownerCoin","null")
  self.queryParametersPrime = {
    withoutEntityId = config.getParameter("ignoreCoin"),
    includedTypes = {"vehicle"},
    order = "nearest"
  }
  self.queryParameters = {
    withoutEntityId = self.sourceEntity,
    includedTypes = {"creature"},
    order = "nearest"
  }
  
  self.targetEntityId = nil
  self.homingDistance = 500
end

function update(dt)
	local params = {}
	params.power = config.getParameter("power")
	params.startingVelocity = config.getParameter("startingVelocity")
	params.damageKind = config.getParameter("damagedKind")
	params.damageType = config.getParameter("damagedType")
	--world.spawnProjectile("gic_coin", mcontroller.position(), projectile.sourceEntity(), {0,0}, false, {startingVelocity = config.getParameter("startingVelocity"), power = config.getParameter("power"), damageKind = config.getParameter("damageKind")})
	
	if config.getParameter("splitCoin") then
		--sb.logInfo("splitcoin")
		local foundCoins = findCoins()
		local target1 = findTarget("buffer")
		
		
		if foundCoins then
		--first coin aims at another coin, second coin splitshots
		target1 = findCoin(self.ownerCoin)
		if not (target1 == "cannot") then
			--sb.logInfo("aimed 1st coin")
			params.pretargetedEntity = target1
			world.spawnProjectile("gic_coin", mcontroller.position(), projectile.sourceEntity(), {0,0}, false, params)
			
			local target2 = findTarget(target1)
			
			if not (target2 == "cannot") then
				--sb.logInfo("aimed 2nd coin")
				params.pretargetedEntity = target2
				world.spawnProjectile("gic_coin", mcontroller.position(), projectile.sourceEntity(), {0,0}, false, params)
			else
				--sb.logInfo("dumb second coin")
				params.pretargetedEntity = nil
				params.dumbProjectile = true
				--params.startingVelocity = vec2.rotate(params.startingVelocity, (-0.3 + 0.6 * math.random())) --range of 70% pi to 130% pi
				params.startingVelocity = vec2.rotate({1,0}, (2 * math.pi * math.random())) --random rotate
				world.spawnProjectile("gic_coin", mcontroller.position(), projectile.sourceEntity(), {0,0}, false, params)
			end
		else
			--sb.logInfo(target1)
			
			params.dumbProjectile = true
			params.startingVelocity = vec2.rotate({1,0}, (2 * math.pi * math.random())) --random rotate
			world.spawnProjectile("gic_coin", mcontroller.position(), projectile.sourceEntity(), {0,0}, false, params)
			
			--second coin
			
			local val = 1
			if math.random() > 0.5 then val = -1 end --randomizes whether base is +45 or -45 degrees
			
			params.startingVelocity = vec2.rotate(params.startingVelocity, math.pi/4 * val * ( 0.5 + 1.0 * math.random())) --range of 50% pi/4 to 150% pi/4
			--params.startingVelocity = vec2.rotate({1,0}, (2 * math.pi * math.random())) --random rotate
			world.spawnProjectile("gic_coin", mcontroller.position(), projectile.sourceEntity(), {0,0}, false, params)
			
			--sb.logInfo("spawned unaimed coins")
		end
		
		else
		
		if not (target1 == "cannot") then
			--sb.logInfo("aimed 1st coin")
			params.pretargetedEntity = target1
			world.spawnProjectile("gic_coin", mcontroller.position(), projectile.sourceEntity(), {0,0}, false, params)
			
			local target2 = findTarget(target1)
			
			if not (target2 == "cannot") then
				--sb.logInfo("aimed 2nd coin")
				params.pretargetedEntity = target2
				world.spawnProjectile("gic_coin", mcontroller.position(), projectile.sourceEntity(), {0,0}, false, params)
			else
				--sb.logInfo("dumb second coin")
				params.pretargetedEntity = nil
				params.dumbProjectile = true
				--params.startingVelocity = vec2.rotate(params.startingVelocity, (-0.3 + 0.6 * math.random())) --range of 70% pi to 130% pi
				params.startingVelocity = vec2.rotate({1,0}, (2 * math.pi * math.random())) --random rotate
				world.spawnProjectile("gic_coin", mcontroller.position(), projectile.sourceEntity(), {0,0}, false, params)
			end
		else
			--sb.logInfo(target1)
			
			params.dumbProjectile = true
			params.startingVelocity = vec2.rotate({1,0}, (2 * math.pi * math.random())) --random rotate
			world.spawnProjectile("gic_coin", mcontroller.position(), projectile.sourceEntity(), {0,0}, false, params)
			
			--second coin
			
			local val = 1
			if math.random() > 0.5 then val = -1 end --randomizes whether base is +45 or -45 degrees
			
			params.startingVelocity = vec2.rotate(params.startingVelocity, math.pi/4 * val * ( 0.5 + 1.0 * math.random())) --range of 50% pi/4 to 150% pi/4
			--params.startingVelocity = vec2.rotate({1,0}, (2 * math.pi * math.random())) --random rotate
			world.spawnProjectile("gic_coin", mcontroller.position(), projectile.sourceEntity(), {0,0}, false, params)
			
			--sb.logInfo("spawned unaimed coins")
		end
		
		
		end
	
	else
		world.spawnProjectile("gic_coin", mcontroller.position(), projectile.sourceEntity(), {0,0}, false, params)
	end
end

function findCoins()
  local pos = mcontroller.position()
  local candidatesPrime = world.entityQuery(pos, self.homingDistance, self.queryParametersPrime)
  
  if #candidatesPrime == 0 then return false end
  
  for _, candidate in ipairs(candidatesPrime) do
    if world.entityCanDamage(self.sourceEntity, candidate) and world.entityName(candidate) == "gic_coin" then
      local canPos = world.entityPosition(candidate)
      if not world.lineTileCollision(pos, canPos) then
        local toTarget = world.distance(canPos, pos)
        --local toTargetAngle = util.angleDiff(angle, vec2.angle(toTarget))
		
		return true
		
      end
    end
  end
  
  return false
end

function findCoin(filter)
  local pos = mcontroller.position()
  local candidates = world.entityQuery(pos, self.homingDistance, self.queryParametersPrime)

  --if #candidates == 0 then return end
  if #candidates == 0 then return "cannot" end

  --local vel = {1,0}--mcontroller.velocity()
  --local angle = vec2.angle(vel)
  
 --self.foundTarget = false
 --sb.logInfo(sb.printJson(candidatesPrime))
 --sb.logInfo(sb.printJson(candidates))
 
  
  
  --sb.logInfo(sb.printJson(foundTarget))
  --if self.foundTarget == false then
	--sb.logInfo("try to find creature")
	
	for _, candidate in ipairs(candidates) do
		--sb.logInfo("--")
		--sb.logInfo("canDamage? "..sb.printJson(world.entityCanDamage(self.sourceEntity, candidate)).." matchesFilter? "..sb.printJson(candidate == filter))
		--sb.logInfo("canContinue? "..sb.printJson(world.entityCanDamage(self.sourceEntity, candidate) and not (candidate == filter)))
		--sb.logInfo("--")
		if world.entityCanDamage(self.sourceEntity, candidate) and world.entityName(candidate) == "gic_coin" then
		local canPos = world.entityPosition(candidate)
		
		--sb.logInfo("LOS?"..sb.printJson(world.lineTileCollision(pos, canPos)))
		if not world.lineTileCollision(pos, canPos) then
			local toTarget = world.distance(canPos, pos)
			--local toTargetAngle = util.angleDiff(angle, vec2.angle(toTarget))
	
			
			return candidate
			
		end
		end
	end
  --end
  
  return "cannot"
  --mcontroller.setRotation(math.atan(vel[2], vel[1]))
end

function findTarget(filter)
  local pos = mcontroller.position()
  local candidates = world.entityQuery(pos, self.homingDistance, self.queryParameters)

  --if #candidates == 0 then return end
  if #candidates == 0 then return "cannot" end

  --local vel = {1,0}--mcontroller.velocity()
  --local angle = vec2.angle(vel)
  
 --self.foundTarget = false
 --sb.logInfo(sb.printJson(candidatesPrime))
 --sb.logInfo(sb.printJson(candidates))
 
  
  
  --sb.logInfo(sb.printJson(foundTarget))
  --if self.foundTarget == false then
	--sb.logInfo("try to find creature")
	
	for _, candidate in ipairs(candidates) do
		--sb.logInfo("--")
		--sb.logInfo("canDamage? "..sb.printJson(world.entityCanDamage(self.sourceEntity, candidate)).." matchesFilter? "..sb.printJson(candidate == filter))
		--sb.logInfo("canContinue? "..sb.printJson(world.entityCanDamage(self.sourceEntity, candidate) and not (candidate == filter)))
		--sb.logInfo("--")
		if world.entityCanDamage(self.sourceEntity, candidate) and not (candidate == filter) then
		local canPos = world.entityPosition(candidate)
		
		--sb.logInfo("LOS?"..sb.printJson(world.lineTileCollision(pos, canPos)))
		if not world.lineTileCollision(pos, canPos) then
			local toTarget = world.distance(canPos, pos)
			--local toTargetAngle = util.angleDiff(angle, vec2.angle(toTarget))
	
			
			return candidate
			
		end
		end
	end
  --end
  
  return "cannot"
  --mcontroller.setRotation(math.atan(vel[2], vel[1]))
end