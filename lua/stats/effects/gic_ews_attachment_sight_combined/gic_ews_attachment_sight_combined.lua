function init()
end

function update(dt)
  
  if not mcontroller.running() and self.statModifierGroup ~= nil then
	effect.removeStatModifierGroup(self.statModifierGroup)
    self.statModifierGroup = nil

  --this elseif statement could be replaced with one else statement, but i want to be safe.
  elseif mcontroller.running() and self.statModifierGroup == nil then
  
  
    self.statModifierGroup = effect.addStatModifierGroup({
    {stat = "ews_misschance_mult", amount = -0.15},	
    {stat = "ews_inaccuracy_mult", amount = -0.15}
    })
	
	
  end

end

function uninit()
    if self.statModifierGroup then
        effect.removeStatModifierGroup(self.statModifierGroup)
    end
end