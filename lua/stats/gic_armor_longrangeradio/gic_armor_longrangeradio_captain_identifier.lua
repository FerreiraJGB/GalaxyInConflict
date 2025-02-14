function init()
  self.statModifierGroup = effect.addStatModifierGroup({
    {stat = "gic_armor_longrangeradio_captain_identifier", amount = 1.0}
  })
end

function update(dt)
end

function uninit()
	effect.removeStatModifierGroup(self.statModifierGroup)
end
