require "/items/active/weapons/ranged/ews_weapon.lua"

SpecialReload = GunFire:new()

function SpecialReload:init()
  GunFire.init(self)
end

function SpecialReload:update(dt, fireMode, shiftHeld)
  GunFire.update(self, dt, fireMode, shiftHeld)
end

function SpecialReload:reload()
    -- reload stuff
	
	self.canReload = self:checkAmmoStatus()
	
	if self:checkAmmoStatus() == true then
	--if self.consumeAmmoModule == true then
	--	player.consumeItem({name = self.consumeAmmoType, count = 1})
	--end
	
	self.lasersightData = self.weapon:setStance(self.stances.reload)
	self:laserSightConfig()
	if not config.getParameter( "partialReloadsEnabled" ) == true then
		animator.setAnimationState("gunState","reloading")
	end
	if not config.getParameter( "partialReloadsEnabled" ) == true and not self.singleBulletLoad == true then
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
	
	
	self.magazineProjectile = config.getParameter("magazineProjectile")
	if config.getParameter("magazineProjectilePartial") then
			self.magazineProjectilePartial = config.getParameter("magazineProjectilePartial")
	end
	animator.setParticleEmitterActive("hotsmoke", false )
	animator.setParticleEmitterActive("muzzleFlash", false)
	
	activeItem.setInstanceValue("ammoAmount",self.weapon.ammoAmount)
	
	-- single bullet load/normal reload stuff, single bullet load parameter toggles this.
	-- single bullet load is to be mostly used for shotguns and the like
	if (not self.singleBulletLoad == true) or (self.singleBulletLoad == nil) then --normal reload
		
		if config.getParameter( "partialReloadsEnabled" ) == true then
			if self.weapon.ammoAmount > 0 then						--partial reload
				animator.playSound("switchAmmoPartial")
				animator.setAnimationState("gunState","reloadingPartial")
				self.lasersightData = self.weapon:setStance(self.stances.partreload)
				self:laserSightConfig()
				
				if self.stances.partreload.duration then
					util.wait(self.stances.partreload.duration)
					
					local spawnPos = firePosition or self:firePosition()
					if shellOffset then spawnPos = vec2.add(mcontroller.position(), activeItem.handPosition(addedPos)) end
					
					if not config.getParameter("spawnedMagazine") then
						world.spawnProjectile(self.magazineProjectilePartial, spawnPos, activeItem.ownerEntityId(),    self:aimVector(inaccuracy or self.finalInaccuracy),false,config.getParameter( "magazineProjectilePartialConfig" ) or {})
					end
					
					activeItem.setInstanceValue("spawnedMagazine",true)
				end
  
				self.cooldownTimer = self.fireTime
				self:setState(self.partReload1)
			else
				animator.playSound("switchAmmo")
				animator.setAnimationState("gunState","reloading")
				
				if self.stances.reload.duration then 					--normal reload
					util.wait(self.stances.reload.duration)
					
					local spawnPos = firePosition or self:firePosition()
					if shellOffset then spawnPos = vec2.add(mcontroller.position(), activeItem.handPosition(addedPos)) end
					
					if not config.getParameter("spawnedMagazine") then
						world.spawnProjectile(self.magazineProjectile, spawnPos, activeItem.ownerEntityId(),    self:aimVector(inaccuracy or self.finalInaccuracy),false,config.getParameter( "magazineProjectileConfig" ) or {})
					end
					
					activeItem.setInstanceValue("spawnedMagazine",true)
				end
     			
				self.cooldownTimer = self.fireTime
				self:setState(self.reload1)
			end
		else
			if self.stances.reload.duration then 						--normal reload
				util.wait(self.stances.reload.duration)
				
				local spawnPos = firePosition or self:firePosition()
				if shellOffset then spawnPos = vec2.add(mcontroller.position(), activeItem.handPosition(addedPos)) end
				
				if not config.getParameter("spawnedMagazine") then
					world.spawnProjectile(self.magazineProjectile, spawnPos, activeItem.ownerEntityId(),    self:aimVector(inaccuracy or self.finalInaccuracy),false,config.getParameter( "magazineProjectileConfig" ) or {})
				end
				activeItem.setInstanceValue("spawnedMagazine",true)
			end
  
			self.cooldownTimer = self.fireTime
			self:setState(self.reload1)
		end
		
	elseif self.singleBulletLoad == true then --single bullet reload
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

function SpecialReload:reload6()
	activeItem.setInstanceValue("spawnedMagazine",false)
	GunFire.reload6(self)
end

function SpecialReload:partReload6()
	activeItem.setInstanceValue("spawnedMagazine",false)
	GunFire.partReload6(self)
end

function SpecialReload:uninit()
	GunFire.uninit(self)
end