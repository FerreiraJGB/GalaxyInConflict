function init()
  self.statModifierGroup = effect.addStatModifierGroup({{stat = config.getParameter("stat"), amount = 1}})
  
  self.durationReductionStat = "gic_ms_reducecd"
end
local expireSfx = true

function update(dt)
  if expireSfx and effect.duration() < 0.1 then
    expireSfx = false
    animator.playSound("expire")
  end
  
  if status.stat("gic_ms_reducecd") == 1 then
	effect.modifyDuration(-5.0)
  end
end

function uninit()
	effect.removeStatModifierGroup(self.statModifierGroup)
end
