require "/items/active/weapons/ranged/ews_weapon.lua"

GunFire70 = GunFire:new()

function GunFire70:init()
  GunFire.init(self)
end

function GunFire70:update(dt, fireMode, shiftHeld)
  GunFire.update(self, dt, fireMode, shiftHeld)
end

function GunFire70:singleload() --SINGLE LOAD RELOAD ANIMS
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
		
		local reload1 = self.stances.reload1
		if self.weapon.ammoAmount == 0 then reload1 = self.stances.emptyReload1; animator.setAnimationState("gunState","emptyReloading") end
		self.lasersightData = self.weapon:setStance(reload1)
		self:laserSightConfig()
		util.wait(reload1.duration)
		
		
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
		
		local reload2 = self.stances.reload2
		if self.weapon.ammoAmount == 1 then reload2 = self.stances.emptyReload2 end
		self.lasersightData = self.weapon:setStance(reload2)
		self:laserSightConfig()
		util.wait(reload2.duration)
		if self.weapon.ammoAmount == 1 then animator.setAnimationState("gunState","reloading") end
		
		
		
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

function GunFire70:uninit()
	GunFire.uninit(self)
end