function init()
end

function update()
   if status.stat("gic_musket_weapon") == 1 then
      status.setPersistentEffects("statusEffect", { "gic_glitch_rankandfile" }) --replace "actualEffect" with target effect for primer to enable
    else
      status.clearPersistentEffects("statusEffect")
   end
end

function uninit()
  status.clearPersistentEffects("statusEffect")
end
