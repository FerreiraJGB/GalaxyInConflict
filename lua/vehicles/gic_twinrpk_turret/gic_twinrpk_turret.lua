require "/scripts/vec2.lua"
require "/scripts/util.lua"
require "/vehicles/gic_mountedturret.lua"

-- equivalent "controls" function (compared to other later GiC vehicles)
function updateDriving()
  local moving = false
  local facing = self.facingDirection
  local diff = world.distance(self.gunnerAimPos, vec2.add(mcontroller.position(),animator.partPoint("frontGun2", "rotationCenter")))
  local aimAngle = math.atan(diff[2], diff[1])
  local facingDirection = (aimAngle > math.pi / 2 or aimAngle < -math.pi / 2) and -1 or 1
  local mechAimLimit = config.getParameter("mechAimLimit") * math.pi / 180
  local mechProjectile = config.getParameter("mechProjectile")
  local mechProjectile2 = config.getParameter("mechProjectile2")
  local mechProjectileConfig = config.getParameter("mechProjectileConfig")
  local mechProjectile2Config = config.getParameter("mechProjectile2Config")
  local mechFireCycle = config.getParameter("mechFireCycle")
  local mechFireCycle2 = config.getParameter("mechFireCycle2")
	
  local driverThisFrame = vehicle.entityLoungingIn("drivingSeat")
  
  
  
  
  
  if (driverThisFrame ~= nil) then
    vehicle.setDamageTeam(world.entityDamageTeam(driverThisFrame))

  if facingDirection < 0 then
    facing = -1

    if aimAngle > 0 then
      aimAngle = math.max(aimAngle, math.pi - mechAimLimit + self.angle)
    else
      aimAngle = math.min(aimAngle, -math.pi + mechAimLimit + self.angle)
    end

    animator.rotateGroup("guns", math.pi - aimAngle + self.angle)
  else
    facing = 1

    if aimAngle > 0 then
      aimAngle = math.min(aimAngle, mechAimLimit + self.angle)
    else
      aimAngle = math.max(aimAngle, -mechAimLimit + self.angle)
    end

    animator.rotateGroup("guns", aimAngle - self.angle)
  end
	
    -- if vehicle.controlHeld("drivingSeat", "left") then
      -- mcontroller.approachXVelocity(-self.targetMoveSpeed, self.moveControlForce)
      -- moving = true
    -- end

    -- if vehicle.controlHeld("drivingSeat", "right") then
      -- mcontroller.approachXVelocity(self.targetMoveSpeed, self.moveControlForce)
      -- moving = true
    -- end
	
	--disable the alt fire function
    --if vehicle.controlHeld("drivingSeat", "altFire") then
      --if self.fireTimer <= 0 then
        --world.spawnProjectile(mechProjectile, vec2.add(mcontroller.position(), animator.partPoint("frontGun", "firePoint")), entity.id(), {math.cos(aimAngle), math.sin(aimAngle)}, false, mechProjectileConfig)
        --self.fireTimer = self.fireTimer + mechFireCycle
        --animator.setAnimationState("frontFiring", "fire")
      --else
        --local oldFireTimer = self.fireTimer
        --self.fireTimer = self.fireTimer - script.updateDt()
        --if oldFireTimer > mechFireCycle / 2 and self.fireTimer <= mechFireCycle / 2 then
          --world.spawnProjectile(mechProjectile, vec2.add(mcontroller.position(), animator.partPoint("frontGun", "firePoint")), entity.id(), {math.cos(aimAngle), math.sin(aimAngle)}, false, mechProjectileConfig)
          --animator.setAnimationState("frontFiring", "fire")
        --end
      --end
    --end
	
	
	local inaccuracy = config.getParameter("inaccuracy",0.02)
	local deteriorationMult = config.getParameter("deteriorationMultiplier",0.75)
	--gun will only function if turret is "loaded"
    if (vehicle.controlHeld("drivingSeat", "primaryFire") or self.aiFire) and animator.animationState("turret") == "loaded" and storage.jammed == false then
	  local projectile = ""
	  local missChanceRoll = math.random(0,100)
	  local missChance = config.getParameter("missChance",20)
	  
	  if missChanceRoll <= missChance then
		projectile = config.getParameter("missProjectile")
	  else
		projectile = mechProjectile2
	  end
	  
	  local jamChanceRoll = 1000 --will be within (0-1000)
	  local jamChance = storage.deterioration - 75 --make this slowly bump up with firing, cap it at 100
	  
      if self.fireTimer2 <= 0 then
		jamChanceRoll = math.random(0,jamChanceRoll)
        world.spawnProjectile(projectile, vec2.add(mcontroller.position(), animator.partPoint("frontGun", "firePoint")), entity.id(), aimVector(aimAngle,inaccuracy), false, mechProjectile2Config)
        self.fireTimer2 = self.fireTimer2 + mechFireCycle2
        animator.setAnimationState("frontFiring", "fire")
		animator.playSound("fire")
		
		storage.deterioration = math.min(storage.deterioration+1*deteriorationMult,100)
      else
        local oldFireTimer2 = self.fireTimer2
        self.fireTimer2 = self.fireTimer2 - script.updateDt()
        if oldFireTimer2 > mechFireCycle2 / 2 and self.fireTimer2 <= mechFireCycle2 / 2 then
		  jamChanceRoll = math.random(0,jamChanceRoll)
          world.spawnProjectile(projectile, vec2.add(mcontroller.position(), animator.partPoint("frontGun2", "firePoint2")), entity.id(), aimVector(aimAngle,inaccuracy), false, mechProjectile2Config)
          animator.setAnimationState("frontFiring2", "fire")
		  animator.playSound("fire")
		  
		  storage.deterioration = math.min(storage.deterioration+1*deteriorationMult,100)
        end
      end
	  
	  if storage.jammed == false and jamChanceRoll <= jamChance then
		local spawnPos = vec2.add(mcontroller.position(),{0,2})
		
		animator.playSound("jam")
		world.spawnProjectile(config.getParameter("textProjectile"),spawnPos,entity.id(),{0,0},false,config.getParameter("jammedTextConfig"))
		storage.jammed = true
		self.jammedRepairReq = storage.wrenchHit + 5
	  end
    end
	
	
  else
    vehicle.setDamageTeam({type = "passive"})
  end
  
  return moving, facing
end
