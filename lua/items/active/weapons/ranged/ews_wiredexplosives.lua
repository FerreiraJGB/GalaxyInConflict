require "/items/active/weapons/ranged/ews_weapon_throwables.lua"

WiredExplosive = GunFire:new()

function WiredExplosive:init()
  GunFire.init(self)
  storage.activeProjectiles = storage.activeProjectiles or {}
end

function activate(fireMode, shiftHeld)
  if fireMode == "alt" then
    triggerProjectiles()
  end
end

function WiredExplosive:update(dt, fireMode, shiftHeld)
  GunFire.update(self, dt, fireMode, shiftHeld)
  
  updateProjectiles()
  updateCursor()
end

function updateCursor()
  if #storage.activeProjectiles > 0 then
    activeItem.setCursor("/cursors/chargeready.cursor")
  else
    activeItem.setCursor("/cursors/reticle0.cursor")
  end
end

function triggerProjectiles()
  if #storage.activeProjectiles > 0 then
    animator.playSound("detonate")
  end
  for i, projectile in ipairs(storage.activeProjectiles) do
    world.callScriptedEntity(projectile, "trigger")
  end
end

function updateProjectiles()
  local newProjectiles = {}
  for i, projectile in ipairs(storage.activeProjectiles) do
    if world.entityExists(projectile) then
      newProjectiles[#newProjectiles + 1] = projectile
    end
  end
  storage.activeProjectiles = newProjectiles
end

function WiredExplosive:fireProjectile(projectileType, projectileParams, inaccuracy, firePosition, projectileCount)
  local params = sb.jsonMerge(self.projectileParameters, projectileParams or {})
  params.power = self:damagePerShot()
  params.powerMultiplier = activeItem.ownerPowerMultiplier()
  params.speed = util.randomInRange(params.speed)

  if not projectileType then
    projectileType = self.projectileType
  end
  if type(projectileType) == "table" then
    projectileType = projectileType[math.random(#projectileType)]
  end

  local projectileId = 0
  for i = 1, (projectileCount or self.projectileCount) do
    if params.timeToLive then
      params.timeToLive = util.randomInRange(params.timeToLive)
    end

    projectileId = world.spawnProjectile(
        projectileType,
        firePosition or self:firePosition(),
        activeItem.ownerEntityId(),
        self:aimVector(inaccuracy or self.inaccuracy),
        false,
        params
      )
  end
  if projectileId then
    storage.activeProjectiles[#storage.activeProjectiles + 1] = projectileId
  end
  
end