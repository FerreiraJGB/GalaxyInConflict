require "/scripts/util.lua"
require "/scripts/vec2.lua"
require "/scripts/versioningutils.lua"
require "/items/buildscripts/abilities.lua"
require "/scripts/echo_util.lua"

function build(directory, config, parameters, level, seed)
  local configParameter = function(keyName, defaultValue)
    if parameters[keyName] ~= nil then
      return parameters[keyName]
    elseif config[keyName] ~= nil then
      return config[keyName]
    else
      return defaultValue
    end
  end

  if level and not configParameter("fixedLevel", true) then
    parameters.level = level
  end

  setupAbility(config, parameters, "primary")
  setupAbility(config, parameters, "alt")

  -- elemental type and config (for alt ability)
  local elementalType = configParameter("elementalType", "physical")
  replacePatternInData(config, nil, "<elementalType>", elementalType)
  if config.altAbility and config.altAbility.elementalConfig then
    util.mergeTable(config.altAbility, config.altAbility.elementalConfig[elementalType])
  end

  -- calculate damage level multiplier
  config.damageLevelMultiplier = root.evalFunction("weaponDamageLevelMultiplier", configParameter("level", 1))

  -- palette swaps
  config.paletteSwaps = ""
  if config.palette then
    local palette = root.assetJson(util.absolutePath(directory, config.palette))
    local selectedSwaps = palette.swaps[configParameter("colorIndex", 1)]
    for k, v in pairs(selectedSwaps) do
      config.paletteSwaps = string.format("%s?replace=%s=%s", config.paletteSwaps, k, v)
    end
  end

  -- gun offsets
  if config.baseOffset then
    construct(config, "animationCustom", "animatedParts", "parts", "middle", "properties")
    config.animationCustom.animatedParts.parts.middle.properties.offset = config.baseOffset
    if config.muzzleOffset then
      config.muzzleOffset = vec2.add(config.muzzleOffset, config.baseOffset)
    end
  end
  
  --echoutil.logJson(parameters)
  -- populate tooltip fields
  if config.tooltipKind ~= "base" then
    config.tooltipFields = sb.jsonMerge(config.tooltipFields,{})
    config.tooltipFields.levelLabel = util.round(configParameter("level", 1), 1)
	
	if parameters.primaryAbility then
		if parameters.primaryAbility.baseDamage then config.primaryAbility.baseDamage = parameters.primaryAbility.baseDamage end
		if parameters.primaryAbility.fireTime then config.primaryAbility.fireTime = parameters.primaryAbility.fireTime end
	end
	
    config.tooltipFields.dpsLabel = util.round((config.primaryAbility.baseDps or 0) * config.damageLevelMultiplier, 1)
    config.tooltipFields.speedLabel = util.round(1 / (config.primaryAbility.fireTime or 1.0), 1)
    config.tooltipFields.damagePerShotLabel = util.round(config.primaryAbility.baseDamage or ((config.primaryAbility.baseDps or 0) * (config.primaryAbility.fireTime or 1.0)) * config.damageLevelMultiplier, 1)
    config.tooltipFields.energyPerShotLabel = util.round((config.primaryAbility.energyUsage or 0) * (config.primaryAbility.fireTime or 1.0), 1)
	
	local weaponDurabilityPercentage;
	local weaponNegativeEffectResult;
	local weaponNegativeEffectResultFinal;
	
	if config.weaponDeterioration == true then
	  config.tooltipFields.weaponDurabilityTitleLabel = "Weapon Integrity:"
	  
	  
	  --HOLY SHIT SO THIS IS HOW YOU CAN RESPOND TO PARAMETERS, LETS FUCKING GOOOOOOO
	  config.weaponDurability = configParameter("weaponDurability", config.weaponDurability)
	  config.weaponDurabilityMax = configParameter("weaponDurabilityMax", config.weaponDurabilityMax)
	  --basically SB has a built in function to find if there is a non-default parameter value
	  --using it here to replace the *actual* value with the parameter's value if it exists
	  --THIS IS HUUUUUUGE!! will be revisiting lots of buildscript codes bc of this
	  
	  
	  --workaround w/o the built in function
	  --if parameters.weaponDurability then config.weaponDurability = parameters.weaponDurability end
	  --if parameters.weaponDurabilityMax then config.weaponDurabilityMax = parameters.weaponDurabilityMax end
	  
	  
	  if type(config.weaponDurability) == "table" then
		config.weaponDurability = math.random(config.weaponDurability[1],config.weaponDurability[2])
		parameters.weaponDurability = config.weaponDurability
	  end
	  weaponDurabilityPercentage = echoutil.round(1,(config.weaponDurability / config.weaponDurabilityMax) * 100)
	  
	  config.tooltipFields.weaponDurabilityLabel = weaponDurabilityPercentage.."%"
	  
	  weaponNegativeEffectResult = (100 - weaponDurabilityPercentage) / 100
	  weaponNegativeEffectResultFinal = 1 + (weaponNegativeEffectResult * (config.weaponDurabilityEffectMultiplier or 1))
	end
	
    if elementalType ~= "physical" then
      config.tooltipFields.damageKindImage = "/interface/elements/"..elementalType..".png"
    end
    if config.primaryAbility then
      config.tooltipFields.primaryAbilityTitleLabel = "Primary:"
      config.tooltipFields.primaryAbilityLabel = config.primaryAbility.name or "unknown"
    end
    if config.altAbility then
      config.tooltipFields.altAbilityTitleLabel = "Special:"
      config.tooltipFields.altAbilityLabel = config.altAbility.name or "unknown"
    end
	
	-- sb.logInfo(sb.printJson(config.primaryAbility))
	if (config.missChanceToggle == nil or config.missChanceToggle == true) and config.primaryAbility.projectileTypeMiss ~= nil then
		-- sb.logInfo("buildscript, trying to config miss chances");
		local baseMissChance = config.primaryAbility.missChance;
		local baseMissChanceCrouch = config.primaryAbility.missChanceCrouch or baseMissChance * 0.4
		
		
		
		local missChanceVar = baseMissChance
		local crouchMissChanceVar = baseMissChanceCrouch
		if config.primaryAbility.fireType == config.primaryAbility.altFireType then
			missChanceVar = config.primaryAbility.altMissChance;
			crouchMissChanceVar = config.primaryAbility.altMissChanceCrouch or missChanceVar * 0.4
		end
		
		missChanceVar = missChanceVar * (weaponNegativeEffectResultFinal or 1)
		crouchMissChanceVar = crouchMissChanceVar * (weaponNegativeEffectResultFinal or 1)
		
		config.tooltipFields.missTitleLabel = "Base Miss Chances: "
		config.tooltipFields.missLabel = echoutil.round(1,missChanceVar).."% ^#999999;|^reset; "..echoutil.round(1,crouchMissChanceVar).."%"
	end
	
	if config.usesAttachments == true then
	  --config.tooltipFields.usesAttachmentsLabel = "^gray;Attachments Enabled^reset;"
	  local labelText = "^gray;Attachments: ^reset;"
	  local acceptedAttachments = config.attachmentsAvailable
	  local labelsTemp = 0
	  
	  local sight = echoutil.findInTablePairs(acceptedAttachments, "sight")
	  local barrel = echoutil.findInTablePairs(acceptedAttachments, "barrel")
	  local underbarrel = echoutil.findInTablePairs(acceptedAttachments, "underbarrel")
	  local stock = echoutil.findInTablePairs(acceptedAttachments, "stock")
	  local misc = echoutil.findInTablePairs(acceptedAttachments, "misc")
	  
	  if sight then labelText = labelText.."sights" 
		labelsTemp = 1 end
	  
	  if barrel then
		if labelsTemp == 1 then labelText = labelText..", " end
		labelText = labelText.."barrels"
		labelsTemp = 1 end
	  
	  if underbarrel then
		if labelsTemp == 1 then labelText = labelText..", " end
		labelText = labelText.."underbarrel"
		labelsTemp = 1 end
	  
	  if stock then 
		if labelsTemp == 1 then labelText = labelText..", " end
		labelText = labelText.."stocks"
		labelsTemp = 1 end
	  
	  if misc then
		if labelsTemp == 1 then labelText = labelText..", " end
		labelText = labelText.."misc"
		labelsTemp = 1 end
	  
	  --labelText = labelText.." ^gray;attachments.^reset;"
	  
	  config.tooltipFields.usesAttachmentsLabel = labelText
	end
		
	
	config.tooltipFields.ammogunhighresImage = config.highResImg
  end
  
   -- ammo setup test
   config.tooltipFields.ammoAmountLabel = config.ammoAmount.."/"..config.ammoMax
   
   --if configParameter("useRPM", 1) == true then
   --if configParameter("RPM") then
   --config.tooltipFields.speedLabel = configParameter("RPM").." RPM"
   --else
   --config.tooltipFields.speedLabel = util.round(1 / (config.primaryAbility.fireTime or 1) * 60, 1).." RPM"
   --end
   --end
  -- set price
  -- TODO: should this be handled elsewhere?
  config.price = (config.price or 0) * root.evalFunction("itemLevelPriceMultiplier", configParameter("level", 1))
  
  
  if config.usesAttachments == true or config.magazineImages then
  if not config.inventoryIconOriginal then
	config.inventoryIconOriginal = config.inventoryIcon
  end
  
  local grenadelauncherAttachment = false
  
  if config.underbarrelAttachment then
	if config.underbarrelAttachment.specialAttachmentConfig then
		if config.underbarrelAttachment.specialAttachmentConfig.type == "grenadelauncher" then
			grenadelauncherAttachment = true
		end
	end
  end
  
  local partImgs = {}
  partImgs["main"] = config.inventoryIconOriginal
  if config.sightAttachment then
	partImgs["sight"] = config.sightAttachment.attachmentImage
  end
  if config.barrelAttachment then
	partImgs["barrel"] = config.barrelAttachment.attachmentImage
  end
  if config.underbarrelAttachment then
	if grenadelauncherAttachment == true then
		partImgs["underbarrel"] = config.underbarrelAttachment.attachmentImage..":armed.1"
	else
		partImgs["underbarrel"] = config.underbarrelAttachment.attachmentImage
	end
  end
  if config.stockAttachment then
	partImgs["stock"] = config.stockAttachment.attachmentImage
  end
  --sb.logInfo(sb.printJson(partImgs["stock"]))
  
  
  if type(config.consumeAmmoType) == "table" and config.magazineImages then
  local magazineImageChosen = config.magazineImages[config.activeIndex or (config.defaultAmmoIndexValue or 1)]
  partImgs["magazine"] = magazineImageChosen..":reload.3"
  --echoutil.logJson(partImgs["magazine"])
  end
  
  
  local animationCustom = config.animationCustom
  --animationCustom.animatedParts.parts
  
  local animationProperties = animationCustom.animatedParts.parts
  
  
  
  local partImagePositions = {}
  partImagePositions["main"] = determinePartOffset(animationProperties.middle.properties.offset or {0,0},partImgs["main"],config.baseOffset or {0,0})
  
  if partImgs["sight"] then
  partImagePositions["sight"] = determinePartOffset(animationProperties.sight.properties.offset or {0,0},partImgs["sight"],config.baseOffset or {0,0})
  end
  if partImgs["barrel"] then
  partImagePositions["barrel"] = determinePartOffset(animationProperties.barrel.properties.offset or {0,0},partImgs["barrel"],config.baseOffset or {0,0})
  end
  if partImgs["underbarrel"] then
  partImagePositions["underbarrel"] = determinePartOffset(animationProperties.underbarrel.properties.offset or {0,0},partImgs["underbarrel"],config.baseOffset or {0,0})
  end
  if partImgs["stock"] then
  partImagePositions["stock"] = determinePartOffset(animationProperties.stock.properties.offset or {0,0},partImgs["stock"],config.baseOffset or {0,0})
  end
  
  if partImgs["magazine"] then
  partImagePositions["magazine"] = determinePartOffset(animationProperties.magazine.properties.offset or {0,0},partImgs["magazine"],config.baseOffset or {0,0})
  end
  
  if not animationProperties.middle then animationProperties.middle = {properties = {}} end
  if not animationProperties.sight then animationProperties.sight = {properties = {}} end
  if not animationProperties.barrel then animationProperties.barrel = {properties = {}} end
  if not animationProperties.underbarrel then animationProperties.underbarrel = {properties = {}} end
  if not animationProperties.stock then animationProperties.stock = {properties = {}} end
  if not animationProperties.magazine then animationProperties.magazine = {properties = {}} end
  
  local partLvls = {}
  if animationProperties.middle then
  partLvls["main"] = animationProperties.middle.properties.zLevel or 0
  end
  if animationProperties.sight then
  partLvls["sight"] = animationProperties.sight.properties.zLevel or 10
  end
  if animationProperties.barrel then
  partLvls["barrel"] = animationProperties.barrel.properties.zLevel or 10
  end
  if animationProperties.underbarrel then
  partLvls["underbarrel"] = animationProperties.underbarrel.properties.zLevel or 10
  end
  if animationProperties.stock then
  partLvls["stock"] = animationProperties.stock.properties.zLevel or 10
  end
  if animationProperties.magazine then
  partLvls["magazine"] = animationProperties.magazine.properties.zLevel or 1
  end
  
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
		
		config.inventoryIcon = inventoryIcon
		--echoutil.logJson(config.inventoryIcon)
  end
  
  if type(config.inventoryIcon) == "string" then
    config.inventoryIcon = config.inventoryIcon .. config.paletteSwaps
  else
    for i, drawable in ipairs(config.inventoryIcon) do
      if drawable.image then drawable.image = drawable.image .. config.paletteSwaps end
    end
  end

  return config, parameters
end

function determinePartOffset(offset,img,baseOffset)
  local imageOffset = {0,0}
  imageOffset = {8 * (offset[1] + baseOffset[1]),8 * (offset[2] + baseOffset[2])}
  return imageOffset
end
