function init()
  effect.addStatModifierGroup({
    {stat = "protection", amount = config.getParameter("protection", 100)},
    {stat = "ews_meleeResistance", amount = config.getParameter("ews_meleeResistance", 100)},
    {stat = "ews_smallarmsResistance", amount = config.getParameter("ews_smallarmsResistance", 100)},
    {stat = "ews_heavyarmsResistance", amount = config.getParameter("ews_heavyarmsResistance", 100)},
    {stat = "ews_explosiveResistance", amount = config.getParameter("ews_explosiveResistance", 100)},
    {stat = "grit", amount = config.getParameter("grit", 1.0)},
    {stat = "gic_tazedStatusImmunity", amount = config.getParameter("gic_tazedStatusImmunity", 100)}
	
	
  })

  script.setUpdateDelta(0)
end

function update(dt)
end

function uninit()
end
