function init()
  self.statModifierGroup = effect.addStatModifierGroup({

    {stat = "gic_reactiveheatshroudStatusImmunity", amount = 1.0},
	
    {stat = "ews_misschance_mult", amount = -0.3},	
    {stat = "ews_inaccuracy_mult", amount = -0.3}

  })
end

function update(dt)
  
end

function uninit()
	effect.removeStatModifierGroup(self.statModifierGroup)  
end
