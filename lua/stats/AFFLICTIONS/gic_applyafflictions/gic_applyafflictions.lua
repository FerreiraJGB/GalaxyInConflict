function init()
end

function gic_tableLen(tab)
   local cnt = 0
   for key, value in ipairs(tab) do
	 cnt = cnt + 1
   end
   return cnt
 end

function update(dt)
  local afflictions = status.statusProperty("gic_afflictions", nil)
  
  if afflictions == nil then
	status.setStatusProperty("gic_afflictions", config.getParameter("statusEffects",jarray()))
  else
	--sb.logInfo(sb.printJson(afflictions))
	local length = gic_tableLen(afflictions)
	
	for key,value in ipairs(config.getParameter("statusEffects")) do
		afflictions[length + key] = value
	end
	
	status.setStatusProperty("gic_afflictions", afflictions)
  end
  
  effect.expire()
end

function uninit()
end
