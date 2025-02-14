function init()

	if entity.entityType() == "monster" then effect.expire() end
	
	self.diseaseConfig = root.assetJson("/stats/gic_diseases.config")
end

function gic_tableLen(tab)
   local cnt = 0
   for key, value in ipairs(tab) do
	 cnt = cnt + 1
   end
   return cnt
 end

function gic_findDuplicateDisease(diseasesTab,diseaseCategory)
	for n, disease in ipairs(diseasesTab) do
		if disease.category == diseaseCategory then
			return true
		end
	end

	return false
end

function update(dt)
  if entity.entityType() == "player" then
	local diseases = status.statusProperty("gic_diseases", nil)
  
	if diseases == nil then
		status.setStatusProperty("gic_diseases", config.getParameter("diseases",jarray()))
	else
		--sb.logInfo(sb.printJson(afflictions))
		local length = gic_tableLen(diseases)
	
		for key,value in ipairs(config.getParameter("diseases")) do
			if not gic_findDuplicateDisease(diseases,self.diseaseConfig[value].category) then --prevent duplicate diseases
				diseases[length + key] = self.diseaseConfig[value]
			end
		end
	
		status.setStatusProperty("gic_diseases", diseases)
	end
  else
	-- for NPCs and etc give them the actual status effect and let it progress from there
	for key, value in ipairs(config.getParameter("diseases")) do
		status.addEphemeralEffect(self.diseaseConfig[value].statusEffect)
		--sb.logInfo(self.diseaseConfig[value].statusEffect)
	end
  end
  
  effect.expire()
end

function uninit()
end
