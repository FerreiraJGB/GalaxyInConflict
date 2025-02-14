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
  
  if output:instanceValue("underbarrelAttachment") and output:instanceValue("underbarrelAttachment").attachmentImage then
	partImgs["underbarrel"] = output:instanceValue("underbarrelAttachment").attachmentImage
  end
  
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
	
	--local attachmentConfig = config.getParameter("attachment")
	local output = Item.new(input)
	
	if output.count > 1 then --prevents the adding of attachments to multiple items at once. failsafe.
		return nil
	end
	
	local attachmentsAvailable = output:instanceValue("attachmentsAvailable")
	if #attachmentsAvailable == 0 then
		return nil
	end
	
	if output:instanceValue("usesAttachments") ~= true then
		return nil
	end
	
	
	local slots = config.getParameter("removeAttachments")
	local attachmentCnt = 0
	
	for key, attachmentType in pairs (slots) do
		--local attachmentConfig = value
		if (echoutil.findInTablePairs(attachmentsAvailable, attachmentType)) then
		
			local attachmentConfigFromOutput = output:instanceValue(attachmentType.."Attachment")
			
			if attachmentConfigFromOutput and attachmentConfigFromOutput.removable == true and attachmentConfigFromOutput.attachmentId then
				attachmentCnt = attachmentCnt + 1
				
				local list = output:instanceValue("replace"..attachmentType.."Attachment")
				--to support multiple attachments being switched and whatnot
				if list then
					list[#list+1] = attachmentConfigFromOutput.attachmentId
							
					output:setInstanceValue("replace"..attachmentType.."Attachment",list)
				else
					output:setInstanceValue("replace"..attachmentType.."Attachment",{attachmentConfigFromOutput.attachmentId})
				end
				
				local attachmentConfigAttach = {}
				attachmentConfigAttach.attachmentAttached = false
				attachmentConfigAttach.attachedName = "undefined"
				attachmentConfigAttach.attachmentImage = "/assetmissing.png"
		
				output:setInstanceValue(attachmentType.."Attachment",attachmentConfigAttach)
		
				output:setInstanceValue("inventoryIcon",updateInventoryIcon(output))
			end
		else
			--return nil
		end
	end
	
	-- if no attachments to be removed, don't consume item.
	if attachmentCnt == 0 then return nil end
	
	return output:descriptor(),1
end