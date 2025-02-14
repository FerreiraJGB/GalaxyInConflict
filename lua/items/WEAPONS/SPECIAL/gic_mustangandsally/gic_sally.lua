require "/items/active/weapons/ranged/ews_weapon.lua"

BigIron = GunFire:new()

function BigIron:init()
  GunFire.init(self)
  self.weapon:setStance(self.stances.holstered)
  self.holsterQuery = true
  self.drawingquery = false
  
  if (not config.getParameter("spentCasings")) then self.spentCasings = 0;
  else self.spentCasings = config.getParameter("spentCasings") end
  
  mcontroller.controlModifiers({runningSuppressed = false})
  
  self.focusing = false
  self.shiftHeldDuration = 0
end

-- note to self: what is "self.weapon.firingquery" even used for????? 

function BigIron:update(dt, fireMode, shiftHeld)
  --if self.weapon.currentAbility == nil
    --and self.fireMode == "alt"
	--and not (self.weapon.firingquery == 1)
	--and self.holsterQuery == false
	--and self.drawingquery == false
    --and self.cooldownTimer == 0 then
	
	--self.weapon:setStance(self.stances.holstered)
	--activeItem.setHoldingItem(false,holdingItem)
	--self.weapon.aimAngle = 0
	--self.holsterQuery = true
	--self.drawingquery = false
		
	--end
	
	
  
  --if self.holsterQuery == true then
	--self.weapon:setStance(self.stances.holstered)
  --end
  if (self.fireMode == (self.activatingFireMode or self.abilitySlot) or shiftHeld)
  and not self.focusing
  and self.holsterQuery == true 
  and self.drawingquery == false then
  self.drawingquery = true
  self.weapon.firingquery = 1
  self.cooldownTimer = 0.2
  -- sb.logInfo("trying to draw")
  self:setState(self.draw)
  
  end
  
 if self.weapon.currentAbility == nil
	and shiftHeld
	and self.shiftHeldDuration > 0.2
	-- and not self.focusing
	-- and not (self.weapon.firingquery == 1)
	and self.holsterQuery == false
	and self.drawingquery == false
    -- and self.cooldownTimer == 0
	and self.weapon.ammoAmount > 0 then
	self.cooldownTimer = 0.2
	-- sb.logInfo("trying to aim")
	self.weapon.firingquery = 1
	self:setState(self.aimReady)
 end
 
 if (self.weapon.ammoAmount == 0) and (self.weapon.firingquery == 0) and shiftHeld
		and not self.weapon.currentAbility
		and self.cooldownTimer == 0
		and not self.focusing
		and not self.switchingGuns == true --this one is so guns don't fire when you "switch" it.
		and (not status.resourceLocked("energy") or self:useEnergy()) then
		
	-- sb.logInfo("trying to reload when gun empty")
	self:setState(self.reload)
 end
 
 
 if not shiftHeld then
	self.weapon.firingquery = 0
  end
 --shift reload has to be located here because main weapon code causes big visual bug otherwise
  if self.weapon.ammoAmount < self.weapon.ammoMax 
	and not (self.weapon.reloading == 1) 
	and not self.focusing
	and not (self.weapon.firingquery == 1)
	and (self.holsterQuery == false
	and self.shiftHeldDuration < 0.2
	and self.shiftHeldDuration > 0
	and not shiftHeld
	and self.drawingquery == false) then
	--self.holsterQuery = false
	--self.drawingquery = false
	--self.weapon:setStance(self.stances.holstered)
	-- sb.logInfo("trying to reload?")
	self:setState(self.reload)
  end
  
  self.shiftHeldA = shiftHeld
  if self.shiftHeldA then
	self.shiftHeldDuration = self.shiftHeldDuration + dt
	-- sb.logInfo(self.shiftHeldDuration)
	self.weapon.firingquery = 1
  else
	self.shiftHeldDuration = 0
	self.weapon.firingquery = 0
  end
  
  
  -- sb.logInfo(sb.printJson(self.shiftHeldA))
  GunFire.update(self, dt, fireMode, shiftHeld)
end

function BigIron:mainfirescripts()
 
 if self.holsterQuery == false then
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
 
end

function BigIron:auto()
	GunFire.auto(self)
	self.spentCasings = self.spentCasings + 1;
	activeItem.setInstanceValue("spentCasings",self.spentCasings)
end


function BigIron:aimReady()
  self.lasersightData = self.weapon:setStance(self.stances.aim)
  self:laserSightConfig()
  self.focusing = true
  
  local progress = 0
	util.wait(self.stances.aim.duration, function()
		mcontroller.controlModifiers({runningSuppressed = true})
		local from = self.stances.idle.weaponOffset or {0,0}
		local to = self.stances.aim.weaponOffset or {0,0}
		self.weapon.weaponOffset = {interp.linear(progress, from[1], to[1]), interp.linear(progress, from[2], to[2])}

		self.weapon.relativeWeaponRotation = util.toRadians(interp.linear(progress, self.stances.idle.weaponRotation, self.stances.aim.weaponRotation))
		self.weapon.relativeArmRotation = util.toRadians(interp.linear(progress, self.stances.idle.armRotation, self.stances.aim.armRotation))

		progress = math.min(1.0, progress + (self.dt / self.stances.aim.duration))
	end)
  animator.playSound("aim")
  util.wait(0.1, function ()
	mcontroller.controlModifiers({runningSuppressed = true})
  end)
  
  util.wait(999, function()
	-- mcontroller.controlModifiers({runningSuppressed = true})
    if not (self.shiftHeldA == true) then return true end
  end)
  self.cooldownTimer = 0
  
	local fireOffset = vec2.add(mcontroller.position(), activeItem.handPosition(vec2.add(self.weapon.muzzleOffset, {0,0.3})))
	local primaryAbility = config.getParameter("primaryAbility")
	local params = {power=primaryAbility.baseDamage * 1.0}
	self:fireProjectile(_,params,0.01,fireOffset,_,true)
	world.spawnProjectile("gic_standardbullet_c_huntersmark", fireOffset,activeItem.ownerEntityId(),self:aimVector(0.0),false,{power = 39.6})
	animator.playSound("fire")
	animator.setAnimationState("gunState","firing")
	animator.setParticleEmitterActive("muzzleFlash", true)
	animator.setParticleEmitterEmissionRate("muzzleFlash", 100)
	animator.setParticleEmitterActive("hotsmoke", true)
	animator.setParticleEmitterEmissionRate("hotsmoke", 100)
	animator.setLightActive("muzzleFlash", true)
	self.weapon.ammoAmount = self.weapon.ammoAmount - 1
	activeItem.setInstanceValue("ammoAmount",self.weapon.ammoAmount)
	
	self.spentCasings = self.spentCasings + 1;
	activeItem.setInstanceValue("spentCasings",self.spentCasings)
	
	self.weapon:setStance(self.stances.aimRecoil)
	util.wait(0.05, function ()
		mcontroller.controlModifiers({runningSuppressed = true})
	end)
	animator.setParticleEmitterActive("muzzleFlash", false)
	animator.setParticleEmitterActive("hotsmoke", false)
	animator.setLightActive("muzzleFlash", false)
	local progress = 0
	util.wait(self.stances.aimRecoil.duration, function()
		mcontroller.controlModifiers({runningSuppressed = true})
		local from = self.stances.aimRecoil.weaponOffset or {0,0}
		local to = self.stances.aim.weaponOffset or {0,0}
		self.weapon.weaponOffset = {interp.linear(progress, from[1], to[1]), interp.linear(progress, from[2], to[2])}

		self.weapon.relativeWeaponRotation = util.toRadians(interp.linear(progress, self.stances.aimRecoil.weaponRotation, self.stances.aim.weaponRotation))
		self.weapon.relativeArmRotation = util.toRadians(interp.linear(progress, self.stances.aimRecoil.armRotation, self.stances.aim.armRotation))

		progress = math.min(1.0, progress + (self.dt / self.stances.aim.duration))
	end)
	util.wait(0.65, function ()
		mcontroller.controlModifiers({runningSuppressed = true})
	end)
	
	if self.weapon.ammoAmount == 0 then
		self.focusing = false
		self:setState(self.aimCooldown)
	else
		self:setState(self.aimFire)
	end
end

function BigIron:aimFire()
  self.lasersightData = self.weapon:setStance(self.stances.aim)
  self:laserSightConfig()
  
  if self.shiftHeldA == true then
	  self.weapon.firingquery = 1
	  animator.playSound("aim")
	  util.wait(0.1, function ()
		-- mcontroller.controlModifiers({runningSuppressed = true})
	  end)
	  
	  util.wait(99999, function()
		-- mcontroller.controlModifiers({runningSuppressed = true})
		if not (self.shiftHeldA == true) then return true end
	  end)
	  if (self.weapon.ammoAmount > 0) then
		local fireOffset = vec2.add(mcontroller.position(), activeItem.handPosition(vec2.add(self.weapon.muzzleOffset, {0,0.3})))
		local primaryAbility = config.getParameter("primaryAbility")
		local params = {power=primaryAbility.baseDamage * 1.0}
		self:fireProjectile(_,params,0.01,fireOffset,_,true)
	--	self:fireProjectile("gic_blackgambit_shot",params,0.01,fireOffset,_,true)	
		world.spawnProjectile("gic_standardbullet_c_huntersmark", fireOffset,activeItem.ownerEntityId(),self:aimVector(0.0),false,{power = 55})
		
		animator.playSound("fire")
		animator.setAnimationState("gunState","firing")
		animator.setParticleEmitterActive("muzzleFlash", true)
		animator.setParticleEmitterEmissionRate("muzzleFlash", 100)
		animator.setParticleEmitterActive("hotsmoke", true)
		animator.setParticleEmitterEmissionRate("hotsmoke", 100)
		animator.setLightActive("muzzleFlash", true)
		self.weapon.ammoAmount = self.weapon.ammoAmount - 1
		activeItem.setInstanceValue("ammoAmount",self.weapon.ammoAmount)
		
		self.spentCasings = self.spentCasings + 1;
		activeItem.setInstanceValue("spentCasings",self.spentCasings)
		
		self.weapon:setStance(self.stances.aimRecoil)
		util.wait(0.05, function ()
			mcontroller.controlModifiers({runningSuppressed = true})
		end)
		animator.setParticleEmitterActive("muzzleFlash", false)
		animator.setParticleEmitterActive("hotsmoke", false)
		animator.setLightActive("muzzleFlash", false)
		local progress = 0
		util.wait(self.stances.aimRecoil.duration, function()
			mcontroller.controlModifiers({runningSuppressed = true})
			local from = self.stances.aimRecoil.weaponOffset or {0,0}
			local to = self.stances.aim.weaponOffset or {0,0}
			self.weapon.weaponOffset = {interp.linear(progress, from[1], to[1]), interp.linear(progress, from[2], to[2])}

			self.weapon.relativeWeaponRotation = util.toRadians(interp.linear(progress, self.stances.aimRecoil.weaponRotation, self.stances.aim.weaponRotation))
			self.weapon.relativeArmRotation = util.toRadians(interp.linear(progress, self.stances.aimRecoil.armRotation, self.stances.aim.armRotation))

			progress = math.min(1.0, progress + (self.dt / self.stances.aim.duration))
		end)
		util.wait(0.65, function ()
			mcontroller.controlModifiers({runningSuppressed = true})
		end)
	  end
	  
  end
  
  
  self:setState(self.aimCooldown)
end

function BigIron:aimCooldown()
  if self.shiftHeldA and (self.weapon.ammoAmount > 0) then
	self:setState(self.aimFire)
  else
	mcontroller.controlModifiers({runningSuppressed = false})
	local progress = 0
	util.wait(self.stances.aim.duration, function()
		local from = self.stances.aim.weaponOffset or {0,0}
		local to = self.stances.idle.weaponOffset or {0,0}
		self.weapon.weaponOffset = {interp.linear(progress, from[1], to[1]), interp.linear(progress, from[2], to[2])}

		self.weapon.relativeWeaponRotation = util.toRadians(interp.linear(progress, self.stances.aim.weaponRotation, self.stances.idle.weaponRotation))
		self.weapon.relativeArmRotation = util.toRadians(interp.linear(progress, self.stances.aim.armRotation, self.stances.idle.armRotation))

		progress = math.min(1.0, progress + (self.dt / self.stances.aim.duration))
	end)
	
	self.focusing = false
	self.weapon.firingquery = 0
  end
end

function BigIron:holstered1()
  self.weapon:setStance(self.stances.holstered1)
  self.weapon:updateAim()
  self.drawingquery = true

  local progress = 0
  util.wait(self.stances.holstered1.duration, function()
    local from = self.stances.holstered1.weaponOffset or {0,0}
    local to = self.stances.idle.weaponOffset or {0,0}
    self.weapon.weaponOffset = {interp.linear(progress, from[1], to[1]), interp.linear(progress, from[2], to[2])}

    self.weapon.relativeWeaponRotation = util.toRadians(interp.linear(progress, self.stances.holstered1.weaponRotation, self.stances.idle.weaponRotation))
    self.weapon.relativeArmRotation = util.toRadians(interp.linear(progress, self.stances.holstered1.armRotation, self.stances.idle.armRotation))

    progress = math.min(1.0, progress + (self.dt / self.stances.holstered1.duration))
  end)
  animator.setParticleEmitterActive("hotsmoke", false )
  animator.setParticleEmitterActive("muzzleFlash", false)
  
  
  self.weapon:setStance(self.stances.idle)
end

function BigIron:draw()
  self.weapon:setStance(self.stances.draw)

  local progress = 0
  util.wait(self.stances.draw.duration, function()
    local from = self.stances.draw.weaponOffset or {0,0}
    local to = self.stances.draw2.weaponOffset or {0,0}
    self.weapon.weaponOffset = {interp.linear(progress, from[1], to[1]), interp.linear(progress, from[2], to[2])}

    self.weapon.relativeWeaponRotation = util.toRadians(interp.linear(progress, self.stances.draw.weaponRotation, self.stances.draw2.weaponRotation))
    self.weapon.relativeArmRotation = util.toRadians(interp.linear(progress, self.stances.draw.armRotation, self.stances.draw2.armRotation))

    progress = math.min(1.0, progress + (self.stances.draw.duration))
  end)

  self:setState(self.draw2)
end

function BigIron:draw2()
  self.weapon:setStance(self.stances.draw2)
  animator.playSound("spin")
  
  local progress = 0
  util.wait(self.stances.draw2.duration, function()
    local from = self.stances.draw2.weaponOffset or {0,0}
    local to = self.stances.draw3.weaponOffset or {0,0}
    self.weapon.weaponOffset = {interp.linear(progress, from[1], to[1]), interp.linear(progress, from[2], to[2])}

    self.weapon.relativeWeaponRotation = util.toRadians(interp.linear(progress, self.stances.draw2.weaponRotation, self.stances.draw3.weaponRotation))
    self.weapon.relativeArmRotation = util.toRadians(interp.linear(progress, self.stances.draw2.armRotation, self.stances.draw3.armRotation))

    progress = math.min(1.0, progress + (self.dt / self.stances.draw2.duration))
  end)

  self:setState(self.draw3)
end

function BigIron:draw3()
  self.weapon:setStance(self.stances.draw3)

  local progress = 0
  util.wait(self.stances.draw3.duration, function()
    local from = self.stances.draw3.weaponOffset or {0,0}
    local to = self.stances.draw4.weaponOffset or {0,0}
    self.weapon.weaponOffset = {interp.linear(progress, from[1], to[1]), interp.linear(progress, from[2], to[2])}

    self.weapon.relativeWeaponRotation = util.toRadians(interp.linear(progress, self.stances.draw3.weaponRotation, self.stances.draw4.weaponRotation))
    self.weapon.relativeArmRotation = util.toRadians(interp.linear(progress, self.stances.draw3.armRotation, self.stances.draw4.armRotation))

    progress = math.min(1.0, progress + (self.dt / self.stances.draw3.duration))
  end)

  self:setState(self.draw4)
end

function BigIron:draw4()
  self.weapon:setStance(self.stances.draw4)

  local progress = 0
  util.wait(self.stances.draw4.duration, function()
    local from = self.stances.draw4.weaponOffset or {0,0}
    local to = self.stances.draw5.weaponOffset or {0,0}
    self.weapon.weaponOffset = {interp.linear(progress, from[1], to[1]), interp.linear(progress, from[2], to[2])}

    self.weapon.relativeWeaponRotation = util.toRadians(interp.linear(progress, self.stances.draw4.weaponRotation, self.stances.draw5.weaponRotation))
    self.weapon.relativeArmRotation = util.toRadians(interp.linear(progress, self.stances.draw4.armRotation, self.stances.draw5.armRotation))

    progress = math.min(1.0, progress + (self.dt / self.stances.draw4.duration))
  end)

  self:setState(self.draw5)
end

function BigIron:draw5()
  self.weapon:setStance(self.stances.draw5)

  local progress = 0
  util.wait(self.stances.draw5.duration, function()
    local from = self.stances.draw5.weaponOffset or {0,0}
    local to = self.stances.idle.weaponOffset or {0,0}
    self.weapon.weaponOffset = {interp.linear(progress, from[1], to[1]), interp.linear(progress, from[2], to[2])}

    self.weapon.relativeWeaponRotation = util.toRadians(interp.linear(progress, self.stances.draw5.weaponRotation, self.stances.idle.weaponRotation))
    self.weapon.relativeArmRotation = util.toRadians(interp.linear(progress, self.stances.draw5.armRotation, self.stances.idle.armRotation))

    progress = math.min(1.0, progress + (self.dt / self.stances.draw5.duration))
  end)
  self.holsterQuery = false
  self.drawingquery = false
  self.weapon.firingquery = 0
  self.weapon:setStance(self.stances.idle)
end

function BigIron:reload()
	if self.holsterQuery == false and self.drawingquery == false then
		GunFire.reload(self)
	end
end

function BigIron:singleload() --SINGLE LOAD RELOAD ANIMS
	if self.holsterQuery == false and self.drawingquery == false then
	
	if config.getParameter( "singleBulletLoadPreAnims" ) == true then
		 animator.setAnimationState("gunState","reloadPre")
		 animator.playSound("reloadPre")
		 --self.weapon:setStance(self.stances.reload1)
		
		 self.lasersightData = self.weapon:setStance(self.stances.prereload1)
		 self:laserSightConfig()
		if self.stances.prereload1.duration then
   		 util.wait(self.stances.prereload1.duration)
 		end
		
		
		
		--drops shell casings
		local addedPos = vec2.add(config.getParameter("emptyCasingSpawn"), config.getParameter("baseOffset"))
		for i=1,self.spentCasings,1
		do
			world.spawnProjectile(config.getParameter( "emptyCasingProjectile" ),vec2.add(mcontroller.position(), activeItem.handPosition(addedPos)),activeItem.ownerEntityId(),self:aimVector(0),false,config.getParameter( "emptyCasingProjectileConfig" ))
		end
		self.spentCasings = 0
		activeItem.setInstanceValue("spentCasings",self.spentCasings)
		
		
		
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
  
		until self.weapon.ammoAmount == config.getParameter("ammoMax",1) or self.fireMode == (self.activatingFireMode or self.abilitySlot) or self.fireMode == "shift" or self:checkAmmoStatus() == false
		animator.stopAllSounds("switchAmmo")
		self.weapon.reloading = 0
  
		self.cooldownTimer = self.fireTime
		
		if config.getParameter( "singleBulletLoadAfterAnims" ) == true then
			animator.setAnimationState("gunState","reloadFinal")
			animator.playSound("reloadFinal")
			self:setState(self.reload3)
		else
			
			if self.holsterQuery == false and self.drawingquery == false then
				self.lasersightData = self.weapon:setStance(self.stances.idle)
			end
			--self:setState(self.cooldown)
			animator.setAnimationState("gunState","armed")
		end
	end 
end


-- function BigIron:reload3()
  -- self.weapon:setStance(self.stances.reload3)
  -- animator.playSound("spin")

  -- local progress = 0
			-- util.wait(self.stances.reload3.duration, function()
			-- local from = self.stances.reload3.weaponOffset or {0,0}
			-- local to = self.stances.reload4.weaponOffset or {0,0}
			-- self.weapon.weaponOffset = {interp.linear(progress, from[1], to[1]), interp.linear(progress, from[2], to[2])}

			-- self.weapon.relativeWeaponRotation = util.toRadians(interp.linear(progress, self.stances.reload3.weaponRotation, self.stances.reload4.weaponRotation))
			-- self.weapon.relativeArmRotation = util.toRadians(interp.linear(progress, self.stances.reload3.armRotation, self.stances.reload4.armRotation))

			-- progress = math.min(1.0, progress + (self.dt / self.stances.reload3.duration))
			-- end)

  -- self:setState(self.reload5)
-- end