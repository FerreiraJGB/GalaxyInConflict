require "/scripts/util.lua"
require "/scripts/status.lua"

function init()
  self.debug = true
  
  self.oldShieldStamina = 0
  self.damageBleedthroughEnabled = config.getParameter("damageBleedthroughEnabled", false)
  self.damageBleedthroughAmount = config.getParameter("damageBleedthroughAmount", 0.1)

  self.trackingVelocities = {}
  self.minDamageAccel = config.getParameter("minVelocity")
  self.lastPosition = mcontroller.position()
  
  self.accelKnockback = config.getParameter("accelKnockback")
  self.accelMaxKnockback = config.getParameter("accelMaxKnockback")
  
  self.accelDamage = config.getParameter("accelDamage")
  self.accelMaxDamage = config.getParameter("accelMaxDamage")
  
  self.minDamageTimeout = config.getParameter("minDamageTimeout")
  self.maxDamageTimeout = config.getParameter("maxDamageTimeout")
  
  self.aimAngle = 0
  self.aimDirection = 1

  self.active = false
  self.cooldownTimer = config.getParameter("cooldownTime")
  self.activeTimer = 0

  self.level = config.getParameter("level", 1)
  self.baseShieldHealth = config.getParameter("baseShieldHealth", 1)
  self.knockback = config.getParameter("knockback", 0)
  self.perfectBlockDirectives = config.getParameter("perfectBlockDirectives", "")
  self.perfectBlockTime = config.getParameter("perfectBlockTime", 0.2)
  self.minActiveTime = config.getParameter("minActiveTime", 0)
  self.cooldownTime = config.getParameter("cooldownTime")
  self.forceWalk = config.getParameter("forceWalk", false)

  animator.setGlobalTag("directives", "")
  animator.setAnimationState("shield", "idle")
  activeItem.setOutsideOfHand(true)

  self.stances = config.getParameter("stances")
  setStance(self.stances.idle)

  updateAim()
end

function update(dt, fireMode, shiftHeld)
  self.cooldownTimer = math.max(0, self.cooldownTimer - dt)

  if not self.active
    and fireMode == "primary"
    and self.cooldownTimer == 0
    and status.resourcePositive("shieldStamina") then

    raiseShield()
  end

  if self.active then
    self.activeTimer = self.activeTimer + dt

	if status.resource("shieldStamina") > self.oldShieldStamina then self.oldShieldStamina = status.resource("shieldStamina"); end
    self.damageListener:update()
	if self.dealtDamageListener then
		self.dealtDamageListener:update()
	end
	updateTracking(dt)

    if status.resourcePositive("perfectBlock") then
      animator.setGlobalTag("directives", self.perfectBlockDirectives)
    else
      animator.setGlobalTag("directives", "")
    end

    if self.forceWalk then
      mcontroller.controlModifiers({runningSuppressed = true})
    end

    if (fireMode ~= "primary" and self.activeTimer >= self.minActiveTime) or not status.resourcePositive("shieldStamina") then
      lowerShield()
    end
  end

  updateAim()
end

function uninit()
  status.clearPersistentEffects(activeItem.hand().."Shield")
  activeItem.setItemShieldPolys({})
  activeItem.setItemDamageSources({})
end

function updateAim()
  local aimAngle, aimDirection = activeItem.aimAngleAndDirection(0, activeItem.ownerAimPosition())
  
  if self.stance.allowRotate then
    self.aimAngle = aimAngle
  end
  activeItem.setArmAngle(self.aimAngle + self.relativeArmRotation)

  if self.stance.allowFlip then
    self.aimDirection = aimDirection
  end
  activeItem.setFacingDirection(self.aimDirection)

  animator.setGlobalTag("hand", isNearHand() and "near" or "far")
  activeItem.setOutsideOfHand(not self.active or isNearHand())
end

function isNearHand()
  return (activeItem.hand() == "primary") == (self.aimDirection < 0)
end

function setStance(stance)
  self.stance = stance
  self.relativeShieldRotation = util.toRadians(stance.shieldRotation) or 0
  self.relativeArmRotation = util.toRadians(stance.armRotation) or 0
end

function raiseShield()
  setStance(self.stances.raised)
  animator.setAnimationState("shield", "raised")
  animator.playSound("raiseShield")
  self.active = true
  self.activeTimer = 0
  status.setPersistentEffects(activeItem.hand().."Shield", {{stat = "shieldHealth", amount = shieldHealth()}})
  local shieldPoly = animator.partPoly("shield", "shieldPoly")
  activeItem.setItemShieldPolys({shieldPoly})

  if self.knockback > 0 then
    local knockbackDamageSource = {
      poly = shieldPoly,
      damage = 0,
      damageType = "Knockback",
      sourceEntity = activeItem.ownerEntityId(),
      team = activeItem.ownerTeam(),
      knockback = self.knockback,
      rayCheck = true,
      damageRepeatTimeout = 0.25
    }
    activeItem.setItemDamageSources({ knockbackDamageSource })
  end

  self.damageListener = damageListener("damageTaken", function(notifications)
    for _,notification in pairs(notifications) do
      if notification.hitType == "ShieldHit" then
        if status.resourcePositive("perfectBlock") then
          animator.playSound("perfectBlock")
          animator.burstParticleEmitter("perfectBlock")
          refreshPerfectBlock()
		  
		  self.oldShieldStamina = status.resource("shieldStamina")
        elseif status.resourcePositive("shieldStamina") then
          animator.playSound("block")
		  
		  if self.damageBleedthroughEnabled then
			-- note: this will only trigger once per damageListener tick, since it should fully account for all damage received in said tick once. hopefully.
			local newShieldStamina = status.resource("shieldStamina");
			--sb.logInfo((self.oldShieldStamina - newShieldStamina) * shieldHealth())
			local healthDiff = (self.oldShieldStamina - newShieldStamina) * shieldHealth()
			--sb.logInfo(healthDiff)
			--status.modifyResource("health", healthDiff * -0.1)
			
			--higher the stat value, better the resistance (i.e. with 0.5 stat mult and 0.1 bleedthrough amount, results in 0.1 - 0.1*0.5 = 0.05% bleedthrough amount)
			local statMult = math.min(math.max(1 - status.stat("gic_shieldDefenseMult"),0),1)
		  
			status.applySelfDamageRequest({
				damageType = "IgnoresDef",
				damage = healthDiff * self.damageBleedthroughAmount * statMult,
				damageSourceKind = "default",
				sourceEntityId = entity.id()
			})
		  
			self.oldShieldStamina = status.resource("shieldStamina")
		  end
        else
          animator.playSound("break")
		  self.oldShieldStamina = 0
        end
        animator.setAnimationState("shield", "block")
        return
      end
    end
  end)

  refreshPerfectBlock()
end

function updateTracking(dt)
	local shieldPoly = animator.partPoly("shield", "shieldPoly")
	if self.knockback > 0 then
		local knockbackDamageSource = {
		poly = shieldPoly,
		damage = 0,
		damageType = "Knockback",
		sourceEntity = activeItem.ownerEntityId(),
		team = activeItem.ownerTeam(),
		knockback = self.knockback,
		rayCheck = true,
		damageRepeatTimeout = 0.25
		}
		activeItem.setItemDamageSources({ knockbackDamageSource })
	end
	
	self.dealtDamageListener = nil
	
    if math.abs(mcontroller.xVelocity()) >= self.minDamageAccel then
		
	  self.dealtDamageListener = damageListener("inflictedDamage", function(notifications)
      for _, notification in pairs(notifications) do
        if notification.healthLost > 0 and notification.damageSourceKind == "ews_melee_shieldbash" then
          animator.playSound("shieldBash")
          return
        end
      end
    end)

	  --animator.playSound("collide")
	  local diff = (math.abs(mcontroller.xVelocity()) - self.minDamageAccel)/(self.minDamageAccel)
	  local damageDealt = math.min(math.max(self.accelDamage * diff,self.accelDamage),self.accelMaxDamage)
	  local knockbackDealt = math.min(math.max(self.accelKnockback * diff,self.accelKnockback),self.accelMaxKnockback)
	  local timeout = math.min(math.max(self.minDamageTimeout * diff,self.minDamageTimeout),self.maxDamageTimeout)
	  
      --self.trackingVelocities = {}
	  
	  local effects = jarray()
	  effects[1] = {effect = "gic_stun_025", duration = 0.25}
	  local knockbackDamageSource = {
			poly = shieldPoly,
			damage = damageDealt,
			--damageType = "default",
			damageSourceKind = "ews_melee_shieldbash",
			sourceEntity = activeItem.ownerEntityId(),
			team = activeItem.ownerTeam(),
			knockback = knockbackDealt,
			rayCheck = true,
			statusEffects = effects,
			damageRepeatTimeout = timeout
		}
		
	  activeItem.setItemDamageSources({ knockbackDamageSource })
	  
    end
end

function refreshPerfectBlock()
  local perfectBlockTimeAdded = math.max(0, math.min(status.resource("perfectBlockLimit"), self.perfectBlockTime - status.resource("perfectBlock")))
  status.overConsumeResource("perfectBlockLimit", perfectBlockTimeAdded)
  status.modifyResource("perfectBlock", perfectBlockTimeAdded)
end

function lowerShield()
  setStance(self.stances.idle)
  animator.setGlobalTag("directives", "")
  animator.setAnimationState("shield", "idle")
  animator.playSound("lowerShield")
  self.active = false
  self.activeTimer = 0
  status.clearPersistentEffects(activeItem.hand().."Shield")
  activeItem.setItemShieldPolys({})
  activeItem.setItemDamageSources({})
  self.cooldownTimer = self.cooldownTime
end

function shieldHealth()
  return self.baseShieldHealth * root.evalFunction("shieldLevelMultiplier", self.level)
end
