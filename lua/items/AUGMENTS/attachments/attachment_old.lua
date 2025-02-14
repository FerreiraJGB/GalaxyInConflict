require "/scripts/augments/item.lua"
require "/scripts/echo_util.lua"

function hasTag(input,tag) --checking for ammo tags.
	for _,v in pairs(input) do
		if v == tag then
			return true
		end
	end
	return false
end

function apply(input)
	local attachmentConfig = config.getParameter("attachment")
	local output = Item.new(input)
	
	if output.count > 1 then --prevents the adding of attachments to multiple items at once. failsafe.
		return nil
	end 
	--config.getParameter("reelName")
	--sb.logInfo(sb.printJson(output:instanceValue("attachmentsAvailable")))
	--sb.logInfo(sb.printJson(attachmentConfig.attachmentType))
	
	
	if output:instanceValue("usesAttachments") == true and hasTag(output:instanceValue("attachmentsAvailable"), attachmentConfig.attachmentType) and  hasTag(output:instanceValue("attachmentTags"), attachmentConfig.attachmentTag) then
		
		local currentAugment = output:instanceValue("attachment_" .. attachmentConfig.attachmentType.."_attached") --checks if the same exact attachment is already inserted
			if currentAugment then
				if currentAugment == attachmentConfig.attachmentName then
				--sb.logInfo("attachment already attached")
				return nil
			end
		end
		
		local outputAttachmentType = attachmentConfig.attachmentType
		output:setInstanceValue("attachment_" .. attachmentConfig.attachmentType,true) --attachment_(type)
		output:setInstanceValue("attachment_" .. attachmentConfig.attachmentType.."_attached",attachmentConfig.attachmentName) --attachment_(type)_attached
		output:setInstanceValue("attachment_" .. attachmentConfig.attachmentType.."_image",attachmentConfig.attachmentImage) --attachment_(type)_image
		output:setInstanceValue("attachment_" .. attachmentConfig.attachmentType.."_bonusType",attachmentConfig.attachmentBonusType) --attachment_(type)_bonusType
		output:setInstanceValue("attachment_" .. attachmentConfig.attachmentType.."_bonuses",attachmentConfig.attachmentBonuses) --attachment_(type)_bonuses
		
		if attachmentConfig.attachmentBonusesAlt then
		output:setInstanceValue("attachment_" .. attachmentConfig.attachmentType.."_bonusesAlt",attachmentConfig.attachmentBonusesAlt) --attachment_(type)_bonusesAlt
		end
	else
		return nil
	end
	
	return output:descriptor(),1
end