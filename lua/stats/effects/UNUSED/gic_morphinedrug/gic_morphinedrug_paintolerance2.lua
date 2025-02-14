function init()
   effect.addStatModifierGroup({
   {stat = "fireResistance", amount = 0.6},
   {stat = "fireStatusImmunity", amount = 0},
   
   {stat = "poisonResistance", amount = 0.6},
   {stat = "poisonStatusImmunity", amount = 0},   
   
   {stat = "electricResistance", amount = 0.6},
   {stat = "electricStatusImmunity", amount = 1},
   
   {stat = "iceResistance", amount = 0.6},
   {stat = "iceStatusImmunity", amount = 1},
   
   {stat = "physicalResistance", amount = 0.4}
   
   })

   script.setUpdateDelta(0)
end

function update(dt)

end

function uninit()
  
end
