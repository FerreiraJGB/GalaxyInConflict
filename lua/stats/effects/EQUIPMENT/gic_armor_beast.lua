function init()
   self.statModifierGroup = effect.addStat({{stat = "gic_armor_beast", amount = 1}})


  script.setUpdateDelta(5)

  self.healingRate = 1.0 / config.getParameter("healTime", 60)



end

function update(dt)

  status.modifyResourcePercentage("health", self.healingRate * dt)

end

function uninit()
	effect.removeStatModifierGroup(self.statModifierGroup)
end
