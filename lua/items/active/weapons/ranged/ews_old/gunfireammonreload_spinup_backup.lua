require "/scripts/util.lua"
require "/scripts/interp.lua"

-- Base gun fire ability
GunFire = WeaponAbility:new()

function GunFire:init()
  self.weapon:setStance(self.stances.idle)
  
  --spinup stuff
  self.spinupFireRate = 0.05
  self.spinupTimerMax = 0.25 + 0
  self.spinupTimer = self.spinupTimerMax
  
  
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
  
  
  -- init detect & enable crouchAccuracy module for all guns unless specifically told not to
  if config.getParameter( "crouchAccuracy" ) == nil or config.getParameter( "crouchAccuracy" ) == true then
  self.crouchAccuracyToggle = true
  end
  
  -- crouchAccuracy variables setup
  if self.crouchAccuracyToggle == true then
  self.inaccuracyVariable = self.inaccuracy
  
  -- if no crouchInaccuracy variable is found, this script automatically creates one with a 60% accuracy increase.
  if not self.crouchInaccuracy then
	self.crouchInaccuracy = self.inaccuracy * 0.4
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
  self.weapon.cocked = not( self.fireType == "bolt" )
  self.weapon.onLeaveAbility = function()
    self.weapon:setStance(self.stances.idle)
  end
  animator.setParticleEmitterActive("hotsmoke", false )
  animator.setParticleEmitterActive("muzzleFlash", false)
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
	
	--spinup update stuff
	self.spinupTimer = math.max(0, self.spinupTimer - self.dt)
  

  
  if self.spinupTimer == 0 then
	--self.spinupFireRate = 0
	if self.spinupFireRate > 0 then
		self.spinupFireRate = self.spinupFireRate - 0.025
	end
	if self.spinupFireRate < 0 then
		self.spinupFireRate = 0
	end
	self.spinupTimer = self.spinupTimerMax
  end
	
	--method to automatically designate a gun as a "npcGun"
	if status.stat("ews_npcgun") == 1
	and not self.npcGun == true then
		self.npcGun = true
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
				self.inaccuracyVariable = (self.crouchInaccuracy or self.inaccuracy * 0.4)
				
				--miss chance module stuff. if crouching, miss chance is reduced by 60% unless otherwise specified
					if self.missChanceToggle == true then
						if not self.missChanceCrouch then
							self.missChanceVar = self.missChance * 0.4
						else
							self.missChanceVar = self.missChanceCrouch
						end
					end
				else
					self.inaccuracyVariable = self.inaccuracy
				
					--miss chance module stuff
					if self.missChanceToggle == true then
						self.missChanceVar = self.missChance
					end
				end
			else 
			--alt fire
			if self.fireType == self.altFireType then
				if mcontroller.crouching() then
				self.inaccuracyVariable = (self.altCrouchInaccuracy or (self.altInaccuracy * 0.4))
				--miss chance module stuff. if crouching, miss chance is reduced by 60% unless otherwise specified
					if self.missChanceToggle == true then
						if not self.altMissChanceCrouch then
							self.missChanceVar = (self.altMissChance or self.missChance) * 0.4
						else
							self.missChanceVar = (self.altMissChanceCrouch or self.missChanceCrouch)
						end
					end
					
				else
				
					self.inaccuracyVariable = self.altInaccuracy
					--miss chance module stuff
					if self.missChanceToggle == true then
						self.missChanceVar = (self.altMissChance or self.missChance)
					end
				end
			end
			end
		else
		-- standard check
			if mcontroller.crouching() then
				self.inaccuracyVariable = (self.crouchInaccuracy or self.inaccuracy * 0.4)
				
				--miss chance module stuff. if crouching, miss chance is reduced by 60% unless otherwise specified
				if self.missChanceToggle == true then
					if not self.altMissChanceCrouch then
						self.missChanceVar = self.missChance * 0.4
					else
						self.missChanceVar = self.missChanceCrouch
					end
				end
			else
				self.inaccuracyVariable = self.inaccuracy
				
				--miss chance module stuff
				if self.missChanceToggle == true then
					self.missChanceVar = self.missChance
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
  

  -- main fire update scripts
  if self.fireMode == (self.activatingFireMode or self.abilitySlot) 
    and not self.weapon.currentAbility
    and self.cooldownTimer == 0
	and not self.switchingGuns == true --this one is so guns don't fire when you "switch" it.
    and (not status.resourceLocked("energy") or self:useEnergy())
    and not world.lineTileCollision(mcontroller.position(), self:firePosition()) then
		if (self.weapon.ammoAmount > 0) and (self.weapon.cocked) then
			if self.fireType == "auto" and (status.overConsumeResource("energy", self:energyPerShot()) or self:useEnergy()) then
				self:setState(self.auto)
			elseif self.fireType == "burst" then
				self:setState(self.burst)
			elseif self.npcGun == true then
				-- if game detects that this is a npcGun from the toggle variable, then the gun won't be semi-auto technically.
				if self.fireType == "semi" and (status.overConsumeResource("energy", self:energyPerShot()) or self:useEnergy()) then
					self:setState(self.semi)
				end
			elseif not self.fireHeld then
				if self.fireType == "semi" and (status.overConsumeResource("energy", self:energyPerShot()) or self:useEnergy()) then
					self:setState(self.semi)
				end
			elseif self.fireType == "bolt" then
				self.weapon.cocked = false
				self:setState(self.semi)
			end
		else
			if not self.fireHeld --and self.weapon.cocked then
			and self.emptySoundPlayQuery == false then
			    --disabled bolt stuff here since GiC doesn't really use it
				--if self.fireType == "bolt" and self.weapon.cocked then
					--self.weapon.cocked = false
				--end
				animator.playSound("empty")	
				self:setState(self.cooldown)
				
				if self.consumeAmmoToggle == true and (self.weapon.ammoAmount == 0) then
				self.emptySoundPlayQuery = true
				end
			end
			
			
			--okay look i tried to make the "empty" sfx work properly without spamming your eardrums into oblivion, but it don't work. and apparently real life guns don't click when empty. Thanks Medic.
		end
		
		if (self.weapon.ammoAmount == 0) and (self.weapon.firingquery == 0) then
			if self.fireType == "auto" and (status.overConsumeResource("energy", self:energyPerShot()) or self:useEnergy()) then
				self:setState(self.reload)
			elseif not self.fireHeld then
				if self.fireType == "semi" and (status.overConsumeResource("energy", self:energyPerShot()) or self:useEnergy()) then
					self:setState(self.reload)
				end
			--elseif self.fireType == "bolt" then
				--self.weapon.cocked = false
				--self:setState(self.reload)
				-- bolt stuff is literally unused. Used in original Guns n Ammo, but not here.
			elseif self.fireType == "burst" then
				self:setState(self.reload)
			end
			end
		
  end
  
  -- detect if fire held
  self.fireHeld = self.fireMode == (self.activatingFireMode or self.abilitySlot)
  
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
  
  
  
  -- increases recoil when recoil module is enabled
  if self.dynamicRecoil == true then
	if self.dynamicRecoilSteps  < self.dynamicRecoilMaxSteps  then
	self.dynamicRecoilSteps  = self.dynamicRecoilSteps  + 1
	end
	self.dynamicRecoilTimer = self.dynamicRecoilTickDuration
	
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
  if self.weapon.ammoCasing then
	world.spawnItem(self.weapon.ammoCasing,mcontroller.position(),1,_)
  end
  
  -- takes away one boolet from magazine, for real this time
  activeItem.setInstanceValue("ammoAmount",self.weapon.ammoAmount)
  animator.setAnimationState("gunState","firing")
  
  --if not self.spinupFireRate == 0.2 or not self.spinupFireRate > 0.2 then
  self.spinupFireRate = self.spinupFireRate + 0.0125
  --end
  if self.spinupFireRate > 0.15 then
  self.spinupFireRate = 0.15
  end
  self.spinupTimer = self.spinupTimerMax + 0.1
  
  -- stance yadaydada, motion1-6 are stances basically
  if self.stances.fire.duration then
    util.wait(self.stances.fire.duration)
  end
  
  
  --self.cooldownTimer = self.fireTime
  self.cooldownTimer = self.fireTime - self.spinupFireRate
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
  
  -- delayed projectile spawn for things like shotguns and bolt actions
  if config.getParameter( "ejectProjectile" ) == true then
  self.shellProjectile = config.getParameter( "shellProjectile" )
  end

  if self.stances.motion3.duration then
    util.wait(self.stances.motion3.duration)
  end
  
  -- spawns delayed projectile after motion3's animation is done
  if config.getParameter( "ejectProjectile" ) == true then
  world.spawnProjectile(self.shellProjectile, firePosition or self:firePosition(), activeItem.ownerEntityId(),    self:aimVector(inaccuracy or self.inaccuracy),false,params)
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

  animator.setLightActive("muzzleFlash", true)
  animator.setParticleEmitterActive("muzzleFlash", true)
  animator.setParticleEmitterEmissionRate("muzzleFlash", 100)
  animator.setParticleEmitterActive("hotsmoke", true)
  animator.setParticleEmitterEmissionRate("hotsmoke", 100)
	self.weapon.ammoAmount = self.weapon.ammoAmount - 1
	if self.weapon.ammoCasing then
		world.spawnItem(self.weapon.ammoCasing,mcontroller.position(),1,_)
	end
	activeItem.setInstanceValue("ammoAmount",self.weapon.ammoAmount)
	animator.setAnimationState("gunState","firing")
  
  if self.stances.fire.duration then
    util.wait(self.stances.fire.duration)
  end
  
   -- increases recoil when recoil module is enabled
  if self.dynamicRecoil == true then
	if self.dynamicRecoilSteps  < self.dynamicRecoilMaxSteps  then
	self.dynamicRecoilSteps  = self.dynamicRecoilSteps  + 1
	end
	self.dynamicRecoilTimer = self.dynamicRecoilTickDuration
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
	if self.weapon.ammoCasing then
		world.spawnItem(self.weapon.ammoCasing,mcontroller.position(),1,_)
	end
    self:fireProjectile()
  animator.setPartTag("muzzleFlash", "variant", math.random(1, 3))
  animator.setAnimationState("firing", "fire")
  animator.playSound("fire")
  
  -- increases recoil when recoil module is enabled
  if self.dynamicRecoil == true then
	if self.dynamicRecoilSteps  < self.dynamicRecoilMaxSteps  then
	self.dynamicRecoilSteps  = self.dynamicRecoilSteps  + 1
	end
	self.dynamicRecoilTimer = self.dynamicRecoilTickDuration
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

function GunFire:reload()
    -- reload stuff
	
	-- checks if the consumeAmmo module is on. If not, then the user will always be able to reload. If the module is on, then the user will only be able to reload IF the player still has ammunition left.
	-- only checks if npcGun is not on.
	if not self.npcGun == true then
		if not self.infAmmo == true then
			if not self.consumeAmmoToggle == true then
				self.canReload = true
			elseif self.consumeAmmoToggle == true then
				if player.hasItem({name = self.consumeAmmoType}) then
					self.canReload = true
				else
					self.canReload = false
			
					--if the weapon has the parameter 
					--"npcGun" : true
					--then the gun will not attempt to check for ammo.
					if self.npcGun == true then
					self.canReload = true
					end
				end
			end
		else
			self.canReload = true
		end
	else
		self.canReload = true
	end
	
	
	if self.canReload == true then
	
	--if self.consumeAmmoToggle == true then
	--	player.consumeItem({name = self.consumeAmmoType, count = 1})
	--end
	
	self.weapon:setStance(self.stances.reload)
	animator.setAnimationState("gunState","reloading")
	if not self.singleBulletLoad == true then
	animator.playSound("switchAmmo")
	end
	--self.weapon.ammoAmount = -1
	self.weapon.reloading = 1
	
	--resets aim position for pistols
	if config.getParameter( "pistolReload" ) == true then
	self.weapon.aimAngle = 0
	end
	
	
	self.magazineProjectile = config.getParameter("magazineProjectile")
	animator.setParticleEmitterActive("hotsmoke", false )
	animator.setParticleEmitterActive("muzzleFlash", false)
	
	activeItem.setInstanceValue("ammoAmount",self.weapon.ammoAmount)
	
	-- single bullet load/normal reload stuff, single bullet load parameter toggles this.
	-- single bullet load is to be mostly used for shotguns and the like
	if not config.getParameter( "singleBulletLoad" ) == true or config.getParameter( "singleBulletLoad" ) == nil then
	
		if self.stances.reload.duration then
			util.wait(self.stances.reload.duration)
			world.spawnProjectile(self.magazineProjectile, firePosition or self:firePosition(), activeItem.ownerEntityId(),    self:aimVector(inaccuracy or self.inaccuracy),false,params)
		end
  
		self.cooldownTimer = self.fireTime
		self:setState(self.reload1)
	elseif config.getParameter( "singleBulletLoad" ) == true then
		repeat
		animator.playSound("switchAmmo")
		self.weapon:setStance(self.stances.reload1)
		util.wait(self.stances.reload1.duration)
		self.weapon:setStance(self.stances.reload2)
		util.wait(self.stances.reload2.duration)
		self.weapon.ammoAmount = self.weapon.ammoAmount + 1
		--self.weapon.ammoAmount = config.getParameter("ammoMax",1)
		activeItem.setInstanceValue("ammoAmount",self.weapon.ammoAmount)
		
		if not self.npcGun == true then
			if not self.infAmmo == true then
				if not self.consumeAmmoToggle == true then
					self.canReload = true
				else
					if player.hasItem({name = self.consumeAmmoType}) then
						self.canReload = true
						player.consumeItem({name = self.consumeAmmoType, count = 1})
					else
						self.canReload = false
					end
				end
			else
				self.canReload = true
			end
		else
			self.canReload = true
		end
  
		until self.weapon.ammoAmount == config.getParameter("ammoMax",1) or self.fireMode == (self.activatingFireMode or self.abilitySlot) or self.canReload == false
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

function GunFire:partReload6()
  -- actually "loads" in the bullets into the magazine here so you can't start the reload, double tap q, and have a fully loaded gun.
  self.weapon:setStance(self.stances.partreload6)
  if not config.getParameter("consumeAmmoAmount") and not self.npcGun == true and not self.infAmmo == true then
	self.weapon.ammoAmount = config.getParameter("ammoMax",1) + 1
	activeItem.setInstanceValue("ammoAmount",self.weapon.ammoAmount)
  end
  
  -- allows the gun to play the empty "click" sfx again once the player is out of ammo 100% again
  self.emptySoundPlayQuery = false
  
  -- fully loads up the gun if the gun is a "npcGun" or if the gun has infinite spare ammo
  if self.npcGun == true or self.infAmmo == true then
	self.weapon.ammoAmount = config.getParameter("ammoMax",1) + 1
	activeItem.setInstanceValue("ammoAmount",self.weapon.ammoAmount)
  end
  
  -- if the weapon is a "npcGun"/if the weapon has inf spare ammo, then no item will be consumed upon finishing reload, even if the "consumeAmmoModule" is enabled.
  if not self.npcGun == true and not self.infAmmo == true then
  
  -- if the consumeAmmoToggle is enabled, then upon reaching the end of the reload animation a "magazine" (or whatever item is used to load into the item) is used up.
	if self.consumeAmmoToggle == true then
		if not config.getParameter("consumeAmmoAmount") then
			player.consumeItem({name = self.consumeAmmoType, count = 1})
			self.weapon.ammoAmount = config.getParameter("ammoMax",1) + 1
			activeItem.setInstanceValue("ammoAmount",self.weapon.ammoAmount)
		else
			self.ammoRequired = config.getParameter("consumeAmmoAmount") --this portion is only in here incase some nutcase uses consumeAmmoAmount with partial reloads... (that nutcase might be me)
			self.ammoLoaded = 0
			if player.hasItem({name = self.consumeAmmoType, count = self.ammoRequired}) then
				player.consumeItem({name = self.consumeAmmoType, count = self.ammoRequired})
				self.weapon.ammoAmount = config.getParameter("ammoMax",1)
				activeItem.setInstanceValue("ammoAmount",self.weapon.ammoAmount)
			else
				repeat
					self.ammoLoaded = self.ammoLoaded  + 1
					player.consumeItem({name = self.consumeAmmoType, count = 1})
			
				until self.ammoLoaded == self.ammoRequired or player.hasItem({name = self.consumeAmmoType}) == false
				
				self.weapon.ammoAmount = self.ammoLoaded --+ 1
				activeItem.setInstanceValue("ammoAmount",self.weapon.ammoAmount)
			end
		end
	end
  end
  

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
  if not config.getParameter( "singleBulletLoad" ) == true then -- prevents extra ammo being consumed
  if not config.getParameter("consumeAmmoAmount") and not self.npcGun == true and not self.infAmmo == true then
	self.weapon.ammoAmount = config.getParameter("ammoMax",1)
	activeItem.setInstanceValue("ammoAmount",self.weapon.ammoAmount)
  end
  
  -- allows the gun to play the empty "click" sfx again once the player is out of ammo 100% again
  self.emptySoundPlayQuery = false
  
  -- fully loads up the gun if the gun is a "npcGun" or if the gun has infinite spare ammo
  if self.npcGun == true or self.infAmmo == true then
	self.weapon.ammoAmount = config.getParameter("ammoMax",1)
	activeItem.setInstanceValue("ammoAmount",self.weapon.ammoAmount)
  end
  
  -- if the weapon is a "npcGun"/if the weapon has inf spare ammo, then no item will be consumed upon finishing reload, even if the "consumeAmmoModule" is enabled.
  if not self.npcGun == true and not self.infAmmo == true then
  
  -- if the consumeAmmoToggle is enabled, then upon reaching the end of the reload animation a "magazine" (or whatever item is used to load into the item) is used up.
	if self.consumeAmmoToggle == true then
		if not config.getParameter("consumeAmmoAmount") then
			player.consumeItem({name = self.consumeAmmoType, count = 1})
			self.weapon.ammoAmount = config.getParameter("ammoMax",1)
			activeItem.setInstanceValue("ammoAmount",self.weapon.ammoAmount)
		else
			self.ammoRequired = config.getParameter("consumeAmmoAmount")
			self.ammoLoaded = 0
			if player.hasItem({name = self.consumeAmmoType, count = self.ammoRequired}) then
				player.consumeItem({name = self.consumeAmmoType, count = self.ammoRequired})
				self.weapon.ammoAmount = config.getParameter("ammoMax",1)
				activeItem.setInstanceValue("ammoAmount",self.weapon.ammoAmount)
			else
				repeat
					self.ammoLoaded = self.ammoLoaded + 1
					player.consumeItem({name = self.consumeAmmoType, count = 1})
			
				until self.ammoLoaded == self.ammoRequired or player.hasItem({name = self.consumeAmmoType}) == false
				
				self.weapon.ammoAmount = self.ammoLoaded
				activeItem.setInstanceValue("ammoAmount",self.weapon.ammoAmount)
			end
		end
	end
  end
  end
  

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
  params.powerMultiplier = 1--activeItem.ownerPowerMultiplier()
  params.speed = util.randomInRange(params.speed)

  --if not projectileType then
  --  projectileType = self.projectileType
  --end
  
  --adds up the final chance for a gun to miss based off of the current dynamic missChance variable (currently only set by crouching/not crouching) multiplied by recoil miss chance stuff. Also, no worries if the number goes above 100. If miss chance >100, then the gun will always miss, no questions asked. No bugs, no nothing. Horray.
  if self.missChanceToggle == true then
  self.missChanceRoll = self.missChanceVar * (1 + (self.dynamicRecoilMissMultiplier or 0) * (self.dynamicRecoilSteps or 1))
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
  
  return ((self.baseDamage or (self.baseDps * self.fireTime))+self.bonusDps) * (self.baseDamageMultiplier or 1.0) * config.getParameter("damageLevelMultiplier") / self.projectileCount
  --end
end

function GunFire:uninit()
end
