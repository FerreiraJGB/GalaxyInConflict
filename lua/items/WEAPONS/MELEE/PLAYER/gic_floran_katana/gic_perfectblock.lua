require "/scripts/util.lua"
require "/scripts/status.lua"
require "/items/active/weapons/weapon.lua"

Parry = WeaponAbility:new()

function Parry:init()
  self.cooldownTimer = 0
  animator.setGlobalTag("directives", "")
  --self.parryTimeTemp = self.parryTime
end

function Parry:update(dt, fireMode, shiftHeld)
  WeaponAbility.update(self, dt, fireMode, shiftHeld)

  self.cooldownTimer = math.max(0, self.cooldownTimer - dt)

  if self.weapon.currentAbility == nil
    and fireMode == "alt"
    and self.cooldownTimer == 0 
	and not self.parryActive
	and status.resourcePositive("shieldStamina") then
    --and status.overConsumeResource("energy", self.energyUsage) then

    self.weapon:setStance(self.stances.parry)
	self.weapon:updateAim()
	self:setState(self.parry)

 
  elseif self.weapon.currentAbility == nil and shiftHeld and self.cooldownTimer == 0 then
	self:setState(self.counter)
	
  end
  if fireMode == "alt" then
	self.fireModeTmp = 1
  else
	self.fireModeTmp = 0
  end
end

function Parry:counter()
  self.weapon:setStance(self.stances.windup)
  self.weapon:updateAim()
  self.counterTime = 0.5
  status.setPersistentEffects("broadswordParry", {{stat = "shieldHealth", amount = 99999}})
  status.setResource("shieldStamina", 1)

  --animator.setAnimationState("parryShield", "active")
  --coroutine.yield()
  
  animator.playSound("guard")
  
  --
  local counterAttackTarget
  local counterAttackQuery = false
  
  local shieldHp = status.resource("shieldStamina")
  local damageListener = damageListener("damageTaken", function(notifications)
    for _,notification in pairs(notifications) do
	  --sb.logInfo(sb.printJson(notification))
      if notification.sourceEntityId ~= -65536 and notification.healthLost == 0 and status.resource("shieldStamina") < shieldHp then
	  --sb.logInfo(status.resource("shieldStamina"))
		--if self.shieldTicks <= self.perfectBlockTime then
			--animator.playSound("counterAttack")
			--status.setResource("shieldStamina", self.shieldHealth)
			--animator.setAnimationState("parryShield", "block")
			
			local validCounterattackTargets = findTargets(vec2.add(mcontroller.position(),{3 * mcontroller.facingDirection(),0}),10)
			status.setResource("shieldStamina", 1)
			
			if validCounterattackTargets then
				counterAttackQuery = true
				--animator.playSound("counterAttack")
				counterAttackTarget = validCounterattackTargets[1]
				--sb.logInfo(sb.printJson(counterAttackTarget))
				--status.addEphemeralEffect("regenerationfast",1)
			end
        return
      end
    end
	
	shieldHp = status.resource("shieldStamina")
  end)
  
  
  
  --local perfectParryGone = false
  self.shieldTicks = 0
  self.fireModeTmp = 1
  
  --local addAttack = false
  status.addEphemeralEffect("gic_superarmor", self.stances.windup.duration + self.stances.fire.duration)
  
  local blockPoly = animator.partPoly("counterShield", "shieldPoly")
  activeItem.setItemShieldPolys({blockPoly})
  util.wait(self.stances.windup.duration, function(dt)
  
	--suppress movement
    mcontroller.controlModifiers({movementSuppressed = true})
	
	if counterAttackQuery == true then return true end
  
	animator.setGlobalTag("directives", "?border=2;AACCFFFF;00000000;?flipx")
	
	damageListener:update()
  end)
  
  
  
  self.weapon:setStance(self.stances.fire)
  self.weapon:updateAim()
  animator.setAnimationState("swoosh", "fire5")
  blockPoly = partDamageArea("swoosh")
  activeItem.setItemShieldPolys({blockPoly})
  
  animator.setAnimationState("swoosh", "fire4")
  animator.playSound("fire4")
  
  
  local damageConfig = self.damageConfig
  util.wait(self.stances.fire.duration, function(dt)
  
	--suppress movement
    mcontroller.controlModifiers({movementSuppressed = true})
  
	animator.setGlobalTag("directives", "?border=2;AACCFFFF;00000000;?flipx")
	
	local damageArea = partDamageArea("swoosh")
	self.weapon:setDamage(damageConfig, damageArea)
	if counterAttackQuery == true then 
		animator.playSound("counterAttack")
		return true 
	end
	
	damageListener:update()
  end)
  
  
  animator.setGlobalTag("directives", "")
  activeItem.setItemShieldPolys({})
  
  if counterAttackQuery == true then
	self.counterTarget = counterAttackTarget
	counterAttackQuery = false
	self:setState(self.counterattack)
  else
	self.cooldownTimer = 1.0
	status.addEphemeralEffect("gic_stun_1",1.0)
	status.overConsumeResource("energy", 9999)
	
	--status.setPersistentEffects("stopMovement", {{stat = "activeMovementAbilities", amount = 1}})
	--util.wait(1.0)
	--status.clearPersistentEffects("stopMovement")
  end
end

function findTargets(pos,trackingDistance)
  local sourceEntity = entity.id()
  local queryParameters = {
    withoutEntityId = sourceEntity,
    includedTypes = {"creature"},
    order = "nearest"
  }

  if not trackingDistance then trackingDistance = 50 end
  if not pos then  pos = mcontroller.position() end
  
  local candidates = world.entityQuery(pos, trackingDistance, queryParameters)
  
  self.targetFound = false
  self.shouldFire = false
  self.toTarget = {mcontroller.facingDirection(),0}

  --sb.logInfo(#candidates)
  if #candidates == 0 then return false end

  --local vel = mcontroller.velocity()
  --local angle = vec2.angle(vel)
  local slashTargets = {}
  for _, candidate in ipairs(candidates) do
    if world.entityCanDamage(sourceEntity, candidate) then
      local canPos = world.entityPosition(candidate)
	  self.canPos = canPos
	  self.candidate = candidate
      if not world.lineTileCollision(pos, canPos) then
        --local toTarget = world.distance(canPos, pos)
		local pulledDat = candidate
		slashTargets[#slashTargets + 1] = pulledDat
      end
    end
  end
  
  if #slashTargets == 0 then return false end
  return slashTargets
end

function Parry:counterattack()
	self:reset()
    status.addEphemeralEffect("invulnerable",self.stances.fire2.duration + self.stances.windup2.duration+0.2)
	
	self.weapon:setStance(self.stances.windup2)
	self.weapon:updateAim()
	util.wait(self.stances.windup2.duration)
	--sb.logInfo(sb.printJson(self.counterTarget))
	
	--if self.counterTarget then
	--sb.logInfo(sb.printJson(world.entityPosition(self.counterTarget)))
	--sb.logInfo("yes")
	--end
	animator.setAnimationState("swoosh", "fire")
	animator.playSound("counterAttack")
	self.weapon:setStance(self.stances.fire2)
	self.weapon:updateAim()
		
	if world.entityPosition(self.counterTarget) then
		local diff = world.distance(world.entityPosition(self.counterTarget), mcontroller.position())
		local hyp = math.sqrt(diff[1]*diff[1] + diff[2]*diff[2])
		local velMult = 45
		local vel = {velMult*diff[1]/hyp,velMult*diff[2]/hyp}
		
		if mcontroller.onGround() and (vel[2] <= 0)then
			vel[1] = vel[1] * 2
		end
	
	--util.wait(self.stances.fire1.duration)
		mcontroller.setVelocity(vel)
	else
		mcontroller.setVelocity({mcontroller.facingDirection()*40,0}) --backup in case target entity is dead
	end
		--local moveConfig = mcontroller.parameters()
		--moveConfig.groundFriction = 0
		--mcontroller.applyParameters(moveConfig)
		
		local damageConfig = self.counterConfig
		--status.setPersistentEffects("stopMovement", {{stat = "activeMovementAbilities", amount = 1}})
		util.wait(self.stances.fire2.duration, function()
			local damageArea = partDamageArea("swoosh")
			self.weapon:setDamage(damageConfig, damageArea)
			mcontroller.controlModifiers({movementSuppressed = true})
		end)
		
		--mcontroller.resetParameters()
		--status.clearPersistentEffects("stopMovement")
	
	self.cooldownTimer = self.cooldownTime
end

function Parry:parry()
  self.parryActive = true
  self.weapon:setStance(self.stances.parry)
  self.weapon:updateAim()
  self.parryTime = 999999
  status.setPersistentEffects("broadswordParry", {{stat = "shieldHealth", amount = 99999}})
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
		if self.shieldTicks <= self.perfectBlockTime and status.resource("shieldStamina") < shieldHp then
			animator.playSound("perfectBlock")
			
			self.shieldTicks = 0
			status.setResource("shieldStamina", 1)
			shieldHp = status.resource("shieldStamina")
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
  self.shieldTicks = 0
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
  
	self.shieldTicks = self.shieldTicks + self.dt
	if self.shieldTicks <= self.perfectBlockTime then
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
  animator.setGlobalTag("directives", "")
  self.parryActive = false

  
  
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

function Parry:reset()
  animator.setAnimationState("parryShield", "inactive")
  status.clearPersistentEffects("broadswordParry")
  --status.clearPersistentEffects("stopMovement")
  activeItem.setItemShieldPolys({})
end

function Parry:uninit()
  self:reset()
end
