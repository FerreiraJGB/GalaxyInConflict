require "/scripts/vec2.lua"
require "/scripts/util.lua"

function init()
  self.homingDistance = config.getParameter("homingDistance", 50)
  self.rotationRate = config.getParameter("rotationRate",0.5)
  self.trackingLimit = config.getParameter("trackingLimit",9999)
  self.sourceEntity = projectile.sourceEntity()
  self.queryParametersPrime = {
    withoutEntityId = self.sourceEntity,
    includedTypes = {"vehicle"},
    order = "nearest"
  }
  self.queryParameters = {
    withoutEntityId = self.sourceEntity,
    includedTypes = {"creature"},
    order = "nearest"
  }

  --local ttlVariance = config.getParameter("timeToLiveVariance")
  --if ttlVariance then
    --projectile.setTimeToLive(projectile.timeToLive() + sb.nrand(ttlVariance))
  --end
  
  local startingVelocity = config.getParameter("startingVelocity")
  --sb.logInfo(sb.printJson(startingVelocity))
  if startingVelocity then
	--mcontroller.setVelocity(startingVelocity)
	
	local angle = math.atan(startingVelocity[2],startingVelocity[1])
	--sb.logInfo(angle)
	mcontroller.setVelocity({1*math.cos(angle),1*math.sin(angle)})
	--sb.logInfo(sb.printJson(startingVelocity))
  end
  
  self.explosiveCoin = false
  self.foundTarget = false
  self.targetEntityId = nil
  
  local pretargetedEntity = config.getParameter("pretargetedEntity")
  if not (pretargetedEntity or config.getParameter("dumbProjectile")) then
	aimProjectile()
  end
  
  --sb.logInfo(sb.printJson(config.getParameter("aimProjectile")))
  
  if pretargetedEntity and world.entityPosition(pretargetedEntity) then
	local vel = {1,0}--mcontroller.velocity()
	local angle = vec2.angle(vel)
	
	local toTarget = world.distance(world.entityPosition(pretargetedEntity), mcontroller.position())
    local toTargetAngle = util.angleDiff(angle, vec2.angle(toTarget))
	
	vel = vec2.rotate(vel, toTargetAngle)
	mcontroller.setVelocity(vel)
	mcontroller.setRotation(math.atan(vel[2], vel[1]))
	
	self.foundTarget = true
	self.targetEntityId = pretargetedEntity
	
	if not (world.entityType(pretargetedEntity) == "vehicle") then
		self.explosiveCoin = true
	end
  end
  
  self.triggered = false
  self.tick = 0
  
  script.setUpdateDelta(1)
end

function update(dt)
	if not self.triggered then
		local targetPos
		local selfPos = mcontroller.position()
		local segment = 1.25
		--note to self - 5pixels = 1 unit of SB distance
		
		--targeting
		if self.foundTarget and world.entityPosition(self.targetEntityId) then
			targetPos = world.entityPosition(self.targetEntityId)
		else
			local newPos = vec2.add(mcontroller.position(),{mcontroller.xVelocity()*200,mcontroller.yVelocity()*200})
			local line = world.lineCollision(mcontroller.position(), newPos)
			
			local angle = util.angleDiff(mcontroller.rotation(), vec2.angle(world.distance(newPos, selfPos)))
			mcontroller.setRotation(angle)
			if line then
				targetPos = line
			else
				targetPos = newPos
			end
		end
		
		local distance = world.magnitude(selfPos, targetPos)
		
		local count = math.ceil(distance / segment)
		
		local deltaX = (targetPos[1]-selfPos[1])/count
		local deltaY = (targetPos[2]-selfPos[2])/count
		
		mcontroller.setVelocity(vec2.rotate({0.1,0}, mcontroller.rotation()))
		--mcontroller.setRotation(math.atan(vel[2], vel[1]))
		
		--world.spawnProjectile("gic_cointrail", {targetPos[1],targetPos[2]}, projectile.sourceEntity(), mcontroller.velocity(), false, params)
		--world.spawnProjectile("gic_cointrail", {selfPos[1],selfPos[2]}, projectile.sourceEntity(), mcontroller.velocity(), false, params)
		
		repeat
			world.spawnProjectile("gic_cointrail", {targetPos[1]-deltaX*(count),targetPos[2]-deltaY*(count)}, projectile.sourceEntity(), mcontroller.velocity(), false, params)
			count = count - 1
		until count <= 0
		
		mcontroller.setVelocity(vec2.rotate({1,0}, mcontroller.rotation()))
		if self.foundTarget and world.entityPosition(self.targetEntityId) then
			targetPos = world.entityPosition(self.targetEntityId) --refresh location
			--mcontroller.setVelocity(world.entityVelocity(self.targetEntityId)) --match velocity to target's velocity
		end
		
		mcontroller.setPosition(targetPos)
		self.triggered = true
		--sb.logInfo("Triggered Coin")
	end
	
	if self.foundTarget and world.entityPosition(self.targetEntityId) then
		mcontroller.setPosition(world.entityPosition(self.targetEntityId)) --refresh location
		--mcontroller.setVelocity(world.entityVelocity(self.targetEntityId)) --match velocity to target's velocity
	end
	
	--mcontroller.setVelocity(vec2.rotate({1,0}, mcontroller.rotation()))
	if self.tick == 2 then projectile.die() end
	
	self.tick = self.tick + 1
end


function aimProjectile()
  local pos = mcontroller.position()
  local candidatesPrime = world.entityQuery(pos, self.homingDistance, self.queryParametersPrime)
  local candidates = world.entityQuery(pos, self.homingDistance, self.queryParameters)

  --if #candidates == 0 then return end
  if #candidatesPrime == 0 and #candidates == 0 then return end

  local vel = {1,0}--mcontroller.velocity()
  local angle = vec2.angle(vel)
  
 self.foundTarget = false

  for _, candidate in ipairs(candidatesPrime) do
    if world.entityCanDamage(self.sourceEntity, candidate) and world.entityName(candidate) == "gic_coin" then
      local canPos = world.entityPosition(candidate)
      if not world.lineTileCollision(pos, canPos) then
        local toTarget = world.distance(canPos, pos)
        local toTargetAngle = util.angleDiff(angle, vec2.angle(toTarget))

        --if math.abs(toTargetAngle) > self.trackingLimit then
          --return
        --end

        local rotateAngle = toTargetAngle--math.max(-self.rotationRate, math.min(toTargetAngle, self.rotationRate))

		--vel = {200,0}
        vel = vec2.rotate(vel, rotateAngle)
        mcontroller.setVelocity(vel)
		self.foundTarget = true
		self.targetEntityId = candidate
		
		--sb.logInfo(world.entityType(candidate)) --returns "vehicle" and etc
		--sb.logInfo(world.entityName(candidate)) -- returns "gic_coin" and etc
		
		--sb.logInfo("FOUND VEHICLE!!!")

        break
      end
    end
  end
  
  --sb.logInfo(sb.printJson(foundTarget))
  if self.foundTarget == false then
	--sb.logInfo("try to find creature")
	
	for _, candidate in ipairs(candidates) do
		if world.entityCanDamage(self.sourceEntity, candidate) then
		local canPos = world.entityPosition(candidate)
		if not world.lineTileCollision(pos, canPos) then
			local toTarget = world.distance(canPos, pos)
			local toTargetAngle = util.angleDiff(angle, vec2.angle(toTarget))
	
			--if math.abs(toTargetAngle) > self.trackingLimit then
			--return
			--end

			local rotateAngle = toTargetAngle--math.max(-self.rotationRate, math.min(toTargetAngle, self.rotationRate))

			--vel = {200,0}
			vel = vec2.rotate(vel, rotateAngle)
			mcontroller.setVelocity(vel)
			self.foundTarget = true
			self.targetEntityId = candidate
			
			self.explosiveCoin = true
			break
		end
		end
	end
  end

  mcontroller.setRotation(math.atan(vel[2], vel[1]))
end

function hit(entityId)
  local params = {}
  local power = config.getParameter("power")
  params.timeToLive = 0
  params.power = math.min(power * 0.2,100) --capped damage at 100
  --sb.logInfo(config.getParameter("power"))
  --params.timeToLive = 0
  --params.actionOnReap = jarray()
  --params.actionOnReap[1] = {action = "sound", options = jarray()}
  --params.actionOnReap[1].options[1] = "/sfx/melee/gic_bloodborne_iron-stab-iron.wav"
  
  if self.explosiveCoin and power >= 350 then
	-- sb.logInfo("spawnedBomb")
	world.spawnProjectile("shrapnelbomb",mcontroller.position(),projectile.sourceEntity(),{0,0},false,params)
  end
end