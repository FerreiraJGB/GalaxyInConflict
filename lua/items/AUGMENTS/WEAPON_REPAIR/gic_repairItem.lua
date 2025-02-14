require "/scripts/augments/item.lua"
require "/scripts/echo_util.lua"

function checkTags(tab,tag)
	
	if type(tag) == "table" then
		for index, value in pairs(tab) do
			if echoutil.findInTablePairs(tag, value) == true then
				return true
			end
		end
		return false
	else
		return echoutil.findInTablePairs(tab,tag)
	end
end

function apply(input)
	local config = config.getParameter("config")
	local output = Item.new(input)
	
	if output.count > 1 then --prevents the adding of attachments to multiple items at once. failsafe.
		return nil
	end 
	
	if output:instanceValue("weaponAcceptRepairs") == true and checkTags(output:instanceValue("weaponRepairAcceptTags"), config.tags) then
		local weaponDurabilityPercentage = output:instanceValue("weaponDurability") / output:instanceValue("weaponDurabilityMax")		
		
		if weaponDurabilityPercentage < config.limit then
			--sb.logInfo("weapon is too broken; durability is too low")
			return nil
		end
		
		local weaponDurability = output:instanceValue("weaponDurability") + echoutil.round(0,output:instanceValue("weaponDurabilityMax") * config.repairAmount)
		
		if weaponDurability > output:instanceValue("weaponDurabilityMax") then
			weaponDurability = output:instanceValue("weaponDurabilityMax")
		end
		
		output:setInstanceValue("weaponDurability",weaponDurability)
	else
		--sb.logInfo("failed")
		--sb.logInfo("weaponAcceptRepairs? " .. sb.printJson(output:instanceValue("weaponAcceptRepairs")))
		--sb.logInfo("tag check? " .. sb.printJson(checkTags(output:instanceValue("weaponRepairAcceptTags"))))
		--echoutil.logJson(output:instanceValue("weaponRepairAcceptTags"))
		--echoutil.logJson(config.tags)
		return nil
	end
	
	return output:descriptor(),1
end
