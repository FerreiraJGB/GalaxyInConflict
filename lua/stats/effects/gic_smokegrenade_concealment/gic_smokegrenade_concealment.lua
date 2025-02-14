function init()
  self.statModifierGroup = effect.addStatModifierGroup({
    {stat = "gic_smokegrenade_concealment", amount = 1.0},
    {stat = "gic_dodge_stat", amount = 0.75},
    {stat = "ews_npcfirerate", amount = 4.0},
    {stat = "ews_misschance_mult", amount = 1.0},	
    {stat = "ews_inaccuracy_mult", amount = 1.0}
  })
end

function update(dt)
  
end

function uninit()
	effect.removeStatModifierGroup(self.statModifierGroup)  
end
