function init()
   effect.addStatModifierGroup({
   {stat = "gic_bleeding_medium_primer", amount = 1}
   })
   
   script.setUpdateDelta(0)
end

function update()
   if status.stat("gic_bulletshot_medium") == 1 then
      status.setPersistentEffects("statusEffect", { "gic_bleeding_medium" }) --replace "actualEffect" with target effect for primer to enable
--    else
--      status.clearPersistentEffects("statusEffect")
   end
end

function uninit()
--  status.clearPersistentEffects("statusEffect")   would clear status effect if this effect timed out. We don't want that, so we let the existing stat remain.
end
