function init()
  if entity.entityType() == "monster" then effect.expire() end
end

function update(dt)
end

function uninit()

	if effect.duration() <= script.updateDt() then
	 status.addEphemeralEffect("gic_opiate_overdose_active_primarycheck_cardiac", 30)
	end

end
