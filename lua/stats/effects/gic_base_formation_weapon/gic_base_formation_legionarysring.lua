function init()
   self.statModifierGroup = effect.addStatModifierGroup({{stat = "gic_base_greatshield_limiterCounter", amount = 1}})

   script.setUpdateDelta(0)
end

function update(dt)

end

function uninit()
	effect.removeStatModifierGroup(self.statModifierGroup)
end
