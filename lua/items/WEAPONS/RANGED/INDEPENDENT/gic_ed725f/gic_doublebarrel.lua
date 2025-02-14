require "/items/active/weapons/ranged/ews_weapon.lua"

DBS = GunFire:new()

function DBS:init()
  GunFire.init(self)
  
  if (not config.getParameter("spentCasings")) then self.spentCasings = jarray();
  else self.spentCasings = config.getParameter("spentCasings"); end--sb.logInfo(sb.printJson(config.getParameter("spentCasings"))) end
end

function DBS:update(dt, fireMode, shiftHeld)
  GunFire.update(self, dt, fireMode, shiftHeld)
end

function DBS:auto()
	local activeAmmoTypeList = config.getParameter("activeAmmoTypeList")
	local consumeAmmoType = config.getParameter("consumeAmmoType")
	if config.getParameter("twoHanded") == false then consumeAmmoType = config.getParameter("consumeAmmoType2") end
			
	self.spentCasings[#self.spentCasings+1] = self:findInTableIndex(consumeAmmoType, activeAmmoTypeList[#activeAmmoTypeList])
	activeItem.setInstanceValue("spentCasings",self.spentCasings)
	GunFire.auto(self)
end

function DBS:semi()
	local activeAmmoTypeList = config.getParameter("activeAmmoTypeList")
	local consumeAmmoType = config.getParameter("consumeAmmoType")
	if config.getParameter("twoHanded") == false then consumeAmmoType = config.getParameter("consumeAmmoType2") end
			
	self.spentCasings[#self.spentCasings+1] = self:findInTableIndex(consumeAmmoType, activeAmmoTypeList[#activeAmmoTypeList])
	activeItem.setInstanceValue("spentCasings",self.spentCasings)
	GunFire.semi(self)
end

function DBS:switchGunSaveDat()
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
			
			--spent casings data carry over
			local spentCasings = self.spentCasings or config.getParameter("spentCasings") or null
			if spentCasings then 
				local temp = jarray();
				for i = 1,#spentCasings,1 do
					temp[#temp+1] = spentCasings[i]
				end
				params.spentCasings = temp 
			end
			--sb.logInfo(sb.printJson(params.spentCasings))
			--sb.logInfo(sb.printJson(config.getParameter("spentCasings")))
			--sb.logInfo("function")
			---------------------------------------------------------------------------
			
			
			--for misc attachments that modify the fire mode. ie full auto pistol attachment will now properly carry over when switched forms
			--have to do a more blanket thing rather than do another check for a new variable so this is a basic solution for now. should be 100% functional
			local primaryAbility = config.getParameter("primaryAbility")
			local attachmentsAvailable = config.getParameter("attachmentsAvailable")
			if config.getParameter("usesAttachments") and attachmentsAvailable then
				if not self:findInTableIndex(attachmentsAvailable,"misc") == false then
					params.primaryAbility = {}
					params.primaryAbility.fireType = primaryAbility.fireType
				end
			end
			
			
			
			local itemGive = {name = self.switchGunItem, count = 1, parameters = params }
			
			return itemGive
end

function DBS:reload()
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
	
	--custom spawn locations for magazines
	local addedPos
	local shellOffset = config.getParameter("shellOffset")
	if shellOffset then
		local baseOffset = config.getParameter("baseOffset")
		addedPos = vec2.add(shellOffset, baseOffset)
	end
	
	animator.setParticleEmitterActive("hotsmoke", false )
	animator.setParticleEmitterActive("muzzleFlash", false)
	
	activeItem.setInstanceValue("ammoAmount",self.weapon.ammoAmount)
	
			if self.stances.reload.duration then 						--normal reload
				util.wait(self.stances.reload.duration)
				
				local spawnPos = firePosition or self:firePosition()
				if shellOffset then spawnPos = vec2.add(mcontroller.position(), activeItem.handPosition(addedPos)) end
				
				for i = 1,#self.spentCasings, 1 do
					local magazineProjectiles = config.getParameter("magazineProjectiles")
					world.spawnProjectile(magazineProjectiles[self.spentCasings[i]], spawnPos, activeItem.ownerEntityId(),    self:aimVector(inaccuracy or self.finalInaccuracy),false,config.getParameter( "magazineProjectileConfig" ) or {})
				end
				
				activeItem.setInstanceValue("spentCasings",{})
				self.spentCasings = {}
			end
  
			self.cooldownTimer = self.fireTime
			self:setState(self.reload1)
	
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

function DBS:reloadFunction(extraBullets,partialReload)
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
	if config.getParameter("consumeAmmoAmount") and type(config.getParameter("consumeAmmoType")) == "table" and config.getParameter("consumeAmmoModule") == true then
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
		if config.getParameter("consumeAmmoAmount") then
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

function DBS:uninit()
	GunFire.uninit(self)
end