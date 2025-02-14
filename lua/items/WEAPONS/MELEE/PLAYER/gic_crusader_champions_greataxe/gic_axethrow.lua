require "/scripts/util.lua"
require "/scripts/status.lua"
require "/items/active/weapons/weapon.lua"
require "/scripts/interp.lua"
--require "/scripts/rope.lua"

Throw = WeaponAbility:new()

function Throw:init()
  self.cooldownTimer = self.cooldownTime
  self:reset()
  
  --self.ropeOffset = config.getParameter("ropeOffset")
  --self.ropeVisualOffset = config.getParameter("ropeVisualOffset")
  
  --self.rope = {}
  --self.ropeLength = 0
  
  self.reeling = false
  
  --if not storage.projectileIds then storage.projectileIds = {} end
  
  if storage.projectileIds then
	animator.setGlobalTag("directives", "?crop=10;3;10;3")
  else
	animator.setGlobalTag("directives", "")
  end
  
  self.lastRecordedProjectileDistance = {999,999}
  
  animator.setGlobalTag("directives", "")
end

function Throw:update(dt, fireMode, shiftHeld)
  WeaponAbility.update(self, dt, fireMode, shiftHeld)

  self.dt = dt
  self.cooldownTimer = math.max(0, self.cooldownTimer - dt)
  
  if self.weapon.currentAbility == nil
    and self.cooldownTimer == 0
    --and not status.resourceLocked("energy")
    and shiftHeld 
	and not storage.projectileIds then
    
    self:setState(self.throw)
  elseif self.weapon.currentAbility == nil
    and fireMode == "alt"
    and self.cooldownTimer == 0
	and not self.parryActive
	and status.resourcePositive("shieldStamina") then
    --and status.overConsumeResource("energy", self.energyUsage) then

    self.weapon:setStance(self.stances.parry)
	self.weapon:updateAim()
	self:setState(self.parry)
  end
  
  if storage.projectileIds then -- locks attacking
    --if shiftHeld then
		--world.callScriptedEntity(storage.projectileIds[1], "forceReturn")
	--end
	self:setState(self.wait)
	animator.setGlobalTag("directives", "?crop=10;3;10;3")
  else
	animator.setGlobalTag("directives", "")
  end
  
  self:checkProjectiles()
  --self:renderRope()
  
  self.shiftHeld = shiftHeld
  if fireMode == "alt" then
	self.fireModeTmp = 1
  else
	self.fireModeTmp = 0
  end
end

function Throw:parry()
  self.parryActive = true
  self.weapon:setStance(self.stances.parry)
  self.weapon:updateAim()
  self.parryTime = 999999
  status.setPersistentEffects("broadswordParry", {{stat = "shieldHealth", amount = 99999}})
  status.setResource("shieldStamina", 1)
  --self.perfectBlockTime = 20 --ticks

  --status.setPersistentEffects("broadswordParry", {{stat = "shieldHealth", amount = self.shieldHealth}})

  local blockPoly = animator.partPoly("parryShield", "shieldPoly")
  activeItem.setItemShieldPolys({blockPoly})

  animator.setAnimationState("parryShield", "active")
  --coroutine.yield()
  
  animator.playSound("guard")
  
  --
  local shieldHp = status.resource("shieldStamina")
  local damageListener = damageListener("damageTaken", function(notifications)
    for _,notification in pairs(notifications) do
      if notification.sourceEntityId ~= -65536 and notification.healthLost == 0 then
		if self.shieldTime <= self.perfectBlockTime and status.resource("shieldStamina") < shieldHp then
			animator.playSound("perfectBlock")
			
			self.shieldTime = 0
			status.setResource("shieldStamina", 1)
		else
			animator.playSound("parry")
		end
        --animator.playSound("parry")
        animator.setAnimationState("parryShield", "block")
        return
      end
    end
	
	shieldHp = status.resource("shieldStamina")
  end)
  
  
  
  local perfectParryGone = false
  self.shieldTime = 0
  self.fireModeTmp = 1
  util.wait(self.parryTime, function(dt)
  
	--Interrupt when running out of shield stamina
	if not status.resourcePositive("shieldStamina") then 
		self.cooldownTimer = 1.5
		animator.playSound("break") 
		return true 
	end
	if self.fireModeTmp == 0 then 
		self.cooldownTimer = self.cooldownTime
		return true 
	end
  
	self.shieldTime = self.shieldTime + self.dt
	if self.shieldTime <= self.perfectBlockTime then
		animator.setGlobalTag("directives", "?border=2;AACCFFFF;00000000")
	else
		animator.setGlobalTag("directives", "")
		if perfectParryGone == false then
			status.setPersistentEffects("broadswordParry", {{stat = "shieldHealth", amount = self.shieldHealth}})
			perfectParryGone = true
		end
	end
	
	damageListener:update()
  end)
  self.parryActive = false
  animator.setGlobalTag("directives", "")

  
  
  --while self.fireModeTmp == 1 and status.resourcePositive("shieldStamina") do
  --  self.damageListener = damageListener("damageTaken", function(notifications)
  --  for _,notification in pairs(notifications) do
      --if notification.sourceEntityId ~= -65536 and notification.healthLost == 0 then
	--  if notification.hitType == "ShieldHit" then
    --    animator.playSound("parry")
	--	animator.playSound("guard")
   --     animator.setAnimationState("parryShield", "block")
   --     return
   --   end
  --  end
  --end)
	--local blockPoly = animator.partPoly("parryShield", "shieldPoly")
   -- activeItem.setItemShieldPolys({blockPoly})
    --coroutine.yield()
  --end
  
  --self.cooldownTimer = self.cooldownTime
  activeItem.setItemShieldPolys({})
end

function Throw:throw()
  local progress = 0
  
  -- self.stances.windup.duration
  --util.wait(9999, function()
		--local from = self.stances.idle.weaponOffset or {0,0}
		--local to = self.stances.windup.weaponOffset or {0,0}
		--self.weapon.weaponOffset = {interp.linear(progress, from[1], to[1]), interp.linear(progress, from[2], to[2])}

		--self.weapon.relativeWeaponRotation = util.toRadians(interp.linear(progress, self.stances.idle.weaponRotation, self.stances.windup.weaponRotation))
		--self.weapon.relativeArmRotation = util.toRadians(interp.linear(progress, self.stances.idle.armRotation, self.stances.windup.armRotation))

		--progress = math.min(1.0, progress + (self.dt / self.stances.windup.duration))
		
		--mcontroller.controlModifiers({runningSuppressed = true})
  --end)
  
  self.weapon:setStance(self.stances.idle)
  self.weapon:updateAim()
  
  local cancel = false
  local progress = 0
  while progress < 1.0 and progress >= 0 do
	local from = self.stances.idle.weaponOffset or {0,0}
	local to = self.stances.windup.weaponOffset or {0,0}
	self.weapon.weaponOffset = {interp.linear(progress, from[1], to[1]), interp.linear(progress, from[2], to[2])}

	self.weapon.relativeWeaponRotation = util.toRadians(interp.linear(progress, self.stances.idle.weaponRotation, self.stances.windup.weaponRotation))
	self.weapon.relativeArmRotation = util.toRadians(interp.linear(progress, self.stances.idle.armRotation, self.stances.windup.armRotation))

	if self.shiftHeld then
		progress = math.min(1.0, progress + (self.dt / self.stances.windup.duration))
	else
		progress = math.max(-0.1, progress - (self.dt / self.stances.windup.duration))
	end
		
	mcontroller.controlModifiers({runningSuppressed = true})
	
	if progress < 0 then
		cancel = true
	end
    coroutine.yield()
  end
  
  if cancel then return end
  
  self.weapon:setStance(self.stances.windup)
  self.weapon:updateAim()

  --animator.setAnimationState("spinSwoosh", "Throw")
  --self.weapon.aimAngle = 0
  --activeItem.setOutsideOfHand(true)

  while self.shiftHeld do
    --self.weapon.relativeWeaponRotation = self.weapon.relativeWeaponRotation + util.toRadians(self.spinRate * self.dt)
    --local damageArea = partDamageArea("spinSwoosh")
    --self.weapon:setDamage(self.damageConfig, damageArea)
    --mcontroller.controlModifiers({runningSuppressed=true})

	--wait for shiftHeld no longer held
    coroutine.yield()
  end
  
  self.weapon:setStance(self.stances.throw)
  self.weapon:updateAim()
  animator.playSound("throw")
  
  self.projectileType = config.getParameter("projectileType")
  self.projectileParameters = config.getParameter("projectileParameters")
  local params = copy(self.projectileParameters)
  params.powerMultiplier = activeItem.ownerPowerMultiplier()
  params.ownerAimPosition = activeItem.ownerAimPosition()
  --if self.aimDirection < 0 then params.processing = "?flipx" end
  
  --local direction = 
  local projectileId = world.spawnProjectile(
      self.projectileType,
      firePosition(),
      activeItem.ownerEntityId(),
      self:aimVector(0),
      false,
      params
    )
  if projectileId then
    storage.projectileIds = {projectileId}
  end
  
  util.wait(self.stances.throw.duration)
  self.cooldownTimer = self.cooldownTime
end

function Throw:wait()
   self.weapon:setStance(self.stances.wait)
   
   local calledDespawn = false
   local callDespawn = false
   self.heldDownTime = 0
   --local heldDownTime = 0
   --local storeProjectile
   while storage.projectileIds do
    self.weapon:setStance(self.stances.wait)
	
	if world.entityExists(storage.projectileIds[1]) then
		if self.shiftHeld  and self.reeling == false then
			world.callScriptedEntity(storage.projectileIds[1], "forceReturn")
		end
		--sb.logInfo(sb.printJson(self.shiftHeld))
		
		if not callDespawn then
			callDespawn = world.callScriptedEntity(storage.projectileIds[1], "projectileCollided")
		end
	
		if callDespawn == true and not calledDespawn then
			local storedProjectile = world.callScriptedEntity(storage.projectileIds[1], "despawn")
			calledDespawn = true
			
			if type(storedProjectile) == "number" then
				self.newProjectile = storedProjectile
			end
			--sb.logInfo(sb.printJson(self.newProjectile))
		end
	else
		if self.newProjectile then storage.projectileIds[1] = self.newProjectile end
	end
	
    coroutine.yield()
  end
  
  --if self.newProjectile then
	--sb.logInfo(sb.printJson(self.newProjectile))
  --end
end

function Throw:renderRope()
  if storage.projectileIds then
    if world.entityExists(storage.projectileIds[1]) then
      local position = mcontroller.position()
      local handPosition = vec2.add(position, activeItem.handPosition(self.ropeOffset))

      local newRope
      if #self.rope == 0 then
        newRope = {handPosition, self.projectilePosition}
		self.rope = newRope
      else
        newRope = copy(self.rope)
        table.insert(newRope, 1, world.nearestTo(newRope[1], handPosition))
        table.insert(newRope, world.nearestTo(newRope[#newRope], self.projectilePosition))
      end
	  
	  windRope(newRope)
      self:updateRope(newRope)
    else
      self:cancel()
    end
  end
end

function Throw:updateRope(newRope)
  local position = mcontroller.position()
  local previousRopeCount = #self.rope
  self.rope = newRope
  self.ropeLength = 0
  
  --if (self.longestRope < previousRopeCount) then self.longestRope = previousRopeCount end

  activeItem.setScriptedAnimationParameter("ropeOffset", self.ropeVisualOffset)
  for i = 2, #self.rope do
    self.ropeLength = self.ropeLength + world.magnitude(self.rope[i], self.rope[i - 1])
    activeItem.setScriptedAnimationParameter("p" .. i, self.rope[i])
  end
  for i = #self.rope + 1, previousRopeCount do
    activeItem.setScriptedAnimationParameter("p" .. i, nil)
  end
end

function Throw:cancel()
  --self:updateRope({})
  --self.rope = {mcontroller.position(),mcontroller.position()}
end

function firePosition()
  return vec2.add(mcontroller.position(), activeItem.handPosition(self.fireOffset))
end

function Throw:aimVector(inaccuracy)
  local aimVector = vec2.rotate({1, 0}, self.weapon.aimAngle + sb.nrand(inaccuracy, 0))
  aimVector[1] = aimVector[1] * mcontroller.facingDirection()
  return aimVector
end

function Throw:reset()
  --animator.setAnimationState("spinSwoosh", "idle")
  --activeItem.setOutsideOfHand(false)
  
  animator.setAnimationState("parryShield", "inactive")
  status.clearPersistentEffects("broadswordParry")
  activeItem.setItemShieldPolys({})
end

function Throw:uninit()
  self:reset()
  self:cancel()
end

function Throw:catch()
	self.weapon:setStance(self.stances.catch)
	animator.playSound("catch")
	
	util.wait(self.stances.catch.duration)
end

function Throw:checkProjectiles()
  if storage.projectileIds then
    local newProjectileIds = {}
    for i, projectileId in ipairs(storage.projectileIds) do
      if world.entityExists(projectileId) then
        local updatedProjectileIds = world.callScriptedEntity(projectileId, "projectileIds")
		
		if self.reeling == false and world.callScriptedEntity(projectileId, "reelingBack") then
			animator.playSound("reel", -1)
		end
		self.reeling = world.callScriptedEntity(projectileId, "reelingBack")

        if updatedProjectileIds then
          for j, updatedProjectileId in ipairs(updatedProjectileIds) do
			local position = mcontroller.position()
			self.projectilePosition = vec2.add(world.distance(world.entityPosition(updatedProjectileId), position), position)
			
            table.insert(newProjectileIds, updatedProjectileId)
          end
        end
		
		self.lastRecordedProjectileDistance = world.distance(world.entityPosition(projectileId),mcontroller.position())
      else
	    --self.rope = {mcontroller.position(),mcontroller.position()}
		self.reeling = false
		animator.stopAllSounds("reel")
		self.cooldownTimer = self.cooldownTime * 2
		
		--sb.logInfo(sb.printJson(self.longestRope))
		--for a = 1, (self.longestRope or 1) do
			--activeItem.setScriptedAnimationParameter("p" .. a, nil)
		--end
		self:cancel()
		
		if vec2.mag(self.lastRecordedProjectileDistance) <= 2.0 then
			self:setState(self.catch)
		end
	  end
    end
    storage.projectileIds = #newProjectileIds > 0 and newProjectileIds or nil
  else
	--self.rope = {mcontroller.position(),mcontroller.position()}
	self.reeling = false
	animator.stopAllSounds("reel")
	self:cancel()
  end
end
