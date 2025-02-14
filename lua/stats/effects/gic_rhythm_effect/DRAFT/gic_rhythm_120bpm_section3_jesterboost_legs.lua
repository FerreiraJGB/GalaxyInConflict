function init()
  self.statModifierGroup = effect.addStatModifierGroup({

    {stat = "ews_misschance_mult", amount = -0.3},	
    {stat = "ews_inaccuracy_mult", amount = -0.3}

  })
end

local expireSfx = true

function update(dt)
  if expireSfx and effect.duration() < 0.1 then
    expireSfx = false
    animator.playSound("expire")
  end
end

function uninit()

	if effect.duration() and effect.duration() <= script.updateDt() then
	 status.addEphemeralEffect("gic_rhythm_120bpm_section4_jesterboost_legs", 0.1)
	end

	effect.removeStatModifierGroup(self.statModifierGroup)  
end
