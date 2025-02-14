function init()
   self.statModifierGroup = effect.addStatModifierGroup({
   {stat = "gic_antilightweight", amount = 1},
   {stat = "gic_antimediumweight", amount = 1},
   
   {stat = "gic_armor_weight_medium_headBlock", amount = 1},
   {stat = "gic_armor_weight_medium_chestBlock", amount = 1},
   {stat = "gic_armor_weight_medium_legsBlock", amount = 1}
   
   })

   script.setUpdateDelta(0)
end

function update(dt)

end

function uninit()
  effect.removeStatModifierGroup(self.statModifierGroup)
end
