require "/scripts/util.lua"
require "/items/active/weapons/weapon.lua"

RocketSpear = WeaponAbility:new()

function RocketSpear:init()
  self.weapon:setStance(self.stances.idle)
  self:reset()

  self.cooldownTimer = self.cooldownTime
end

function RocketSpear:update(dt, fireMode, shiftHeld)
  WeaponAbility.update(self, dt, fireMode, shiftHeld)

  self.cooldownTimer = math.max(0, self.cooldownTimer - self.dt)

  if self.weapon.currentAbility == nil
      and self.fireMode == "primary"
      and self.cooldownTimer == 0
      --and (not self.boostSpeed)
	  and (not self.boostSpeed or not status.statPositive("activeMovementAbilities"))
      and not status.resourceLocked("energy") then

    self:setState(self.windup)
  end
end

function RocketSpear:windup()
  --self.weapon:setStance(self.stances.windup)
  self.weapon:updateAim()

  if self.boostSpeed then
    status.setPersistentEffects("weaponMovementAbility", {{stat = "activeMovementAbilities", amount = 1}})
  end

  animator.setAnimationState("blade", "boost")

  --util.wait(self.stances.windup.duration)

  self:setState(self.fire)
end

function RocketSpear:fire()
  --self.weapon:setStance(self.stances.fire)
  self.weapon:updateAim()

  animator.setAnimationState("blade", "boost")
  animator.playSound("fireStart")
  animator.playSound("fireBlast", -1)

  --local params = copy(self.projectileParameters)
  --params.power = self.baseDps * self.fireTime * config.getParameter("damageLevelMultiplier")
  --params.powerMultiplier = activeItem.ownerPowerMultiplier()

  local fireTimer = 0
  while self.fireMode == "primary" and status.overConsumeResource("energy", self.energyUsage * self.dt) do
    self.weapon:updateAim()

    if self.boostSpeed then
      local boostAngle = mcontroller.facingDirection() == 1 and self.weapon.aimAngle + math.pi or -self.weapon.aimAngle
      local vel = mcontroller.velocity()
      local speed = vec2.mag(vel)
      -- if speed <= self.boostSpeed then
        --mcontroller.controlApproachVelocity(vec2.withAngle(boostAngle, self.boostSpeed), self.boostForce)
		
		mcontroller.controlApproachVelocity(vec2.withAngle(boostAngle, self.boostSpeed), self.boostForce)
		-- mcontroller.addMomentum(vec2.withAngle(boostAngle, -speed))
      -- else
        -- local angleDiff = math.abs(util.angleDiff(boostAngle, vec2.angle(vel)))
        -- local boostSpeedFactor = math.min(1, angleDiff / (math.pi * 0.5))
        -- local targetSpeed = boostSpeedFactor * self.boostSpeed + (1 - boostSpeedFactor) * speed
        --mcontroller.controlApproachVelocity(vec2.withAngle(boostAngle, targetSpeed), self.boostForce)
		
		-- mcontroller.addMomentum(vec2.withAngle(boostAngle, targetSpeed))
      -- end
    end

    --fireTimer = math.max(0, fireTimer - self.dt)
    --if fireTimer == 0 then
    --  fireTimer = self.fireTime
    --  local position = vec2.add(mcontroller.position(), activeItem.handPosition(animator.partPoint("chargeSwoosh", "projectileSource")))
    --  local aim = self.weapon.aimAngle + util.randomInRange({-self.inaccuracy, self.inaccuracy})
    --  if not world.lineTileCollision(mcontroller.position(), position) then
    --    world.spawnProjectile(self.projectileType, position, activeItem.ownerEntityId(), {mcontroller.facingDirection() * math.cos(aim), math.sin(aim)}, false, params)
    --  end
    --end

    coroutine.yield()
  end

  animator.stopAllSounds("fireStart")
  animator.stopAllSounds("fireBlast")
  animator.playSound("fireEnd")
  self.cooldownTimer = self.cooldownTime
  self.weapon:setStance(self.stances.idle)
end

function RocketSpear:reset()
  if self.boostSpeed then
    status.clearPersistentEffects("weaponMovementAbility")
  end
  animator.setAnimationState("blade", "idle")
  animator.stopAllSounds("fireBlast")
end

function RocketSpear:uninit()
  self:reset()
end
