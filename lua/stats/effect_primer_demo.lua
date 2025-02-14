function init()
end

function update()
   if status.stat("demo_triggerStat") == 1 then
      status.setPersistentEffects("statusEffect", { "actualEffect" }) --replace "actualEffect" with target effect for primer to enable
    else
      status.clearPersistentEffects("statusEffect")
   end
end

function uninit()
  status.clearPersistentEffects("statusEffect")
end
