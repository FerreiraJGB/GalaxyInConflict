function init()
	effect.addStatModifierGroup({{stat = "gic_ms_reducecd", amount = 1}})
end

function update()
	effect.expire()
end

function uninit()
end