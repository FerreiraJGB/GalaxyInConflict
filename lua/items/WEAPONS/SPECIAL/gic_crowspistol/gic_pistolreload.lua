require "/items/active/weapons/ranged/ews_weapon.lua"

OnehandedPistol = GunFire:new()

function OnehandedPistol:init()
  GunFire.init(self)
  
  self.doubleTapShiftTimer = 0
end

function OnehandedPistol:update(dt, fireMode, shiftHeld)
	WeaponAbility.update(self, dt, fireMode, shiftHeld)
	
	--animator.resetTransformationGroup("muzzle")
	--animator.translateTransformationGroup("muzzle", self.weapon.muzzleOffset)
	
	--does durability calcs
	self:updateWeaponDeterioration()
	
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
	if not self.npcGun == true and status.stat("ews_npcgun") == 1 then
		self.npcGun = true
	end
	
	
	--enables the weapon to have infinite spare ammo, albiet with a 40% reduction in damage output.
	-- SirBucketKicker - 1-19-22: damage output reduction wtf? look into removing/making configureable at later date
	if not config.getParameter( "alwaysUseAmmo" ) == true and not self.infAmmo == true and status.stat("ews_infammo") == 1 then
		self.infAmmo = true
	end
	
	
	-- dynamic recoil timer
	if self.dynamicRecoil == true then
		self.dynamicRecoilTimer = math.max(0, self.dynamicRecoilTimer - self.dt)
		
		-- ticks down recoil after time
		if self.dynamicRecoilTimer == 0 then
			if self.dynamicRecoilSteps > 0 then
				self.dynamicRecoilSteps  = self.dynamicRecoilSteps - 1
				self.dynamicRecoilTimer = self.dynamicRecoilTickDuration
			end
		end
	end
	
	
	--if switch gun module is enabled and shift+primary fire, then "switches" the current gun into the other specified gun.
	--more or less spawns another gun then original gun suicides.
	--don't do suicide kids.
	--I do not promote nor do I encourage suicide
	--kek plz don't sue me for that.
	
	
	
	--if config.getParameter( "switchGun" ) == true and not self.jammed == true and not self.unjamming == true then
		
		--timer for the double-tap shift function
		self.doubleTapShiftTimer = math.max(0, self.doubleTapShiftTimer - self.dt)
		self.spawnReloadTimer = math.max(0, self.spawnReloadTimer - self.dt)
		
	
		if shiftHeld and self.shiftHoldQuery == false and self.doubleTapShiftTimer == 0 then
			self.shiftHoldQuery = true
			self.doubleTapShiftTimer = 0.25
		end
			
		if shiftHeld and self.shiftHoldQuery == false and self.doubleTapShiftTimer > 0 and (self.weapon.ammoAmount < self.weapon.ammoMax) then --reload is triggered on double-tap of shift rather than single hold
			self:setState(self.reload)
			--self.switchingGuns = true
			--self.switchGunItem = config.getParameter( "switchGunItem" )
			--item.consume(1)
			
			--local targItem = self:switchGunSaveDat()
			--player.giveItem(targItem)
			
			--animator.stopAllSounds("switchAmmo")
			--animator.stopSound("switchAmmo")
			
		end
		
		-- here to prevent player from holding down shift for "too long" so instantly hitting shift won't cause the gun to change "grips"
		if not shiftHeld then
			self.shiftHoldQuery = false
		end
	--end
	
	
	
	
	
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
		self:updateNPCAutoReload()
		self:setState(self.reload)
	end
	
	-- NPC AUTO RELOAD  SCRIPTS --
	-- hopefully won't run into a situation where the far above hold shift code and the mainfirescripts triggers with this code;
	if self.npcAutoReload then
		self.npcAutoReloadTimer = math.max(0,self.npcAutoReloadTimer - self.dt)
	
		if self.npcAutoReloadTimer == 0 and (self.weapon.firingquery == 0) and (self.weapon.ammoAmount < config.getParameter("ammoMax",1)) then
			self:updateNPCAutoReload()
			self:setState(self.reload)
		end
	end
	
	
	--------------------
	-- JAMMING SCRIPTS--
	--------------------
	
	if (self.jammed == true and not self.unjamming == true) 
	and shiftHeld--(self.fireMode == (self.activatingFireMode or self.abilitySlot) and self.fireHeld == false) --shiftHeld
	then
		self.unjamming = true
		self:setState(self.jammedState)
	end
	
	
	
	
	
	
	-----------------------------------------------------------------------------------------------------------------------------------------------------------------
	---NOTE TO SELF- BELOW STUFF INVOLVES MANUAL RELOADING. HOLY SHIT THIS CODE IS MESSY - 3-1-21
	-- like seriously what the fuck are these logic scripts? half of the comments are wrong or something
	-- A C K
	-- clean up later when mostly done with EWS cus I can't be arsed to clean this up.  ETA unknown.
	-----------------------------------------------------------------------------------------------------------------------------------------------------------------
	-- note- kinda have cleaned up? - 5-20-21
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
					self.reloadHeld = false
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
					self.reloadHeld = false
					self.shiftHeldTmp = true
				elseif self.reloadHoldTimer == 0 and self.shiftHeldTmp == false 
				and not self.unjamming == true --for jamming scripts
				and not self.jammed == true then
					self.reloadHoldTimer = 0.2--player has to tap shift for less than 0.2 seconds to properly reload. Done to allow other shift-based abilities to exist.
					self.reloadHeld = true
				end
			end
		end
	
	else
	
		if config.getParameter( "switchGun" ) == true then
	
			--normal manual reload, but some extra variables are run through to ensure no bugs. Hopefully.
			-- this one is so guns don't immedietaly reload upon switch, about half second delay before manual reload is re-enabled.
			if shiftHeld and (self.weapon.ammoAmount < config.getParameter("ammoMax",1)) and not (self.weapon.reloading == 1) and not (self.weapon.firingquery == 1) 
			and not self.switchingGuns == true --this one is so guns don't reload when you "switch" it.
			and self.spawnReloadTimer == 0
			and not self.jammed == true 
			and not self.unjamming == true then --for jamming scripts
				--self:setState(self.reload)
			end
		else
			--normal manual reload
			if shiftHeld and (self.weapon.ammoAmount < config.getParameter("ammoMax",1)) and not (self.weapon.reloading == 1) and not (self.weapon.firingquery == 1) 
			and not self.jammed == true 
			and not self.unjamming == true then --for jamming scripts
				--self:setState(self.reload)
			end
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
	
	
	
	------------------------------------------------------------------------------------------------------------------
	-- DISABLED FOR NOW --
	-- main issue is balancing the throw attachment with an ammo econ, and I'm far too lazy right now to set one up.
	-- so for the time being, this is disabled.
	------------------------------------------------------------------------------------------------------------------
	
	-- update throw item script
	--if self.weapon.currentAbility == nil
	--and config.getParameter( "throwItemAttachment" ) == true
    --and self.fireMode == "alt"
	--and not (self.weapon.firingquery == 1)
    --and self.cooldownTimer == 0 then
		--self:setState(self.throw1)
	--end
	
	
	
	
	
	-----------------------------------------------------------------------------------------------------------------------------------------------------------------
	-- update switch ammo script
	-----------------------------------------------------------------------------------------------------------------------------------------------------------------
	-- (note: consider consolidating switch ammo and grenade launcher scripts into one?)
	
	if self.weapon.currentAbility == nil
	and config.getParameter( "switchFireModeAttachment" ) == true
    and self.fireMode == "alt"
	and not shiftHeld
	and not self.unjamming == true --for jamming scripts
	--and not self.jammed == true
    and self.cooldownTimer == 0 then
		if self.changeFireModeHeld == true and self.changeFireModeHoldTimer == 0 then
		
			--stops hold alt fire for grenade launcher scripts
			self.altFireHeldTimer = 0.2
			self.altFireHeld = true
			
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
	
	
	if self.altFireHeldTimer >= 0.2 then
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
			
			--stops hold alt fire for switch fire mode scripts
			self.changeFireModeHoldTimer = 0.2
			self.changeFireModeHeld = false
			
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
  
  --world.debugText("altFireHeldTimer: " .. sb.printJson(self.altFireHeldTimer), vec2.add(mcontroller.position(), {0,1.0}), "red")
  --world.debugText("altFireHeld: " .. sb.printJson(self.altFireHeld), vec2.add(mcontroller.position(), {0,2.0}), "red")
  --world.debugText("altFireHeldMarker: " .. sb.printJson(self.altFireHeldMarker), vec2.add(mcontroller.position(), {0,3.0}), "red")
  
  
  -- main fire update scripts
  self:mainfirescripts()
  
  --if debug mode is enabled, here's all the scripts for displaying debug related texts.
  self:debugMode()
  
  
  --attempt to allow "priming" of semi-auto mode, i.e. can hold m1 down before animation finishes to get one shot off after animation finishes
  --basically QOL change to permit for less "precise" inputs; useful when encountering lots of ingame lag
  if not (self.semiPrimed or self.fireHeld or self.needResetSemiPrime) and self.fireMode == (self.activatingFireMode or self.abilitySlot) then
	self.semiPrimed = true
  end
  
  -- detect if fire held
  self.fireHeld = self.fireMode == (self.activatingFireMode or self.abilitySlot)
  if not self.fireHeld then 
	self.semiPrimed = false
	self.needResetSemiPrime = false
  end
end
