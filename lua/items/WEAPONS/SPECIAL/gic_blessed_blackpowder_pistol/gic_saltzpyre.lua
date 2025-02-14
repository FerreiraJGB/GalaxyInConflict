require "/items/active/weapons/ranged/ews_weapon.lua"

Saltzpyre = GunFire:new()

function Saltzpyre:init()
  GunFire.init(self)
end

function Saltzpyre:update(dt, fireMode, shiftHeld)
  GunFire.update(self, dt, fireMode, shiftHeld)
end

function Saltzpyre:uninit()
  GunFire.uninit(self)
end

function Saltzpyre:semi()
	self:updateNPCAutoReload()
	
	
	self.lasersightData = self.weapon:setStance(self.stances.fire)
	self:laserSightConfig()

  for i = 1,self.weapon.ammoAmount,1 
  do
	if type(config.getParameter("consumeAmmoType")) == "table" and config.getParameter("consumeAmmoModule") == true then
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
	
	if type(config.getParameter("consumeAmmoType")) == "table" and config.getParameter("consumeAmmoModule") == true then
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
	
	if config.getParameter("oneInChamber") == true and type(config.getParameter("consumeAmmoType")) == "table" and config.getParameter("consumeAmmoModule") == true then
		self:setupNewValuesPostChamber()
		activeItem.setInstanceValue("oneInChamber",false)
	end
  end
  
  
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