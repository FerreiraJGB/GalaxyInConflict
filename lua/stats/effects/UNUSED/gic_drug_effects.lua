function uninit()
  local addictionEffect = string.format("%s_addiction", effect.getParameter("drug"))
  local currentAddictionEffect = nil
  
  -- search for addictionEffect in character status effects table
  local activeStatusEffects = status.activeUniqueStatusEffectSummary()
  --sb.logInfo("activeStatusEffects: %s", activeStatusEffects)
  for _,activeEffect in pairs(activeStatusEffects) do
    if string.match(activeEffect[1], addictionEffect) then -- find <drug>_addiction
      currentAddictionEffect = activeEffect[1]
      --sb.logInfo("currentAddictionEffect: %s", currentAddictionEffect)
      break
    end
  end
  
  local drugStatusEffects = effect.getParameter("drugStatusEffects")
  --sb.logInfo("drugStatusEffects: %s", drugStatusEffects)
  
  if currentAddictionEffect then
    local addictionStage = 0
    
    -- get stage
    for _,stage in pairs(drugStatusEffects) do
      for _,effect in pairs(stage) do
        if effect.effect == currentAddictionEffect then
          --sb.logInfo("effect.effect : %s", effect.effect)
          addictionStage = string.match(effect.effect, "%d")
          --sb.logInfo("addictionStage: %s", addictionStage)
          break
        end
      end
    end
    --sb.logInfo("drugStatusEffect: %s", drugStatusEffects[addictionStage])
    
    local nextAddictionStage = tostring(addictionStage + 1)
    nextAddictionStage = string.format("%s", string.match(nextAddictionStage, "%d"))
    if drugStatusEffects[nextAddictionStage] then
      -- remove effects from current stage
      for _,effect in pairs(drugStatusEffects[addictionStage]) do
        status.removeEphemeralEffect(effect.effect)
        --sb.logInfo("removeEphemeralEffect: %s", effect.effect)
      end
      
      -- add effects from the next stage
      for _,effect in pairs(drugStatusEffects[nextAddictionStage]) do
        status.addEphemeralEffect(effect.effect, effect.time)
        --sb.logInfo("addEphemeralEffect: %s, %s", effect.effect, effect.time)
      end
    else
      drugAddictionEase = effect.getParameter("drugAddictionEaseEffects")
      --sb.logInfo("drugAddictionEase: %s", drugAddictionEase)
      if drugAddictionEase["1"] then -- remove all listed effects for a specified period of time
        -- remove effects from current stage
        for _,effect in pairs(drugStatusEffects[addictionStage]) do
          status.removeEphemeralEffect(effect.effect)
          --sb.logInfo("removeEphemeralEffect: %s", effect.effect)
        end
        
        -- add addiction effect
        for _,effect in pairs(drugStatusEffects[addictionStage]) do
          if effect.effect == currentAddictionEffect then
            status.addEphemeralEffect(effect.effect, effect.time)
            --sb.logInfo("addEphemeralEffect: %s, %s", effect.effect, effect.time)
            break
          end
        end
        
        world.setProperty("last_addiction_stage_time", effect.getParameter("drugAddictionEaseTime"))
        world.setProperty("last_addiction_stage_effects", drugStatusEffects[addictionStage])
      else -- add effects from the last stage
        for _,effect in pairs(drugStatusEffects[addictionStage]) do
          status.addEphemeralEffect(effect.effect, effect.time)
          --sb.logInfo("addEphemeralEffect: %s, %s", effect.effect, effect.time)
        end
      end
    end
  else -- if stage 1
    for _,effect in pairs(drugStatusEffects["1"]) do -- add effects from first stage
      status.addEphemeralEffect(effect.effect, effect.time)
      --sb.logInfo("addEphemeralEffect: %s, %s", effect.effect, effect.time)
    end
  end
end