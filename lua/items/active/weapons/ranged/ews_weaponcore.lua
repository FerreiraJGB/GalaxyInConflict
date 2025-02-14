require "/scripts/util.lua"
require "/scripts/vec2.lua"
require "/items/active/weapons/ews_weaponinit.lua"

function generateStatusEffects()
	if not self.statusEffectList then 
		self.statusEffectList = jarray()
	end
end

function mergeEffects(input)
	for i, value in ipairs(input) do
		self.statusEffectList[#self.statusEffectList + 1] = value
    end
end

function init()
  activeItem.setCursor("/cursors/reticle0.cursor")
  animator.setGlobalTag("paletteSwaps", config.getParameter("paletteSwaps", ""))

  self.weapon = Weapon:new()

  self.weapon:addTransformationGroup("weapon", {0,0}, 0)
  self.weapon:addTransformationGroup("muzzle", self.weapon.muzzleOffset, 0)

  local primaryAbility = getPrimaryAbility()
  self.weapon:addAbility(primaryAbility)

  local secondaryAbility = getAltAbility(self.weapon.elementalType)
  if secondaryAbility then
    self.weapon:addAbility(secondaryAbility)
  end

  self.debug = ""
  
  self.weaponDeterioration = config.getParameter("weaponDeterioration")
  
  --self.ammoMax = config.getParameter("ammoMax") or 1
  --self.ammoAmount = config.getParameter("ammoAmount") or 1
  self.weapon.ammoMax = config.getParameter("ammoMax") or 0
  self.weapon.ammoAmount = config.getParameter("ammoAmount") or 0
  self.weapon.altAmmoMax = config.getParameter("altAmmoMax") or 0
  self.weapon.altAmmoAmount = config.getParameter("altAmmoAmount") or 0
  
  local tooltipFields = config.getParameter("tooltipFields")
  tooltipFields["ammoAmountLabel"]=self.weapon.ammoAmount.."/"..self.weapon.ammoMax
  
  if self.weaponDeterioration == true then
	self.weapon.weaponDurability = config.getParameter("weaponDurability")
	self.weapon.weaponDurabilityMax = config.getParameter("weaponDurabilityMax")
	local weaponDurabilityPercentage = echoutil.round(1,(self.weapon.weaponDurability / self.weapon.weaponDurabilityMax) * 100).."%"
	tooltipFields["weaponDurabilityLabel"] = weaponDurabilityPercentage
	--sb.logInfo(config.getParameter("weaponDurability"))
	--sb.logInfo((self.weapon.weaponDurability / self.weapon.weaponDurabilityMax) * 100)
  end
  
  
  -- ATTACHMENT STUFF -- ATTACHMENT STUFF -- ATTACHMENT STUFF --
  if config.getParameter("usesAttachments") then
  
	local attachmentConfig = config.getParameter( "sightAttachment" ) -- sets the sight data if an attachment is inserted
	if attachmentConfig and attachmentConfig.specialAttachmentConfig then
		if attachmentConfig.specialAttachmentConfig.type == "statusEffect" or attachmentConfig.specialAttachmentConfig.type == "scopeStatusEffect" then
			generateStatusEffects()
			mergeEffects(attachmentConfig.specialAttachmentConfig.statusEffects)
		end
	end
	
	local attachmentConfig = config.getParameter( "barrelAttachment" ) -- sets the barrel data if an attachment is inserted
	if attachmentConfig and attachmentConfig.specialAttachmentConfig then
		if attachmentConfig.specialAttachmentConfig.type == "statusEffect" then
			generateStatusEffects()
			mergeEffects(attachmentConfig.specialAttachmentConfig.statusEffects)
		end
	end
  
	local attachmentConfig = config.getParameter( "underbarrelAttachment" ) -- sets the underbarrel data if an attachment is inserted
	if attachmentConfig and attachmentConfig.specialAttachmentConfig then
		if attachmentConfig.specialAttachmentConfig.type == "bipod" then
			self.bipod = true
			--self.bipodLeg1 = attachmentConfig.specialAttachmentConfig.bipodConfig.legPos1
			--self.bipodLeg2 = attachmentConfig.specialAttachmentConfig.legPos2
			self.bipodLegs = {attachmentConfig.specialAttachmentConfig.bipodConfig.legPos1,attachmentConfig.specialAttachmentConfig.bipodConfig.legPos2}
			self.bipodVertex = attachmentConfig.specialAttachmentConfig.bipodConfig.bipodVertex
		elseif attachmentConfig.specialAttachmentConfig.type == "statusEffect" then
			generateStatusEffects()
			mergeEffects(attachmentConfig.specialAttachmentConfig.statusEffects)		
		elseif attachmentConfig.specialAttachmentConfig.type == "grenadelauncher" then
			self.underbarrelgrenadelauncherEnabled = true
			tooltipFields["ammoAmountLabel"] = tooltipFields["ammoAmountLabel"].." ^#999999;|^reset; "..self.weapon.altAmmoAmount.."/"..self.weapon.altAmmoMax
		end
	end
	
	local attachmentConfig = config.getParameter( "stockAttachment" ) -- sets the stock data if an attachment is inserted
	if attachmentConfig and attachmentConfig.specialAttachmentConfig then
		if attachmentConfig.specialAttachmentConfig.type == "statusEffect" then
			generateStatusEffects()
			mergeEffects(attachmentConfig.specialAttachmentConfig.statusEffects)
		end
	end
  end
  
  if (config.getParameter( "missChanceToggle" ) == nil or config.getParameter( "missChanceToggle" ) == true) and primaryAbility.projectileTypeMiss then
	if not tooltipFields.missTitleLabel then
		tooltipFields["missTitleLabel"] = "Base Miss Chances: "
	end
  end
  
  
  activeItem.setInstanceValue("tooltipFields",tooltipFields)
  --sb.logInfo(sb.printJson(animator.partProperty("underbarrel", "offset")))
 -- sb.logInfo(sb.printJson(animator.partPoint("underbarrel", "offset")))
  
  self.weapon:init()
end

function update(dt, fireMode, shiftHeld)
  self.weapon:update(dt, fireMode, shiftHeld)
	
	
	if self.weapon.ammoAmount == 0 then
		if animator.animationState("gunState") == "armed" then
			animator.setAnimationState("gunState","empty")
		end
	elseif animator.animationState("gunState") == "empty" then
		animator.setAnimationState("gunState","armed")
	end
	
	self.weapon.ammoMax = config.getParameter("ammoMax") or 1
	self.weapon.ammoAmount = config.getParameter("ammoAmount") or 1
	self.weapon.altAmmoMax = config.getParameter("altAmmoMax") or 1
	self.weapon.altAmmoAmount = config.getParameter("altAmmoAmount") or 1
	
	local tooltipFields = config.getParameter("tooltipFields")
	tooltipFields["ammoAmountLabel"] = self.weapon.ammoAmount.."/"..self.weapon.ammoMax
	
	if self.weaponDeterioration == true then
		self.weapon.weaponDurability = config.getParameter("weaponDurability") or 1
		self.weapon.weaponDurabilityMax = config.getParameter("weaponDurabilityMax") or 1
		local weaponDurabilityPercentage = echoutil.round(1,(self.weapon.weaponDurability / self.weapon.weaponDurabilityMax) * 100).."%"
		tooltipFields["weaponDurabilityLabel"] = weaponDurabilityPercentage
		--sb.logInfo(util.round(self.weapon.weaponDurability / self.weapon.weaponDurabilityMax) * 100)
	end
	
	if self.underbarrelgrenadelauncherEnabled then
		tooltipFields["ammoAmountLabel"] = tooltipFields["ammoAmountLabel"].." ^#999999;|^reset; "..self.weapon.altAmmoAmount.."/"..self.weapon.altAmmoMax
	end
	
	activeItem.setInstanceValue("tooltipFields",tooltipFields)
	
	if self.statusEffectList then
		status.setPersistentEffects("attachmentStatusEffects", self.statusEffectList)
	end
	
	--shows current fire mode selected if possible to change current fire mode
	if config.getParameter( "switchFireModeAttachment" ) == true then
		--local primaryAbility = config.getParameter("primaryAbility")
		if config.getParameter("fireTypeLastUsed") == "auto" then
			status.setPersistentEffects("fireMode", { "ews_auto" })
		end
		if config.getParameter("fireTypeLastUsed") == "semi" then
			status.setPersistentEffects("fireMode", { "ews_semi" })
		end
		if config.getParameter("fireTypeLastUsed") == "burst" then
			status.setPersistentEffects("fireMode", { "ews_burst" })
		end
	end
	
	if self.bipod == true then
		local animationCustom = config.getParameter( "animationCustom" )
		
		local weaponAngle = self.weapon.relativeWeaponRotation - math.pi/2
		local weaponDetails = {math.cos(weaponAngle),math.sin(weaponAngle)}
	
		-- THIS FUCKING LUA VERSION DOESN'T FUCKING HAVE MATH.ATAN2 --
		-- augggggh --
		function customAtan2(y,x)
			local angle = math.atan(y/x)
		
			if x > 0 then
				angle = math.atan(y/x)
			elseif (x < 0) and (y >= 0) then
				angle = angle + math.pi
			elseif (x < 0) and (y < 0) then
				angle = angle - math.pi
			elseif (x == 0) and (y > 0) then
				angle = math.pi / 2
			elseif (x == 0) and (y < 0) then
				angle = 0 - (math.pi / 2 )
			elseif (x == 0) and (y == 0) then
				angle = 1000               --represents undefined
		end
		
		return angle
		end
		-- translated from C++ from https://stackoverflow.com/questions/40778955/c-creating-atan2-from-atan
		-- because i was lazy
		
		
		function bipodPoint(weaponAngle,x,y) --translates psuedo-cartesian coordinates into cartesian coordinates
			local hypotenuse = math.sqrt(x*x+y*y)
			return {math.cos(weaponAngle)*hypotenuse,math.sin(weaponAngle)*hypotenuse}
		end
	
		local underbarrelOffset = animationCustom.animatedParts.parts.underbarrel.properties.offset
		local underbarrelData = bipodPoint(self.weapon.relativeWeaponRotation+customAtan2(underbarrelOffset[2]+self.weapon.weaponOffset[2],underbarrelOffset[1]+self.weapon.weaponOffset[1]),underbarrelOffset[1]+self.weapon.weaponOffset[1],underbarrelOffset[2]+self.weapon.weaponOffset[2])
	
		--world.debugPoint(vec2.add(mcontroller.position(), activeItem.handPosition(underbarrelData)), "green")
	
		local bipodVertexOffset = underbarrelData --animator.partPoint("underbarrel", "offset")
		local bipodVertex = vec2.add(bipodVertexOffset,bipodPoint(self.weapon.relativeWeaponRotation+customAtan2(self.bipodVertex[2],self.bipodVertex[1]),-self.bipodVertex[1],self.bipodVertex[2]))
	
	
		local bipodAngle1 = weaponAngle + customAtan2(self.bipodLegs[1][2]-self.bipodVertex[2],self.bipodLegs[1][1]-self.bipodVertex[1]) + math.pi/2
		local bipodAngle2 = weaponAngle + customAtan2(self.bipodLegs[2][2]-self.bipodVertex[2],self.bipodLegs[2][1]-self.bipodVertex[1]) + math.pi/2
	
		local bipodleg1 = vec2.add(bipodVertex,bipodPoint(bipodAngle1,self.bipodLegs[1][1]-self.bipodVertex[1],self.bipodLegs[1][2]-self.bipodVertex[2]))
		local bipodleg2 = vec2.add(bipodVertex,bipodPoint(bipodAngle2,self.bipodLegs[2][1]-self.bipodVertex[1],self.bipodLegs[2][2]-self.bipodVertex[2]))
		
		
		world.debugPoint(vec2.add(mcontroller.position(), activeItem.handPosition(bipodleg1)), "yellow")
		world.debugPoint(vec2.add(mcontroller.position(), activeItem.handPosition(bipodleg2)), "yellow")
		
		world.debugPoint(vec2.add(mcontroller.position(), activeItem.handPosition(bipodVertex)), "red")
		
		
		world.debugLine(vec2.add(mcontroller.position(), activeItem.handPosition(bipodVertex)), vec2.add(mcontroller.position(), activeItem.handPosition(bipodleg1)), "red")
		world.debugLine(vec2.add(mcontroller.position(), activeItem.handPosition(bipodVertex)), vec2.add(mcontroller.position(), activeItem.handPosition(bipodleg2)), "red")
		
	
		local collision1 = world.lineCollision(vec2.add(mcontroller.position(), activeItem.handPosition(bipodVertex)), vec2.add(mcontroller.position(), activeItem.handPosition(bipodleg1)),{"Block","Dynamic","Platform"})
		local collision2 = world.lineCollision(vec2.add(mcontroller.position(), activeItem.handPosition(bipodVertex)), vec2.add(mcontroller.position(), activeItem.handPosition(bipodleg2)),{"Block","Dynamic","Platform"})
		
		--sb.logInfo(sb.printJson(type(collision1)))
		
		if type(collision1) == "table" or type(collision2) == "table" then
			status.setPersistentEffects("bipodAttached", { "ews_bipod" })
		else
			status.clearPersistentEffects("bipodAttached")
		end
	end
end

function uninit()
  self.weapon:uninit()
  status.clearPersistentEffects("fireMode")
  status.clearPersistentEffects("bipodAttached")
  
  if self.statusEffectList then
	status.clearPersistentEffects("attachmentStatusEffects")
  end
end
