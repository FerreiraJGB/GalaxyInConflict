require "/scripts/util.lua"
require "/scripts/interp.lua"
require "/scripts/vec2.lua"
require "/scripts/echo_util.lua"

-- Base gun fire ability
GunFire = WeaponAbility:new()

function GunFire:init()
  self.lasersightData = {} --thingie so lasersights don't freak out n stuff
  

  
  self.lasersightData = self.weapon:setStance(self.stances.idle)
  
  self.jammed = false
  self.unjamming = false
  if config.getParameter("weaponJammed") == true then
	self.jammed = true
  end
  
  if config.getParameter("usesAttachments") == true then	--updates tooltip fields to show "Attachments Enabled" if attachments are enabled
	--sb.logInfo("yes")
	local tooltipFields = config.getParameter("tooltipFields")
	if not tooltipFields["usesAttachmentsLabel"] == "gray;Attachments Enabled^reset;" or tooltipFields["usesAttachmentsLabel"] == "Attachments Enabled" then
		tooltipFields["usesAttachmentsLabel"] = "^gray;Attachments Enabled^reset;"
		activeItem.setInstanceValue("tooltipFields",tooltipFields)
	end
  end
  
  activeItem.setCursor("/cursors/reticle1.cursor")
  self.scopeOutMarker = true
  
  if config.getParameter("ammoAmount") > 0 then
	animator.setAnimationState("gunState","armed")
  else
	animator.setAnimationState("gunState","empty")
  end
  
  if (config.getParameter("singleBulletLoad") == true and type(config.getParameter("consumeAmmoType")) == "table" and not config.getParameter("activeAmmoTypeList")) or (config.getParameter("consumeAmmoAmount") and type(config.getParameter("consumeAmmoType")) == "table" and not config.getParameter("activeAmmoTypeList")) then
	local activeAmmoTypeList = {}
	local ammoItemLoaded = config.getParameter("consumeAmmoType")
	for i = 1, config.getParameter("ammoAmount") do
		activeAmmoTypeList[#activeAmmoTypeList + 1] = ammoItemLoaded[config.getParameter("defaultAmmoIndexValue") or 1]
	end
	activeItem.setInstanceValue("activeAmmoTypeList",activeAmmoTypeList)
  end
  
  if config.getParameter("activeAmmoTypeList") then
	self:determineSingleLoadedAmmoVars()
  end
  
  if type(config.getParameter("consumeAmmoType")) == "table" and not config.getParameter("activeIndex") then
	self:setupNewValuesPostAmmo()
	activeItem.setInstanceValue("activeIndex",config.getParameter("defaultAmmoIndexValue") or 1)
  end
  
  if config.getParameter("weaponDeterioration") == true then
	self.weaponDeterioration = true
  end
  
  --sb.logInfo(sb.printJson(config.getParameter("activeAmmoTypeList")))
  
  --if config.getParameter("activeAmmoProjectileType") then self.activeAmmoProjectileType = config.getParameter("activeAmmoProjectileType") end
  --if config.getParameter("activeAmmoProjectileTypeMiss") then self.activeAmmoProjectileTypeMiss = config.getParameter("activeAmmoProjectileTypeMiss") end
  
  --activeItem.setCursor("/cursors/standard_aim4.cursor")
  --sb.logInfo(status.stat("ews_npcfirerate"))
  --sb.logInfo("hello world")
  
  
  -- important variables; dictates how the gun will function. replaces using seperate lua files for things like bolt action snipers, shotguns, changing fire modes, etc.
  --actually ignore this; apparently variables don't like to work. keeping this here for future reference
  
  --if not config.getParameter( "ejectProjectile" ) == nil and not config.getParameter( "shellProjectile" ) == nil then
  --self.ejectProjectileQuery = config.getParameter( "ejectProjectile" )
  --end
  
  --if not config.getParameter( "singleBulletLoad" ) == nil then
  --self.singleBulletLoad = config.getParameter( "singleBulletLoad" )
  --end
  
  --if not config.getParameter( "throwItemAttachment" ) == nil and not config.getParameter( "thrownProjectile" ) == nil then
  --self.throwItemAttachment = config.getParameter( "throwItemAttachment" )
  --end
  
  
  
  -- init detect switchFireModeAttachment toggle variable, enables switch ammo attachment.
  if config.getParameter( "switchFireModeAttachment" ) == true then
	self.inaccuracyVariable = self.inaccuracy
	self.fireTypeTemp = self.fireType
	--self.switchAmmo = true
	
	if config.getParameter( "fireTypeLastUsed" ) then
	self.fireType = config.getParameter( "fireTypeLastUsed" )
	end
  end
  
  
  -- init detect & enable consumeAmmo module if toggle is on and consumed item type is defined
  if config.getParameter( "consumeAmmoModule" ) == true and config.getParameter( "consumeAmmoType" ) then
	self.consumeAmmoToggle = true
	self.consumeAmmoType = config.getParameter( "consumeAmmoType" )
  end
  
  
  if config.getParameter( "npcGun" ) == true or not player then
  self.npcGun = true
  end
  
  -- init resets the empty sound "clicking" for when the player is out of ammunition completely.
  self.emptySoundPlayQuery = false
  
  
  -- init detect & enable missChance module for all guns unless specifically told not to. 
  -- also checks if "projectileTypeMiss" is configed to prevent any accidental crashes
  local primaryAbility = config.getParameter("primaryAbility")
  if config.getParameter( "missChanceToggle" ) == nil or config.getParameter( "missChanceToggle" ) == true and primaryAbility.projectileTypeMiss then
	self.missChanceToggle = true
  else
	self.missChanceToggle = false
  end
  
  --sets up missChance module variables
  if self.missChanceToggle == true then
  
  self.missChanceVar = 0
  
  --if no miss chance is specified, then this script automatically makes one.
  if not self.missChance then
  self.missChance = 25
  --miss chance is out of 100. 50/100 means 50% miss chance, 20/100 means 20% miss chance, etc.
  end
  end
  
  
  
  -- init detect & enable dynamicRecoil module for all guns unless specifically told not to
  if config.getParameter( "dynamicRecoil" ) == nil or config.getParameter( "dynamicRecoil" ) == true then
  self.dynamicRecoil = true
  end
  
  -- sets up variables for recoil module if no previous variables were already set up. this was done so people like me can be lazy.
  if self.dynamicRecoil == true then
  
  self.dynamicRecoilSteps = 0
  self.dynamicRecoilTimer = 0
  
  --sets up dynamic variable for miss chance if miss chance module is on
  if self.missChanceToggle == true then
	self.dynamicRecoilMissChance = 0
  end
  
  if not self.dynamicRecoilTemplate then
  
  -- defaults, consider as an ASSAULTRIFLE recoil template
  if not self.dynamicRecoilMaxSteps then
	self.dynamicRecoilMaxSteps = 7
  end
  if not self.dynamicRecoilMultiplier then
	self.dynamicRecoilMultiplier = 0.17 -- mutiplier based off of original inaccuracy
  end
  if not self.dynamicRecoilTickDuration then
	self.dynamicRecoilTickDuration = 0.17 -- seconds
  end
  if self.missChanceToggle == true and not self.dynamicRecoilMissMultiplier then
	self.dynamicRecoilMissMultiplier = 0.12 -- miss chance increase per recoil step
  end
  end
  
  -- SMG recoil template
  if self.dynamicRecoilTemplate == "SMG" then
	if not self.dynamicRecoilMaxSteps then
		self.dynamicRecoilMaxSteps = 9
	end
	if not self.dynamicRecoilMultiplier then
		self.dynamicRecoilMultiplier = 0.15 -- mutiplier based off of original inaccuracy
		--animator.playSound("switchAmmo")
	end
	if not self.dynamicRecoilTickDuration then
		self.dynamicRecoilTickDuration = 0.17 -- seconds
	end
	if self.missChanceToggle == true and not self.dynamicRecoilMissMultiplier then
		self.dynamicRecoilMissMultiplier = 0.15 -- miss chance increase per recoil step
	end
  end
  
  -- PISTOL recoil template
  if self.dynamicRecoilTemplate == "PISTOL" then
	if not self.dynamicRecoilMaxSteps then
		self.dynamicRecoilMaxSteps = 5
	end
	if not self.dynamicRecoilMultiplier then
		self.dynamicRecoilMultiplier = 0.75 -- mutiplier based off of original inaccuracy
	end
	if not self.dynamicRecoilTickDuration then
		self.dynamicRecoilTickDuration = 0.17 -- seconds
	end
	if self.missChanceToggle == true and not self.dynamicRecoilMissMultiplier then
		self.dynamicRecoilMissMultiplier = 0.5 -- miss chance increase per recoil step
	end
  end
  
  -- MACHINEGUN recoil template
  if self.dynamicRecoilTemplate == "MACHINEGUN" then
	if not self.dynamicRecoilMaxSteps then
		self.dynamicRecoilMaxSteps = 15
	end
	if not self.dynamicRecoilMultiplier then
		self.dynamicRecoilMultiplier = 0.2 -- mutiplier based off of original inaccuracy
		--animator.playSound("fire")
	end
	if not self.dynamicRecoilTickDuration then
		self.dynamicRecoilTickDuration = 0.2 -- seconds
	end
	if self.missChanceToggle == true and not self.dynamicRecoilMissMultiplier then
		self.dynamicRecoilMissMultiplier = 0.14 -- miss chance increase per recoil step
	end
  end
  
  -- backup default template in case of fucky-wucky.
  if not self.dynamicRecoilMaxSteps then
	self.dynamicRecoilMaxSteps = 7
  end
  if not self.dynamicRecoilMultiplier then
	self.dynamicRecoilMultiplier = 0.17 -- mutiplier based off of original inaccuracy
  end
  if not self.dynamicRecoilTickDuration then
	self.dynamicRecoilTickDuration = 0.17 -- seconds
  end
  if self.missChanceToggle == true and not self.dynamicRecoilMissMultiplier then
	self.dynamicRecoilMissMultiplier = 0.12 -- miss chance increase per recoil step
  end
  
  end
  
  
  if config.getParameter( "switchGun" ) == true and config.getParameter( "switchGunItem" ) then
  self.switchGun = true
  self.doubleTapShiftTimer = 0
  self.spawnReloadTimer = 0.25 --timer so switching guns won't automatically trigger a reload
  else
  self.spawnReloadTimer = 0.0
  end
  
  if config.getParameter( "holoToggle" ) == true then
	if config.getParameter( "holoToggleRequireStat" ) == true then
		if status.stat("ews_holovisor") == 1 then
			self.holoToggle = true
		end
	else
		self.holoToggle = true
	end
	animator.setAnimationState("holoState","inactive")
	if config.getParameter( "holoAmmoCounter" ) == true then
		self.holoAmmoCounterToggle = true
		animator.setAnimationState("holoAmmoState","0")
	end
	
	if config.getParameter( "holoEnabledState" ) == true and self.holoToggle == true then
		self.holoEnabled = true
	else
		self.holoEnabled = false
	end
  end
  
  --if not config.getParameter( "attachmentsAttached" ) then
	--local attachmentsAttachedtable = {}
	--attachmentsAttachedtable[#attachmentsAttachedtable+1]="ignore1"
	--attachmentsAttachedtable[#attachmentsAttachedtable+1]="ignore2"
	
	--activeItem.setInstanceValue("attachmentsAttached",attachmentsAttachedtable)
	--sb.logInfo(sb.printJson(config.getParameter( "attachmentsAttached" )))
  --end
  
  
  
  
  -- init detect & enable crouchAccuracy module for all guns unless specifically told not to
  if config.getParameter( "crouchAccuracy" ) == nil or config.getParameter( "crouchAccuracy" ) == true then
  self.crouchAccuracyToggle = true
  
  
  -- crouchAccuracy variables setup
  self.inaccuracyVariable = self.finalInaccuracy
  end
  
  
  
  
  
  -- sets up fire and reload detection variables
  self.weapon.reloading = 0
  self.weapon.firingquery = 0

  --updates base dps according to json schenanigans
  --self.weapon.baseDpsTooltipTemp = util.round(((self.baseDamage or (self.baseDps * self.fireTime))+self.bonusDps) * (self.baseDamageMultiplier or 1.0) * config.getParameter("damageLevelMultiplier"))
  
  --self.damagePerShotTooltipTemp = config.getParameter("tooltipFields")
  --self.damagePerShotTooltipTemp["damagePerShotLabel"]=self.weapon.baseDpsTooltipTemp
  --activeItem.setInstanceValue("tooltipFields",self.damagePerShotTooltipTemp)
  
  self.reloadHoldTimer = 0.0
  self.changeFireModeHoldTimer = 0.0
  
  self.cooldownTimer = self.fireTime
  
  self.fireHeld = false
  self.shiftHeldTmp = false
  self.weapon.onLeaveAbility = function()
    self.lasersightData = self.weapon:setStance(self.stances.idle)
  end
  animator.setParticleEmitterActive("hotsmoke", false )
  animator.setParticleEmitterActive("muzzleFlash", false)
  
  if config.getParameter("usesAttachments") == true then
  
  local attachmentConfig = config.getParameter( "sightAttachment" ) -- sets the sight data if an attachment is inserted
  if attachmentConfig then
	if attachmentConfig.attachmentImage then
		animator.setGlobalTag("sightImage", attachmentConfig.attachmentImage)
		world.sendEntityMessage(entity.id(), "queueRadioMessage", "ews_attachment")
		self.sightImage = attachmentConfig.attachmentImage
		
		if attachmentConfig.specialAttachmentConfig then						--sets up cursor scope stuff
			if attachmentConfig.specialAttachmentConfig.type == "scope" then
			self.scopedIn = attachmentConfig.specialAttachmentConfig.scopedIn or null
			
			self.scopeIn = attachmentConfig.specialAttachmentConfig.scopeIn or null
			self.scopeInTime = attachmentConfig.specialAttachmentConfig.scopeInTime or 0
			self.scopeOut = attachmentConfig.specialAttachmentConfig.scopeOut or null
			self.scopeOutTime = attachmentConfig.specialAttachmentConfig.scopeOutTime or 0
			end
		end
	else
		animator.setGlobalTag("sightImage", "")
	end
  end
  
 local attachmentConfig = config.getParameter( "barrelAttachment" ) -- sets the barrel data if an attachment is inserted
  if attachmentConfig then
	if attachmentConfig.attachmentImage then
		animator.setGlobalTag("barrelImage", attachmentConfig.attachmentImage)
		world.sendEntityMessage(entity.id(), "queueRadioMessage", "ews_attachment")
		self.barrelImage = attachmentConfig.attachmentImage
		
		if attachmentConfig.specialAttachmentConfig then						-- sets up suppressor stuff
			if attachmentConfig.specialAttachmentConfig.type == "suppressor" then
			self.suppressed = true
				if config.getParameter("fireShellProjectile") and not config.getParameter("fireShellProjectile") == attachmentConfig.specialAttachmentConfig.fireShellProjectile then
					activeItem.setInstanceValue("fireShellProjectile",attachmentConfig.specialAttachmentConfig.fireShellProjectile)
				end
			elseif attachmentConfig.specialAttachmentConfig.type == "flashhider" then
			self.flashhider = true
			else
			self.flashhider = false
			self.suppressed = false
			end
		else
		self.flashhider = false
		self.suppressed = false
		end
	else
		animator.setGlobalTag("barrelImage", "")
	end
  end
  
  --self.laserSightAttached = false
  
  local attachmentConfig = config.getParameter( "underbarrelAttachment" ) -- sets the underbarrel data if an attachment is inserted
  local animationCustom = config.getParameter( "animationCustom" )
  if attachmentConfig then
	if attachmentConfig.attachmentImage then
		animator.setGlobalTag("underbarrelImage", attachmentConfig.attachmentImage)
		world.sendEntityMessage(entity.id(), "queueRadioMessage", "ews_attachment")
		self.underbarrelImage = attachmentConfig.attachmentImage
	else
		animator.setGlobalTag("underbarrelImage", "")
	end
	
	activeItem.setScriptedAnimationParameter("lasersight", {})
	
	if attachmentConfig.specialAttachmentConfig then
		if animationCustom.lights then
		if animationCustom.lights.flashlightAttachment then				-- sets up flashlight/laser sight stuff
			if not attachmentConfig.specialAttachmentConfig.type == "light" then
				animator.setLightActive("flashlightAttachment", false)
			end
		end
		end
		
		if attachmentConfig.specialAttachmentConfig.type == "light" then
			
			local lightConfigPos = attachmentConfig.specialAttachmentConfig.lightConfig.offset
			local underbarrelPartPos = animationCustom.animatedParts.parts.underbarrel.properties.offset
			if not animationCustom.lights.flashlightAttachment.position then						--sends radio msg w dev note about flashlight wack
				world.sendEntityMessage(entity.id(), "queueRadioMessage", "ews_flashlightattachment")
			end
			attachmentConfig.specialAttachmentConfig.lightConfig.position = {lightConfigPos[1] + underbarrelPartPos[1],lightConfigPos[2] + 	underbarrelPartPos[2]}								--sets up flashlight offsets
			animationCustom.lights.flashlightAttachment = attachmentConfig.specialAttachmentConfig.lightConfig
		
			activeItem.setInstanceValue("animationCustom",animationCustom)							--updates flashlight directly to activeitem
		end
		
		if attachmentConfig.specialAttachmentConfig.type == "lasersight" then
		
			local resultLaserSight = attachmentConfig.specialAttachmentConfig.lasersightConfig
			self.laserSightAttached = true
			activeItem.setScriptedAnimationParameter("lasersight", {resultLaserSight})
			
			if attachmentConfig.specialAttachmentConfig.transformationGroupWeapon == true then
				self.lasersightTransformationGroupWeapon = true
			end
			
			if animationCustom.lights then
				if animationCustom.lights.flashlightAttachment then
					animator.setLightActive("flashlightAttachment", false)			--resets state of flashlight
				end
			end
		end
		
		self.grenadelauncherAttachment = false
		if attachmentConfig.specialAttachmentConfig.type == "grenadelauncher" then					--grenade launcher config
			self.grenadelauncherAttachment = true
			self.altFireTime = attachmentConfig.specialAttachmentConfig.grenadelauncherConfig.altFireTime
			animator.setAnimationState("grenadeLauncher", "armed")
			
			self.altInaccuracy = attachmentConfig.specialAttachmentConfig.grenadelauncherConfig.altInaccuracy
			self.projectileTypeGrenade = attachmentConfig.specialAttachmentConfig.grenadelauncherConfig.projectileTypeGrenade
			self.projectileTypeGrenadeCount =  attachmentConfig.specialAttachmentConfig.grenadelauncherConfig.projectileTypeGrenadeCount
			self.projectileTypeGrenadeConfig = attachmentConfig.specialAttachmentConfig.grenadelauncherConfig.projectileTypeGrenadeConfig
			self.altMagazine = attachmentConfig.specialAttachmentConfig.grenadelauncherConfig.altMagazine
			
			local grenadeMuzzleOffset = attachmentConfig.specialAttachmentConfig.grenadelauncherConfig.grenadeMuzzleOffset
			local muzzleOffset = config.getParameter("muzzleOffset")
			self.grenadeMuzzleOffset = {grenadeMuzzleOffset[1] + muzzleOffset[1], grenadeMuzzleOffset[2] + muzzleOffset[2]}
			
		end
	else
		if animationCustom.lights then
			if animationCustom.lights.flashlightAttachment then
			animator.setLightActive("flashlightAttachment", false)			--resets state of flashlight
			end
		end
	end
  end
  
  local attachmentConfig = config.getParameter( "stockAttachment" ) -- sets the stock data if an attachment is inserted
  if attachmentConfig then
	if attachmentConfig.attachmentImage then
		animator.setGlobalTag("stockImage", attachmentConfig.attachmentImage)
		world.sendEntityMessage(entity.id(), "queueRadioMessage", "ews_attachment")
		self.stockImage = attachmentConfig.attachmentImage
	else
		animator.setGlobalTag("stockImage", "")
	end
  end
  
  
  end
  self:setupInventoryIcon()
  
  --sb.logInfo(sb.printJson(inventoryIcon))
  
  --local animationCustom2 = config.getParameter( "animationCustom" )
  --animationCustom2.lights.flashlight = {}
  --activeItem.setInstanceValue("animationCustom",animationCustom2)
  
  self:setFinalVariables()
end

function GunFire:setupInventoryIcon()
  if config.getParameter( "usesAttachments" ) == true or config.getParameter("magazineImages") then			--sets up dynamic inventoryIcon if attachments are involved/multiple magazine images
  local inventoryIcon = config.getParameter( "inventoryIcon" )
  if not config.getParameter( "inventoryIconOriginal" ) then
	activeItem.setInstanceValue("inventoryIconOriginal",config.getParameter( "inventoryIcon" ))
  end
  
  local partImgs = {}
  partImgs["main"] = config.getParameter( "inventoryIconOriginal" )
  --sb.logInfo(sb.printJson(partImgs["main"]))
  partImgs["sight"] = self.sightImage
  --sb.logInfo(sb.printJson(partImgs["sight"]))
  partImgs["barrel"] = self.barrelImage
  if self.grenadelauncherAttachment == true then
	local attachmentConfig = config.getParameter( "underbarrelAttachment" ) -- sets the underbarrel data if an attachment is inserted
	self.underbarrelImage = attachmentConfig.attachmentImage..":armed.1"
	--self.underbarrelImage = self.underbarrelImage..":armed.1"
  end
  partImgs["underbarrel"] = self.underbarrelImage
  partImgs["stock"] = self.stockImage
  
  if type(config.getParameter("consumeAmmoType")) == "table" and config.getParameter("magazineImages") then
  local magazineImageChosen = config.getParameter("magazineImages")
  magazineImageChosen = magazineImageChosen[config.getParameter("activeIndex") or 1]
  partImgs["magazine"] = magazineImageChosen..":reload.3"
  animator.setGlobalTag("magazineImage", magazineImageChosen)
  end
  
  
  local animationCustom = config.getParameter( "animationCustom" )
  --animationCustom.animatedParts.parts
  
  local animationProperties = animationCustom.animatedParts.parts
  
  
  
  local partImagePositions = {}
  partImagePositions["main"] = self:determinePartOffset(animationProperties.middle.properties.offset or {0,0},partImgs["main"])
  
  if partImgs["sight"] then
  partImagePositions["sight"] = self:determinePartOffset(animationProperties.sight.properties.offset or {0,0},partImgs["sight"])
  end
  if partImgs["barrel"] then
  partImagePositions["barrel"] = self:determinePartOffset(animationProperties.barrel.properties.offset or {0,0},partImgs["barrel"])
  end
  if partImgs["underbarrel"] then
  partImagePositions["underbarrel"] = self:determinePartOffset(animationProperties.underbarrel.properties.offset or {0,0},partImgs["underbarrel"])
  end
  if partImgs["stock"] then
  partImagePositions["stock"] = self:determinePartOffset(animationProperties.stock.properties.offset or {0,0},partImgs["stock"])
  end
  
  if partImgs["magazine"] then
  partImagePositions["magazine"] = self:determinePartOffset(animationProperties.magazine.properties.offset or {0,0},partImgs["magazine"])
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
		
		--sb.logInfo(sb.printJson(inventoryIcon))
		activeItem.setInstanceValue("inventoryIcon",inventoryIcon)
  end
end

function GunFire:determinePartOffset(offset,img)
  local imageOffset = {0,0}
  local baseOffset = config.getParameter( "baseOffset" )
  imageOffset = {8 * (offset[1] + baseOffset[1]),8 * (offset[2] + baseOffset[2])}
  return imageOffset
end

function GunFire:modifyFinalVariablesOld(input,modifier,modifierType) -- old function here just in case stuff happens
	--modifierType = (modifierType or "additive")
	--sb.logInfo(sb.printJson(input)..", "..sb.printJson(modifier)..", "..sb.printJson(modifierType))

	if modifierType == "additive" then
	return input + modifier
	end
	
	if modifierType == "multiplicative" then
	return input * modifier
	end
	
	if modifierType == "set" then
		if modifier == -1 then
			return input
		else
			return modifier
		end
	end
end

function GunFire:modifyFinalVariables(input,modifier,modifierType)
	--modifierType = (modifierType or "additive")
	--sb.logInfo(sb.printJson(input)..", "..sb.printJson(modifier)..", "..sb.printJson(modifierType))

	if modifierType == "additive" then
	input[2] = input[2] + modifier
	end
	
	if modifierType == "multiplicative" then
		--if not modifier == 1 then
		input[3] = input[3] * modifier
		--end
		--sb.logInfo(sb.printJson(input[3]))
		--sb.logInfo(sb.printJson(input[3]))
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

function GunFire:fillVarTableFields(tab)
	tab[2] = 0
	tab[3] = 1
	tab[4] = 0
end

function GunFire:setupModifiers(parameterName)
  local attachmentConfig = config.getParameter(parameterName)
  if attachmentConfig then
  if attachmentConfig.attachmentAttached == true then
	local attachmentBonusType = attachmentConfig.attachmentBonusType
	--sb.logInfo(sb.printJson(attachmentConfig))
	local attachmentBonuses = attachmentConfig.attachmentBonuses
	--sb.logInfo(sb.printJson(attachmentBonuses))
	--self:modifyFinalVariables(self.temp,attachmentBonuses[1],attachmentBonusType)
	
	--sb.logInfo(sb.printJson("finalInaccuracy"))
	self:modifyFinalVariables(self.finalInaccuracy,attachmentBonuses[1],attachmentBonusType)
	--sb.logInfo(sb.printJson("finalInaccuracyCrouch"))
	self:modifyFinalVariables(self.finalInaccuracyCrouch,attachmentBonuses[2],attachmentBonusType)
	--sb.logInfo(sb.printJson("finalMissChance"))
	self:modifyFinalVariables(self.finalMissChance,attachmentBonuses[3],attachmentBonusType)
	--sb.logInfo(sb.printJson("finalMissChanceCrouch"))
	self:modifyFinalVariables(self.finalMissChanceCrouch,attachmentBonuses[4],attachmentBonusType)
	--sb.logInfo(sb.printJson("finalDynamicRecoilMaxSteps"))
	self:modifyFinalVariables(self.finalDynamicRecoilMaxSteps,attachmentBonuses[5],attachmentBonusType)
	--sb.logInfo(sb.printJson("finalDynamicRecoilMultiplier"))
	self:modifyFinalVariables(self.finalDynamicRecoilMultiplier,attachmentBonuses[6],attachmentBonusType)
	--sb.logInfo(sb.printJson("finalDynamicRecoilTickDuration"))
	self:modifyFinalVariables(self.finalDynamicRecoilTickDuration,attachmentBonuses[7],attachmentBonusType)
	--sb.logInfo(sb.printJson("finalDynamicRecoilMissMultiplier"))
	self:modifyFinalVariables(self.finalDynamicRecoilMissMultiplier,attachmentBonuses[8],attachmentBonusType)
	--sb.logInfo(sb.printJson(self.finalInaccuracy))
  end
  
  if attachmentConfig.attachmentBonusesAlt then
	local attachmentBonusType = attachmentConfig.attachmentBonusType
	local attachmentBonusesAlt = attachmentConfig.attachmentBonusesAlt
	
	--sb.logInfo(sb.printJson("finalAltInaccuracy"))
	self:modifyFinalVariables(self.finalAltInaccuracy,attachmentBonusesAlt[1],attachmentBonusType)
	--sb.logInfo(sb.printJson("finalAltInaccuracyCrouch"))
	self:modifyFinalVariables(self.finalAltInaccuracyCrouch,attachmentBonusesAlt[1],attachmentBonusType)
	--sb.logInfo(sb.printJson("finalAltMissChance"))
	self:modifyFinalVariables(self.finalAltMissChance,attachmentBonusesAlt[1],attachmentBonusType)
	--sb.logInfo(sb.printJson("finalAltMissChanceCrouch"))
	self:modifyFinalVariables(self.finalAltMissChanceCrouch,attachmentBonusesAlt[1],attachmentBonusType)
  end
  end
end

function GunFire:finalizeFinalVariable(variable)
	local variableStore = variable[1]
	if variable[4] > 0 then
		variableStore = variable[4]
	end
	if variable[3] == 0 then variable[3] = 1 end
	variable = (variableStore + variable[2]) * variable[3]
	return variable
end

function GunFire:setFinalVariables()
	self.finalInaccuracy = {}
	self.finalInaccuracyCrouch = {}
	self.finalMissChance = {}
	self.finalMissChanceCrouch = {}
	self.finalDynamicRecoilMaxSteps = {}
	self.finalDynamicRecoilMultiplier = {}
	self.finalDynamicRecoilTickDuration = {}
	self.finalDynamicRecoilMissMultiplier = {}
	self.finalAltInaccuracy = {}
	self.finalAltInaccuracyCrouch = {}
	self.finalAltMissChance = {}
	self.finalAltMissChanceCrouch = {}
	
	
	self.finalInaccuracy[1] = self.inaccuracy
	self.finalInaccuracyCrouch[1] = (self.crouchInaccuracy or self.finalInaccuracy[1] * 0.4)
	self.finalMissChance[1] = (self.missChance or 0)
	self.finalMissChanceCrouch[1] = (self.missChanceCrouch or self.finalMissChance[1] * 0.4)
	self.finalDynamicRecoilMaxSteps[1] = self.dynamicRecoilMaxSteps or 0
	self.finalDynamicRecoilMultiplier[1] = self.dynamicRecoilMultiplier or 0
	self.finalDynamicRecoilTickDuration[1] = self.dynamicRecoilTickDuration or 0
	self.finalDynamicRecoilMissMultiplier[1] = self.dynamicRecoilMissMultiplier or 0
	
	
	self.finalAltInaccuracy[1] = (self.altInaccuracy or self.finalInaccuracy[1])
	self.finalAltInaccuracyCrouch[1] = (self.altCrouchInaccuracy or self.finalAltInaccuracy[1] * 0.4)
	self.finalAltMissChance[1] = (self.altMissChance or self.finalMissChance[1])
	self.finalAltMissChanceCrouch[1] = (self.altMissChanceCrouch or self.finalAltMissChance[1] * 0.4)
	
	self:fillVarTableFields(self.finalInaccuracy)
	self:fillVarTableFields(self.finalInaccuracyCrouch)
	self:fillVarTableFields(self.finalMissChance)
	self:fillVarTableFields(self.finalMissChanceCrouch)
	self:fillVarTableFields(self.finalDynamicRecoilMaxSteps)
	self:fillVarTableFields(self.finalDynamicRecoilMultiplier)
	self:fillVarTableFields(self.finalDynamicRecoilTickDuration)
	self:fillVarTableFields(self.finalDynamicRecoilMissMultiplier)
	
	self:fillVarTableFields(self.finalAltInaccuracy)
	self:fillVarTableFields(self.finalAltInaccuracyCrouch)
	self:fillVarTableFields(self.finalAltMissChance)
	self:fillVarTableFields(self.finalAltMissChanceCrouch)
	
	self:setupModifiers("sightAttachment")
	self:setupModifiers("barrelAttachment")
	self:setupModifiers("underbarrelAttachment")
	self:setupModifiers("stockAttachment")
	self:setupModifiers("miscAttachment")
	-- variable[1] = original variable, variable[2] = collective additive bonuses, variable[3] = collective multiplicative bonus, variable[4] = largest set value bonus
	
	--sb.logInfo(sb.printJson(self.finalInaccuracy))
	self.finalInaccuracy = self:finalizeFinalVariable(self.finalInaccuracy)
	--sb.logInfo(sb.printJson(self.finalInaccuracy))
	--sb.logInfo("yes")
	self.finalInaccuracyCrouch = self:finalizeFinalVariable(self.finalInaccuracyCrouch)
	self.finalMissChance = self:finalizeFinalVariable(self.finalMissChance)
	self.finalMissChanceCrouch = self:finalizeFinalVariable(self.finalMissChanceCrouch)
	self.finalDynamicRecoilMaxSteps = self:finalizeFinalVariable(self.finalDynamicRecoilMaxSteps)
	self.finalDynamicRecoilMultiplier = self:finalizeFinalVariable(self.finalDynamicRecoilMultiplier)
	self.finalDynamicRecoilTickDuration = self:finalizeFinalVariable(self.finalDynamicRecoilTickDuration)
	self.finalDynamicRecoilMissMultiplier = self:finalizeFinalVariable(self.finalDynamicRecoilMissMultiplier)
	
	self.finalAltInaccuracy = self:finalizeFinalVariable(self.finalAltInaccuracy)
	self.finalAltInaccuracyCrouch = self:finalizeFinalVariable(self.finalAltInaccuracyCrouch)
	self.finalAltMissChance = self:finalizeFinalVariable(self.finalAltMissChance)
	self.finalAltMissChanceCrouch = self:finalizeFinalVariable(self.finalAltMissChanceCrouch)
end

function GunFire:laserSightConfig()
	if self.laserSightAttached == true then
	local attachmentConfig = config.getParameter( "underbarrelAttachment" )
	local resultLaserSight = attachmentConfig.specialAttachmentConfig.lasersightConfig
		
	if self.lasersightTransformationGroupWeapon == true then
		resultLaserSight.angle = self.lasersightData[2] or 0
		local laseroffset = self.lasersightData[1] or {0,0}
		local animationCustom = config.getParameter("animationCustom") or {}
		local baseOffset = {0,0} --config.getParameter("baseOffset") or {0,0}
		local partOffset = animationCustom.animatedParts.parts.underbarrel.properties.offset
		resultLaserSight.offset = {baseOffset[1] + partOffset[1] + laseroffset[1] + resultLaserSight.originalOffset[1],baseOffset[1] + partOffset[2] +laseroffset[2] + resultLaserSight.originalOffset[2]}
	end
		
	activeItem.setScriptedAnimationParameter("lasersight", {resultLaserSight})
	end
end

function GunFire:cursor() -- cursor stuff for when crouching/not crouching; main feature is diff. cursors for scopes n stuff.
	if self.crouchAccuracyToggle == true then
	if self.scopedIn then															-- special crouch-based cursors
		if mcontroller.crouching() then
			if not self.scopeOutMarker == false then self.scopeOutMarker = false end
			
			if self.scopeIn then
				if not self.scopeInMarker == true then
					self.scopeInMarker = true
					self.scopeTimer = self.scopeInTime
					activeItem.setCursor(self.scopeIn)
				else
					if self.scopeTimer == 0  then
					activeItem.setCursor(self.scopedIn)
					end
				end
			else
			
			activeItem.setCursor(self.scopedIn)
			end
		else
			if not self.scopeInMarker == false then self.scopeInMarker = false end
			
			if self.scopeOut then
				if not self.scopeOutMarker == true then
					self.scopeOutMarker = true
					self.scopeTimer = self.scopeOutTime
					activeItem.setCursor(self.scopeOut)
				else
					if self.scopeTimer == 0 then
					activeItem.setCursor("/cursors/reticle0.cursor")
					end
				end
			else
			activeItem.setCursor("/cursors/reticle1.cursor")
			end
		end
	else
		if mcontroller.crouching() then
		activeItem.setCursor("/cursors/reticle0.cursor")
		else
		activeItem.setCursor("/cursors/reticle1.cursor")
		end
	end
	end
end

function GunFire:holographics() --holo stuff for holographic display stuff. holo features will need to be expanded upon laters.
	
	--first set of logic circuts
	if self.weapon.currentAbility == nil
    and self.reloadHoldTimer == 0 and self.reloadHeld == true
	and self.holoToggle == true 
	and self.holoTogglerState == false then
		if not self.holoEnabled == true then
		self.holoEnabled = true
		activeItem.setInstanceValue("holoEnabledState",self.holoEnabled)
		else
		self.holoEnabled = false
		animator.setAnimationState("holoState","inactive")
		if self.holoAmmoCounterToggle == true then
		animator.setAnimationState("holoAmmoState","0")
		activeItem.setInstanceValue("holoEnabledState",self.holoEnabled)
		end
		end
	end
	
	--second set of logic circuts
	if self.holoEnabled == true then
	animator.setAnimationState("holoState","active")
	
		if self.holoAmmoCounterToggle == true then
			if self.weapon.reloading == 1 then
				animator.setAnimationState("holoAmmoState","0")
			else
				if self.weapon.ammoAmount == config.getParameter("ammoMax") or self.weapon.ammoAmount/config.getParameter("ammoMax") > 0.9 then
					animator.setAnimationState("holoAmmoState","100")
				elseif self.weapon.ammoAmount/config.getParameter("ammoMax") > 0.8 then
					animator.setAnimationState("holoAmmoState","90")
				elseif self.weapon.ammoAmount/config.getParameter("ammoMax") > 0.7 then
					animator.setAnimationState("holoAmmoState","80")
				elseif self.weapon.ammoAmount/config.getParameter("ammoMax") > 0.6 then
					animator.setAnimationState("holoAmmoState","70")
				elseif self.weapon.ammoAmount/config.getParameter("ammoMax") > 0.5 then
					animator.setAnimationState("holoAmmoState","60")
				elseif self.weapon.ammoAmount/config.getParameter("ammoMax") > 0.4 then
					animator.setAnimationState("holoAmmoState","50")
				elseif self.weapon.ammoAmount/config.getParameter("ammoMax") > 0.3 then
					animator.setAnimationState("holoAmmoState","40")
				elseif self.weapon.ammoAmount/config.getParameter("ammoMax") > 0.2 then
					animator.setAnimationState("holoAmmoState","30")
				elseif self.weapon.ammoAmount/config.getParameter("ammoMax") > 0.1 then
					animator.setAnimationState("holoAmmoState","20")
				elseif self.weapon.ammoAmount/config.getParameter("ammoMax") > 0.0 then
					animator.setAnimationState("holoAmmoState","10")
				elseif self.weapon.ammoAmount/config.getParameter("ammoMax") == 0.0 then
					animator.setAnimationState("holoAmmoState","0")
				end
			end
		end
	end
	
	--old scripts, placing here incase they end up being useful later.
	--self.holoTogglerState = shiftHeld
	
	--self.upHeld = mcontroller.up()
	--if self.weapon.reloading > 0.999 then
		--activeItem.setCursor("/cursors/aim_ews9.cursor")
	--else
		--if self.weapon.ammoAmount == config.getParameter("ammoMax") then
			--activeItem.setCursor("/cursors/aim_ews0.cursor")
		--elseif self.weapon.ammoAmount/config.getParameter("ammoMax") > 0.875 then
			--activeItem.setCursor("/cursors/aim_ews1.cursor")
		--elseif self.weapon.ammoAmount/config.getParameter("ammoMax") > 0.75 then
			--activeItem.setCursor("/cursors/aim_ews2.cursor")
		--elseif self.weapon.ammoAmount/config.getParameter("ammoMax") > 0.625 then
			--activeItem.setCursor("/cursors/aim_ews3.cursor")
		--elseif self.weapon.ammoAmount/config.getParameter("ammoMax") > 0.5 then
			--activeItem.setCursor("/cursors/aim_ews4.cursor")
		--elseif self.weapon.ammoAmount/config.getParameter("ammoMax") > 0.375 then
			--activeItem.setCursor("/cursors/aim_ews5.cursor")
		--elseif self.weapon.ammoAmount/config.getParameter("ammoMax") > 0.25 then
			--activeItem.setCursor("/cursors/aim_ews6.cursor")
		--elseif self.weapon.ammoAmount/config.getParameter("ammoMax") > 0.125 then
			--activeItem.setCursor("/cursors/aim_ews7.cursor")
		--elseif self.weapon.ammoAmount/config.getParameter("ammoMax") > 0.0 or self.weapon.ammoAmount == 0 then
			--activeItem.setCursor("/cursors/aim_ews8.cursor")
		--end
	--end
end

function GunFire:switchGunSaveDat()
			--base parameters
			local params = {ammoAmount = config.getParameter( "ammoAmount" ), ammoMax = config.getParameter( "ammoMax" )}
			
			---------------------------------------------------------------------------		--attachment storage stuff
			local sightAttachment = config.getParameter( "sightAttachment" ) or null
			if sightAttachment then params.sightAttachment = sightAttachment end
			
			local barrelAttachment = config.getParameter( "barrelAttachment" ) or null
			if barrelAttachment then params.barrelAttachment = barrelAttachment end
			
			local underbarrelAttachment = config.getParameter( "underbarrelAttachment" ) or null
			if underbarrelAttachment then params.underbarrelAttachment = underbarrelAttachment end
			
			local stockAttachment = config.getParameter( "stockAttachment" ) or null
			if stockAttachment then params.stockAttachment = stockAttachment end
			
			local miscAttachment = config.getParameter( "miscAttachment" ) or null
			if miscAttachment then params.miscAttachment = miscAttachment end
			---------------------------------------------------------------------------
			
			local activeAmmoProjectileType = config.getParameter("activeAmmoProjectileType") or null
			if activeAmmoProjectileType then params.activeAmmoProjectileType = activeAmmoProjectileType end
			
			local activeAmmoProjectileTypeMiss = config.getParameter("activeAmmoProjectileTypeMiss") or null
			if activeAmmoProjectileTypeMiss then params.activeAmmoProjectileTypeMiss = activeAmmoProjectileTypeMiss end
			
			local currentDamageAmount = config.getParameter("currentDamageAmount") or null
			if currentDamageAmount then params.currentDamageAmount = currentDamageAmount end
			
			---------------------------------------------------------------------------				--magazine stuff
			local magazineProjectile = config.getParameter( "magazineProjectile" ) or null
			if magazineProjectile then params.magazineProjectile = magazineProjectile end
			
			local magazineProjectileConfig = config.getParameter( "magazineProjectileConfig" ) or null
			if magazineProjectileConfig then params.magazineProjectileConfig = magazineProjectileConfig end
			
			local magazineProjectilePartial = config.getParameter( "magazineProjectilePartial" ) or null
			if magazineProjectilePartial then params.magazineProjectilePartial = magazineProjectilePartial end
			
			local magazineProjectilePartialConfig = config.getParameter( "magazineProjectilePartialConfig" ) or null
			if magazineProjectilePartialConfig then params.magazineProjectilePartialConfig = magazineProjectilePartialConfig end
			
			local fireShellProjectile = config.getParameter( "fireShellProjectile" ) or null
			if fireShellProjectile then params.fireShellProjectile = fireShellProjectile end
			
			local fireShellProjectileConfig = config.getParameter( "fireShellProjectileConfig" ) or null
			if fireShellProjectileConfig then params.fireShellProjectileConfig = fireShellProjectileConfig end
			
			local activeIndex = config.getParameter( "activeIndex" ) or null
			if activeIndex then params.activeIndex = activeIndex end
			
			local activeAmmoProjectileCount = config.getParameter("activeAmmoProjectileCount") or null
			if activeAmmoProjectileCount then params.activeAmmoProjectileCount = activeAmmoProjectileCount end
			
			local activeAmmoTypeList = config.getParameter("activeAmmoTypeList") or null
			if activeAmmoTypeList then params.activeAmmoTypeList = activeAmmoTypeList end
			
			---------------------------------------------------------------------------				--durability stuff, jamming n such
			local weaponDeterioration = config.getParameter("weaponDeterioration") or null
			if weaponDeterioration == true then 
				params.weaponDurability = config.getParameter("weaponDurability") 
				params.weaponDeterioration = weaponDeterioration
			end
			
			--jammed data carry over
			local weaponJammed = config.getParameter("weaponJammed") or null
			if weaponJammed then params.weaponJammed = weaponJammed end
			---------------------------------------------------------------------------
			
			local itemGive = {name = self.switchGunItem, count = 1, parameters = params }
			
			return itemGive
end

function GunFire:update(dt, fireMode, shiftHeld)
	WeaponAbility.update(self, dt, fireMode, shiftHeld)
	
	--does durability calcs
	if self.weaponDeterioration == true and not self.npcGun == true then
		local weaponDurabilityPercentage = echoutil.round(1,(config.getParameter("weaponDurability") / config.getParameter("weaponDurabilityMax")) * 100)
		self.weaponNegativeEffectResult = (100 - weaponDurabilityPercentage) / 100
		self.weaponNegativeEffectResultFinal = 1 + (self.weaponNegativeEffectResult * (config.getParameter("weaponDurabilityEffectMultiplier") or 1))
		--activeItem.setInstanceValue("weaponNegativeEffectResult",self.weaponNegativeEffectResult) -- don't see a reason why result needs to have its value displayed in gun json, could just use other debug methods instead.
	end
	
	if self.laserSightAttached == true then
		self:laserSightConfig()
	end
	
	--scope/cursor scripts
	self:cursor()
	if self.scopeTimer then
		self.scopeTimer = math.max(0, self.scopeTimer - self.dt)
	end
	
	if config.getParameter( "holoToggleRequireStat" ) == true and status.stat("ews_holovisor") == 1 and not self.holoToggle == true then
		self.holoToggle = true
	end
	
	
	--holographics scripts
	if self.reloadHoldTimer > 0
	and not shiftHeld
	and self.holoToggle == true then
	self.holoTogglerState = true
	else
	self.holoTogglerState = false
	end
	self:holographics()
	
		
	--method to automatically designate a gun as a "npcGun"
	if status.stat("ews_npcgun") == 1 
	and not self.npcGun == true then
		self.npcGun = true
	end
	
	--enables the weapon to have infinite spare ammo, albiet with a 40% reduction in damage output.
	if status.stat("ews_infammo") == 1 
	and not self.infAmmo == true 
	and not config.getParameter( "alwaysUseAmmo" ) == true then
		self.infAmmo = true
	end
	
	
	
	--if miss projectile no existo and toggle is enabled, then disable toggle to prevent le crasho. failsafe.
	if not self.projectileTypeMiss and self.missChanceToggle == true then
		self.missChanceToggle = false
	end
	
	
	-- dynamic recoil timer
	if self.dynamicRecoil == true then
		self.dynamicRecoilTimer = math.max(0, self.dynamicRecoilTimer - self.dt)
	
	
	
		-- ticks down recoil after time
		if self.dynamicRecoilTimer == 0 then
			if self.dynamicRecoilSteps  > 0 then
				self.dynamicRecoilSteps  = self.dynamicRecoilSteps  - 1
				self.dynamicRecoilTimer = self.dynamicRecoilTickDuration
			end
		end
	
	end
	
	--if switch gun module is enabled and shift+primary fire, then "switches" the current gun into the other specified gun.
	--more or less spawns another gun then original gun suicides.
	--don't do suicide kids.
	--I do not promote nor do I encourage suicide
	--kek plz don't sue me for that.
	
	--timer for the double-tap shift function
	if config.getParameter( "switchGun" ) == true and not self.jammed == true and not self.unjamming == true then
		self.doubleTapShiftTimer = math.max(0, self.doubleTapShiftTimer - self.dt)
		self.spawnReloadTimer = math.max(0, self.spawnReloadTimer - self.dt)
	end
	
	
	if config.getParameter( "switchGun" ) == true and not self.jammed == true and not self.unjamming == true then
		if shiftHeld and self.shiftHoldQuery == false and self.doubleTapShiftTimer == 0 then
			self.shiftHoldQuery = true
			self.doubleTapShiftTimer = 0.25
		end
			
		if shiftHeld and self.shiftHoldQuery == false and self.doubleTapShiftTimer > 0 then
			
			self.switchingGuns = true
			self.switchGunItem = config.getParameter( "switchGunItem" )
			item.consume(1)
			
			local targItem = self:switchGunSaveDat()
			player.giveItem(targItem)
			
			animator.stopAllSounds("switchAmmo")
			--animator.stopSound("switchAmmo")
			
		end
		
		-- here to prevent player from holding down shift for "too long" so instantly hitting shift won't cause the gun to change "grips"
		if not shiftHeld then
		self.shiftHoldQuery = false
		end
	end
	
	
	
	
	
	--old switchGun method which involved holding shift and primary fire. This was an issue because parrying w the one-handed weeb katana was done by holding shift, so this caused the parry/shield ability of the katana to be completely defunct when paired with a EWS sidearm.
	--NOTE: new method still defunct when trying to use the weeb katana base, but whatever.
	--if config.getParameter( "switchGun" ) == true then
		--if shiftHeld and self.fireMode == (self.activatingFireMode or self.abilitySlot) then
			--self.switchingGuns = true
			--self.switchGunItem = config.getParameter( "switchGunItem" )
			--local itemGive = {name=self.switchGunItem, count=1, parameters = nil }
			--player.giveItem(itemGive)
			--sb.logInfo("%s",item)
			--item.consume(1)
		--end
	--end
	
  
	-- automatically reload gun if its empty without having the npc fire said gun.
	if self.npcGun == true and (self.weapon.ammoAmount == 0) and not (self.weapon.reloading == 1) and not (self.weapon.firingquery == 1) 
	and not self.switchingGuns == true then--this one is so guns don't reload when you "switch" it.
		self:setState(self.reload)
	end
	
	
	
	-----------------------------------------------------------------------------------------------------------------------------------------------------------------
	---NOTE TO SELF- BELOW STUFF INVOLVES MANUAL RELOADING. HOLY SHIT THIS CODE IS MESSY - 3-1-21
	-- like seriously what the fuck are these logic scripts? half of the comments are wrong or something
	-- A C K
	-- clean up later when mostly done with EWS cus I can't be arsed to clean this up.  ETA unknown.
	-----------------------------------------------------------------------------------------------------------------------------------------------------------------
	
	if config.getParameter( "holoToggle" ) == true then
	
	-- if player only taps reload, then player will reload normally
	if self.reloadHoldTimer > 0 and not shiftHeld
	and not self.unjamming == true --for jamming scripts
	and not self.jammed == true
	and (self.weapon.ammoAmount < config.getParameter("ammoMax",1)) and not (self.weapon.reloading == 1) and not (self.weapon.firingquery == 1) 
	and self.spawnReloadTimer == 0 then
		if config.getParameter( "switchGun" ) == true then
			if not self.switchingGuns == true then--this one is so guns don't reload when you "switch" it.
				self:setState(self.reload)
				self.reloadHeld = false
			end
		else
		self:setState(self.reload)
		self.reloadHeld = false
		end
	end

	-- reload manually
	if config.getParameter( "switchGun" ) == true then
	
		--normal manual reload, but some extra variables are run through to ensure no bugs. Hopefully.
		if shiftHeld then -- this one is so guns don't immediately reload upon switch, about half second delay before manual reload is re-enabled.
			if self.reloadHoldTimer == 0 and self.reloadHeld == true
			and not self.jammed == true and not self.unjamming == true then --for jamming scripts
				--if shiftHeld and (self.weapon.ammoAmount < config.getParameter("ammoMax",1)) and not (self.weapon.reloading == 1) and not (self.weapon.firingquery == 1) 
		--and not self.switchingGuns == true --this one is so guns don't reload when you "switch" it.
		--and self.spawnReloadTimer == 0 then
					--self:setState(self.reload)
					--self.reloadHeld = false
				--else
					self.reloadHeld = false
				--end
			elseif self.reloadHoldTimer == 0
			and not self.unjamming == true --for jamming scripts
			and not self.jammed == true then
				self.reloadHoldTimer = 0.2--player has to hold down shift for 0.2 seconds to properly reload. Done to allow other shift-based abilities to exist.
				self.reloadHeld = true
			end
		end
	else
		
		--normal manual reload
		if shiftHeld then
			if self.reloadHoldTimer == 0 and self.reloadHeld == true and self.shiftHeldTmp == false
			and not self.jammed == true and not self.unjamming == true then --for jamming scripts
				--if shiftHeld and (self.weapon.ammoAmount < config.getParameter("ammoMax",1)) and not (self.weapon.reloading == 1) and not (self.weapon.firingquery == 1) then
					--self:setState(self.reload)
					--self.reloadHeld = false
				--else
					self.reloadHeld = false
					self.shiftHeldTmp = true
				--end
			elseif self.reloadHoldTimer == 0 and self.shiftHeldTmp == false 
			and not self.unjamming == true --for jamming scripts
			and not self.jammed == true then
			self.reloadHoldTimer = 0.2--player has to tap shift for less than 0.1 seconds to properly reload. Done to allow other shift-based abilities to exist.
			self.reloadHeld = true
			end
		end
	end
	else
	
	if config.getParameter( "switchGun" ) == true then
	
		--normal manual reload, but some extra variables are run through to ensure no bugs. Hopefully.
		--if shiftHeld then -- this one is so guns don't immedietaly reload upon switch, about half second delay before manual reload is re-enabled.
			if shiftHeld and (self.weapon.ammoAmount < config.getParameter("ammoMax",1)) and not (self.weapon.reloading == 1) and not (self.weapon.firingquery == 1) 
		and not self.switchingGuns == true --this one is so guns don't reload when you "switch" it.
		and self.spawnReloadTimer == 0
		and not self.jammed == true and not self.unjamming == true then --for jamming scripts
					self:setState(self.reload)
					--self.reloadHeld = false
				--else
					--self.reloadHeld = false
				--end
			--elseif self.reloadHoldTimer == 0 then
				--self.reloadHoldTimer = 0.1--player has to hold down shift for 0.2 seconds to properly reload. Done to allow other shift-based abilities to exist.
				--self.reloadHeld = true
			end
		--end
	else
		
		--normal manual reload
		--if shiftHeld then
			if shiftHeld and (self.weapon.ammoAmount < config.getParameter("ammoMax",1)) and not (self.weapon.reloading == 1) and not (self.weapon.firingquery == 1) 
			and not self.jammed == true and not self.unjamming == true then --for jamming scripts
					self:setState(self.reload)
					--self.reloadHeld = false
				--else
					--self.reloadHeld = false
					--self.shiftHeldTmp = true
				--end
			--elseif self.reloadHoldTimer == 0 and self.shiftHeldTmp == false then
			--self.reloadHoldTimer = 0.1--player has to tap shift for less than 0.1 seconds to properly reload. Done to allow other shift-based abilities to exist.
			--self.reloadHeld = true
			end
		--end
	end
	
	end
	
	if self.reloadHoldTimer == 0 and self.reloadHeld == true then
		self.reloadHeld = false
	end
	
	if self.reloadHoldTimer == 0 and not shiftHeld then
		self.shiftHeldTmp = false
	end
	
	self.reloadHoldTimer = math.max(0, self.reloadHoldTimer - self.dt)

	
	self.cooldownTimer = math.max(0, self.cooldownTimer - self.dt)
	
	
	-- update crouch detection
	if self.crouchAccuracyToggle == true then
	
		--if the switch fire mode type module is enabled, then the crouch accuracy increase scripts run
		if config.getParameter( "switchFireModeAttachment" ) == true then 
			if self.fireType == self.fireTypeTemp then
				if mcontroller.crouching() then
				self.inaccuracyVariable = self.finalInaccuracyCrouch
				
				--miss chance module stuff. if crouching, miss chance is reduced by 60% unless otherwise specified
					if self.missChanceToggle == true then
						self.missChanceVar = self.finalMissChanceCrouch
					end
				else
					self.inaccuracyVariable = self.finalInaccuracy
				
					--miss chance module stuff
					if self.missChanceToggle == true then
						self.missChanceVar = self.finalMissChance
					end
				end
			else 
			--alt fire
			if self.fireType == self.altFireType then
				if mcontroller.crouching() then
				self.inaccuracyVariable = self.finalAltInaccuracyCrouch
				
				--miss chance module stuff. if crouching, miss chance is reduced by 60% unless otherwise specified
					if self.missChanceToggle == true then
						self.missChanceVar = self.finalAltMissChanceCrouch
					end
				else
				
					self.inaccuracyVariable = self.finalAltInaccuracy
					--miss chance module stuff
					if self.missChanceToggle == true then
						self.missChanceVar = self.finalAltMissChance
					end
				end
			end
			end
		else
		-- standard check
			if mcontroller.crouching() then
				self.inaccuracyVariable = self.finalInaccuracyCrouch
				
				--miss chance module stuff. if crouching, miss chance is reduced by 60% unless otherwise specified
				if self.missChanceToggle == true then
					self.missChanceVar = self.finalMissChanceCrouch
				end
			else
				self.inaccuracyVariable = self.finalInaccuracy
				
				--miss chance module stuff
				if self.missChanceToggle == true then
					self.missChanceVar = self.finalMissChance
				end
			end
		end
	else
		self.inaccuracyVariable = self.finalInaccuracy
				
		--miss chance module stuff
		if self.missChanceToggle == true then
			self.missChanceVar = self.finalMissChance
		end
	end
	
	
	-- if animation state = fire, then turn off muzzle flash light
	if animator.animationState("firing") ~= "fire" then
		animator.setLightActive("muzzleFlash", false)
	end
	
	-- update throw item script
	if self.weapon.currentAbility == nil
	and config.getParameter( "throwItemAttachment" ) == true
    and self.fireMode == "alt"
	and placeholderHereBecauseThisScriptShouldBeDisabled == true			--temp. disabler of the script until i feel like re-enabling it
	and not (self.weapon.firingquery == 1)
    and self.cooldownTimer == 0 then
		self:setState(self.throw1)
	end
	
	
	
	-----------------------------------------------------------------------------------------------------------------------------------------------------------------
	-- update switch ammo script
	-----------------------------------------------------------------------------------------------------------------------------------------------------------------
	
	if self.weapon.currentAbility == nil
	and config.getParameter( "switchFireModeAttachment" ) == true
    and self.fireMode == "alt"
	and not shiftHeld
	and not self.unjamming == true --for jamming scripts
	and not self.jammed == true
    and self.cooldownTimer == 0 then
		if self.changeFireModeHeld == true and self.changeFireModeHoldTimer == 0 then
			if self.fireMode == "alt" then
				if self.fireType == self.fireTypeTemp then
					self.fireType = self.altFireType
					activeItem.setInstanceValue("fireTypeLastUsed",self.fireType)
					self.inaccuracyVariable = self.altInaccuracy
				else
					self.fireType = self.fireTypeTemp
					activeItem.setInstanceValue("fireTypeLastUsed",self.fireType)
					self.inaccuracyVariable = self.inaccuracy
				end

				self:setState(self.switchfiremodes)
				animator.playSound("switch")
				self.changeFireModeHeld = false
			else
				self.changeFireModeHeld = false
			end
		elseif self.changeFireModeHoldTimer == 0 then
			self.changeFireModeHoldTimer = 0.2--player has to hold down alt for 0.2 seconds to properly reload. Done to allow other alt-based abilities to exist.
			self.changeFireModeHeld = true
		end
	end
	
	if self.changeFireModeHoldTimer == 0 and self.changeFireModeHeld == true then
		self.changeFireModeHeld = false
	end
	
	self.changeFireModeHoldTimer = math.max(0, self.changeFireModeHoldTimer - self.dt)
	
	--shows current fire mode selected if possible to change current fire mode
	if config.getParameter( "switchFireModeAttachment" ) == true then
		if self.fireType == "auto" then
			status.setPersistentEffects("fireMode", { "ews_auto" })
		end
		if self.fireType == "semi" then
			status.setPersistentEffects("fireMode", { "ews_semi" })
		end
		if self.fireType == "burst" then
			status.setPersistentEffects("fireMode", { "ews_burst" })
		end
	end
	
	
	
	
	
	-- grenade launcher attachment tap-fire scripts. fml, this took way too long.
	if not (self.weapon.firingquery == 1)
	and not (self.weapon.reloading == 1) then
	if self.fireMode == "alt" then
		self.altFireHeld = true
		if not self.altFireHeldMarker == true then
			self.altFireHeldMarker = true
		end
	else
		self.altFireHeld = false
	end
	end
	
	if not self.altFireHeldTimer then self.altFireHeldTimer = 0 end
	
	if self.altFireHeldTimer > 0.2 then
		self.altFireHeldMarker = false
	end
	
	--grenade launcher attachment script
	if self.weapon.currentAbility == nil
	and self.grenadelauncherAttachment == true
	and not (self.weapon.firingquery == 1)
	and not (self.weapon.reloading == 1)
	and not self.unjamming == true --for jamming scripts
	and not self.jammed == true
    and self.cooldownTimer == 0 then
		if self.altFireHeld == false and self.altFireHeldTimer < 0.2 and self.altFireHeldMarker == true then
			self.altFireHeldMarker = false
			if self.weapon.altAmmoAmount > 0 then
				self:setState(self.grenadelauncher)
			else
				if self.infAmmo == true or self.npcGun == true then
					self:setState(self.grenadelauncherReload)
				else
					local altAmmoItemReload = self.altMagazine
					if player.hasItem({name = altAmmoItemReload}) then
						self:setState(self.grenadelauncherReload)
					end
				end

			end
		end
	end
	
	if self.altFireHeld == true then
		self.altFireHeldTimer = math.max(0, self.altFireHeldTimer + self.dt)
	else
		self.altFireHeldTimer = 0
	end
	
	
			--if self.reloadHoldTimer == 0 and self.reloadHeld == true then
				--if shiftHeld then
					--self:setState(self.reload)
					--self.reloadHeld = false
				--else
					--self.reloadHeld = false
				--end
			--elseif self.reloadHoldTimer == 0 then
			--self.reloadHoldTimer = 0.1--player has to hold down shift for 0.2 seconds to properly reload. Done to allow other shift-based abilities to exist.
			--self.reloadHeld = true
  

  -- main fire update scripts
  self:mainfirescripts()
  
  
  if (self.jammed == true and not self.unjamming == true) and (self.fireMode == (self.activatingFireMode or self.abilitySlot) and self.fireHeld == false) then
	self:setState(self.jammedState)
  end
  
  
  -- detect if fire held
  self.fireHeld = self.fireMode == (self.activatingFireMode or self.abilitySlot)
end


function GunFire:jammedState()
  self.unjamming = true
  animator.setAnimationState("gunState", "jammed")
  animator.playSound("jam")
  self:setState(self.jammedAnims)
end

function GunFire:jammedAnims()
  
  self.lasersightData = self.weapon:setStance(self.stances.jam1)
  self:laserSightConfig()
  if self.stances.jam1.duration then
    util.wait(self.stances.jam1.duration)
  end
  
  self.lasersightData = self.weapon:setStance(self.stances.jam2)
  self:laserSightConfig()
  if self.stances.jam2.duration then
    util.wait(self.stances.jam2.duration)
  end
  
  self.lasersightData = self.weapon:setStance(self.stances.jam3)
  self:laserSightConfig()
  
  if config.getParameter("weaponJammingType") == "ejectFail" then
	self:spawnShell()
	
	--yeah ok look player can technically waste all boolet like dis, but not my problem if they keep anim skipping
	self.weapon.ammoAmount = self.weapon.ammoAmount - 1
	activeItem.setInstanceValue("ammoAmount",self.weapon.ammoAmount)
  end
  
  if self.stances.jam3.duration then
    util.wait(self.stances.jam3.duration)
  end
  
  self.lasersightData = self.weapon:setStance(self.stances.jam4)
  self:laserSightConfig()
  if self.stances.jam4.duration then
    util.wait(self.stances.jam4.duration)
  end
  
  self.lasersightData = self.weapon:setStance(self.stances.jam5)
  self:laserSightConfig()
  if self.stances.jam5.duration then
    util.wait(self.stances.jam5.duration)
  end
  
  self.lasersightData = self.weapon:setStance(self.stances.jam6)
  self:laserSightConfig()
  if self.stances.jam6.duration then
    util.wait(self.stances.jam6.duration)
  end
  
  self.lasersightData = self.weapon:setStance(self.stances.idle)
  self:laserSightConfig()
  self.jammed = false
  self.unjamming = false
  --sb.logInfo("unjammed")
  

  
  --to prevent constant back to back jams
  self.safeShots = 2 --echoutil.round(0,config.getParameter("ammoMax") / 5)
  --sb.logInfo(self.safeShots)
  activeItem.setInstanceValue("weaponJammed",self.jammed)
end

-- if i ever want to implement energy usage, here it do be (status.overConsumeResource("energy", self:energyPerShot()) or self:useEnergy())
function GunFire:mainfirescripts()
	if self.fireMode == (self.activatingFireMode or self.abilitySlot) 
		and not self.weapon.currentAbility
		and self.cooldownTimer == 0
		and not self.unjamming == true --for jamming scripts
		and not self.jammed == true
		and self:jamCheck() == true	--for jamming scripts, 
		and not self.switchingGuns == true --this one is so guns don't fire when you "switch" it.
		and (not status.resourceLocked("energy") or self:useEnergy())
		and not world.lineTileCollision(mcontroller.position(), self:firePosition()) then
			if (self.weapon.ammoAmount > 0) then
				if self.fireType == "auto" and (status.overConsumeResource("energy", self:energyPerShot()) or self:useEnergy()) then
					self:setState(self.auto)
				elseif self.fireType == "burst" then
					self:setState(self.burst)
				end
			
				if self.npcGun == true then
					-- if game detects that this is a npcGun from the toggle variable, then the gun won't be semi-auto technically.
					if self.fireType == "semi" and (status.overConsumeResource("energy", self:energyPerShot()) or self:useEnergy()) then
						self:setState(self.semi)
					end
				elseif not self.fireHeld then
					if self.fireType == "semi" and (status.overConsumeResource("energy", self:energyPerShot()) or self:useEnergy()) then
						self:setState(self.semi)
					end
				end
			else
				if not self.fireHeld and self.emptySoundPlayQuery == false then
					animator.playSound("empty")	
					if self.consumeAmmoToggle == true and (self.weapon.ammoAmount == 0) then
						self.emptySoundPlayQuery = true
					end
				end
			end
			
			-----------------------------------------------------------------------------------------------------------------------------
		
			if (self.weapon.ammoAmount == 0) and (self.weapon.firingquery == 0) then
				if self.fireType == "auto" or self.fireType == "burst" then
					self:setState(self.reload)
				end
				if not self.fireHeld then
					if self.fireType == "semi" then
						self:setState(self.reload)
					end
				end
			end
	end
end

function GunFire:jamCheck()
	if self.weapon.ammoAmount > 0 --prevents jamming when mag is empty
	and not self.unjamming == true --prevents running "safe shots" dry when unjamming
	then
	
	if not self.safeShots then
		self.safeShots = 0
	end
	self.safeShots = math.max(0,self.safeShots - 1)
	if config.getParameter("weaponJamming") == true and self.safeShots < 1 then	--math wack, fix up later
		--sb.logInfo("negativeEffect" .. self.weaponNegativeEffectResult)
		local weaponJamChance = config.getParameter("weaponJammingInitChance") + (config.getParameter("weaponJammingMultiplier") * (self.weaponNegativeEffectResult))
			weaponJamChance = weaponJamChance * 100
		
		local roll = math.random(100)
		--sb.logInfo("rolled " .. roll)
		if roll < weaponJamChance then
			self.jammed = true
			activeItem.setInstanceValue("weaponJammed",self.jammed)
			--sb.logInfo(roll .. "/" .. weaponJamChance)
			return false
		else
			return true
		end
	else
		return true
	end
	
	else
		return true
	end
end

function GunFire:switchfiremodes()
  -- self explanatory
  self.lasersightData = self.weapon:setStance(self.stances.switchfiremodes)
  self:laserSightConfig()

  if self.stances.switchfiremodes.duration then
    util.wait(self.stances.switchfiremodes.duration)
  end

  self.lasersightData = self.weapon:setStance(self.stances.idle)
  self:laserSightConfig()
end

function GunFire:grenadelauncher()
	self.altFireHeldTimer = 0

	self.weapon.altAmmoAmount = self.weapon.altAmmoAmount - 1
	activeItem.setInstanceValue("altAmmoAmount",self.weapon.altAmmoAmount)
	
	self.lasersightData = self.weapon:setStance(self.stances.altFire)
	self:laserSightConfig()

    self:fireProjectile(self.projectileTypeGrenade,self.projectileTypeGrenadeConfig,self.altInaccuracy,self:firePositionAltFire(),self.projectileTypeGrenadeCount,false)
	
	animator.playSound("soundEffectGrenade")
	animator.setParticleEmitterActive("altMuzzleFlash", true)
	animator.setParticleEmitterEmissionRate("altMuzzleFlash", 100)
	
	self.weapon.firingquery = 1
	
	if self.stances.altFire.duration then
		util.wait(self.stances.altFire.duration)
	end
	
	animator.setParticleEmitterActive("altMuzzleFlash", false)
	self.cooldownTimer = self.altFireTime
	
	self.lasersightData = self.weapon:setStance(self.stances.altFire1)
	self:laserSightConfig()
	if self.stances.altFire1.duration then
		util.wait(self.stances.altFire1.duration)
	end
	
	self.lasersightData = self.weapon:setStance(self.stances.altFire2)
	self:laserSightConfig()
	if self.stances.altFire2.duration then
		util.wait(self.stances.altFire2.duration)
	end
	
	self.weapon.firingquery = 0
	self:setState(self.cooldown)
end

function GunFire:grenadelauncherReload()
  self.altFireHeldTimer = 0
  
  self.weapon.reloading = 1
  animator.setAnimationState("grenadeLauncher", "reloading")
  animator.playSound("switchAmmoAlt")
  
  self.lasersightData = self.weapon:setStance(self.stances.altReload)
  self:laserSightConfig()
  if self.stances.altReload.duration then
    util.wait(self.stances.altReload.duration)
  end
  
  self.lasersightData = self.weapon:setStance(self.stances.altReload1)
  self:laserSightConfig()
  if self.stances.altReload1.duration then
    util.wait(self.stances.altReload1.duration)
  end
  
  self.lasersightData = self.weapon:setStance(self.stances.altReload2)
  self:laserSightConfig()
  if self.stances.altReload2.duration then
    util.wait(self.stances.altReload2.duration)
  end
  
  self.lasersightData = self.weapon:setStance(self.stances.altReload3)
  self:laserSightConfig()
  if self.stances.altReload3.duration then
    util.wait(self.stances.altReload3.duration)
  end
  
  self.lasersightData = self.weapon:setStance(self.stances.altReload4)
  self:laserSightConfig()
  if self.stances.altReload4.duration then
    util.wait(self.stances.altReload4.duration)
  end
  
  self.lasersightData = self.weapon:setStance(self.stances.altReload5)
  self:laserSightConfig()
  if self.stances.altReload5.duration then
    util.wait(self.stances.altReload5.duration)
  end
  
  self.lasersightData = self.weapon:setStance(self.stances.altReload6)
  self:laserSightConfig()
  if self.stances.altReload6.duration then
    util.wait(self.stances.altReload6.duration)
  end
  
  if self.infAmmo == true or self.npcGun == true then
	self.weapon.altAmmoAmount = self.weapon.altAmmoMax
	activeItem.setInstanceValue("altAmmoAmount",self.weapon.altAmmoAmount)
  else
	local altAmmoItemReload = self.altMagazine
	if player.hasItem({name = altAmmoItemReload}) then
		player.consumeItem({name = altAmmoItemReload, count = 1})
		self.weapon.altAmmoAmount = self.weapon.altAmmoMax
		activeItem.setInstanceValue("altAmmoAmount",self.weapon.altAmmoAmount)
	end
  end
  
  self.cooldownTimer = 0.1
  self.weapon.reloading = 0
  self.lasersightData = self.weapon:setStance(self.stances.idle)
  --self:setState(self.cooldown)
end

function GunFire:findInTableIndex(tab, val)
	 for index, value in ipairs(tab) do
        if value == val then
            return index
        end
    end

    return false
end

function GunFire:determineSingleLoadedAmmoVars(indexValueVar)
				local magazineDamageValues = config.getParameter("magazineDamageValues")
				local ammoProjectileType = config.getParameter("ammoProjectileType")
				local ammoProjectileTypeMiss = config.getParameter("ammoProjectileTypeMiss")
				local activeAmmoTypeList = config.getParameter("activeAmmoTypeList")
				local ammoProjectileCount = config.getParameter("ammoProjectileCount")
				local fireShellProjectiles = config.getParameter("fireShellProjectiles")
				local fireShellProjectileConfigs = config.getParameter("fireShellProjectileConfigs")
				local ejectProjectileTypes = config.getParameter("ejectProjectileTypes")
				local ejectProjectileTypeConfigs = config.getParameter("ejectProjectileTypeConfigs")
				local indexedValue = activeAmmoTypeList[#activeAmmoTypeList]
				--sb.logInfo(sb.printJson(indexedValue))
				indexedValue =	self:findInTableIndex(config.getParameter("consumeAmmoType"),indexedValue)
				--sb.logInfo(sb.printJson(indexedValue))
				--sb.logInfo("yes")
				--local ammoMaxCurrentValue = 0
				
				if not indexedValue == false then
				if indexValueVar then indexedValue = indexValueVar end
				
				if type(magazineDamageValues) == "table" then 
					magazineDamageValues = magazineDamageValues[indexedValue] 
				else 
					magazineDamageValues = magazineDamageValues 
				end
				activeItem.setInstanceValue("currentDamageAmount",magazineDamageValues)
				
				
				if ammoProjectileType then
				if type(ammoProjectileType) == "table" then 
					self.ammoProjectileType = ammoProjectileType[indexedValue]
				else 
					self.ammoProjectileType = ammoProjectileType
				end
				self.activeAmmoProjectileType = self.ammoProjectileType
				activeItem.setInstanceValue("activeAmmoProjectileType",self.ammoProjectileType)
				end
				
				if ammoProjectileTypeMiss then
				if type(ammoProjectileTypeMiss) == "table" then 
					self.ammoProjectileTypeMiss = ammoProjectileTypeMiss[indexedValue]
				else 
					self.ammoProjectileTypeMiss = ammoProjectileTypeMiss
				end
				self.activeAmmoProjectileTypeMiss = self.ammoProjectileTypeMiss
				activeItem.setInstanceValue("activeAmmoProjectileTypeMiss",self.ammoProjectileTypeMiss)
				end
				
				if ammoProjectileCount then
					if type(ammoProjectileCount) == "table" then 
						self.ammoProjectileCount = ammoProjectileCount[indexedValue]
					else 
						self.ammoProjectileCount = ammoProjectileCount
					end
					self.activeAmmoProjectileCount = self.ammoProjectileCount
					activeItem.setInstanceValue("activeAmmoProjectileCount",self.ammoProjectileCount)
				end
				
		------------------------------------------------------------------------------------------------
		if fireShellProjectiles then
			if type(fireShellProjectiles) == "table" then 
				self.fireShellProjectiles = fireShellProjectiles[indexedValue]
			else 
				self.fireShellProjectiles = fireShellProjectiles
			end
			activeItem.setInstanceValue("fireShellProjectile",self.fireShellProjectiles)
		end
		
		if fireShellProjectileConfigs then
			if type(fireShellProjectileConfigs) == "table" then 
				self.fireShellProjectileConfigs = fireShellProjectileConfigs[indexedValue]
			else 
				self.fireShellProjectileConfigs = fireShellProjectileConfigs
			end
			activeItem.setInstanceValue("fireShellProjectileConfig",self.fireShellProjectileConfigs)
		end
		
		if ejectProjectileTypes then
			if type(ejectProjectileTypes) == "table" then 
				self.ejectProjectileTypes = ejectProjectileTypes[indexedValue]
			else 
				self.ejectProjectileTypes = ejectProjectileTypes
			end
			activeItem.setInstanceValue("ejectProjectileType",self.ejectProjectileTypes)
		end
		
		if ejectProjectileTypeConfigs then
			if type(ejectProjectileTypeConfigs) == "table" then 
				self.ejectProjectileTypeConfigs = ejectProjectileTypeConfigs[indexedValue]
			else 
				self.ejectProjectileTypeConfigs = ejectProjectileTypeConfigs
			end
			activeItem.setInstanceValue("ejectProjectileTypeConfig",self.ejectProjectileTypeConfigs)
		end
		------------------------------------------------------------------------------------------------
				
				
				
				
				self.baseDpsTooltipTemp = ((magazineDamageValues or self.baseDamage) * (self.baseDamageMultiplier or 1.0) * config.getParameter("damageLevelMultiplier"))
				self.damagePerShotTooltipTemp = config.getParameter("tooltipFields")
				self.damagePerShotTooltipTemp["damagePerShotLabel"] = self.baseDpsTooltipTemp			
				activeItem.setInstanceValue("tooltipFields",self.damagePerShotTooltipTemp)
				end
end

function GunFire:spawnShell()
	if config.getParameter( "fireShellProjectile" ) then
	
	local shellOffset = config.getParameter("shellOffset")
		
		if shellOffset then
			local baseOffset = config.getParameter("baseOffset")
			local addedPos = vec2.add(shellOffset, baseOffset)
			
			world.spawnProjectile(config.getParameter( "fireShellProjectile" ),vec2.add(mcontroller.position(), activeItem.handPosition(addedPos)),activeItem.ownerEntityId(),self:aimVector(self.inaccuracyVariable),false,config.getParameter( "fireShellProjectileConfig" ) or {})
		else
			world.spawnProjectile(config.getParameter( "fireShellProjectile" ),self:firePosition(),activeItem.ownerEntityId(),self:aimVector(self.inaccuracyVariable),false,config.getParameter( "fireShellProjectileConfig" ) or {})
		end
	end
end

function GunFire:auto()
  --auto fire scripts
	self.lasersightData = self.weapon:setStance(self.stances.fire)
	self:laserSightConfig()

	if type(config.getParameter("consumeAmmoType")) == "table" then
	if config.getParameter("activeAmmoTypeList") or config.getParameter("consumeAmmoAmount") then
		self:determineSingleLoadedAmmoVars()
	end
	end
	
	if self.weaponDeterioration == true then
		if self.weapon.weaponDurability > 0 then
		self.weapon.weaponDurability = self.weapon.weaponDurability - 1
		activeItem.setInstanceValue("weaponDurability",self.weapon.weaponDurability)
		end
	end
	
	--animator.playSound("fire")
    self:fireProjectile(_,_,_,_,_,true)
	animator.setAnimationState("firing", "fire")
	
	if self.suppressed == true then
		animator.playSound("suppressedFire")
	else
		--standard animation stuff, enables particles and animation states.
		animator.playSound("fire")
		if not self.flashhider == true then
		animator.setPartTag("muzzleFlash", "variant", math.random(1, 3))
		animator.setParticleEmitterActive("muzzleFlash", true)
		animator.setParticleEmitterEmissionRate("muzzleFlash", 100)
		animator.setLightActive("muzzleFlash", true)
		end
		animator.setParticleEmitterActive("hotsmoke", true)
		animator.setParticleEmitterEmissionRate("hotsmoke", 100)
	end
	--removes one bullet from the magazine since you've just fired a bullet
	self.weapon.ammoAmount = self.weapon.ammoAmount - 1
	
	if type(config.getParameter("consumeAmmoType")) == "table" then
	if config.getParameter("activeAmmoTypeList") or config.getParameter("consumeAmmoAmount") then
		local activeAmmoTypeList = config.getParameter("activeAmmoTypeList")
		
		self.indexedValueHolder = self:findInTableIndex(config.getParameter("consumeAmmoType"),activeAmmoTypeList[#activeAmmoTypeList])
		
		activeAmmoTypeList[#activeAmmoTypeList] = null
		activeItem.setInstanceValue("activeAmmoTypeList",activeAmmoTypeList)
		
		self:determineSingleLoadedAmmoVars()
	end
	end
  
	--variable that prevents certain other actions from happening if the weapon is firing.
	self.weapon.firingquery = 1
	
	--spawns a projectile shell every time player fires if defined
	self:spawnShell()
  
  
  
  -- increases recoil when recoil module is enabled
  if self.dynamicRecoil == true then
	if self.dynamicRecoilSteps  < self.finalDynamicRecoilMaxSteps  then
	self.dynamicRecoilSteps  = self.dynamicRecoilSteps  + 1
	end
	self.dynamicRecoilTimer = self.finalDynamicRecoilTickDuration
	
	--increases miss chance when miss chance module is enabled
	--if self.missChanceToggle == true then
	--if self.missChanceVar  < self.missChance  then
	--self.missChanceVar  = self.missChanceVar  + 1
	--end
	--end
  end
  
  
  
  
  -- drops ammo casings when fired
  
  -- "ammoCasing" : true,
  -- "primaryAbility" : {
  -- "ammoCasing" : "projectileName"
  -- }
  
  -- takes away one boolet from magazine, for real this time
  activeItem.setInstanceValue("ammoAmount",self.weapon.ammoAmount)
  animator.setAnimationState("gunState","firing")
  
  -- stance yadaydada, motion1-6 are stances basically
  if self.stances.fire.duration then
    util.wait(self.stances.fire.duration)
  end
  
  if self.npcGun == true and status.stat("ews_npcfirerate") > 0 then
	--self.cooldownTimer = self.fireTime
	--sb.logInfo(sb.printJson(status.stat("ews_npcfirerate")))
	--if status.stat("ews_npcfirerate") > 0 then
		--custom fire rate stat for npcs
		--sb.logInfo(sb.printJson(status.stat("ews_npcfirerate")))
		self.cooldownTimer = status.stat("ews_npcfirerate")
	--end
  else
	self.cooldownTimer = self.fireTime
  end
  self:setState(self.motion1)
end

function GunFire:motion1()
  self.lasersightData = self.weapon:setStance(self.stances.motion1)
  self:laserSightConfig()

  -- disables smoke n all that jazz
  animator.setParticleEmitterActive("muzzleFlash", false)
  animator.setParticleEmitterActive("hotsmoke", false)
  animator.setLightActive("muzzleFlash", false)
  if self.stances.motion1.duration then
    util.wait(self.stances.motion1.duration)
  end

  self:setState(self.motion2)
end

function GunFire:motion2()
  self.lasersightData = self.weapon:setStance(self.stances.motion2)
  self:laserSightConfig()

  if self.stances.motion2.duration then
    util.wait(self.stances.motion2.duration)
  end

  self:setState(self.motion3)
end

function GunFire:motion3()
  self.lasersightData = self.weapon:setStance(self.stances.motion3)
  self:laserSightConfig()
  

  if self.stances.motion3.duration then
    util.wait(self.stances.motion3.duration)
  end
  
  -- delayed projectile spawn for things like shotguns and bolt actions
  -- spawns delayed projectile after motion3's animation is done
  if config.getParameter( "ejectProjectile" ) == true then
  --self:setupNewValuesPostAmmo()
    if type(config.getParameter("consumeAmmoType")) == "table" then
      self:determineSingleLoadedAmmoVars(self.indexedValueHolder)
    end

  local shellOffset = config.getParameter("shellOffset")
  
  if shellOffset then
	local baseOffset = config.getParameter("baseOffset")
	local addedPos = vec2.add(shellOffset, baseOffset)
	world.spawnProjectile(config.getParameter( "ejectProjectileType" ), vec2.add(mcontroller.position(), activeItem.handPosition(addedPos)), activeItem.ownerEntityId(),    self:aimVector(inaccuracy or self.inaccuracy),false,config.getParameter( "ejectProjectileTypeConfig" ) or {})
  else
	world.spawnProjectile(config.getParameter( "ejectProjectileType" ), self:firePosition(), activeItem.ownerEntityId(),    self:aimVector(inaccuracy or self.inaccuracy),false,config.getParameter( "ejectProjectileTypeConfig" ) or {})
  end
    if type(config.getParameter("consumeAmmoType")) == "table" then
      self:determineSingleLoadedAmmoVars()
    end
  end

  self:setState(self.motion4)
end

function GunFire:motion4()
  self.lasersightData = self.weapon:setStance(self.stances.motion4)
  self:laserSightConfig()

  if self.stances.motion4.duration then
    util.wait(self.stances.motion4.duration)
  end

  self:setState(self.motion5)
end

function GunFire:motion5()
  self.lasersightData = self.weapon:setStance(self.stances.motion5)
  self:laserSightConfig()

  if self.stances.motion5.duration then
    util.wait(self.stances.motion5.duration)
  end

  self:setState(self.motion6)
end

function GunFire:motion6()
  self.lasersightData = self.weapon:setStance(self.stances.motion6)
  self:laserSightConfig()

  if self.stances.motion6.duration then
    util.wait(self.stances.motion6.duration)
  end

  -- sets gun into cooldown stance and sets the fire detect variable to false
  self:setState(self.cooldown)
  self.weapon.firingquery = 0
end

function GunFire:throw1()
  --used for throw attachment
  self.weapon.firingquery = 1
  self.lasersightData = self.weapon:setStance(self.stances.throw1)
  self:laserSightConfig()

  if self.stances.throw1.duration then
    util.wait(self.stances.throw1.duration)
  end

  self:setState(self.throw2)
end

function GunFire:throw2()
  self.lasersightData = self.weapon:setStance(self.stances.throw2)
  self:laserSightConfig()
  
  -- throws projectile and plays sound, all before throw2 ends.
  self.thrownProjectile = config.getParameter( "thrownProjectile" )
  animator.playSound("throw")
  world.spawnProjectile(self.thrownProjectile, firePosition or self:firePosition(), activeItem.ownerEntityId(),    self:aimVector(0),false,params)

  if self.stances.throw2.duration then
    util.wait(self.stances.throw2.duration)
  end

  self:setState(self.throw3)
end

function GunFire:throw3()
  self.lasersightData = self.weapon:setStance(self.stances.throw3)
  self:laserSightConfig()
  

  if self.stances.throw3.duration then
    util.wait(self.stances.throw3.duration)
  end
  
  
  self:setState(self.throw4)
end

function GunFire:throw4()
  self.lasersightData = self.weapon:setStance(self.stances.throw4)
  self:laserSightConfig()

  if self.stances.throw4.duration then
    util.wait(self.stances.throw4.duration)
  end

  self:setState(self.throw5)
end

function GunFire:throw5()
  self.lasersightData = self.weapon:setStance(self.stances.throw5)
  self:laserSightConfig()

  if self.stances.throw5.duration then
    util.wait(self.stances.throw5.duration)
  end

  self:setState(self.throw6)
end

function GunFire:throw6()
  self.lasersightData = self.weapon:setStance(self.stances.throw6)
  self:laserSightConfig()

  if self.stances.throw6.duration then
    util.wait(self.stances.throw6.duration)
  end

  --self:setState(self.cooldown)
  animator.setParticleEmitterActive("hotsmoke", false )
  animator.setParticleEmitterActive("muzzleFlash", false)
  self.weapon:setStance(self.stances.idle)
  self.weapon.firingquery = 0
end

function GunFire:semi()
	self.lasersightData = self.weapon:setStance(self.stances.fire)
	self:laserSightConfig()

	if type(config.getParameter("consumeAmmoType")) == "table" then
	if config.getParameter("activeAmmoTypeList") or config.getParameter("consumeAmmoAmount") then
		self:determineSingleLoadedAmmoVars()
	end
	end
	
	if self.weaponDeterioration == true then
		if self.weapon.weaponDurability > 0 then
		self.weapon.weaponDurability = self.weapon.weaponDurability - 1
		activeItem.setInstanceValue("weaponDurability",self.weapon.weaponDurability)
		end
	end
	
    self:fireProjectile(_,_,_,_,_,true)
	if self.suppressed == true then
		animator.playSound("suppressedFire")
	else
		--standard animation stuff, enables particles and animation states.
		animator.playSound("fire")
		if not self.flashhider == true then
		animator.setPartTag("muzzleFlash", "variant", math.random(1, 3))
		animator.setParticleEmitterActive("muzzleFlash", true)
		animator.setParticleEmitterEmissionRate("muzzleFlash", 100)
		animator.setLightActive("muzzleFlash", true)
		end
		animator.setParticleEmitterActive("hotsmoke", true)
		animator.setParticleEmitterEmissionRate("hotsmoke", 100)
	end
	-- semi-auto yadayada most stuff same as auto
  
	self.weapon.firingquery = 1
	
	--spawns a shell projectile every time player fires if defined
	self:spawnShell()

	--removes one bullet from the magazine since you've just fired a bullet
	self.weapon.ammoAmount = self.weapon.ammoAmount - 1
	
	if type(config.getParameter("consumeAmmoType")) == "table" then
	if config.getParameter("activeAmmoTypeList") or config.getParameter("consumeAmmoAmount") then
		local activeAmmoTypeList = config.getParameter("activeAmmoTypeList")
		
		self.indexedValueHolder = self:findInTableIndex(config.getParameter("consumeAmmoType"),activeAmmoTypeList[#activeAmmoTypeList])
		
		activeAmmoTypeList[#activeAmmoTypeList] = null
		activeItem.setInstanceValue("activeAmmoTypeList",activeAmmoTypeList)
		
		self:determineSingleLoadedAmmoVars()
	end
	end
	activeItem.setInstanceValue("ammoAmount",self.weapon.ammoAmount)
	animator.setAnimationState("gunState","firing")
  
  if self.stances.fire.duration then
    util.wait(self.stances.fire.duration)
  end
  
   -- increases recoil when recoil module is enabled
  if self.dynamicRecoil == true then
	if self.dynamicRecoilSteps  < self.finalDynamicRecoilMaxSteps  then
	self.dynamicRecoilSteps  = self.dynamicRecoilSteps  + 1
	end
	self.dynamicRecoilTimer = self.finalDynamicRecoilTickDuration
  end

  -- this makes the gun fire at roughly 8 rounds per second, which is about the same speed a human can normally click at. Another script above makes gun shoot at "full auto" here so NPC's don't shoot the gun once per 5 seconds
  if self.npcGun == true then
	self.cooldownTimer = 0.125
	if status.stat("ews_npcfirerate") > 0 then
		--custom fire rate stat for npcs
		self.cooldownTimer = status.stat("ews_npcfirerate")
	end
  else
  
  --used to make gun feel more like a semi-auto, basically loosens restrictions on cooldown time
  self.cooldownTimer = self.fireTime/10
  end
  self:setState(self.motion1)
end

function GunFire:burst()
  self.lasersightData = self.weapon:setStance(self.stances.fire)
  self:laserSightConfig()
  
  -- burst fire. need i say more?
  -- will say that on my todo list is to optimize this ish. adding recoil to this will be a PITA
  -- small note here to figure out what i meant by the above comment
  
  if type(config.getParameter("consumeAmmoType")) == "table" then
	if config.getParameter("activeAmmoTypeList") or config.getParameter("consumeAmmoAmount") then
		self:determineSingleLoadedAmmoVars()
	end
  end

  local shots = math.min(self.burstCount,self.weapon.ammoAmount)
  while shots > 0 and (status.overConsumeResource("energy", self:energyPerShot())or self:useEnergy()) do
  --do
	self.weapon.ammoAmount = self.weapon.ammoAmount - 1
	activeItem.setInstanceValue("ammoAmount",self.weapon.ammoAmount)
	
	--spawns a shell projectile every time player fires if defined
	self:spawnShell()
	
	if self.weaponDeterioration == true then
		if self.weapon.weaponDurability > 0 then
		self.weapon.weaponDurability = self.weapon.weaponDurability - 1
		activeItem.setInstanceValue("weaponDurability",self.weapon.weaponDurability)
		end
	end
	
    self:fireProjectile(_,_,_,_,_,true)
	animator.setAnimationState("firing", "fire")
	if self.suppressed == true then
		animator.playSound("suppressedFire")
	else
		--standard animation stuff, enables particles and animation states.
		animator.playSound("fire")
		if not self.flashhider == true then
		animator.setPartTag("muzzleFlash", "variant", math.random(1, 3))
		animator.setParticleEmitterActive("muzzleFlash", true)
		animator.setParticleEmitterEmissionRate("muzzleFlash", 100)
		animator.setLightActive("muzzleFlash", true)
		end
		animator.setParticleEmitterActive("hotsmoke", true)
		animator.setParticleEmitterEmissionRate("hotsmoke", 100)
	end
  
  -- increases recoil when recoil module is enabled
  if self.dynamicRecoil == true then
	if self.dynamicRecoilSteps  < self.finalDynamicRecoilMaxSteps  then
	self.dynamicRecoilSteps  = self.dynamicRecoilSteps  + 1
	end
	self.dynamicRecoilTimer = self.finalDynamicRecoilTickDuration
  end
	
    shots = shots - 1

    self.weapon.relativeWeaponRotation = util.toRadians(interp.linear(1 - shots / self.burstCount, 0, self.stances.fire.weaponRotation))
    self.weapon.relativeArmRotation = util.toRadians(interp.linear(1 - shots / self.burstCount, 0, self.stances.fire.armRotation))
	
	activeItem.setInstanceValue("weaponOffsetVar",self.stances.fire.offset)
	activeItem.setInstanceValue("weaponRotationVar",self.weapon.relativeWeaponRotation)
	self:laserSightConfig()
	
	animator.setAnimationState("gunState","firing")

    util.wait(self.burstTime)
  end
  
  if type(config.getParameter("consumeAmmoType")) == "table" then
	if config.getParameter("activeAmmoTypeList") or config.getParameter("consumeAmmoAmount") then
		local activeAmmoTypeList = config.getParameter("activeAmmoTypeList")
		
		self.indexedValueHolder = self:findInTableIndex(config.getParameter("consumeAmmoType"),activeAmmoTypeList[#activeAmmoTypeList])
		
		activeAmmoTypeList[#activeAmmoTypeList] = null
		activeItem.setInstanceValue("activeAmmoTypeList",activeAmmoTypeList)
		
		self:determineSingleLoadedAmmoVars()
 end
 end

  if config.getParameter( "switchFireModeAttachment" ) == true then
	if self.npcGun == true then
		self.cooldownTimer = (self.burstCooldown - self.burstTime) * self.burstCount
		if status.stat("ews_npcfirerate") > 0 then
			--custom fire rate stat for npcs
			self.burstCooldownOverride = status.stat("ews_npcfirerate")
			self.cooldownTimer = (self.burstCooldownOverride - self.burstTime) * self.burstCount
		end
	else
		self.cooldownTimer = (self.burstCooldown - self.burstTime) * self.burstCount
	end
			
  else
    if self.npcGun == true then
		self.cooldownTimer = (self.fireTime - self.burstTime) * self.burstCount
		if status.stat("ews_npcfirerate") > 0 then
			--custom fire rate stat for npcs
			self.burstCooldownOverride = status.stat("ews_npcfirerate")
			self.cooldownTimer = (self.burstCooldownOverride - self.burstTime) * self.burstCount
		end
	else
		self.cooldownTimer = (self.fireTime - self.burstTime) * self.burstCount
	end

  end
  animator.setParticleEmitterActive("muzzleFlash", false)
  animator.setParticleEmitterActive("hotsmoke", false)
end

function GunFire:findAmmo()
 if self.consumeAmmoType then
	if not self.npcGun == true then
	if type(self.consumeAmmoType) == "table" then
		self.ammoItemChosenTable = echoutil.playerHasInTable(self.consumeAmmoType)
		--echoutil.logJson(self.ammoItemChosenTable)
		if self.ammoItemChosenTable == false then self.ammoItemChosen = false else self.ammoItemChosen = self.ammoItemChosenTable[1] end
		--echoutil.logJson(self.ammoItemChosenTable)
		--echoutil.logJson(self.ammoItemChosenTable[1])
		--sb.logInfo("__________________")
		--if consumeAmmoType is an array, then search through the array until a valid ammo that the player has is found. if not found, then return as "false".
		
		--sb.logInfo("ammoitemchosen "..sb.printJson(self.ammoItemChosen))
	else
		self.ammoItemChosen = self.consumeAmmoType
	end
	else
		if type(self.consumeAmmoType) == "table" then
			self.ammoItemChosen = self.consumeAmmoType[config.getParameter("defaultAmmoIndexValue") or 1]
		else
			self.ammoItemChosen = self.consumeAmmoType
		end
	end
 end
 
end

function GunFire:checkAmmoStatus()
	self:findAmmo() --sets the ammo item chosen
    if config.getParameter("consumeAmmoModule") == true then -- checks if the consumeAmmo module is on. If not, then the user will always be able to reload. If the module is on, then the user will only be able to reload IF the player still has ammunition left.
	if not self.npcGun == true then -- checks if npcGun is not on
		if not self.infAmmo == true then
			if not self.ammoItemChosen == false then
				--echoutil.logJson(self.ammoItemChosen)
				--echoutil.logJson(player.hasItem({name = self.ammoItemChosen}))
				if player.hasItem({name = self.ammoItemChosen}) then
					return true
				else
					--if the weapon has the parameter 
					--"npcGun" : true
					--then the gun will not attempt to check for ammo.
					if self.npcGun == true then
						return true
					else
						return false
					end
				end
			else
				return false
			end
		else
			return true
		end
	else
		return true
	end
	else
		return true
	end
end

function GunFire:reload()
    -- reload stuff
	
	self.canReload = self:checkAmmoStatus()
	
	
	
	
	if self:checkAmmoStatus() == true then
	
	--if self.consumeAmmoToggle == true then
	--	player.consumeItem({name = self.consumeAmmoType, count = 1})
	--end
	
	self.lasersightData = self.weapon:setStance(self.stances.reload)
	self:laserSightConfig()
	if not config.getParameter( "partialReloadsEnabled" ) == true then
		animator.setAnimationState("gunState","reloading")
	end
	if not config.getParameter( "partialReloadsEnabled" ) == true and not config.getParameter( "singleBulletLoad" ) == true then
		animator.playSound("switchAmmo")
	end
	--self.weapon.ammoAmount = -1
	self.weapon.reloading = 1
	
	--resets aim position for pistols
	if config.getParameter( "pistolReload" ) == true then
		self.weapon.aimAngle = 0
	end
	
	
	self.magazineProjectile = config.getParameter("magazineProjectile")
	if config.getParameter("magazineProjectilePartial") then
			self.magazineProjectilePartial = config.getParameter("magazineProjectilePartial")
	end
	animator.setParticleEmitterActive("hotsmoke", false )
	animator.setParticleEmitterActive("muzzleFlash", false)
	
	activeItem.setInstanceValue("ammoAmount",self.weapon.ammoAmount)
	
	-- single bullet load/normal reload stuff, single bullet load parameter toggles this.
	-- single bullet load is to be mostly used for shotguns and the like
	if not config.getParameter( "singleBulletLoad" ) == true or config.getParameter( "singleBulletLoad" ) == nil then --normal reload
		
		if config.getParameter( "partialReloadsEnabled" ) == true then
			if self.weapon.ammoAmount > 0 then						--partial reload
				animator.playSound("switchAmmoPartial")
				animator.setAnimationState("gunState","reloadingPartial")
				self.lasersightData = self.weapon:setStance(self.stances.partreload)
				self:laserSightConfig()
				
				if self.stances.partreload.duration then
					util.wait(self.stances.partreload.duration)
					world.spawnProjectile(self.magazineProjectilePartial, firePosition or self:firePosition(), activeItem.ownerEntityId(),    self:aimVector(inaccuracy or self.finalInaccuracy),false,config.getParameter( "magazineProjectilePartialConfig" ) or {})
				end
  
				self.cooldownTimer = self.fireTime
				self:setState(self.partReload1)
			else
				animator.playSound("switchAmmo")
				animator.setAnimationState("gunState","reloading")
				
				if self.stances.reload.duration then 					--normal reload
					util.wait(self.stances.reload.duration)
					world.spawnProjectile(self.magazineProjectile, firePosition or self:firePosition(), activeItem.ownerEntityId(),    self:aimVector(inaccuracy or self.finalInaccuracy),false,config.getParameter( "magazineProjectileConfig" ) or {})
				end
     			
				self.cooldownTimer = self.fireTime
				self:setState(self.reload1)
			end
		else
			if self.stances.reload.duration then 						--normal reload
				util.wait(self.stances.reload.duration)
				world.spawnProjectile(self.magazineProjectile, firePosition or self:firePosition(), activeItem.ownerEntityId(),    self:aimVector(inaccuracy or self.finalInaccuracy),false,config.getParameter( "magazineProjectileConfig" ) or {})
			end
  
			self.cooldownTimer = self.fireTime
			self:setState(self.reload1)
		end
		
	elseif config.getParameter( "singleBulletLoad" ) == true then --single bullet reload
		--redirects to singleload function for better moddability for any lads lookin to make a custom lua that modifies single load only without having to override the whole reload function.
		self:setState(self.singleload)
	end
	
	else
	
	self.cooldownTimer = self.fireTime
	--self:setState(self.cooldown)
	self.lasersightData = self.weapon:setStance(self.stances.idle)
	self:laserSightConfig()
	self.weapon:updateAim()
	animator.setParticleEmitterActive("hotsmoke", false )
	animator.setParticleEmitterActive("muzzleFlash", false)
	
	end
end

function GunFire:singleload() --SINGLE LOAD RELOAD ANIMS
	if config.getParameter( "singleBulletLoadPreAnims" ) == true then
		 animator.setAnimationState("gunState","reloadPre")
		 animator.playSound("reloadPre")
		 --self.weapon:setStance(self.stances.reload1)
		
		 self.lasersightData = self.weapon:setStance(self.stances.prereload1)
		 self:laserSightConfig()
		if self.stances.prereload1.duration then
   		 util.wait(self.stances.prereload1.duration)
 		end
		
		self.lasersightData = self.weapon:setStance(self.stances.prereload2)
		self:laserSightConfig()
		if self.stances.prereload2.duration then
   		 util.wait(self.stances.prereload2.duration)
 		end
		
		self.lasersightData = self.weapon:setStance(self.stances.prereload3)
		self:laserSightConfig()
		if self.stances.prereload3.duration then
   		 util.wait(self.stances.prereload3.duration)
 		end
		
		self.lasersightData = self.weapon:setStance(self.stances.reload2)
		self:laserSightConfig()
		util.wait(self.stances.reload2.duration)
		animator.setAnimationState("gunState","reloading")
		end
		
		repeat
		
		animator.playSound("switchAmmo",0)
		self.lasersightData = self.weapon:setStance(self.stances.reload1)
		self:laserSightConfig()
		util.wait(self.stances.reload1.duration)
		if not self.infAmmo == true and not self.npcGun == true and self.consumeAmmoToggle == true then
			player.consumeItem({name = self.ammoItemChosen, count = 1})
		end
		self.weapon.ammoAmount = self.weapon.ammoAmount + 1
		activeItem.setInstanceValue("ammoAmount",self.weapon.ammoAmount)
		
		if type(self.consumeAmmoType) == "table" then
				--if not self.ammoItemChosenTable == false or self.infAmmo == true or self.npcGun == true then
				local ammoMaxValues = config.getParameter("ammoMaxValues")
				local magazineDamageValues = config.getParameter("magazineDamageValues")
				local ammoProjectileType = config.getParameter("ammoProjectileType")
				local ammoProjectileTypeMiss = config.getParameter("ammoProjectileTypeMiss")
				local ammoProjectileCount = config.getParameter("ammoProjectileCount")
				
				if not self.ammoItemChosenTable == false and not self.infAmmo == true and not self.npcGun == true then
					indexedValue = self.ammoItemChosenTable[2]
					
					local activeAmmoTypeList = config.getParameter("activeAmmoTypeList")
					activeAmmoTypeList[#activeAmmoTypeList+1] = self.ammoItemChosenTable[1]
					activeItem.setInstanceValue("activeAmmoTypeList",activeAmmoTypeList)
				end
				
				if self.infAmmo == true or self.npcGun == true then
					indexedValue = config.getParameter("defaultAmmoIndexValue") or 1
					
					local consumeAmmoType = config.getParameter("consumeAmmoType")
					local activeAmmoTypeList = config.getParameter("activeAmmoTypeList")
					activeAmmoTypeList[#activeAmmoTypeList+1] = consumeAmmoType[indexedValue]
					activeItem.setInstanceValue("activeAmmoTypeList",activeAmmoTypeList)
				end
				
				if type(magazineDamageValues) == "table" then 
					magazineDamageValues = magazineDamageValues[indexedValue] 
				else 
					magazineDamageValues = magazineDamageValues 
				end
				activeItem.setInstanceValue("currentDamageAmount",magazineDamageValues)
				
				if ammoProjectileType then
				if type(ammoProjectileType) == "table" then 
					self.ammoProjectileType = ammoProjectileType[indexedValue]
				else 
					self.ammoProjectileType = ammoProjectileType
				end
				self.activeAmmoProjectileType = self.ammoProjectileType
				activeItem.setInstanceValue("activeAmmoProjectileType",self.ammoProjectileType)
				end
				
				if ammoProjectileTypeMiss then
				if type(ammoProjectileTypeMiss) == "table" then 
					self.ammoProjectileTypeMiss = ammoProjectileTypeMiss[indexedValue]
				else 
					self.ammoProjectileTypeMiss = ammoProjectileTypeMiss
				end
				self.activeAmmoProjectileTypeMiss = self.ammoProjectileTypeMiss
				activeItem.setInstanceValue("activeAmmoProjectileTypeMiss",self.ammoProjectileTypeMiss)
				end
				
				if ammoProjectileCount then
					if type(ammoProjectileCount) == "table" then 
						self.ammoProjectileCount = ammoProjectileCount[indexedValue]
					else 
						self.ammoProjectileCount = ammoProjectileCount
					end
					self.activeAmmoProjectileCount = self.ammoProjectileCount
					activeItem.setInstanceValue("activeAmmoProjectileCount",self.ammoProjectileCount)
				end
				
				
				
				self.baseDpsTooltipTemp = (magazineDamageValues * (self.baseDamageMultiplier or 1.0) * config.getParameter("damageLevelMultiplier"))
				self.damagePerShotTooltipTemp = config.getParameter("tooltipFields")
				self.damagePerShotTooltipTemp["damagePerShotLabel"] = self.baseDpsTooltipTemp			
				activeItem.setInstanceValue("tooltipFields",self.damagePerShotTooltipTemp)
				--end
		end
		
		self.lasersightData = self.weapon:setStance(self.stances.reload2)
		self:laserSightConfig()
		util.wait(self.stances.reload2.duration)
		
		
		--self:checkAmmoStatus()
  
		until self.weapon.ammoAmount == config.getParameter("ammoMax",1) or self.fireMode == (self.activatingFireMode or self.abilitySlot) or self:checkAmmoStatus() == false
		animator.stopAllSounds("switchAmmo")
		self.weapon.reloading = 0
  
		self.cooldownTimer = self.fireTime
		
		if config.getParameter( "singleBulletLoadAfterAnims" ) == true then
			animator.setAnimationState("gunState","reloadFinal")
			animator.playSound("reloadFinal")
			self:setState(self.reload3)
		else
			self.lasersightData = self.weapon:setStance(self.stances.idle)
			--self:setState(self.cooldown)
			animator.setAnimationState("gunState","armed")
		end
end

function GunFire:partReload1()
  self.lasersightData = self.weapon:setStance(self.stances.partreload1)
  self:laserSightConfig()
  local indexedValue
  if self.consumeAmmoToggle == true and self:checkAmmoStatus() == true then
		if not config.getParameter("consumeAmmoAmount") then
			if self.ammoItemChosenTable then
				indexedValue = self.ammoItemChosenTable[2] 
			else 
				indexedValue = config.getParameter("activeIndex") or config.getParameter("defaultAmmoIndexValue")
			end
			
			if self.npcGun == true or self.infAmmo == true then
				indexedValue = config.getParameter("defaultAmmoIndexValue")
			end
			
			if type(config.getParameter("consumeAmmoType")) == "table" and config.getParameter("magazineImages") then
				local magazineImages = config.getParameter("magazineImages")
				magazineImages = magazineImages[indexedValue]
				animator.setGlobalTag("magazineImage", magazineImages)
			end
		end
  end

  if self.stances.partreload1.duration then
    util.wait(self.stances.partreload1.duration)
  end

  self:setState(self.partReload2)
end

function GunFire:partReload2()
  self.lasersightData = self.weapon:setStance(self.stances.partreload2)
  self:laserSightConfig()

  if self.stances.partreload2.duration then
    util.wait(self.stances.partreload2.duration)
  end

  self:setState(self.partReload3)
end

function GunFire:partReload3()
  self.lasersightData = self.weapon:setStance(self.stances.partreload3)
  self:laserSightConfig()

  if self.stances.partreload3.duration then
    util.wait(self.stances.partreload3.duration)
  end

  self:setState(self.partReload4)
end

function GunFire:partReload4()
  self.lasersightData = self.weapon:setStance(self.stances.partreload4)
  self:laserSightConfig()

  if self.stances.partreload4.duration then
    util.wait(self.stances.partreload4.duration)
  end

  self:setState(self.partReload5)
end

function GunFire:partReload5()
  self.lasersightData = self.weapon:setStance(self.stances.partreload5)
  self:laserSightConfig()

  if self.stances.partreload5.duration then
    util.wait(self.stances.partreload5.duration)
  end

  self:setState(self.partReload6)
end

function GunFire:setupNewValuesPostAmmo()
		local ammoMaxValues = config.getParameter("ammoMaxValues")
		local magazineDamageValues = config.getParameter("magazineDamageValues")
		local ammoProjectileType = config.getParameter("ammoProjectileType")
		local ammoProjectileTypeMiss = config.getParameter("ammoProjectileTypeMiss")
		local ammoProjectileCount = config.getParameter("ammoProjectileCount")
		local indexedValue = config.getParameter("defaultAmmoIndexValue") or 1
		
		local magazineProjectiles = config.getParameter("magazineProjectiles")
		local magazineProjectileConfigs = config.getParameter("magazineProjectileConfigs")
		local magazineProjectilesPartial = config.getParameter("magazineProjectilesPartial")
		local magazineProjectilePartialConfigs = config.getParameter("magazineProjectilePartialConfigs")
		local fireShellProjectiles = config.getParameter("fireShellProjectiles")
		local fireShellProjectileConfigs = config.getParameter("fireShellProjectileConfigs")
		local ejectProjectileTypes = config.getParameter("ejectProjectileTypes")
		local ejectProjectileTypeConfigs = config.getParameter("ejectProjectileTypeConfigs")
		
		local ammoMaxCurrentValue = 0
		
		if not self.ammoItemChosenTable == false then
			indexedValue = self.ammoItemChosenTable[2]
		end
				
		if self.infAmmo == true or self.npcGun == true then
			indexedValue = config.getParameter("defaultAmmoIndexValue") or 1
		end
		
		if ammoMaxValues then
			if type(ammoMaxValues) == "table" then 
				ammoMaxCurrentValue = ammoMaxValues[indexedValue] 
			else 
				ammoMaxCurrentValue = ammoMaxValues 
			end
			activeItem.setInstanceValue("ammoMax",ammoMaxCurrentValue)
		end
				
		if magazineDamageValues then
		if type(magazineDamageValues) == "table" then 
			magazineDamageValues = magazineDamageValues[indexedValue] 
		else 
			magazineDamageValues = magazineDamageValues 
		end
			activeItem.setInstanceValue("currentDamageAmount",magazineDamageValues)
		end
				
				
		if ammoProjectileType then
		if type(ammoProjectileType) == "table" then 
			self.ammoProjectileType = ammoProjectileType[indexedValue]
		else 
			self.ammoProjectileType = ammoProjectileType
		end
		self.activeAmmoProjectileType = self.ammoProjectileType
		activeItem.setInstanceValue("activeAmmoProjectileType",self.ammoProjectileType)
		end
				
		if ammoProjectileTypeMiss then
		if type(ammoProjectileTypeMiss) == "table" then 
			self.ammoProjectileTypeMiss = ammoProjectileTypeMiss[indexedValue]
		else 
			self.ammoProjectileTypeMiss = ammoProjectileTypeMiss
		end
		self.activeAmmoProjectileTypeMiss = self.ammoProjectileTypeMiss
		activeItem.setInstanceValue("activeAmmoProjectileTypeMiss",self.ammoProjectileTypeMiss)
		end
				
		if ammoProjectileCount then
			if type(ammoProjectileCount) == "table" then 
				self.ammoProjectileCount = ammoProjectileCount[indexedValue]
			else 
				self.ammoProjectileCount = ammoProjectileCount
			end
			self.activeAmmoProjectileCount = self.ammoProjectileCount
			activeItem.setInstanceValue("activeAmmoProjectileCount",self.ammoProjectileCount)
		end
		
		
		------------------------------------------------------------------------------------------------
		if magazineProjectiles then
			if type(magazineProjectiles) == "table" then 
				self.magazineProjectiles = magazineProjectiles[indexedValue]
			else 
				self.magazineProjectiles = magazineProjectiles
			end
			activeItem.setInstanceValue("magazineProjectile",self.magazineProjectiles)
		end
		
		if magazineProjectileConfigs then
			if type(magazineProjectileConfigs) == "table" then 
				self.magazineProjectileConfigs = magazineProjectileConfigs[indexedValue]
			else 
				self.magazineProjectileConfigs = magazineProjectileConfigs
			end
			activeItem.setInstanceValue("magazineProjectileConfig",self.magazineProjectileConfigs)
		end
		
		if magazineProjectilesPartial then
			if type(magazineProjectilesPartial) == "table" then 
				self.magazineProjectilesPartial = magazineProjectilesPartial[indexedValue]
			else 
				self.magazineProjectilesPartial = magazineProjectilesPartial
			end
			activeItem.setInstanceValue("magazineProjectilePartial",self.magazineProjectilesPartial)
		end
		
		if magazineProjectilePartialConfigs then
			if type(magazineProjectilePartialConfigs) == "table" then 
				self.magazineProjectilePartialConfigs = magazineProjectilePartialConfigs[indexedValue]
			else 
				self.magazineProjectilePartialConfigs = magazineProjectilePartialConfigs
			end
			activeItem.setInstanceValue("magazineProjectilePartialConfig",self.magazineProjectilePartialConfigs)
		end
		
		if fireShellProjectiles then
			if type(fireShellProjectiles) == "table" then 
				self.fireShellProjectiles = fireShellProjectiles[indexedValue]
			else 
				self.fireShellProjectiles = fireShellProjectiles
			end
			activeItem.setInstanceValue("fireShellProjectile",self.fireShellProjectiles)
		end
		
		if fireShellProjectileConfigs then
			if type(fireShellProjectileConfigs) == "table" then 
				self.fireShellProjectileConfigs = fireShellProjectileConfigs[indexedValue]
			else 
				self.fireShellProjectileConfigs = fireShellProjectileConfigs
			end
			activeItem.setInstanceValue("fireShellProjectileConfig",self.fireShellProjectileConfigs)
		end
		
		if ejectProjectileTypes then
			if type(ejectProjectileTypes) == "table" then 
				self.ejectProjectileTypes = ejectProjectileTypes[indexedValue]
			else 
				self.ejectProjectileTypes = ejectProjectileTypes
			end
			activeItem.setInstanceValue("ejectProjectileType",self.ejectProjectileTypes)
		end
		
		if ejectProjectileTypeConfigs then
			if type(ejectProjectileTypeConfigs) == "table" then 
				self.ejectProjectileTypeConfigs = ejectProjectileTypeConfigs[indexedValue]
			else 
				self.ejectProjectileTypeConfigs = ejectProjectileTypeConfigs
			end
			activeItem.setInstanceValue("ejectProjectileTypeConfig",self.ejectProjectileTypeConfigs)
		end
		------------------------------------------------------------------------------------------------
				
		
		
				
		--self.baseDpsTooltipTemp = ((magazineDamageValues or self.baseDamage) * (self.baseDamageMultiplier or 1.0) * config.getParameter("damageLevelMultiplier"))
		self.baseDpsTooltipTemp = self:damagePerShot()
		self.damagePerShotTooltipTemp = config.getParameter("tooltipFields")
		self.damagePerShotTooltipTemp["damagePerShotLabel"] = self.baseDpsTooltipTemp			
		activeItem.setInstanceValue("tooltipFields",self.damagePerShotTooltipTemp)
end

function GunFire:reloadFunction(extraBullets)
  if not config.getParameter("consumeAmmoAmount") and not self.npcGun == true and not self.infAmmo == true then
	if self:checkAmmoStatus() == true then
	self.weapon.ammoAmount = config.getParameter("ammoMax",1) + (extraBullets or 0)
	activeItem.setInstanceValue("ammoAmount",self.weapon.ammoAmount)
	end
  end
  
  -- allows the gun to play the empty "click" sfx again once the player is out of ammo 100% again
  self.emptySoundPlayQuery = false
  
  -- fully loads up the gun if the gun is a "npcGun" or if the gun has infinite spare ammo
  if self.npcGun == true or self.infAmmo == true then
	if config.getParameter("consumeAmmoAmount") and type(config.getParameter("consumeAmmoType")) == "table" then
		local activeAmmoTypeList = config.getParameter("activeAmmoTypeList")
		local ammoItemLoaded = config.getParameter("consumeAmmoType")
		for i = 1, (config.getParameter("ammoMax",1) - self.weapon.ammoAmount) do
			activeAmmoTypeList[#activeAmmoTypeList + 1] = ammoItemLoaded[config.getParameter("defaultAmmoIndexValue") or 1]
		end
		activeItem.setInstanceValue("activeAmmoTypeList",activeAmmoTypeList)
		
		self:setupNewValuesPostAmmo()
	end
	
	self:setupNewValuesPostAmmo()
	self.weapon.ammoAmount = config.getParameter("ammoMax",1) + (extraBullets or 0)
	activeItem.setInstanceValue("ammoAmount",self.weapon.ammoAmount)
	
	if self.consumeAmmoToggle == true then
		local indexedValue = config.getParameter("defaultAmmoIndexValue") or 1
		activeItem.setInstanceValue("activeIndex",indexedValue)
		self:setupInventoryIcon()
		self:setupNewValuesPostAmmo()
	end
  end
  
  -- if the weapon is a "npcGun"/if the weapon has inf spare ammo, then no item will be consumed upon finishing reload, even if the "consumeAmmoModule" is enabled.
  if not self.npcGun == true and not self.infAmmo == true then
  
  -- if the consumeAmmoToggle is enabled, then upon reaching the end of the reload animation a "magazine" (or whatever item is used to load into the item) is used up.
	if self.consumeAmmoToggle == true and self:checkAmmoStatus() == true then
		if not config.getParameter("consumeAmmoAmount") then
			player.consumeItem({name = self.ammoItemChosen, count = 1})
			if type(self.consumeAmmoType) == "table" then
				local ammoMaxValues = config.getParameter("ammoMaxValues")
				local magazineDamageValues = config.getParameter("magazineDamageValues")
				local ammoProjectileType = config.getParameter("ammoProjectileType")
				local ammoProjectileTypeMiss = config.getParameter("ammoProjectileTypeMiss")
				local ammoProjectileCount = config.getParameter("ammoProjectileCount")
				local indexedValue = self.ammoItemChosenTable[2]
				
				local magazineProjectiles = config.getParameter("magazineProjectiles")
				local magazineProjectileConfigs = config.getParameter("magazineProjectileConfigs")
				local magazineProjectilesPartial = config.getParameter("magazineProjectilesPartial")
				local magazineProjectilePartialConfigs = config.getParameter("magazineProjectilePartialConfigs")
				local fireShellProjectiles = config.getParameter("fireShellProjectiles")
				local fireShellProjectileConfigs = config.getParameter("fireShellProjectileConfigs")
				local ejectProjectileTypes = config.getParameter("ejectProjectileTypes")
				local ejectProjectileTypeConfigs = config.getParameter("ejectProjectileTypeConfigs")
				
		------------------------------------------------------------------------------------------------
		if magazineProjectiles then
			if type(magazineProjectiles) == "table" then 
				self.magazineProjectiles = magazineProjectiles[indexedValue]
			else 
				self.magazineProjectiles = magazineProjectiles
			end
			activeItem.setInstanceValue("magazineProjectile",self.magazineProjectiles)
		end
		
		if magazineProjectileConfigs then
			if type(magazineProjectileConfigs) == "table" then 
				self.magazineProjectileConfigs = magazineProjectileConfigs[indexedValue]
			else 
				self.magazineProjectileConfigs = magazineProjectileConfigs
			end
			activeItem.setInstanceValue("magazineProjectileConfig",self.magazineProjectileConfigs)
		end
		
		if magazineProjectilesPartial then
			if type(magazineProjectilesPartial) == "table" then 
				self.magazineProjectilesPartial = magazineProjectilesPartial[indexedValue]
			else 
				self.magazineProjectilesPartial = magazineProjectilesPartial
			end
			activeItem.setInstanceValue("magazineProjectilePartial",self.magazineProjectilesPartial)
		end
		
		if magazineProjectilePartialConfigs then
			if type(magazineProjectilePartialConfigs) == "table" then 
				self.magazineProjectilePartialConfigs = magazineProjectilePartialConfigs[indexedValue]
			else 
				self.magazineProjectilePartialConfigs = magazineProjectilePartialConfigs
			end
			activeItem.setInstanceValue("magazineProjectilePartialConfig",self.magazineProjectilePartialConfigs)
		end
		
		if fireShellProjectiles then
			if type(fireShellProjectiles) == "table" then 
				self.fireShellProjectiles = fireShellProjectiles[indexedValue]
			else 
				self.fireShellProjectiles = fireShellProjectiles
			end
			activeItem.setInstanceValue("fireShellProjectile",self.fireShellProjectiles)
		end
		
		if fireShellProjectileConfigs then
			if type(fireShellProjectileConfigs) == "table" then 
				self.fireShellProjectileConfigs = fireShellProjectileConfigs[indexedValue]
			else 
				self.fireShellProjectileConfigs = fireShellProjectileConfigs
			end
			activeItem.setInstanceValue("fireShellProjectileConfig",self.fireShellProjectileConfigs)
		end
		
		if ejectProjectileTypes then
			if type(ejectProjectileTypes) == "table" then 
				self.ejectProjectileTypes = ejectProjectileTypes[indexedValue]
			else 
				self.ejectProjectileTypes = ejectProjectileTypes
			end
			activeItem.setInstanceValue("ejectProjectileType",self.ejectProjectileTypes)
		end
		
		if ejectProjectileTypeConfigs then
			if type(ejectProjectileTypeConfigs) == "table" then 
				self.ejectProjectileTypeConfigs = ejectProjectileTypeConfigs[indexedValue]
			else 
				self.ejectProjectileTypeConfigs = ejectProjectileTypeConfigs
			end
			activeItem.setInstanceValue("ejectProjectileTypeConfig",self.ejectProjectileTypeConfigs)
		end
		------------------------------------------------------------------------------------------------
				
				local ammoMaxCurrentValue = 0
				
				if not self.ammoItemChosenTable == false then
					indexedValue = self.ammoItemChosenTable[2]
				end
				
				if self.infAmmo == true or self.npcGun == true then
					indexedValue = config.getParameter("defaultAmmoIndexValue") or 1
				end
				
				if ammoMaxValues then
				if type(ammoMaxValues) == "table" then 
					ammoMaxCurrentValue = ammoMaxValues[indexedValue] 
				else 
					ammoMaxCurrentValue = ammoMaxValues 
				end
				activeItem.setInstanceValue("ammoMax",ammoMaxCurrentValue)
				end
				
				if magazineDamageValues then
				if type(magazineDamageValues) == "table" then 
					magazineDamageValues = magazineDamageValues[indexedValue] 
				else 
					magazineDamageValues = magazineDamageValues 
				end
				activeItem.setInstanceValue("currentDamageAmount",magazineDamageValues)
				end
				
				if ammoMaxValues then
				if type(ammoMaxValues) == "table" then 
					self.weapon.ammoAmount = ammoMaxValues[indexedValue] + (extraBullets or 0) 
				else 
					self.weapon.ammoAmount = ammoMaxValues + (extraBullets or 0) 
				end
				activeItem.setInstanceValue("ammoAmount",self.weapon.ammoAmount)
				end
				
				
				if ammoProjectileType then
				if type(ammoProjectileType) == "table" then 
					self.ammoProjectileType = ammoProjectileType[indexedValue]
				else 
					self.ammoProjectileType = ammoProjectileType
				end
				self.activeAmmoProjectileType = self.ammoProjectileType
				activeItem.setInstanceValue("activeAmmoProjectileType",self.ammoProjectileType)
				end
				
				if ammoProjectileTypeMiss then
				if type(ammoProjectileTypeMiss) == "table" then 
					self.ammoProjectileTypeMiss = ammoProjectileTypeMiss[indexedValue]
				else 
					self.ammoProjectileTypeMiss = ammoProjectileTypeMiss
				end
				self.activeAmmoProjectileTypeMiss = self.ammoProjectileTypeMiss
				activeItem.setInstanceValue("activeAmmoProjectileTypeMiss",self.ammoProjectileTypeMiss)
				end
				
				if ammoProjectileCount then
					if type(ammoProjectileCount) == "table" then 
						self.ammoProjectileCount = ammoProjectileCount[indexedValue]
					else 
						self.ammoProjectileCount = ammoProjectileCount
					end
					self.activeAmmoProjectileCount = self.ammoProjectileCount
					activeItem.setInstanceValue("activeAmmoProjectileCount",self.ammoProjectileCount)
				end
				
				--for mag stuff. single load stuff already finds the current index n stuff, but since today's a new day, i forgot how i did that.
				activeItem.setInstanceValue("activeIndex",indexedValue)
				
				
				self.baseDpsTooltipTemp = ((magazineDamageValues or self.baseDamage) * (self.baseDamageMultiplier or 1.0) * config.getParameter("damageLevelMultiplier"))
				self.damagePerShotTooltipTemp = config.getParameter("tooltipFields")
				self.damagePerShotTooltipTemp["damagePerShotLabel"] = self.baseDpsTooltipTemp			
				activeItem.setInstanceValue("tooltipFields",self.damagePerShotTooltipTemp)
			else
				self.weapon.ammoAmount = self.ammoLoaded
				--activeItem.setInstanceValue("ammoAmount",self.weapon.ammoAmount)
			end

		else
			self.ammoRequired = self.weapon.ammoMax - self.weapon.ammoAmount
			self.ammoLoaded = 0
			self:checkAmmoStatus()
			if player.hasItem({name = self.ammoItemChosen, count = self.ammoRequired}) then
				player.consumeItem({name = self.ammoItemChosen, count = self.ammoRequired})
				
				if config.getParameter("activeAmmoTypeList") then
					local activeAmmoTypeList = config.getParameter("activeAmmoTypeList")
					local ammoItemLoaded = config.getParameter("consumeAmmoType")
					local indexedValue = self.ammoItemChosenTable[2]
					for i = 1, (config.getParameter("ammoMax",1) - self.weapon.ammoAmount) do
						activeAmmoTypeList[#activeAmmoTypeList + 1] = ammoItemLoaded[indexedValue]
					end
					activeItem.setInstanceValue("activeAmmoTypeList",activeAmmoTypeList)
		
					self:setupNewValuesPostAmmo()
				end
				
				self.weapon.ammoAmount = config.getParameter("ammoMax",1)
				activeItem.setInstanceValue("ammoAmount",self.weapon.ammoAmount)
			else
				repeat
					self.ammoLoaded = self.ammoLoaded + 1
					player.consumeItem({name = self.ammoItemChosen, count = 1})
				
				if config.getParameter("activeAmmoTypeList") then
					local activeAmmoTypeList = config.getParameter("activeAmmoTypeList")
					local ammoItemLoaded = config.getParameter("consumeAmmoType")
					local indexedValue = self.ammoItemChosenTable[2]
					activeAmmoTypeList[#activeAmmoTypeList + 1] = ammoItemLoaded[indexedValue]
					activeItem.setInstanceValue("activeAmmoTypeList",activeAmmoTypeList)
		
					self:setupNewValuesPostAmmo()
				end
				
				until self.ammoLoaded == self.ammoRequired or self:checkAmmoStatus() == false
				
				self.weapon.ammoAmount = self.weapon.ammoAmount + self.ammoLoaded
				activeItem.setInstanceValue("ammoAmount",self.weapon.ammoAmount)
			end
		end
	end
	end
end

function GunFire:partReload6()
  -- actually "loads" in the bullets into the magazine here so you can't start the reload, double tap q, and have a fully loaded gun.
  self.lasersightData = self.weapon:setStance(self.stances.partreload6)
  self:laserSightConfig()
  
  self:reloadFunction(1)
  
  if type(config.getParameter("consumeAmmoType")) == "table" and config.getParameter("magazineImages") then
  local magazineImages = config.getParameter("magazineImages")
  if self.npcGun == true or self.infAmmo then
	magazineImages = magazineImages[config.getParameter("defaultAmmoIndexValue") or 1]
  else
	magazineImages = magazineImages[config.getParameter("activeIndex") or 1]
  end
  animator.setGlobalTag("magazineImage", magazineImages)
  
  self:setupInventoryIcon()
  end

  if self.stances.partreload6.duration then
    util.wait(self.stances.partreload6.duration)
  end

  self.weapon.reloading = 0
  animator.setAnimationState("gunState","armed")
  animator.setParticleEmitterActive("hotsmoke", false )
  animator.setParticleEmitterActive("muzzleFlash", false)
  self.lasersightData = self.weapon:setStance(self.stances.idle)
  self:laserSightConfig()
  --self:setState(self.cooldown)
end

function GunFire:reload1()
  self.lasersightData = self.weapon:setStance(self.stances.reload1)
  self:laserSightConfig()
  
  local indexedValue
  if self.consumeAmmoToggle == true and self:checkAmmoStatus() == true then
		if not config.getParameter("consumeAmmoAmount") then
			if self.ammoItemChosenTable then
				indexedValue = self.ammoItemChosenTable[2] 
			else 
				indexedValue = config.getParameter("activeIndex") or config.getParameter("defaultAmmoIndexValue")
			end
			
			if self.npcGun == true or self.infAmmo == true then
				indexedValue = config.getParameter("defaultAmmoIndexValue")
			end
			
			if type(config.getParameter("consumeAmmoType")) == "table" and config.getParameter("magazineImages") then
				local magazineImages = config.getParameter("magazineImages")
				magazineImages = magazineImages[indexedValue]
				animator.setGlobalTag("magazineImage", magazineImages)
			end
		end
  end
  
  if self.stances.reload1.duration then
    util.wait(self.stances.reload1.duration)
  end

  self:setState(self.reload2)
end

function GunFire:reload2()
  self.lasersightData = self.weapon:setStance(self.stances.reload2)
  self:laserSightConfig()

  if self.stances.reload2.duration then
    util.wait(self.stances.reload2.duration)
  end

  self:setState(self.reload3)
end

function GunFire:reload3()
  self.lasersightData = self.weapon:setStance(self.stances.reload3)
  self:laserSightConfig()

  if self.stances.reload3.duration then
    util.wait(self.stances.reload3.duration)
  end

  self:setState(self.reload4)
end

function GunFire:reload4()
  self.lasersightData = self.weapon:setStance(self.stances.reload4)
  self:laserSightConfig()

  if self.stances.reload4.duration then
    util.wait(self.stances.reload4.duration)
  end

  self:setState(self.reload5)
end

function GunFire:reload5()
  self.lasersightData = self.weapon:setStance(self.stances.reload5)
  self:laserSightConfig()

  if self.stances.reload5.duration then
    util.wait(self.stances.reload5.duration)
  end

  self:setState(self.reload6)
end

function GunFire:reload6()
  -- actually "loads" in the bullets into the magazine here so you can't start the reload, double tap q, and have a fully loaded gun.
  self.lasersightData = self.weapon:setStance(self.stances.reload6)
  self:laserSightConfig()
  
  if not config.getParameter( "singleBulletLoad" ) == true then -- prevents extra ammo being consumed
  self:reloadFunction()
  end
  
  if type(config.getParameter("consumeAmmoType")) == "table" and config.getParameter("magazineImages") then
  local magazineImages = config.getParameter("magazineImages")
  if self.npcGun == true or self.infAmmo then
	magazineImages = magazineImages[config.getParameter("defaultAmmoIndexValue") or 1]
  else
	magazineImages = magazineImages[config.getParameter("activeIndex") or 1]
  end
  animator.setGlobalTag("magazineImage", magazineImages)
  
  self:setupInventoryIcon()
  end
  

  if self.stances.reload6.duration then
    util.wait(self.stances.reload6.duration)
  end

  self.weapon.reloading = 0
  animator.setAnimationState("gunState","armed")
  animator.setParticleEmitterActive("hotsmoke", false )
  animator.setParticleEmitterActive("muzzleFlash", false)
  self.lasersightData = self.weapon:setStance(self.stances.idle)
  self:laserSightConfig()
  --self:setState(self.cooldown)
end

function GunFire:cooldown()
  self.lasersightData = self.weapon:setStance(self.stances.cooldown)
  self:laserSightConfig()
  self.weapon:updateAim()

  local progress = 0
  util.wait(self.stances.cooldown.duration, function()
    local from = self.stances.cooldown.weaponOffset or {0,0}
    local to = self.stances.idle.weaponOffset or {0,0}
    self.weapon.weaponOffset = {interp.linear(progress, from[1], to[1]), interp.linear(progress, from[2], to[2])}

    self.weapon.relativeWeaponRotation = util.toRadians(interp.linear(progress, self.stances.cooldown.weaponRotation, self.stances.idle.weaponRotation))
    self.weapon.relativeArmRotation = util.toRadians(interp.linear(progress, self.stances.cooldown.armRotation, self.stances.idle.armRotation))

    progress = math.min(1.0, progress + (self.dt / self.stances.cooldown.duration))
  end)
  animator.setParticleEmitterActive("hotsmoke", false )
  animator.setParticleEmitterActive("muzzleFlash", false)
end


function GunFire:fireProjectile(projectileType, projectileParams, inaccuracy, firePosition, projectileCount,normalFire)
  --local normalFire = normalFire
  --local projectileParams = projectileParams
  --sb.logInfo(sb.printJson(projectileParams.."projectileParams self"..self.projectileParameters))
  local normalFireActual = normalFire
  if not normalFireActual then
  normalFireActual = true
  end
  
  local params
  
  -- additional check to see if this is being fired normally (auto, semi, burst) so grenade attachment can use this function as well
  if normalFireActual == true then
	params = sb.jsonMerge(self.projectileParameters, projectileParams or {})
	params.power = params.power or self:damagePerShot()
  else
	params = projectileParams or self.projectileParameters
	params.power = params.power or self:damagePerShot()
  end
  if config.getParameter("usePowerMultiplier") == true then
	params.powerMultiplier = activeItem.ownerPowerMultiplier()
  else
	params.powerMultiplier = 1
  end
  params.speed = util.randomInRange(params.speed)
  
  local attachmentConfig = config.getParameter("barrelAttachment")
  if attachmentConfig then
	if attachmentConfig.specialAttachmentConfig then						--lotta if statements here but gotta make sure the script don't crash
	if attachmentConfig.specialAttachmentConfig.projectileConfig then
		params = sb.jsonMerge(params, attachmentConfig.specialAttachmentConfig.projectileConfig or {})
		--sb.logInfo(sb.printJson(params))
	end
	end
  end

  --if not projectileType then
  --  projectileType = self.projectileType
  --end
  
  if type(projectileType) == "table" then
    projectileType = projectileType[math.random(#projectileType)]
  end

  --echoutil.logJson(config.getParameter("activeAmmoProjectileCount"))
  local projectileId = 0
  for i = 1, projectileCount or config.getParameter("activeAmmoProjectileCount") or self.projectileCount do
  
	-- additional check to see if this is being fired normally (auto, semi, burst) so grenade attachment can use this function as well
	if normalFire == true then
  
  
	--rolls miss chance. If the pseudo-random number is less or equal to the miss chance, then a "miss" projectile is spawned. "miss" projectile is simply a projectile (could be a table) under "projectileTypeMiss".
	if self.missChanceToggle == true then
	
		--adds up the final chance for a gun to miss based off of the current dynamic missChance variable (currently only set by crouching/not crouching) multiplied by recoil miss chance stuff. Also, no worries if the number goes above 100. If miss chance >100, then the gun will always miss, no questions asked. No bugs, no nothing. Horray.
		local missChanceRoll = self.missChanceVar * (1 + (self.finalDynamicRecoilMissMultiplier or 0) * (self.finalDynamicRecoilSteps or 1))
		--sb.logInfo("endResult "..sb.printJson(missChanceRoll))
		--sb.logInfo("missChanceVar "..sb.printJson(self.missChanceVar))
		--sb.logInfo("finalDynamicRecoilMissMultiplier "..(1 + (self.finalDynamicRecoilMissMultiplier or 0)))
		--sb.logInfo("finalDynamicRecoilSteps "..(self.finalDynamicRecoilSteps or 1))
		
		--sb.logInfo(self.weaponNegativeEffectResultFinal)
		local missChanceResultVar = util.round(math.random(100) / (self.weaponNegativeEffectResultFinal or 1)) --why did i give miss chance a 1.5 multiplier? nobody knows. removed for now because incorrect calcs ain't cool.
		if missChanceResultVar <= missChanceRoll then
			projectileType = config.getParameter("activeAmmoProjectileTypeMiss") or self.projectileTypeMiss
			--sb.logInfo("miss")
		else
			projectileType = config.getParameter("activeAmmoProjectileType") or self.projectileType
			--sb.logInfo("hit")
		end
		--sb.logInfo(sb.printJson(missChanceResultVar))
		
		if type(projectileType) == "table" then
			projectileType = projectileType[math.random(#projectileType)]
		end
	else
		projectileType = config.getParameter("activeAmmoProjectileType") or self.projectileType
		
		if type(projectileType) == "table" then
			projectileType = projectileType[math.random(#projectileType)]
		end
	end
  
	end
  
    if params.timeToLive then
      params.timeToLive = util.randomInRange(params.timeToLive)
    end

    -- used for changing accuracy for stuff like switchFireMode and crouchAccuracy
    if config.getParameter( "switchFireModeAttachment" ) == true or self.crouchAccuracyToggle == true then
	if self.dynamicRecoil == true then
	
	-- projectile spawn only if dynamicRecoil and switchFireMode or crouchAccuracy modules are equipped
	projectileId = world.spawnProjectile(
        projectileType,
        firePosition or self:firePosition(),
        activeItem.ownerEntityId(),
        self:aimVector(self.inaccuracyVariable * (1 + (self.dynamicRecoilMultiplier) * self.dynamicRecoilSteps)),
        false,
        params
      )
	  
	else
	
	-- projectile spawn only if switchFireMode and/or crouchAccuracy modules are equipped
	projectileId = world.spawnProjectile(
        projectileType,
        firePosition or self:firePosition(),
        activeItem.ownerEntityId(),
        self:aimVector(self.inaccuracyVariable),
        false,
        params
      )
	end
	
	else
	
	if self.dynamicRecoil == true then
	-- projectile spawn if only dynamicRecoil module is equipped
	projectileId = world.spawnProjectile(
        projectileType,
        firePosition or self:firePosition(),
        activeItem.ownerEntityId(),
        self:aimVector((inaccuracy or self.inaccuracy) * (1 + (self.dynamicRecoilMultiplier) * self.dynamicRecoilSteps)),
        false,
        params
      )
	
	else
	
	-- normal projectile spawn if no modules are equipped
	projectileId = world.spawnProjectile(
        projectileType,
        firePosition or self:firePosition(),
        activeItem.ownerEntityId(),
        self:aimVector(inaccuracy or self.inaccuracy),
        false,
        params
      )
	  
	end
	end
  end
  return projectileId
  
end

function GunFire:useEnergy()
	return not self.energyUsage
end

function GunFire:firePosition()
  return vec2.add(mcontroller.position(), activeItem.handPosition(self.weapon.muzzleOffset))
end

function GunFire:firePositionAltFire()
  return vec2.add(mcontroller.position(), activeItem.handPosition(self.grenadeMuzzleOffset))
end


function GunFire:aimVector(inaccuracy)
  local aimVector = vec2.rotate({1, 0}, (self.weapon.aimAngle + sb.nrand(inaccuracy, 0)))
  aimVector[1] = aimVector[1] * mcontroller.facingDirection()
  --sb.logInfo(self.weaponNegativeEffectResultFinal)
  --aimVector[1] * (self.weaponNegativeEffectResultFinal or 1) = aimVector[1] * mcontroller.facingDirection() * (self.weaponNegativeEffectResultFinal or 1)
  return aimVector
end

function GunFire:energyPerShot()
  return (self.energyUsage or 0) * self.fireTime * (self.energyUsageMultiplier or 1.0)
end

function GunFire:damagePerShot()

  --if self.infAmmo == true then
  
  --return ((self.baseDamage or (self.baseDps * self.fireTime))+self.bonusDps) * (self.baseDamageMultiplier or 1.0) * config.getParameter("damageLevelMultiplier") * 0.3 / self.projectileCount
  --else
  self.damageUsed = (config.getParameter("currentDamageAmount") or (self.baseDamage or (self.baseDps * self.fireTime)))
  
  return ((self.damageUsed)) * (self.baseDamageMultiplier or 1.0) * config.getParameter("damageLevelMultiplier") / (config.getParameter("activeAmmoProjectileCount") or self.projectileCount)
  --end
end

function GunFire:uninit()
--activeItem.setCursor()
  status.clearPersistentEffects("fireMode")
end
