require "/scripts/vec2.lua"
require "/scripts/util.lua"

function init()
  self.homingDistance = config.getParameter("homingDistance", 400)
  self.rotationRate = config.getParameter("rotationRate")
  self.trackingLimit = config.getParameter("trackingLimit")
  self.initialTargetEntity = config.getParameter("initialTarget")
  self.trackInitial = true
  self.sourceEntity = projectile.sourceEntity()
  self.queryParameters = {
    withoutEntityId = self.sourceEntity,
    includedTypes = {"creature"},
    order = "nearest"
  }

  local ttlVariance = config.getParameter("timeToLiveVariance")
  if ttlVariance then
    projectile.setTimeToLive(projectile.timeToLive() + sb.nrand(ttlVariance))
  end
end

function calculateIntercept(target)
	-- initial reference was https://stackoverflow.com/questions/17204513/how-to-find-the-interception-coordinates-of-a-moving-target-in-3d-space, thanks internet
	-- still a good bit of my own code; ripped and translated from javascript from a personal project of mine.

	-- self pos and vel
	local posX = mcontroller.position()[1]
	local posY = mcontroller.position()[2]
	
	local svelX = mcontroller.velocity()[1]
	local svelY = mcontroller.velocity()[2]
	local velA = math.sqrt(svelX*svelX + svelY*svelY)
	-- self pos and vel
	
	-- target pos and vel
	local targetPosX = world.entityPosition(target)[1]
	local targetPosY = world.entityPosition(target)[2]
	
	local targetVelX = world.entityVelocity(target)[1]
	local targetVelY = world.entityVelocity(target)[2]
	-- target pos and vel
	
	local a = (targetVelX*targetVelX) + (targetVelY*targetVelY) - (velA*velA)
	local b = 2 * (targetVelX*(targetPosX-posX)+targetVelY*(targetPosY-posY))
	local c = posX*posX + targetPosX*targetPosX + posY*posY + targetPosY*targetPosY - 2 * (posX*targetPosX) - 2 * (posY*targetPosY)
	
	local t1 = (-1*b + math.sqrt(b*b - 4 * a * c))/(2*a)
	local t2 = (-1*b - math.sqrt(b*b - 4 * a * c))/(2*a)
	
	local invalidNum = 999999
	if (t1 < 0) then t1 = invalidNum end
	if (t2 < 0) then t2 = invalidNum end
	local finalT = math.min(t1,t2)
	if (finalT == invalidNum) then finalT = 1 end
	
	local fireAngle = math.atan( (targetPosY - posY + targetVelY * finalT), (targetPosX - posX + targetVelX * finalT) )
	
	--sb.logInfo(sb.printJson(fireAngle))
	--sb.logInfo(sb.printJson(velA))
	return fireAngle
end

function update(dt)
  local pos = mcontroller.position()
  local candidates = world.entityQuery(pos, self.homingDistance, self.queryParameters)

  if #candidates == 0 then return end

  local vel = mcontroller.velocity()
  local angle = vec2.angle(vel)
  
  self.checkInitial = (function()
  
	if world.entityExists(self.initialTargetEntity) then
		local canPos = world.entityPosition(self.initialTargetEntity)
		if not world.lineTileCollision(pos, canPos) then
			--local toTarget = world.distance(canPos, pos)
			--local targetVel = world.entityVelocity(self.initialTargetEntity) or {0,0} --allows missile to "lead" target
			--targetVel = {targetVel[1]*0.25,targetVel[2]*0.25}
		
			--local toTargetAngle = util.angleDiff(angle, vec2.angle(vec2.add(toTarget,targetVel)))
			local toTargetAngle = util.angleDiff(angle, calculateIntercept(self.initialTargetEntity))

			if math.abs(toTargetAngle) > self.trackingLimit then
				return
			end

			local rotateAngle = math.max(dt * -self.rotationRate, math.min(toTargetAngle, dt * self.rotationRate))

			vel = vec2.rotate(vel, rotateAngle)
			mcontroller.setVelocity(vel)

			return
		end
	end
	
	self.trackInitial = false
  end)

  if self.trackInitial == true then
	self.checkInitial()
  else
  for _, candidate in ipairs(candidates) do
    if world.entityCanDamage(self.sourceEntity, candidate) then
      local canPos = world.entityPosition(candidate)
      if not world.lineTileCollision(pos, canPos) then
        --local toTarget = world.distance(canPos, pos)
		--local targetVel = world.entityVelocity(candidate) or {0,0} --allows missile to "lead" target
		--targetVel = {targetVel[1]*0.25,targetVel[2]*0.25}
		
        --local toTargetAngle = util.angleDiff(angle, vec2.angle(vec2.add(toTarget,targetVel)))
		local toTargetAngle = util.angleDiff(angle, calculateIntercept(candidate))

        if math.abs(toTargetAngle) > self.trackingLimit then
          return
        end

        local rotateAngle = math.max(dt * -self.rotationRate, math.min(toTargetAngle, dt * self.rotationRate))

        vel = vec2.rotate(vel, rotateAngle)
        mcontroller.setVelocity(vel)

        break
      end
    end
  end
  end

  mcontroller.setRotation(math.atan(vel[2], vel[1]))
end
