function init()
   self.statModifierGroup = effect.addStatModifierGroup({
{stat = "gic_psychicbleeding_lightStatusImmunity", amount = 1},
{stat = "gic_shadowsweat_slowStatusImmunity", amount = 1},
{stat = "gic_shadowsweat_poisonStatusImmunity", amount = 1}
   })

   script.setUpdateDelta(0)
end

function update(dt)

end

function uninit()
  effect.removeStatModifierGroup(self.statModifierGroup)
end
