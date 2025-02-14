require "/scripts/util.lua"
require "/scripts/vec2.lua"

function init()

	storage.activeProjectiles = storage.activeProjectiles or {}
	self.primaryHeld = false
end

function activate(fireMode, shiftHeld)
    if fireMode == "primary" and not self.primaryHeld then
		triggerProjectiles()
		--animator.playSound("aimTeleport")
    end
end

function update(dt, fireMode)
   self.aimAngle, self.facingDirection = activeItem.aimAngleAndDirection(0, activeItem.ownerAimPosition())
   activeItem.setFacingDirection(self.facingDirection)
   
   activeItem.setArmAngle(self.aimAngle)

   self.primaryHeld = fireMode == "primary";
   
   updateCursor()
   updateProjectiles()
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
    animator.playSound("trigger")
  else
	animator.playSound("triggerFailed")
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

function addNewProjectile(projectileId)
	--sb.logInfo(projectileId)
	storage.activeProjectiles[#storage.activeProjectiles + 1] = projectileId
end