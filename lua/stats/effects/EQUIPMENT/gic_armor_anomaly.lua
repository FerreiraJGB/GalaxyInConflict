function init()
  self.statModifierGroup = effect.addStatModifierGroup({
    {stat = "protection", amount = config.getParameter("protection", 100)},
	
    {stat = "physicalResistance", amount = config.getParameter("ews_meleeResistance", 100)},
    {stat = "fireResistance", amount = config.getParameter("ews_smallarmsResistance", 100)},
    {stat = "iceResistance", amount = config.getParameter("ews_heavyarmsResistance", 100)},
    {stat = "electricResistance", amount = config.getParameter("ews_explosiveResistance", 100)},
    {stat = "poisonResistance", amount = config.getParameter("ews_antitankResistance", 100)},
	
    {stat = "ews_meleeResistance", amount = config.getParameter("ews_meleeResistance", 100)},
    {stat = "ews_smallarmsResistance", amount = config.getParameter("ews_smallarmsResistance", 100)},
    {stat = "ews_heavyarmsResistance", amount = config.getParameter("ews_heavyarmsResistance", 100)},
    {stat = "ews_explosiveResistance", amount = config.getParameter("ews_explosiveResistance", 100)},
    {stat = "ews_antitankResistance", amount = config.getParameter("ews_antitankResistance", 100)},
    {stat = "grit", amount = config.getParameter("grit", 1.0)},
    {stat = "gic_tazedStatusImmunity", amount = config.getParameter("gic_tazedStatusImmunity", 100)}
	
	
  })

  script.setUpdateDelta(0)
end

function update(dt)
end

function uninit()
	effect.removeStatModifierGroup(self.statModifierGroup)
end
