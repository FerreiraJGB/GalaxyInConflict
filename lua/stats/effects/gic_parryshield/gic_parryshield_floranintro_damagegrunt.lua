require "/scripts/status.lua"

function init()
  self.listener = damageListener("damageTaken", function()
    animator.setAnimationState("shield", "hit")
	animator.playSound("perfectBlock")
--	world.spawnProjectile("gic_blood_smallexplosion", mcontroller.position(), entity.id(), {0,0}, false, {})
  end)

  self.statModifierGroup = effect.addStatModifierGroup({
  })
end

function update(dt)
  self.listener:update()
end

function uninit()
	effect.removeStatModifierGroup(self.statModifierGroup)
end
