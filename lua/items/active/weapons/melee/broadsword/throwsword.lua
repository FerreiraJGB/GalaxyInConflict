require "/scripts/util.lua"
require "/scripts/interp.lua"
require "/items/active/weapons/weapon.lua"

RocketSpear = WeaponAbility:new()

function RocketSpear:init()
  animator.setAnimationState("sword", "idle")
  self:reset()
  mcontroller.controlModifiers({runningSuppressed = false})

  self.cooldownTimer = self.cooldownTime
end

function RocketSpear:update(dt, fireMode, shiftHeld)
  WeaponAbility.update(self, dt, fireMode, shiftHeld)

  self.cooldownTimer = math.max(0, self.cooldownTimer - self.dt)

  if self.weapon.currentAbility == nil
      and self.fireMode == "alt"
      and self.cooldownTimer == 0 then
      --and (not self.boostSpeed or not status.statPositive("activeMovementAbilities"))
      --and not status.resourceLocked("energy") then

    self:setState(self.windup)
  end
end

function RocketSpear:windup()
 mcontroller.controlModifiers({runningSuppressed = true})
  self.weapon:setStance(self.stances.windup)
  self.weapon:updateAim()

  local progress = 0
  util.wait(self.stances.windup.duration, function()
	mcontroller.controlModifiers({runningSuppressed = true})
    local from = self.stances.windup.weaponOffset or {0,0}
    local to = self.stances.windup1.weaponOffset or {0,0}
    self.weapon.weaponOffset = {interp.linear(progress, from[1], to[1]), interp.linear(progress, from[2], to[2])}

    self.weapon.relativeWeaponRotation = util.toRadians(interp.linear(progress, self.stances.windup.weaponRotation, self.stances.windup1.weaponRotation))
    self.weapon.relativeArmRotation = util.toRadians(interp.linear(progress, self.stances.windup.armRotation, self.stances.windup1.armRotation))

    progress = math.min(1.0, progress + (self.dt / self.stances.windup.duration))
  end)
  --self.weapon:setStance(self.stances.windup1)

  self:setState(self.fire)
end

function RocketSpear:fire()
  --self.weapon:setStance(self.stances.windup)
  self.weapon:updateAim()
  --util.wait(self.stances.windup.duration)

  self.weapon:setStance(self.stances.windup1)
  
  
  while self.fireMode == "alt" do
  mcontroller.controlModifiers({runningSuppressed = true})
  coroutine.yield()
  --mcontroller.controlModifiers({runningSuppressed = true})
  end
  mcontroller.controlModifiers({runningSuppressed = false})
  
  --self.weapon:setStance(self.stances.prefire)
  --util.wait(self.stances.prefire.duration)
  
  self.weapon:setStance(self.stances.prefire)
  self.weapon:updateAim()

  local progress = 0
  util.wait(self.stances.prefire.duration, function()
    local from = self.stances.prefire.weaponOffset or {0,0}
    local to = self.stances.midfire.weaponOffset or {0,0}
    self.weapon.weaponOffset = {interp.linear(progress, from[1], to[1]), interp.linear(progress, from[2], to[2])}

    self.weapon.relativeWeaponRotation = util.toRadians(interp.linear(progress, self.stances.prefire.weaponRotation, self.stances.midfire.weaponRotation))
    self.weapon.relativeArmRotation = util.toRadians(interp.linear(progress, self.stances.prefire.armRotation, self.stances.midfire.armRotation))

    progress = math.min(1.0, progress + (self.dt / self.stances.prefire.duration))
  end)
  
  animator.playSound("throw")
  
  local params = copy(self.projectileParameters)
  params.power = self.baseDps * self.fireTime * config.getParameter("damageLevelMultiplier")
  params.powerMultiplier = activeItem.ownerPowerMultiplier()
  
  local fireTimer = 0
  --while self.fireMode == "alt" and status.overConsumeResource("energy", self.energyUsage * self.dt) do
    self.weapon:updateAim()
	
    --fireTimer = math.max(0, fireTimer - self.dt)
    --if fireTimer == 0 then
      fireTimer = self.fireTime
      local position = vec2.add(mcontroller.position(), activeItem.handPosition(self.throwOffset))
      local aim = self.weapon.aimAngle + util.randomInRange({-self.inaccuracy, self.inaccuracy})
      --if not world.lineTileCollision(mcontroller.position(), position) then
        world.spawnProjectile(self.projectileType, position, activeItem.ownerEntityId(), {mcontroller.facingDirection() * math.cos(aim), math.sin(aim)}, false, params)
      --end
    --end

    --coroutine.yield()
  --end
  
  animator.setAnimationState("sword", "fire")
  
  self.weapon:setStance(self.stances.midfire)
  self.weapon:updateAim()

  local progress = 0
  util.wait(self.stances.midfire.duration, function()
    local from = self.stances.midfire.weaponOffset or {0,0}
    local to = self.stances.fire.weaponOffset or {0,0}
    self.weapon.weaponOffset = {interp.linear(progress, from[1], to[1]), interp.linear(progress, from[2], to[2])}

    self.weapon.relativeWeaponRotation = util.toRadians(interp.linear(progress, self.stances.midfire.weaponRotation, self.stances.fire.weaponRotation))
    self.weapon.relativeArmRotation = util.toRadians(interp.linear(progress, self.stances.midfire.armRotation, self.stances.fire.armRotation))

    progress = math.min(1.0, progress + (self.dt / self.stances.midfire.duration))
  end)
  
  self.weapon:setStance(self.stances.fire)
  util.wait(self.stances.fire.duration)
  self.weapon:setStance(self.stances.idle)
  self.weapon.aimAngle = 0
  util.wait(self.stances.idle.duration)
  
  self.weapon:setStance(self.stances.warp)
  self.weapon.aimAngle = 0
  animator.playSound("warp")
  animator.setAnimationState("sword", "warp")
  util.wait(self.stances.warp.duration)
  
  animator.setAnimationState("sword", "idle")
  self.weapon:setStance(self.stances.idle)
  
  self.weapon.aimAngle = 0
  self.weapon:updateAim()

  self.cooldownTimer = self.cooldownTime
end

function RocketSpear:reset()
  --animator.stopAllSounds(self.weapon.elementalType.."Blast")
end

function RocketSpear:uninit()
  self:reset()
end
