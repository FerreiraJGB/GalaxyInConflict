function init()
  self.statModifierGroup = effect.addStatModifierGroup({
    {stat = "ews_misschance_mult", amount = -0.1},	
    {stat = "ews_inaccuracy_mult", amount = -0.1}
  })
end

function update(dt)
  
end

function uninit()
	effect.removeStatModifierGroup(self.statModifierGroup)  
end
