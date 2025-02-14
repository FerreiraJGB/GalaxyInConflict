function init()
  self.statModifierGroup = effect.addStatModifierGroup({

    {stat = "gic_armor_sniper_focus_weakness_chest", amount = 1.0}

  })
end

function update(dt)
  
end

function uninit()
	effect.removeStatModifierGroup(self.statModifierGroup)  
end
