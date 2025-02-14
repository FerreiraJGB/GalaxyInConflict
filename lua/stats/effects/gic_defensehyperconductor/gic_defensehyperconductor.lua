function init()
end

function update(dt)
  
  if mcontroller.running() and self.statModifierGroup ~= nil then
	effect.removeStatModifierGroup(self.statModifierGroup)
    self.statModifierGroup = nil

  --this elseif statement could be replaced with one else statement, but i want to be safe.
  elseif not mcontroller.running() and self.statModifierGroup == nil then
  
  
    self.statModifierGroup = effect.addStatModifierGroup({
	
    {stat = "healthRegen", amount = 4.0}
    })
	
	
  end

end

function uninit()
    if self.statModifierGroup then
        effect.removeStatModifierGroup(self.statModifierGroup)
    end
end