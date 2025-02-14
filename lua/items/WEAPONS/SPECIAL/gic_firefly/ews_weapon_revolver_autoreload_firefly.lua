require "/items/active/weapons/ranged/ews_weapon.lua"

BigIron = GunFire:new()

function BigIron:init()
  GunFire.init(self)
  
--Slabvolver Incision Start
  
  if not storage.currentTime then storage.currentTime = world.time() end
  
  if math.abs(world.time() - storage.currentTime) > 0.9 and self:checkAmmoStatus() and (self.weapon.ammoAmount == 0) then --automatic reloading
	self:setState(self.reload6)
  end
  
--Slabvolver Incision End
  
  if (not config.getParameter("spentCasings")) then self.spentCasings = 0;
  else self.spentCasings = config.getParameter("spentCasings") end
end

function BigIron:update(dt, fireMode, shiftHeld)
  GunFire.update(self, dt, fireMode, shiftHeld)

--Slabvolver Incision Start  
  
  storage.currentTime = world.time()
  
  if (self.weapon.ammoAmount == 0) and not (self.weapon.reloading == 1) and not (self.weapon.firingquery == 1) 
	and not self.switchingGuns == true then--this one is so guns don't reload when you "switch" it.
		self:setState(self.reload)
	end
  
--Slabvolver Incision End
  
end

function BigIron:auto()
	GunFire.auto(self)
	self.spentCasings = self.spentCasings + 1;
	activeItem.setInstanceValue("spentCasings",self.spentCasings)
end

function BigIron:semi()
	GunFire.semi(self)
	self.spentCasings = self.spentCasings + 1;
	activeItem.setInstanceValue("spentCasings",self.spentCasings)
end

function BigIron:singleload() --SINGLE LOAD RELOAD ANIMS
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
		
		self.lasersightData = self.weapon:setStance(self.stances.reload)
		self:laserSightConfig()
		util.wait(self.stances.reload.duration)
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
  
		until self.weapon.ammoAmount == config.getParameter("ammoMax",1) or self.fireMode == (self.activatingFireMode or self.abilitySlot) or self.fireMode == "alt" or self:checkAmmoStatus() == false
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