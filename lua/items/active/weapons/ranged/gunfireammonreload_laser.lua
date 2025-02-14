require "/items/active/weapons/ranged/ews_weapon.lua"

BeamAttack = GunFire:new()

function BeamAttack:init()
  GunFire.init(self)
  self.beams = config.getParameter( "beams" )
  activeItem.setScriptedAnimationParameter("beams", {})
end

function BeamAttack:update(dt, fireMode, shiftHeld)
  GunFire.update(self, dt, fireMode, shiftHeld)
end

function BeamAttack:burst()
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
    self:fireProjectile(_,_,_,_,_,true)
	animator.setAnimationState("firing", "fire")
	if not self.suppressed == true then
		animator.playSound("fire")
		animator.setPartTag("muzzleFlash", "variant", math.random(1, 3))
		animator.setParticleEmitterActive("muzzleFlash", true)
		animator.setParticleEmitterEmissionRate("muzzleFlash", 100)
		animator.setParticleEmitterActive("hotsmoke", true)
		animator.setParticleEmitterEmissionRate("hotsmoke", 100)
		animator.setLightActive("muzzleFlash", true)
	else
		animator.playSound("suppressedFire")
	end
  
  -- increases recoil when recoil module is enabled
  if self.dynamicRecoil == true then
	if self.dynamicRecoilSteps  < self.finalDynamicRecoilMaxSteps  then
	self.dynamicRecoilSteps  = self.dynamicRecoilSteps  + 1
	end
	self.dynamicRecoilTimer = self.finalDynamicRecoilTickDuration
  end
	
    shots = shots - 1

    self.weapon.relativeWeaponRotation = util.toRadians(interp.linear(1 - shots / self.burstCount, 0, self.stances.fire.weaponRotation))
    self.weapon.relativeArmRotation = util.toRadians(interp.linear(1 - shots / self.burstCount, 0, self.stances.fire.armRotation))
	
	animator.setAnimationState("gunState","firing")

	util.wait(self.burstTime / 2)
	--------------------------------------------------------------------------------------
	activeItem.setScriptedAnimationParameter("beams", {})
	--------------------------------------------------------------------------------------
	util.wait(self.burstTime / 2)
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

function BeamAttack:motion1()
  --------------------------------------------------------------------------------------
  activeItem.setScriptedAnimationParameter("beams", {})
  --------------------------------------------------------------------------------------
  
  
  self.weapon:setStance(self.stances.motion2)

  if self.stances.motion1.duration then
    util.wait(self.stances.motion1.duration, function()
		self.cooldownTimer = math.max(0, self.cooldownTimer - self.dt)
	end)
  end

  self:setState(self.motion2)
end

function BeamAttack:reload()
  --------------------------------------------------------------------------------------
  activeItem.setScriptedAnimationParameter("beams", {})
  --------------------------------------------------------------------------------------
  GunFire.reload(self)
end

function BeamAttack:fireProjectile(projectileType, projectileParams, inaccuracy, firePosition, projectileCount, normalFire)
  
  --------------------------------------------------------------------------------------
  activeItem.setScriptedAnimationParameter("beams", {self.beams})
  --------------------------------------------------------------------------------------
  GunFire.fireProjectile(self, projectileType, projectileParams, inaccuracy, firePosition, projectileCount, normalFire)
end