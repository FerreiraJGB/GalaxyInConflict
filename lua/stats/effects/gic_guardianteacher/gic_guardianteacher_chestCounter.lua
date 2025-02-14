--This is technically half-broken code I barely understand that just happens to work lmao. Activates ability during the day, so a counter status effect is needed. - Socii

function init()

  self.detectThresholdHigh = 1
  self.detectThresholdLow = 40

  self.statModifierGroup = effect.addStatModifierGroup({
    {stat = "jumpModifier", amount = -0.2}
  })
end

function getSample()
  local sample = world.lightLevel(entity.position())
  return math.floor(sample * 1000) * 0.1
end

function update(dt)

  local sample = getSample()

  if sample >= self.detectThresholdLow then
  mcontroller.controlModifiers({
      groundMovementModifier = 0.8,
      speedModifier = 0.8,
      airJumpModifier = 0.8
    })


end

  if sample >= self.detectThresholdHigh then

end  
  
  
  
	
end

function uninit()
	effect.removeStatModifierGroup(self.statModifierGroup)
end
