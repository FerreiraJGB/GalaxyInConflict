function init()
  propertyGet = false
  propertyTime = 0
  property = nil
end

function update(dt)
  if propertyGet then
    if property then
      script.setUpdateDelta(60) -- update per second
      
      propertyTime = propertyTime - dt
      --sb.logInfo("propertyTime: %s", propertyTime)
      if propertyTime <= 0 then
        for _,effect in pairs(property) do
          status.addEphemeralEffect(effect.effect, effect.time)
          --sb.logInfo("addEphemeralEffect: %s, %s", effect.effect, effect.time)
        end
        
        property = nil
      end
    else
      script.setUpdateDelta(math.huge)
    end
  else
    if world.getProperty("last_addiction_stage_effects") then
      propertyTime = world.getProperty("last_addiction_stage_time")
      property = world.getProperty("last_addiction_stage_effects")
      
      world.setProperty("last_addiction_stage_time", nil)
      world.setProperty("last_addiction_stage_effects", nil)
      
      --sb.logInfo("last_addiction_stage_time: %s", propertyTime)
      --sb.logInfo("last_addiction_stage_effects: %s", property)
      
      propertyGet = true
    end
  end
end