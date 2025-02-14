function init()
end

function update()
   if status.stat("gic_gunfirenoise") == 1 then
      status.setPersistentEffects("statusEffect", { "gic_floran_gunfirespeed" }) --replace "actualEffect" with target effect for primer to enable
    else
      status.clearPersistentEffects("statusEffect")
   end
end

function uninit()
  status.clearPersistentEffects("statusEffect")
end
