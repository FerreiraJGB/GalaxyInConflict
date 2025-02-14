function init()
  self.statModifierGroup = effect.addStatModifierGroup({
  
    {stat = "gic_opiate_addictionProtection", amount = 1.0},
    {stat = "gic_opiate_withdrawalProtection", amount = 1.0},
{stat = "gic_burn_woundsProtection", amount = 1},
{stat = "gic_burn_wounds_severeProtection", amount = 1},
{stat = "gic_bruising_lightProtection", amount = 1},
{stat = "gic_bruising_mediumProtection", amount = 1},
{stat = "gic_bloodloss_heavyProtection", amount = 1},

{stat = "gic_opiate_overdose_active_primarycheck_cardiacProtection", amount = 1},
{stat = "gic_paralyzantProtection", amount = 1},
{stat = "gic_fracture_injuryProtection", amount = 1},

{stat = "gic_cyanide_poisoningProtection", amount = 1},
{stat = "gic_opium_medkithealProtection", amount = 1},
{stat = "gic_opiate_medkithealProtection", amount = 1},
{stat = "gic_opiate_fentanyl_medkithealProtection", amount = 1},

{stat = "gic_pericarpyx_infectionProtection", amount = 1}


  })
end

function update(dt)
  
end

function uninit()
	effect.removeStatModifierGroup(self.statModifierGroup)  
end
