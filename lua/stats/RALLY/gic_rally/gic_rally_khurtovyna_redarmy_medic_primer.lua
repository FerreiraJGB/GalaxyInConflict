function init()
end

local duration = 5
function update()
	if status.stat("gic_rally_khurtovyna_redarmy_medic") == 1 then
		status.addEphemeralEffect("gic_khurtovyna_medic_heal",1); -- this function can config effect duration
		status.addEphemeralEffect("gic_maxhealthboost_redsun_400",30); -- this function can config effect duration		
		-- if this function is specified w/o duration, will default to base duration of effect
		effect.expire(); --kills off primer effect. hopefully will avoid any crashes w primer running out of duration. Note from Med: Confirmed working. Doesn't cause crashes.
    end
end

function uninit()
end
