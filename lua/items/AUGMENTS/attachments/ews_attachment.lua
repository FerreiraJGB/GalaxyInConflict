require "/scripts/augments/item.lua"
require "/scripts/echo_util.lua"

function checkTags(tab1,tag1)
	
	if type(tag1) == "table" then
		for index, value in pairs(tag1) do
		--sb.logInfo(sb.printJson(value1) .. " value1, " .. sb.printJson(index) .. " index, ".. sb.printJson(tab1) .. " tab1")
		--echoutil.logJson(echoutil.findInTablePairs(tab1,value1))
			if echoutil.findInTablePairs(tab1, value) == true then
				return true
			end
		end

		return false
	else
		return echoutil.findInTablePairs(tab1,tag1)
	end
end

function determinePartOffset(offset,img,output)
  local imageOffset = {0,0}
  local baseOffset = output:instanceValue( "baseOffset" )
  imageOffset = {8 * (offset[1] + baseOffset[1]),8 * (offset[2] + baseOffset[2])}
  return imageOffset
end

-- CODE THAT CALCULATES EFFECTS OF ATTACHMENT --
function modifyFinalVariables(input,modifier,modifierType)
	--modifierType = (modifierType or "additive")
	--sb.logInfo(sb.printJson(input)..", "..sb.printJson(modifier)..", "..sb.printJson(modifierType))

	if modifierType == "additive" then
	input[2] = input[2] + modifier
	end
	
	if modifierType == "multiplicative" then
		input[3] = input[3] * modifier
	end
	
	if modifierType == "set" then
		if modifier == -1 then
			input[4] = input[4] or 0
		elseif input[4] then
			if modifier > input[4] then
			input[4] = modifier
			end
		else
			input[4] = modifier
		end
	end
end

function fillVarTableFields(tab)
	tab[2] = 0
	tab[3] = 1
	tab[4] = 0
end

function setupModifiers(parameterName, output)
  local attachmentConfig = output:instanceValue(parameterName)
  if attachmentConfig then
  if attachmentConfig.attachmentAttached == true then
	local attachmentBonusType = attachmentConfig.attachmentBonusType
	--sb.logInfo(sb.printJson(attachmentConfig))
	local attachmentBonuses = attachmentConfig.attachmentBonuses
	--sb.logInfo(sb.printJson(attachmentBonuses))
	--self:modifyFinalVariables(self.temp,attachmentBonuses[1],attachmentBonusType)
	
	
	--sb.logInfo(sb.printJson("finalMissChance"))
	modifyFinalVariables(self.finalMissChance,attachmentBonuses[3],attachmentBonusType)
	--sb.logInfo(sb.printJson("finalMissChanceCrouch"))
	modifyFinalVariables(self.finalMissChanceCrouch,attachmentBonuses[4],attachmentBonusType)	
  end
  
  if attachmentConfig.attachmentBonusesAlt then
	local attachmentBonusType = attachmentConfig.attachmentBonusType
	local attachmentBonusesAlt = attachmentConfig.attachmentBonusesAlt
	
	modifyFinalVariables(self.finalAltMissChance,attachmentBonusesAlt[3],attachmentBonusType)
	--sb.logInfo(sb.printJson("finalAltMissChanceCrouch"))
	modifyFinalVariables(self.finalAltMissChanceCrouch,attachmentBonusesAlt[4],attachmentBonusType)
  end
  end
end

function finalizeFinalVariable(variable)
	-- sb.logInfo(sb.printJson(variable))
	local variableStore = variable[1]
	if variable[4] > 0 then
		variableStore = variable[4]
	end
	if variable[3] == 0 then variable[3] = 1 end
	variable = (variableStore + variable[2]) * variable[3]
	return variable
end

function setFinalVariables(output)
	local primaryAbility = output:instanceValue( "primaryAbility" )
	
	self.finalMissChance = {}
	self.finalMissChanceCrouch = {}
	
	self.finalAltMissChance = {}
	self.finalAltMissChanceCrouch = {}
	
	self.finalMissChance[1] = (primaryAbility.missChance or 0)
	self.finalMissChanceCrouch[1] = (primaryAbility.missChanceCrouch or self.finalMissChance[1] * 0.4)
	
	self.finalAltMissChance[1] = (primaryAbility.altMissChance or self.finalMissChance[1])
	self.finalAltMissChanceCrouch[1] = (primaryAbility.altMissChanceCrouch or self.finalAltMissChance[1] * 0.4)
	
	fillVarTableFields(self.finalMissChance)
	fillVarTableFields(self.finalMissChanceCrouch)
	
	fillVarTableFields(self.finalAltMissChance)
	fillVarTableFields(self.finalAltMissChanceCrouch)
	
	setupModifiers("sightAttachment", output)
	setupModifiers("barrelAttachment", output)
	setupModifiers("underbarrelAttachment", output)
	setupModifiers("stockAttachment", output)
	setupModifiers("miscAttachment", output)
	-- variable[1] = original variable, variable[2] = collective additive bonuses, variable[3] = collective multiplicative bonus, variable[4] = largest set value bonus
	
	
	self.finalMissChance = finalizeFinalVariable(self.finalMissChance)
	self.finalMissChanceCrouch = finalizeFinalVariable(self.finalMissChanceCrouch)
	
	self.finalAltMissChance = finalizeFinalVariable(self.finalAltMissChance)
	self.finalAltMissChanceCrouch = finalizeFinalVariable(self.finalAltMissChanceCrouch)
end
-- CODE THAT CALCULATES EFFECTS OF ATTACHMENT --

-- updates attachment's miss chance stuff to account for newly activated attachment
function updateMissLabel(output)
	local primaryAbility = output:instanceValue( "primaryAbility" )
	local missChanceToggle = output:instanceValue( "missChanceToggle" )
	
	local weaponDurability = output:instanceValue( "weaponDurability" )
	local weaponDurabilityMax = output:instanceValue( "weaponDurabilityMax" )
	
	if (missChanceToggle == nil or missChanceToggle == true) and primaryAbility.projectileTypeMiss ~= nil then
	
		-- figure out effects of attachments
		setFinalVariables(output)
	
		local baseMissChance = self.finalMissChance -- primaryAbility.missChance;
		local baseMissChanceCrouch = self.finalMissChanceCrouch or baseMissChance * 0.4--primaryAbility.missChanceCrouch or baseMissChance * 0.4	
		-- sb.logInfo("misschance "..baseMissChance.."|"..baseMissChanceCrouch)
		
		local missChanceVar = baseMissChance
		local crouchMissChanceVar = baseMissChanceCrouch
		if primaryAbility.fireType == primaryAbility.altFireType then
			missChanceVar = self.finalAltMissChance;
			crouchMissChanceVar = self.finalAltMissChanceCrouch or missChanceVar * 0.4
		end
		
		-- calculate durability effects
		local weaponNegativeEffectResultFinal
		if weaponDurability ~= nil and weaponDurabilityMax ~= nil then
			local weaponDurabilityPercentage = echoutil.round(1,(weaponDurability / weaponDurabilityMax) * 100)
			local weaponDurabilityEffectMultiplier = output:instanceValue( "weaponDurabilityEffectMultiplier" )
			-- sb.logInfo("durability: " .. weaponDurabilityPercentage)
			
			local weaponNegativeEffectResult = (100 - weaponDurabilityPercentage) / 100
			weaponNegativeEffectResultFinal = 1 + (weaponNegativeEffectResult * (weaponDurabilityEffectMultiplier or 1))
			-- sb.logInfo("durability negative mult " .. weaponNegativeEffectResultFinal)
		end
		
		missChanceVar = missChanceVar * (weaponNegativeEffectResultFinal or 1)
		crouchMissChanceVar = crouchMissChanceVar * (weaponNegativeEffectResultFinal or 1)
		
		local tooltipFields = output:instanceValue( "tooltipFields" ) or {}
		tooltipFields.missLabel = echoutil.round(1,missChanceVar).."% ^#999999;|^reset; "..echoutil.round(1,crouchMissChanceVar).."%"
		output:setInstanceValue("tooltipFields", tooltipFields)
	end
end

function updateInventoryIcon(output)
  if output:instanceValue( "usesAttachments" ) == true or output:instanceValue("magazineImages") then			--sets up dynamic inventoryIcon if attachments are involved/multiple magazine images
  local inventoryIcon = output:instanceValue( "inventoryIcon" )
  if not output:instanceValue( "inventoryIconOriginal" ) then
	output:setInstanceValue("inventoryIconOriginal",output:instanceValue("inventoryIcon"))
  end
  
  local partImgs = {}
  partImgs["main"] = output:instanceValue( "inventoryIconOriginal" )
  
  if output:instanceValue( "sightAttachment" ) and output:instanceValue( "sightAttachment" ).attachmentImage then
	partImgs["sight"] = output:instanceValue( "sightAttachment" ).attachmentImage
  end
  
  if output:instanceValue( "barrelAttachment" ) and output:instanceValue( "barrelAttachment" ).attachmentImage then
	partImgs["barrel"] = output:instanceValue( "barrelAttachment" ).attachmentImage
  end
  
  
  
  local underbarrelImage
  if output:instanceValue("underbarrelAttachment") and output:instanceValue("underbarrelAttachment").attachmentImage then
	underbarrelImage = output:instanceValue("underbarrelAttachment").attachmentImage
	
	local specialAttachment
  
	if output:instanceValue( "underbarrelAttachment" ) and output:instanceValue( "underbarrelAttachment" ).specialAttachmentConfig then
		specialAttachment = output:instanceValue("underbarrelAttachment").specialAttachmentConfig.type
	end
  
	if specialAttachment == "grenadelauncher" then
		local attachmentConfig = output:instanceValue( "underbarrelAttachment" ) -- sets the underbarrel data if an attachment is inserted
		underbarrelImage = attachmentConfig.attachmentImage..":armed.1"
	end
	
	if specialAttachment == "light" or specialAttachment == "laserlight" then
		local animationCustom = output:instanceValue( "animationCustom" )
		local attachmentConfig = output:instanceValue( "underbarrelAttachment" )
		local lightConfigPos = attachmentConfig.specialAttachmentConfig.lightConfig.offset
		local underbarrelPartPos = animationCustom.animatedParts.parts.underbarrel.properties.offset
		--if not animationCustom.lights.flashlightAttachment.position then						--sends radio msg w dev note about flashlight wack
			--world.sendEntityMessage(entity.id(), "queueRadioMessage", "ews_flashlightattachment")
		--end
		attachmentConfig.specialAttachmentConfig.lightConfig.position = {lightConfigPos[1] + underbarrelPartPos[1],lightConfigPos[2] + 	underbarrelPartPos[2]}--sets up flashlight offsets
		animationCustom.lights.flashlightAttachment = attachmentConfig.specialAttachmentConfig.lightConfig
		
		output:setInstanceValue("animationCustom",animationCustom)
		
		--sb.logInfo(sb.printJson(output:instanceValue("animationCustom").lights))
		--activeItem.setInstanceValue("animationCustom",animationCustom)							--updates flashlight directly to activeitem
	end
  end
  partImgs["underbarrel"] = underbarrelImage
  
  
  
  if output:instanceValue( "stockAttachment" ) and output:instanceValue( "stockAttachment" ).attachmentImage then
	partImgs["stock"] = output:instanceValue( "stockAttachment" ).attachmentImage
  end
  
  if type(output:instanceValue("consumeAmmoType")) == "table" and output:instanceValue("consumeAmmoModule") == true and output:instanceValue("magazineImages") then
	local magazineImageChosen = output:instanceValue("magazineImages")
	magazineImageChosen = magazineImageChosen[output:instanceValue("activeIndex") or 1]
	partImgs["magazine"] = magazineImageChosen..":reload.3"
  end
  
  
  local animationCustom = output:instanceValue( "animationCustom" )
  --animationCustom.animatedParts.parts
  
  local animationProperties = animationCustom.animatedParts.parts
  --sb.logInfo(sb.printJson(animationProperties))
  
  
  --local baseOffset = output:instanceValue("baseOffset")
  local partImagePositions = {}
  partImagePositions["main"] = determinePartOffset(animationProperties.middle.properties.offset or {0,0},partImgs["main"],output)
  
  if partImgs["sight"] then
  partImagePositions["sight"] = determinePartOffset(animationProperties.sight.properties.offset or {0,0},partImgs["sight"],output)
  end
  if partImgs["barrel"] then
  partImagePositions["barrel"] = determinePartOffset(animationProperties.barrel.properties.offset or {0,0},partImgs["barrel"],output)
  end
  if partImgs["underbarrel"] then
  partImagePositions["underbarrel"] = determinePartOffset(animationProperties.underbarrel.properties.offset or {0,0},partImgs["underbarrel"],output)
  end
  if partImgs["stock"] then
  partImagePositions["stock"] = determinePartOffset(animationProperties.stock.properties.offset or {0,0},partImgs["stock"],output)
  end
  
  if partImgs["magazine"] then
  partImagePositions["magazine"] = determinePartOffset(animationProperties.magazine.properties.offset or {0,0},partImgs["magazine"],output)
  end
  
  if not animationProperties.middle then animationProperties.middle = {properties = {}} end
  if not animationProperties.sight then animationProperties.sight = {properties = {}} end
  if not animationProperties.barrel then animationProperties.barrel = {properties = {}} end
  if not animationProperties.underbarrel then animationProperties.underbarrel = {properties = {}} end
  if not animationProperties.stock then animationProperties.stock = {properties = {}} end
  if not animationProperties.magazine then animationProperties.magazine = {properties = {}} end
  
  local partLvls = {}
  partLvls["main"] = animationProperties.middle.properties.zLevel or 0
  partLvls["sight"] = animationProperties.sight.properties.zLevel or 10
  partLvls["barrel"] = animationProperties.barrel.properties.zLevel or 10
  partLvls["underbarrel"] = animationProperties.underbarrel.properties.zLevel or 10
  partLvls["stock"] = animationProperties.stock.properties.zLevel or 10
  partLvls["magazine"] = animationProperties.magazine.properties.zLevel or 1
  
  --sb.logInfo(sb.printJson(partLvls))
		inventoryIcon = jarray()
		local parts = {"main","sight","barrel","underbarrel","stock","magazine"}
		
		--sorts parts by zLevel to properly render stuff in inventoryIcon, since zLevel doesn't actually matter here. main thing that matters is drawn order.
		table.sort(parts, function (a, b) return partLvls[a] < partLvls[b] end )
		
		for _,partName in pairs(parts) do
			local drawable = {
				image = partImgs[partName],
				position = partImagePositions[partName],
				zLevel = partLvls[partName],
				centered = true
			}
			if drawable.image then
			inventoryIcon[#inventoryIcon+1] = drawable
			end
		end
		
		return inventoryIcon
  end
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
	
	
	
	--local testDebugTable2 = {"maybe"}
	--local testDebugTable = {"yes", "no", "maybe"}
	--echoutil.logJson(testDebugTable2)
	--echoutil.logJson(testDebugTable)
	--echoutil.logJson(checkTags(testDebugTable2, testDebugTable))
	--sb.logInfo("---------------")
	
	--local attachmentTags = output:instanceValue("attachmentTags")
	--local attachmentTag = attachmentConfig.attachmentTag
	
	--echoutil.logJson(output:instanceValue("attachmentTags"))
	--echoutil.logJson(attachmentConfig.attachmentTag)
	--sb.logInfo("---------------")
	--echoutil.logJson(checkTags(output:instanceValue("attachmentTags"), attachmentConfig.attachmentTag))
	--echoutil.logJson(checkTags(attachmentTags, attachmentTag))
	--sb.logInfo("")
	--sb.logInfo("")
	--sb.logInfo("")
	
	
	if output:instanceValue("usesAttachments") == true and (echoutil.findInTablePairs(output:instanceValue("attachmentsAvailable"), attachmentConfig.attachmentType) and checkTags(output:instanceValue("attachmentTags"), attachmentConfig.attachmentTag)) then
	
		
		
		local attachmentConfigFromOutput = output:instanceValue(attachmentConfig.attachmentType.."Attachment")
		
		if attachmentConfigFromOutput then
		local currentAugment = attachmentConfigFromOutput.attachedName --checks if the same exact attachment is already inserted
			if currentAugment then
				if currentAugment == attachmentConfig.attachmentName then
					--sb.logInfo("attachment already attached")
					return nil
				else
					--sb.logInfo(attachmentConfigFromOutput.attachmentId)
					if attachmentConfigFromOutput.removable == true and attachmentConfigFromOutput.attachmentId then
						-- TODO --
						--sb.logInfo("removable attachment logged")
						local list = output:instanceValue("replace"..attachmentConfig.attachmentType.."Attachment")
						
						--to support multiple attachments being switched and whatnot
						if list then
							list[#list+1] = attachmentConfigFromOutput.attachmentId
							
							output:setInstanceValue("replace"..attachmentConfig.attachmentType.."Attachment",list)
						else
							output:setInstanceValue("replace"..attachmentConfig.attachmentType.."Attachment",{attachmentConfigFromOutput.attachmentId})
						end
					end
				end
			end
		end
		
		if attachmentConfig.attachmentType == "misc" then			--misc attachment setup. Currently only function of misc attachments is to change fire types.
			if attachmentConfig.fireType then
				local primaryAbility = output:instanceValue("primaryAbility")
				-- sb.logInfo(sb.printJson(attachmentConfig.fireType))
				-- sb.logInfo(sb.printJson(primaryAbility.fireType))
				if attachmentConfig.fireType == primaryAbility.fireType and not output:instanceValue("switchAmmoAttachment") == true then
					return nil
				else
					--sb.logInfo()
					local primaryAbility = output:instanceValue("primaryAbility")
					primaryAbility.fireType = attachmentConfig.fireType
					output:setInstanceValue("primaryAbility",primaryAbility)
					
					
					--avoids occupying or modifying the miscAttachment slot if told to do so.
					if attachmentConfig.notAttachment == true then
						return output:descriptor(), 1
					end
					
					
					local attachmentConfigAttach = {}
					attachmentConfigAttach.attachmentAttached = true
					attachmentConfigAttach.attachedName = attachmentConfig.attachmentName
					attachmentConfigAttach.attachmentBonusType = attachmentConfig.attachmentBonusType
					attachmentConfigAttach.attachmentBonuses = attachmentConfig.attachmentBonuses
					if attachmentConfig.attachmentBonusesAlt then
						attachmentConfigAttach.attachmentBonusesAlt = attachmentConfig.attachmentBonusesAlt
					end
					
					output:setInstanceValue("miscAttachment",attachmentConfigAttach)
					
					output:setInstanceValue("inventoryIcon",updateInventoryIcon(output))
					
					return output:descriptor(),1
				end
			end
		end
		
		--local outputAttachmentType = attachmentConfig.attachmentType
		--output:setInstanceValue("attachment_" .. attachmentConfig.attachmentType,true) --attachment_(type)
		--output:setInstanceValue("attachment_" .. attachmentConfig.attachmentType.."_attached",attachmentConfig.attachmentName) --attachment_(type)_attached
		--output:setInstanceValue("attachment_" .. attachmentConfig.attachmentType.."_image",attachmentConfig.attachmentImage) --attachment_(type)_image
		--output:setInstanceValue("attachment_" .. attachmentConfig.attachmentType.."_bonusType",attachmentConfig.attachmentBonusType) --attachment_(type)_bonusType
		--output:setInstanceValue("attachment_" .. attachmentConfig.attachmentType.."_bonuses",attachmentConfig.attachmentBonuses) --attachment_(type)_bonuses
		
		
		local attachmentConfigAttach = {}
		attachmentConfigAttach.attachmentAttached = true
		attachmentConfigAttach.attachedName = attachmentConfig.attachmentName
		attachmentConfigAttach.attachmentImage = attachmentConfig.attachmentImage
		attachmentConfigAttach.attachmentBonusType = attachmentConfig.attachmentBonusType
		attachmentConfigAttach.attachmentBonuses = attachmentConfig.attachmentBonuses
		
		--removable attachment stuff
		attachmentConfigAttach.attachmentId = attachmentConfig.attachmentId
		attachmentConfigAttach.removable = attachmentConfig.removable
		
		
		if attachmentConfig.attachmentBonusesAlt then
		--output:setInstanceValue("attachment_" .. attachmentConfig.attachmentType.."_bonusesAlt",attachmentConfig.attachmentBonusesAlt) --attachment_(type)_bonusesAlt
		attachmentConfigAttach.attachmentBonusesAlt = attachmentConfig.attachmentBonusesAlt
		end
		
		if attachmentConfig.specialAttachmentConfig then
		--output:setInstanceValue("attachment_" .. attachmentConfig.attachmentType.."_bonusesAlt",attachmentConfig.attachmentBonusesAlt) --attachment_(type)_bonusesAlt
		attachmentConfigAttach.specialAttachmentConfig = attachmentConfig.specialAttachmentConfig
			if attachmentConfig.specialAttachmentConfig.grenadelauncherConfig then
				output:setInstanceValue("altAmmoMax",attachmentConfig.specialAttachmentConfig.grenadelauncherConfig.altAmmoMax)
				output:setInstanceValue("altAmmoAmount",attachmentConfig.specialAttachmentConfig.grenadelauncherConfig.altAmmo)
			end
		else
		attachmentConfigAttach.specialAttachmentConfig = {type = "undefined"}
		end
		
		output:setInstanceValue(attachmentConfig.attachmentType.."Attachment",attachmentConfigAttach)
		
		output:setInstanceValue("inventoryIcon",updateInventoryIcon(output))
	else
		return nil
	end
	
	updateMissLabel(output)
	
	return output:descriptor(),1
end