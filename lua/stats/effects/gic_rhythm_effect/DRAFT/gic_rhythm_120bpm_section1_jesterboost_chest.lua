function init()
  self.statModifierGroup = effect.addStatModifierGroup({

    {stat = "ews_misschance_mult", amount = 0.99},	
    {stat = "ews_inaccuracy_mult", amount = 0.99}


  })
end

local expireSfx = true

function update(dt)
  if expireSfx and effect.duration() < 0.01 then
    expireSfx = false
    animator.playSound("expire")
  end
end

function uninit()

	if effect.duration() and effect.duration() <= script.updateDt() then
	 status.addEphemeralEffect("gic_rhythm_120bpm_section2_jesterboost_chest", 0.1)
	end

	effect.removeStatModifierGroup(self.statModifierGroup)  
end
