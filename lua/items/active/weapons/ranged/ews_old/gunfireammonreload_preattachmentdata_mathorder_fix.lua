require "/scripts/util.lua"
require "/scripts/interp.lua"
require "/scripts/vec2.lua"
require "/scripts/echo_util.lua"

-- Base gun fire ability
GunFire = WeaponAbility:new()

function GunFire:init()
  self.weapon:setStance(self.stances.idle)
  
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
  
  
  
  -- init detect switchAmmoAttachment toggle variable, enables switch ammo attachment.
  -- switchAmmoAttachment should be renamed to switchFireModeAttachment, but I'm a lazy bum. 
  --Anywho, no harm done with misnaming this- unless you're trying to make a gun yourself and/or if a legitimate switchAmmoAttachment module is made in the future
  if config.getParameter( "switchAmmoAttachment" ) == true then
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
  
  
  if config.getParameter( "npcGun" ) == true then
  self.npcGun = true
  end
  
  -- init resets the empty sound "clicking" for when the player is out of ammunition completely.
  self.emptySoundPlayQuery = false
  
  
  -- init detect & enable missChance module for all guns unless specifically told not to. 
  -- Script in update checks if the field "projectileTypeMiss" exists in the item json before toggling to prevent any possible crashes, since fucky-wucky shit happens if I check primaryAbility fields here.
  if config.getParameter( "missChanceToggle" ) == nil or config.getParameter( "missChanceToggle" ) == true then
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
  
  
  self:setFinalVariables()
  
  
  
  
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
    self.weapon:setStance(self.stances.idle)
  end
  animator.setParticleEmitterActive("hotsmoke", false )
  animator.setParticleEmitterActive("muzzleFlash", false)
  
  
  
  local attachmentConfig = config.getParameter( "sightAttachment" ) -- sets the sight image if an attachment is inserted
  if attachmentConfig then
	if attachmentConfig.attachmentImage then
		animator.setGlobalTag("sightImage", attachmentConfig.attachmentImage)
		self.sightImage = attachmentConfig.attachmentImage
	else
		animator.setGlobalTag("sightImage", "")
	end
  end
  
 local attachmentConfig = config.getParameter( "barrelAttachment" ) -- sets the barrel image if an attachment is inserted
  if attachmentConfig then
	if attachmentConfig.attachmentImage then
		animator.setGlobalTag("barrelImage", attachmentConfig.attachmentImage)
		self.barrelImage = attachmentConfig.attachmentImage
	else
		animator.setGlobalTag("barrelImage", "")
	end
  end
  
  local attachmentConfig = config.getParameter( "underbarrelAttachment" ) -- sets the underbarrel image if an attachment is inserted
  if attachmentConfig then
	if attachmentConfig.attachmentImage then
		animator.setGlobalTag("barrelImage", attachmentConfig.attachmentImage)
		self.underbarrelImage = attachmentConfig.attachmentImage
	else
		animator.setGlobalTag("barrelImage", "")
	end
  end
  
  local attachmentConfig = config.getParameter( "stockAttachment" ) -- sets the stock image if an attachment is inserted
  if attachmentConfig then
	if attachmentConfig.attachmentImage then
		animator.setGlobalTag("stockImage", attachmentConfig.attachmentImage)
		self.stockImage = attachmentConfig.attachmentImage
	else
		animator.setGlobalTag("stockImage", "")
	end
  end
  
  if config.getParameter( "usesAttachments" ) == true then
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
  partImgs["underbarrel"] = self.underbarrelImage
  partImgs["stock"] = self.stockImage
  
  
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
  
  
  
  local partLvls = {}
  partLvls["main"] = 0
  partLvls["sight"] = 10
  partLvls["barrel"] = 10
  partLvls["underbarrel"] = 10
  partLvls["stock"] = 10
  
  --sb.logInfo(sb.printJson(partLvls))
		inventoryIcon = jarray()
		local parts = {"main","sight","barrel","underbarrel","stock"}
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
  
  --sb.logInfo(sb.printJson(inventoryIcon))
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




function GunFire:setFinalVariables()
	self.finalInaccuracy[1] = self.inaccuracy
	self.finalInaccuracyCrouch[1] = (self.crouchInaccuracy or self.finalInaccuracy[1] * 0.4)
	self.finalMissChance[1] = (self.missChance or 0)
	self.finalMissChanceCrouch[1] = (self.missChanceCrouch or self.finalMissChance[1] * 0.4)
	self.finalDynamicRecoilMaxSteps[1] = self.dynamicRecoilMaxSteps
	self.finalDynamicRecoilMultiplier[1] = self.dynamicRecoilMultiplier
	self.finalDynamicRecoilTickDuration[1] = self.dynamicRecoilTickDuration
	self.finalDynamicRecoilMissMultiplier[1] = self.dynamicRecoilMissMultiplier
	
	
	self.finalAltInaccuracy = (self.altInaccuracy or self.finalInaccuracy)
	self.finalAltInaccuracyCrouch = (self.altCrouchInaccuracy or self.finalAltInaccuracy * 0.4)
	self.finalAltMissChance = (self.altMissChance or self.finalMissChance)
	self.finalAltMissChanceCrouch = (self.altMissChanceCrouch or self.finalAltMissChance * 0.4)
	
	
	
  local attachmentConfig = config.getParameter( "sightAttachment" )
  if attachmentConfig then
  if attachmentConfig.attachmentAttached == true then
	local attachmentBonusType = attachmentConfig.attachmentBonusType
	--sb.logInfo(sb.printJson(attachmentBonusType))
	local attachmentBonuses = attachmentConfig.attachmentBonuses
	--sb.logInfo(sb.printJson(attachmentBonuses[1]))
	--self:modifyFinalVariables(self.temp,attachmentBonuses[1],attachmentBonusType)
	
	self.finalInaccuracy = self:modifyFinalVariables(self.finalInaccuracy,attachmentBonuses[1],attachmentBonusType)
	--sb.logInfo(sb.printJson(self.finalInaccuracy))
	self.finalInaccuracyCrouch = self:modifyFinalVariables(self.finalInaccuracyCrouch,attachmentBonuses[2],attachmentBonusType)
	self.finalMissChance = self:modifyFinalVariables(self.finalMissChance,attachmentBonuses[3],attachmentBonusType)
	self.finalMissChanceCrouch = self:modifyFinalVariables(self.finalMissChanceCrouch,attachmentBonuses[4],attachmentBonusType)
	self.finalDynamicRecoilMaxSteps = self:modifyFinalVariables(self.finalDynamicRecoilMaxSteps,attachmentBonuses[5],attachmentBonusType)
	self.finalDynamicRecoilMultiplier = self:modifyFinalVariables(self.finalDynamicRecoilMultiplier,attachmentBonuses[6],attachmentBonusType)
	self.finalDynamicRecoilTickDuration = self:modifyFinalVariables(self.finalDynamicRecoilTickDuration,attachmentBonuses[7],attachmentBonusType)
	self.finalDynamicRecoilMissMultiplier = self:modifyFinalVariables(self.finalDynamicRecoilMissMultiplier,attachmentBonuses[8],attachmentBonusType)
  end
  
  if attachmentConfig.attachmentBonusesAlt then
	local attachmentBonusType = attachmentConfig.attachmentBonusType
	local attachmentBonusesAlt = attachmentConfig.attachmentBonusesAlt
	
	self.finalAltInaccuracy = self:modifyFinalVariables(self.finalAltInaccuracy,attachmentBonusesAlt[1],attachmentBonusType)
	self.finalAltInaccuracyCrouch = self:modifyFinalVariables(self.finalAltInaccuracyCrouch,attachmentBonusesAlt[1],attachmentBonusType)
	self.finalAltMissChance = self:modifyFinalVariables(self.finalAltMissChance,attachmentBonusesAlt[1],attachmentBonusType)
	self.finalAltMissChanceCrouch = self:modifyFinalVariables(self.finalAltMissChanceCrouch,attachmentBonusesAlt[1],attachmentBonusType)
  end
  end
  
  
  
  
  local attachmentConfig = config.getParameter( "barrelAttachment" )
  if attachmentConfig then
  if attachmentConfig.attachmentAttached == true then
	local attachmentBonusType = attachmentConfig.attachmentBonusType
	--sb.logInfo(sb.printJson(attachmentBonusType))
	local attachmentBonuses = attachmentConfig.attachmentBonuses
	--sb.logInfo(sb.printJson(attachmentBonuses[1]))
	--self:modifyFinalVariables(self.temp,attachmentBonuses[1],attachmentSightBonusType)
	
	self.finalInaccuracy = self:modifyFinalVariables(self.finalInaccuracy,attachmentBonuses[1],attachmentBonusType)
	--sb.logInfo(sb.printJson(self.finalInaccuracy))
	self.finalInaccuracyCrouch = self:modifyFinalVariables(self.finalInaccuracyCrouch,attachmentBonuses[2],attachmentBonusType)
	self.finalMissChance = self:modifyFinalVariables(self.finalMissChance,attachmentBonuses[3],attachmentBonusType)
	self.finalMissChanceCrouch = self:modifyFinalVariables(self.finalMissChanceCrouch,attachmentBonuses[4],attachmentBonusType)
	self.finalDynamicRecoilMaxSteps = self:modifyFinalVariables(self.finalDynamicRecoilMaxSteps,attachmentBonuses[5],attachmentBonusType)
	self.finalDynamicRecoilMultiplier = self:modifyFinalVariables(self.finalDynamicRecoilMultiplier,attachmentBonuses[6],attachmentBonusType)
	self.finalDynamicRecoilTickDuration = self:modifyFinalVariables(self.finalDynamicRecoilTickDuration,attachmentBonuses[7],attachmentBonusType)
	self.finalDynamicRecoilMissMultiplier = self:modifyFinalVariables(self.finalDynamicRecoilMissMultiplier,attachmentBonuses[8],attachmentBonusType)
  end
  
  if attachmentConfig.attachmentBonusesAlt then
	local attachmentBonusType = attachmentConfig.attachmentBonusType
	local attachmentBonusesAlt = attachmentConfig.attachmentBonusesAlt
	--sb.logInfo(sb.printJson(config.getParameter( "attachment_stock_bonusesAlt" )))
	
	self.finalAltInaccuracy = self:modifyFinalVariables(self.finalAltInaccuracy,attachmentBonusesAlt[1],attachmentBonusType)
	self.finalAltInaccuracyCrouch = self:modifyFinalVariables(self.finalAltInaccuracyCrouch,attachmentBonusesAlt[1],attachmentBonusType)
	self.finalAltMissChance = self:modifyFinalVariables(self.finalAltMissChance,attachmentBonusesAlt[1],attachmentBonusType)
	self.finalAltMissChanceCrouch = self:modifyFinalVariables(self.finalAltMissChanceCrouch,attachmentBonusesAlt[1],attachmentBonusType)
  end
  end
  
  local attachmentConfig = config.getParameter( "underbarrelAttachment" )
  if attachmentConfig then
  if attachmentConfig.attachmentAttached == true then
	local attachmentBonusType = attachmentConfig.attachmentBonusType
	--sb.logInfo(sb.printJson(attachmentBonusType))
	local attachmentBonuses = attachmentConfig.attachmentBonuses
	--sb.logInfo(sb.printJson(attachmentBonuses[1]))
	--self:modifyFinalVariables(self.temp,attachmentBonuses[1],attachmentSightBonusType)
	
	self.finalInaccuracy = self:modifyFinalVariables(self.finalInaccuracy,attachmentBonuses[1],attachmentBonusType)
	--sb.logInfo(sb.printJson(self.finalInaccuracy))
	self.finalInaccuracyCrouch = self:modifyFinalVariables(self.finalInaccuracyCrouch,attachmentBonuses[2],attachmentBonusType)
	self.finalMissChance = self:modifyFinalVariables(self.finalMissChance,attachmentBonuses[3],attachmentBonusType)
	self.finalMissChanceCrouch = self:modifyFinalVariables(self.finalMissChanceCrouch,attachmentBonuses[4],attachmentBonusType)
	self.finalDynamicRecoilMaxSteps = self:modifyFinalVariables(self.finalDynamicRecoilMaxSteps,attachmentBonuses[5],attachmentBonusType)
	self.finalDynamicRecoilMultiplier = self:modifyFinalVariables(self.finalDynamicRecoilMultiplier,attachmentBonuses[6],attachmentBonusType)
	self.finalDynamicRecoilTickDuration = self:modifyFinalVariables(self.finalDynamicRecoilTickDuration,attachmentBonuses[7],attachmentBonusType)
	self.finalDynamicRecoilMissMultiplier = self:modifyFinalVariables(self.finalDynamicRecoilMissMultiplier,attachmentBonuses[8],attachmentBonusType)
  end
  
  if attachmentConfig.attachmentBonusesAlt then
	local attachmentBonusType = attachmentConfig.attachmentBonusType
	local attachmentBonusesAlt = attachmentConfig.attachmentBonusesAlt
	--sb.logInfo(sb.printJson(config.getParameter( "attachment_stock_bonusesAlt" )))
	
	self.finalAltInaccuracy = self:modifyFinalVariables(self.finalAltInaccuracy,attachmentBonusesAlt[1],attachmentBonusType)
	self.finalAltInaccuracyCrouch = self:modifyFinalVariables(self.finalAltInaccuracyCrouch,attachmentBonusesAlt[1],attachmentBonusType)
	self.finalAltMissChance = self:modifyFinalVariables(self.finalAltMissChance,attachmentBonusesAlt[1],attachmentBonusType)
	self.finalAltMissChanceCrouch = self:modifyFinalVariables(self.finalAltMissChanceCrouch,attachmentBonusesAlt[1],attachmentBonusType)
  end
  end
  
  
  
  
  local attachmentConfig = config.getParameter( "stockAttachment" )
  if attachmentConfig then
  if attachmentConfig.attachmentAttached == true then
	local attachmentBonusType = attachmentConfig.attachmentBonusType
	--sb.logInfo(sb.printJson(attachmentBonusType))
	local attachmentBonuses = attachmentConfig.attachmentBonuses
	--sb.logInfo(sb.printJson(attachmentSightBonuses[1]))
	--self:modifyFinalVariables(self.temp,attachmentSightBonuses[1],attachmentSightBonusType)
	
	self.finalInaccuracy = self:modifyFinalVariables(self.finalInaccuracy,attachmentBonuses[1],attachmentBonusType)
	--sb.logInfo(sb.printJson(self.finalInaccuracy))
	self.finalInaccuracyCrouch = self:modifyFinalVariables(self.finalInaccuracyCrouch,attachmentBonuses[2],attachmentBonusType)
	self.finalMissChance = self:modifyFinalVariables(self.finalMissChance,attachmentBonuses[3],attachmentBonusType)
	self.finalMissChanceCrouch = self:modifyFinalVariables(self.finalMissChanceCrouch,attachmentBonuses[4],attachmentBonusType)
	self.finalDynamicRecoilMaxSteps = self:modifyFinalVariables(self.finalDynamicRecoilMaxSteps,attachmentBonuses[5],attachmentBonusType)
	self.finalDynamicRecoilMultiplier = self:modifyFinalVariables(self.finalDynamicRecoilMultiplier,attachmentBonuses[6],attachmentBonusType)
	self.finalDynamicRecoilTickDuration = self:modifyFinalVariables(self.finalDynamicRecoilTickDuration,attachmentBonuses[7],attachmentBonusType)
	self.finalDynamicRecoilMissMultiplier = self:modifyFinalVariables(self.finalDynamicRecoilMissMultiplier,attachmentBonuses[8],attachmentBonusType)
  end
  
  if attachmentConfig.attachmentBonusesAlt then
	local attachmentBonusType = attachmentConfig.attachmentBonusType
	local attachmentBonusesAlt = attachmentConfig.attachmentBonusesAlt
	
	self.finalAltInaccuracy = self:modifyFinalVariables(self.finalAltInaccuracy,attachmentBonusesAlt[1],attachmentBonusType)
	self.finalAltInaccuracyCrouch = self:modifyFinalVariables(self.finalAltInaccuracyCrouch,attachmentBonusesAlt[1],attachmentBonusType)
	self.finalAltMissChance = self:modifyFinalVariables(self.finalAltMissChance,attachmentBonusesAlt[1],attachmentBonusType)
	self.finalAltMissChanceCrouch = self:modifyFinalVariables(self.finalAltMissChanceCrouch,attachmentBonusesAlt[1],attachmentBonusType)
  end
  end
end




function GunFire:update(dt, fireMode, shiftHeld)
	WeaponAbility.update(self, dt, fireMode, shiftHeld)
	
	if config.getParameter( "holoToggleRequireStat" ) == true and status.stat("ews_holovisor") == 1 and not self.holoToggle == true then
		self.holoToggle = true
	end
	
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
	
	if self.reloadHoldTimer > 0
	and not shiftHeld
	and self.holoToggle == true then
	self.holoTogglerState = true
	else
	self.holoTogglerState = false
	end
	
	
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
	
	
	
	--if miss projectile no existo and toggle is enabled, then disable toggle to prevent le crasho
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
	if config.getParameter( "switchGun" ) == true then
	self.doubleTapShiftTimer = math.max(0, self.doubleTapShiftTimer - self.dt)
	self.spawnReloadTimer = math.max(0, self.spawnReloadTimer - self.dt)
	end
	
	
	if config.getParameter( "switchGun" ) == true then
		if shiftHeld and self.shiftHoldQuery == false and self.doubleTapShiftTimer == 0 then
			
			self.shiftHoldQuery = true
			self.doubleTapShiftTimer = 0.25
			
		end
			
		if shiftHeld and self.shiftHoldQuery == false and self.doubleTapShiftTimer > 0 then
			
			self.switchingGuns = true
			self.switchGunItem = config.getParameter( "switchGunItem" )
			item.consume(1)
			
			local itemGiveParams = {ammoAmount=config.getParameter( "ammoAmount" )}
			local itemGive = {name=self.switchGunItem, count=1, parameters = itemGiveParams }
			player.giveItem(itemGive)
			
			animator.stopAllSounds("switchAmmo")
			--animator.stopSound("switchAmmo")
			
		end
		
		-- here to prevent player from holding down shift for "too long" so instantly hitting shift won't cause the gun to change "grips"
		if not shiftHeld then
		self.shiftHoldQuery = false
		end
	end
	
	
	
	
	
	--old switchGun method which involved holding shift and primary fire. This was an issue because parrying w the one-handed weeb katana was done by holding shift, so this caused the parry/shield ability of the katana to be completely defunct when paired with a EWS sidearm.
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
	
	if config.getParameter( "holoToggle" ) == true then
	
	-- if player only taps reload, then player will reload normally
	if self.reloadHoldTimer > 0 and not shiftHeld 
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
	
		--normal manual reload, but some extra variables are run through to insure no bugs. Hopefully.
		if shiftHeld then -- this one is so guns don't immedietaly reload upon switch, about half second delay before manual reload is re-enabled.
			if self.reloadHoldTimer == 0 and self.reloadHeld == true then
				--if shiftHeld and (self.weapon.ammoAmount < config.getParameter("ammoMax",1)) and not (self.weapon.reloading == 1) and not (self.weapon.firingquery == 1) 
		--and not self.switchingGuns == true --this one is so guns don't reload when you "switch" it.
		--and self.spawnReloadTimer == 0 then
					--self:setState(self.reload)
					--self.reloadHeld = false
				--else
					self.reloadHeld = false
				--end
			elseif self.reloadHoldTimer == 0 then
				self.reloadHoldTimer = 0.2--player has to hold down shift for 0.2 seconds to properly reload. Done to allow other shift-based abilities to exist.
				self.reloadHeld = true
			end
		end
	else
		
		--normal manual reload
		if shiftHeld then
			if self.reloadHoldTimer == 0 and self.reloadHeld == true and self.shiftHeldTmp == false then
				--if shiftHeld and (self.weapon.ammoAmount < config.getParameter("ammoMax",1)) and not (self.weapon.reloading == 1) and not (self.weapon.firingquery == 1) then
					--self:setState(self.reload)
					--self.reloadHeld = false
				--else
					self.reloadHeld = false
					self.shiftHeldTmp = true
				--end
			elseif self.reloadHoldTimer == 0 and self.shiftHeldTmp == false then
			self.reloadHoldTimer = 0.2--player has to tap shift for less than 0.1 seconds to properly reload. Done to allow other shift-based abilities to exist.
			self.reloadHeld = true
			end
		end
	end
	else
	
	if config.getParameter( "switchGun" ) == true then
	
		--normal manual reload, but some extra variables are run through to insure no bugs. Hopefully.
		--if shiftHeld then -- this one is so guns don't immedietaly reload upon switch, about half second delay before manual reload is re-enabled.
			if shiftHeld and (self.weapon.ammoAmount < config.getParameter("ammoMax",1)) and not (self.weapon.reloading == 1) and not (self.weapon.firingquery == 1) 
		and not self.switchingGuns == true --this one is so guns don't reload when you "switch" it.
		and self.spawnReloadTimer == 0 then
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
			if shiftHeld and (self.weapon.ammoAmount < config.getParameter("ammoMax",1)) and not (self.weapon.reloading == 1) and not (self.weapon.firingquery == 1) then
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
		if config.getParameter( "switchAmmoAttachment" ) == true then 
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
	end

	
	-- if animation state = fire, then turn off muzzle flash light
	if animator.animationState("firing") ~= "fire" then
		animator.setLightActive("muzzleFlash", false)
	end
	
	-- update throw item script
	if self.weapon.currentAbility == nil
	and config.getParameter( "throwItemAttachment" ) == true
    and self.fireMode == "alt"
	and not (self.weapon.firingquery == 1)
    and self.cooldownTimer == 0 then
		self:setState(self.throw1)
	end
	
	
	-- update switch ammo script
	if self.weapon.currentAbility == nil
	and config.getParameter( "switchAmmoAttachment" ) == true
    and self.fireMode == "alt"
	and not shiftHeld
    and self.cooldownTimer == 0 then
		if self.changeFireModeHeld == true and self.changeFireModeHoldTimer == 0 then
		if self.fireMode == "alt"
		and not shiftHeld then
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
		
  
  -- detect if fire held
  self.fireHeld = self.fireMode == (self.activatingFireMode or self.abilitySlot)
  
end

-- if i ever want to implement energy usage, here it do be (status.overConsumeResource("energy", self:energyPerShot()) or self:useEnergy())

function GunFire:mainfirescripts()
	if self.fireMode == (self.activatingFireMode or self.abilitySlot) 
		and not self.weapon.currentAbility
		and self.cooldownTimer == 0
		and not self.switchingGuns == true --this one is so guns don't fire when you "switch" it.
		and (not status.resourceLocked("energy") or self:useEnergy())
		and not world.lineTileCollision(mcontroller.position(), self:firePosition()) then
			if (self.weapon.ammoAmount > 0) then
				if self.fireType == "auto" then
					self:setState(self.auto)
				elseif self.fireType == "burst" then
					self:setState(self.burst)
				end
			
				if self.npcGun == true then
					-- if game detects that this is a npcGun from the toggle variable, then the gun won't be semi-auto technically.
					if self.fireType == "semi" then
						self:setState(self.semi)
					end
				elseif not self.fireHeld then
					if self.fireType == "semi" then
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

function GunFire:switchfiremodes()
  -- self explanatory
  self.weapon:setStance(self.stances.switchfiremodes)

  if self.stances.switchfiremodes.duration then
    util.wait(self.stances.switchfiremodes.duration)
  end

  self:setState(self.cooldown)
end

function GunFire:auto()
  --auto fire scripts
	self.weapon:setStance(self.stances.fire)

    self:fireProjectile()
	animator.setPartTag("muzzleFlash", "variant", math.random(1, 3))
	animator.setAnimationState("firing", "fire")
	animator.playSound("fire")
	animator.setParticleEmitterActive("muzzleFlash", true)
	animator.setParticleEmitterEmissionRate("muzzleFlash", 100)
	animator.setParticleEmitterActive("hotsmoke", true)
	animator.setParticleEmitterEmissionRate("hotsmoke", 100)
	animator.setLightActive("muzzleFlash", true)
	self.weapon.ammoAmount = self.weapon.ammoAmount - 1
	--standard animation stuff, enables particles and animation states. also removes one bullet from the magazine since you've just fired a bullet
  
	--variable that prevents certain other actions from happening if the weapon is firing.
	self.weapon.firingquery = 1
	
	--spawns a projectile every time player fires if defined
	if config.getParameter( "fireShellProjectile" ) then
		world.spawnProjectile(config.getParameter( "fireShellProjectile" ),self:firePosition(),activeItem.ownerEntityId(),self:aimVector(self.inaccuracyVariable),false,{})
	end
  
  
  
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
  
  if self.npcGun == true then
	self.cooldownTimer = self.fireTime
	--sb.logInfo(sb.printJson(status.stat("ews_npcfirerate")))
	if status.stat("ews_npcfirerate") > 0 then
		--custom fire rate stat for npcs
		--sb.logInfo(sb.printJson(status.stat("ews_npcfirerate")))
		self.cooldownTimer = status.stat("ews_npcfirerate")
	end
  else
	self.cooldownTimer = self.fireTime
  end
  self:setState(self.motion1)
end

function GunFire:motion1()
  self.weapon:setStance(self.stances.motion1)

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
  self.weapon:setStance(self.stances.motion2)

  if self.stances.motion2.duration then
    util.wait(self.stances.motion2.duration)
  end

  self:setState(self.motion3)
end

function GunFire:motion3()
  self.weapon:setStance(self.stances.motion3)
  

  if self.stances.motion3.duration then
    util.wait(self.stances.motion3.duration)
  end
  
  -- delayed projectile spawn for things like shotguns and bolt actions
  -- spawns delayed projectile after motion3's animation is done
  if config.getParameter( "ejectProjectile" ) == true then
  world.spawnProjectile(config.getParameter( "ejectProjectile" ), self:firePosition(), activeItem.ownerEntityId(),    self:aimVector(inaccuracy or self.inaccuracy),false,{})
  end

  self:setState(self.motion4)
end

function GunFire:motion4()
  self.weapon:setStance(self.stances.motion4)

  if self.stances.motion4.duration then
    util.wait(self.stances.motion4.duration)
  end

  self:setState(self.motion5)
end

function GunFire:motion5()
  self.weapon:setStance(self.stances.motion5)

  if self.stances.motion5.duration then
    util.wait(self.stances.motion5.duration)
  end

  self:setState(self.motion6)
end

function GunFire:motion6()
  self.weapon:setStance(self.stances.motion6)

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
  self.weapon:setStance(self.stances.throw1)

  if self.stances.throw1.duration then
    util.wait(self.stances.throw1.duration)
  end

  self:setState(self.throw2)
end

function GunFire:throw2()
  self.weapon:setStance(self.stances.throw2)
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
  self.weapon:setStance(self.stances.throw3)
  

  if self.stances.throw3.duration then
    util.wait(self.stances.throw3.duration)
  end
  
  
  self:setState(self.throw4)
end

function GunFire:throw4()
  self.weapon:setStance(self.stances.throw4)

  if self.stances.throw4.duration then
    util.wait(self.stances.throw4.duration)
  end

  self:setState(self.throw5)
end

function GunFire:throw5()
  self.weapon:setStance(self.stances.throw5)

  if self.stances.throw5.duration then
    util.wait(self.stances.throw5.duration)
  end

  self:setState(self.throw6)
end

function GunFire:throw6()
  self.weapon:setStance(self.stances.throw6)

  if self.stances.throw6.duration then
    util.wait(self.stances.throw6.duration)
  end

  self:setState(self.cooldown)
  self.weapon.firingquery = 0
end

function GunFire:semi()
	self.weapon:setStance(self.stances.fire)

    self:fireProjectile()
	animator.setPartTag("muzzleFlash", "variant", math.random(1, 3))
	animator.setAnimationState("firing", "fire")
	animator.playSound("fire")
	-- semi-auto yadayada most stuff same as auto
  
	self.weapon.firingquery = 1
	
	--spawns a projectile every time player fires if defined
	if config.getParameter( "fireShellProjectile" ) then
		world.spawnProjectile(config.getParameter( "fireShellProjectile" ),self:firePosition(),activeItem.ownerEntityId(),self:aimVector(self.inaccuracyVariable),false,{})
	end

	animator.setLightActive("muzzleFlash", true)
	animator.setParticleEmitterActive("muzzleFlash", true)
	animator.setParticleEmitterEmissionRate("muzzleFlash", 100)
	animator.setParticleEmitterActive("hotsmoke", true)
	animator.setParticleEmitterEmissionRate("hotsmoke", 100)
	self.weapon.ammoAmount = self.weapon.ammoAmount - 1
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
  self.weapon:setStance(self.stances.fire)
  
  -- burst fire. need i say more?
  -- will say that on my todo list is to optimize this ish. adding recoil to this will be a PITA  

  local shots = math.min(self.burstCount,self.weapon.ammoAmount)
  while shots > 0 and (status.overConsumeResource("energy", self:energyPerShot())or self:useEnergy()) do
	self.weapon.ammoAmount = self.weapon.ammoAmount - 1
	activeItem.setInstanceValue("ammoAmount",self.weapon.ammoAmount)
	--spawns a projectile every time player fires if defined
	if config.getParameter( "fireShellProjectile" ) then
		world.spawnProjectile(config.getParameter( "fireShellProjectile" ),self:firePosition(),activeItem.ownerEntityId(),self:aimVector(self.inaccuracyVariable),false,{})
	end
    self:fireProjectile()
	animator.setPartTag("muzzleFlash", "variant", math.random(1, 3))
	animator.setAnimationState("firing", "fire")
	animator.playSound("fire")
  
  -- increases recoil when recoil module is enabled
  if self.dynamicRecoil == true then
	if self.dynamicRecoilSteps  < self.finalDynamicRecoilMaxSteps  then
	self.dynamicRecoilSteps  = self.dynamicRecoilSteps  + 1
	end
	self.dynamicRecoilTimer = self.finalDynamicRecoilTickDuration
  end

  animator.setLightActive("muzzleFlash", true)
  animator.setParticleEmitterActive("muzzleFlash", true)
  animator.setParticleEmitterEmissionRate("muzzleFlash", 100)
  animator.setParticleEmitterActive("hotsmoke", true)
  animator.setParticleEmitterEmissionRate("hotsmoke", 100)
    shots = shots - 1

    self.weapon.relativeWeaponRotation = util.toRadians(interp.linear(1 - shots / self.burstCount, 0, self.stances.fire.weaponRotation))
    self.weapon.relativeArmRotation = util.toRadians(interp.linear(1 - shots / self.burstCount, 0, self.stances.fire.armRotation))
	
	animator.setAnimationState("gunState","firing")

    util.wait(self.burstTime)
  end

  if config.getParameter( "switchAmmoAttachment" ) == true then
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
	if type(self.consumeAmmoType) == "table" then
		self.ammoItemChosenTable = echoutil.playerHasInTable(self.consumeAmmoType)
		
		if self.ammoItemChosenTable == false then self.ammoItemChosen = false else self.ammoItemChosen = self.ammoItemChosenTable[1] end
		--if consumeAmmoType is an array, then search through the array until a valid ammo that the player has is found. if not found, then return as "false".
		
		--sb.logInfo("ammoitemchosen "..sb.printJson(self.ammoItemChosen))
	else
		self.ammoItemChosen = self.consumeAmmoType
	end
 end
 
end

function GunFire:checkAmmoStatus()
	self:findAmmo() --sets the ammo item chosen
    if config.getParameter("consumeAmmoModule") == true then
	if not self.npcGun == true then -- checks if the consumeAmmo module is on. If not, then the user will always be able to reload. If the module is on, then the user will only be able to reload IF the player still has ammunition left.
	-- only checks if npcGun is not on.
		if not self.infAmmo == true then
			if not self.consumeAmmoToggle == true then
				self.canReload = true
			elseif not self.ammoItemChosen == false then
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
	
	self.weapon:setStance(self.stances.reload)
	if not config.getParameter( "partialReloadsEnabled" ) == true then
		animator.setAnimationState("gunState","reloading")
	end
	if config.getParameter( "partialReloadsEnabled" ) == true or self.singleBulletLoad == true then
		
	else
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
				self.weapon:setStance(self.stances.partreload)
				
				if self.stances.partreload.duration then
					util.wait(self.stances.partreload.duration)
					world.spawnProjectile(self.magazineProjectilePartial, firePosition or self:firePosition(), activeItem.ownerEntityId(),    self:aimVector(inaccuracy or self.finalInaccuracy),false,params)
				end
  
				self.cooldownTimer = self.fireTime
				self:setState(self.partReload1)
			else
				animator.playSound("switchAmmo")
				animator.setAnimationState("gunState","reloading")
				
				if self.stances.reload.duration then 					--normal reload
					util.wait(self.stances.reload.duration)
					world.spawnProjectile(self.magazineProjectile, firePosition or self:firePosition(), activeItem.ownerEntityId(),    self:aimVector(inaccuracy or self.finalInaccuracy),false,params)
				end
     			
				self.cooldownTimer = self.fireTime
				self:setState(self.reload1)
			end
		else
			if self.stances.reload.duration then 						--normal reload
				util.wait(self.stances.reload.duration)
				world.spawnProjectile(self.magazineProjectile, firePosition or self:firePosition(), activeItem.ownerEntityId(),    self:aimVector(inaccuracy or self.finalInaccuracy),false,params)
			end
  
			self.cooldownTimer = self.fireTime
			self:setState(self.reload1)
		end
		
	elseif config.getParameter( "singleBulletLoad" ) == true then --single bullet reload
		
		
		if config.getParameter( "singleBulletLoadPreAnims" ) == true then
		 animator.setAnimationState("gunState","reloadPre")
		 animator.playSound("reloadPre")
		 --self.weapon:setStance(self.stances.reload1)
		
		 self.weapon:setStance(self.stances.prereload1)
		if self.stances.prereload1.duration then
   		 util.wait(self.stances.prereload1.duration)
 		end
		
		self.weapon:setStance(self.stances.prereload2)
		if self.stances.prereload2.duration then
   		 util.wait(self.stances.prereload2.duration)
 		end
		
		self.weapon:setStance(self.stances.prereload3)
		if self.stances.prereload3.duration then
   		 util.wait(self.stances.prereload3.duration)
 		end
		
		self.weapon:setStance(self.stances.reload2)
		util.wait(self.stances.reload2.duration)
		animator.setAnimationState("gunState","reloading")
		end
		
		repeat
		
		animator.playSound("switchAmmo")
		self.weapon:setStance(self.stances.reload1)
		util.wait(self.stances.reload1.duration)
		self.weapon:setStance(self.stances.reload2)
		util.wait(self.stances.reload2.duration)
		self.weapon.ammoAmount = self.weapon.ammoAmount + 1
		--self.weapon.ammoAmount = config.getParameter("ammoMax",1)
		activeItem.setInstanceValue("ammoAmount",self.weapon.ammoAmount)
		
		--self:checkAmmoStatus()
  
		until self.weapon.ammoAmount == config.getParameter("ammoMax",1) or self.fireMode == (self.activatingFireMode or self.abilitySlot) or self:checkAmmoStatus() == false
		self.weapon.reloading = 0
  
		self.cooldownTimer = self.fireTime
		
		if config.getParameter( "singleBulletLoadAfterAnims" ) == true then
		animator.setAnimationState("gunState","reloadFinal")
		animator.playSound("reloadFinal")
		self:setState(self.reload3)
		else
		self:setState(self.cooldown)
		end
	end
	
	else
	
	self.cooldownTimer = self.fireTime
	--self:setState(self.cooldown)
	self.weapon:setStance(self.stances.idle)
	self.weapon:updateAim()
	animator.setParticleEmitterActive("hotsmoke", false )
	animator.setParticleEmitterActive("muzzleFlash", false)
	
	end
end

function GunFire:partReload1()
  self.weapon:setStance(self.stances.partreload1)

  if self.stances.partreload1.duration then
    util.wait(self.stances.partreload1.duration)
  end

  self:setState(self.partReload2)
end

function GunFire:partReload2()
  self.weapon:setStance(self.stances.partreload2)

  if self.stances.partreload2.duration then
    util.wait(self.stances.partreload2.duration)
  end

  self:setState(self.partReload3)
end

function GunFire:partReload3()
  self.weapon:setStance(self.stances.partreload3)

  if self.stances.partreload3.duration then
    util.wait(self.stances.partreload3.duration)
  end

  self:setState(self.partReload4)
end

function GunFire:partReload4()
  self.weapon:setStance(self.stances.partreload4)

  if self.stances.partreload4.duration then
    util.wait(self.stances.partreload4.duration)
  end

  self:setState(self.partReload5)
end

function GunFire:partReload5()
  self.weapon:setStance(self.stances.partreload5)

  if self.stances.partreload5.duration then
    util.wait(self.stances.partreload5.duration)
  end

  self:setState(self.partReload6)
end

function GunFire:reloadFunction(extraBullets)
  if not config.getParameter( "singleBulletLoad" ) == true then -- prevents extra ammo being consumed
  if not config.getParameter("consumeAmmoAmount") and not self.npcGun == true and not self.infAmmo == true then
	if self:checkAmmoStatus() == true then
	self.weapon.ammoAmount = config.getParameter("ammoMax",1) + (extraBullets or 0)
	activeItem.setInstanceValue("ammoAmount",self.weapon.ammoAmount)
	end
  end
  end
  
  -- allows the gun to play the empty "click" sfx again once the player is out of ammo 100% again
  self.emptySoundPlayQuery = false
  
  -- fully loads up the gun if the gun is a "npcGun" or if the gun has infinite spare ammo
  if self.npcGun == true or self.infAmmo == true then
	self.weapon.ammoAmount = config.getParameter("ammoMax",1) + (extraBullets or 0)
	activeItem.setInstanceValue("ammoAmount",self.weapon.ammoAmount)
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
				local indexedValue = self.ammoItemChosenTable[2]
				local ammoMaxCurrentValue = 0
				
				if type(ammoMaxValues) == "table" then 
					ammoMaxCurrentValue = ammoMaxValues[indexedValue] 
				else 
					ammoMaxCurrentValue = ammoMaxValues 
				end
				activeItem.setInstanceValue("ammoMax",ammoMaxCurrentValue)
				
				
				if type(ammoMaxValues) == "table" then 
					magazineDamageValues = magazineDamageValues[indexedValue] 
				else 
					magazineDamageValues = magazineDamageValues 
				end
				activeItem.setInstanceValue("currentDamageAmount",magazineDamageValues)
				
				
				if type(ammoMaxValues) == "table" then 
					self.weapon.ammoAmount = ammoMaxValues[indexedValue] + (extraBullets or 0) 
				else 
					self.weapon.ammoAmount = ammoMaxValues + (extraBullets or 0) 
				end
				activeItem.setInstanceValue("ammoAmount",self.weapon.ammoAmount)
				
				
				self.baseDpsTooltipTemp = (magazineDamageValues * (self.baseDamageMultiplier or 1.0) * config.getParameter("damageLevelMultiplier"))
				self.damagePerShotTooltipTemp = config.getParameter("tooltipFields")
				self.damagePerShotTooltipTemp["damagePerShotLabel"] = self.baseDpsTooltipTemp			
				activeItem.setInstanceValue("tooltipFields",self.damagePerShotTooltipTemp)
			else
				self.weapon.ammoAmount = config.getParameter("ammoMax",1) + (extraBullets or 0)
				activeItem.setInstanceValue("ammoAmount",self.weapon.ammoAmount)
			end

		else
			self.ammoRequired = config.getParameter("consumeAmmoAmount")
			self.ammoLoaded = 0
			if player.hasItem({name = self.ammoItemChosen, count = self.ammoRequired}) then
				player.consumeItem({name = self.ammoItemChosen, count = self.ammoRequired})
				self.weapon.ammoAmount = config.getParameter("ammoMax",1)
				activeItem.setInstanceValue("ammoAmount",self.weapon.ammoAmount)
			else
				repeat
					self.ammoLoaded = self.ammoLoaded + 1
					player.consumeItem({name = self.ammoItemChosen, count = 1})
			
				until self.ammoLoaded == self.ammoRequired or player.hasItem({name = self.ammoItemChosen}) == false
				
				self.weapon.ammoAmount = self.ammoLoaded
				activeItem.setInstanceValue("ammoAmount",self.weapon.ammoAmount)
			end
		end
	end
	end
end

function GunFire:partReload6()
  -- actually "loads" in the bullets into the magazine here so you can't start the reload, double tap q, and have a fully loaded gun.
  self.weapon:setStance(self.stances.partreload6)
  
  
  self:reloadFunction(1)


  if self.stances.partreload6.duration then
    util.wait(self.stances.partreload6.duration)
  end

  self.weapon.reloading = 0
  self:setState(self.cooldown)
end

function GunFire:reload1()
  self.weapon:setStance(self.stances.reload1)

  if self.stances.reload1.duration then
    util.wait(self.stances.reload1.duration)
  end

  self:setState(self.reload2)
end

function GunFire:reload2()
  self.weapon:setStance(self.stances.reload2)

  if self.stances.reload2.duration then
    util.wait(self.stances.reload2.duration)
  end

  self:setState(self.reload3)
end

function GunFire:reload3()
  self.weapon:setStance(self.stances.reload3)

  if self.stances.reload3.duration then
    util.wait(self.stances.reload3.duration)
  end

  self:setState(self.reload4)
end

function GunFire:reload4()
  self.weapon:setStance(self.stances.reload4)

  if self.stances.reload4.duration then
    util.wait(self.stances.reload4.duration)
  end

  self:setState(self.reload5)
end

function GunFire:reload5()
  self.weapon:setStance(self.stances.reload5)

  if self.stances.reload5.duration then
    util.wait(self.stances.reload5.duration)
  end

  self:setState(self.reload6)
end

function GunFire:reload6()
  -- actually "loads" in the bullets into the magazine here so you can't start the reload, double tap q, and have a fully loaded gun.
  self.weapon:setStance(self.stances.reload6)
  
  self:reloadFunction()
  

  if self.stances.reload6.duration then
    util.wait(self.stances.reload6.duration)
  end

  self.weapon.reloading = 0
  self:setState(self.cooldown)
end

function GunFire:cooldown()
  self.weapon:setStance(self.stances.cooldown)
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


function GunFire:fireProjectile(projectileType, projectileParams, inaccuracy, firePosition, projectileCount)
  local params = sb.jsonMerge(self.projectileParameters, projectileParams or {})
  params.power = self:damagePerShot()
  params.powerMultiplier = 1 --activeItem.ownerPowerMultiplier()
  params.speed = util.randomInRange(params.speed)

  --if not projectileType then
  --  projectileType = self.projectileType
  --end
  
  --adds up the final chance for a gun to miss based off of the current dynamic missChance variable (currently only set by crouching/not crouching) multiplied by recoil miss chance stuff. Also, no worries if the number goes above 100. If miss chance >100, then the gun will always miss, no questions asked. No bugs, no nothing. Horray.
  if self.missChanceToggle == true then
  self.missChanceRoll = self.missChanceVar * (1 + (self.finalDynamicRecoilMissMultiplier or 0) * (self.finalDynamicRecoilSteps or 1))
  end
  
  
  --rolls miss chance. If the pseudo-random number is less or equal to the miss chance, then a "miss" projectile is spawned. "miss" projectile is simply a projectile (could be a table) under "projectileTypeMiss".
  if self.missChanceToggle == true then
		self.missChanceResultVar = math.random(100)
	if self.missChanceResultVar <= self.missChanceRoll then
		projectileType = self.projectileTypeMiss
	else
		projectileType = self.projectileType
	end
  else
	projectileType = self.projectileType
  end
  
  if type(projectileType) == "table" then
    projectileType = projectileType[math.random(#projectileType)]
  end

  local projectileId = 0
  for i = 1, (projectileCount or self.projectileCount) do
    if params.timeToLive then
      params.timeToLive = util.randomInRange(params.timeToLive)
    end

    -- used for changing accuracy for stuff like switchFireMode and crouchAccuracy
    if config.getParameter( "switchAmmoAttachment" ) == true or self.crouchAccuracyToggle == true then
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


function GunFire:aimVector(inaccuracy)
  local aimVector = vec2.rotate({1, 0}, self.weapon.aimAngle + sb.nrand(inaccuracy, 0))
  aimVector[1] = aimVector[1] * mcontroller.facingDirection()
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
  
  return ((self.damageUsed)) * (self.baseDamageMultiplier or 1.0) * config.getParameter("damageLevelMultiplier") / self.projectileCount
  --end
end

function GunFire:uninit()
--activeItem.setCursor()
end
