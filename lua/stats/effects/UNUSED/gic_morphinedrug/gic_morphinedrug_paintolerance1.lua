function init()
   effect.addStatModifierGroup({
   {stat = "fireResistance", amount = 0.3},
   {stat = "fireStatusImmunity", amount = 0},
   
   {stat = "poisonResistance", amount = 0.3},
   {stat = "poisonStatusImmunity", amount = 0},   
   
   {stat = "electricResistance", amount = 0.3},
   {stat = "electricStatusImmunity", amount = 1},
   
   {stat = "iceResistance", amount = 0.3},
   {stat = "iceStatusImmunity", amount = 0},
   
   {stat = "physicalResistance", amount = 0.2}
   
   })

   script.setUpdateDelta(0)
end

function update(dt)

end

function uninit()
  
end
