function init()
  --Health Scale
  -- optimize these stat modifier groups later, i'm lazy atm
  
  self.statModifierGroup = effect.addStatModifierGroup({
    {stat = "jumpModifier", amount = 0.0}
	})
  
  if entity.entityType() == "monster" then effect.expire() end
  
  effect.setParentDirectives("fade=808080=0.2")
end
local expireSfx = true


function update(dt)

  mcontroller.controlModifiers({
      groundMovementModifier = 1.4,
      speedModifier = 1.4,
      airJumpModifier = 1.4
    })

  if expireSfx and effect.duration() < 0.1 then
    expireSfx = false
    animator.playSound("expire")
  end
  
end

function uninit()

	if effect.duration() and effect.duration() <= script.updateDt() then
	 status.addEphemeralEffect("gic_chapter6_lunarartifact_stage4", 60)
	end

	effect.removeStatModifierGroup(self.statModifierGroup)
end
