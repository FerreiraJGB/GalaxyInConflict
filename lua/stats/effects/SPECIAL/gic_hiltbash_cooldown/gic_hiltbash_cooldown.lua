function init()
  self.statModifierGroup = effect.addStatModifierGroup({{stat = config.getParameter("stat"), amount = 1}})
end
local expireSfx = true

function update(dt)
  if expireSfx and effect.duration() < 0.1 then
    expireSfx = false
    animator.playSound("expire")
  end
end

function uninit()
	effect.removeStatModifierGroup(self.statModifierGroup)
end
