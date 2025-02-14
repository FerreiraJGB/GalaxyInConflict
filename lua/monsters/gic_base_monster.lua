require "/scripts/behavior.lua"
require "/scripts/pathing.lua"
require "/scripts/util.lua"
require "/scripts/vec2.lua"
require "/scripts/poly.lua"
require "/scripts/drops.lua"
require "/scripts/status.lua"
require "/scripts/companions/capturable.lua"
require "/scripts/tenant.lua"
require "/scripts/actions/movement.lua"
require "/scripts/actions/animator.lua"

-- Engine callback - called on initialization of entity
function init()
  self.pathing = {}

  self.shouldDie = true
  self.notifications = {}
  storage.spawnTime = world.time()
  if storage.spawnPosition == nil or config.getParameter("wasRelocated", false) then
    local position = mcontroller.position()
    local groundSpawnPosition
    if mcontroller.baseParameters().gravityEnabled then
      groundSpawnPosition = findGroundPosition(position, -20, 3)
    end
    storage.spawnPosition = groundSpawnPosition or position
  end

  self.behavior = behavior.behavior(config.getParameter("behavior"), sb.jsonMerge(config.getParameter("behaviorConfig", {}), skillBehaviorConfig()), _ENV)
  self.board = self.behavior:blackboard()
  self.board:setPosition("spawn", storage.spawnPosition)

  self.collisionPoly = mcontroller.collisionPoly()

  if animator.hasSound("deathPuff") then
    monster.setDeathSound("deathPuff")
  end
  if config.getParameter("deathParticles") then
    monster.setDeathParticleBurst(config.getParameter("deathParticles"))
  end

  script.setUpdateDelta(config.getParameter("initialScriptDelta", 5))
  mcontroller.setAutoClearControls(false)
  self.behaviorTickRate = config.getParameter("behaviorUpdateDelta", 2)
  self.behaviorTick = math.random(1, self.behaviorTickRate)

  animator.setGlobalTag("flipX", "")
  self.board:setNumber("facingDirection", mcontroller.facingDirection())

  capturable.init()
  
  -- (GiC) Block Initialization
  self.blockMax = config.getParameter("blockMax",0)
  self.blocks = self.blockMax
  self.blockTimeMax = config.getParameter("blockRechargeTime",5.0)
  self.blockTime = self.blockTimeMax
  
  self.blockEffectBufferTimeMax = config.getParameter("blockEffectBufferTime",0.5)
  self.blockEffectBufferTime = self.blockEffectBufferTimeMax
  status.clearPersistentEffects("gic_blockingEffect")
  self.blockingStatusEffect = config.getParameter("blockStatusEffect","gic_parryshield")
  self.blockEffect = false
  
  self.guardBroken = false
  self.guardCanBreak = config.getParameter("blockingGuardBreakEnabled",false)
  self.guardBreakDuration = config.getParameter("blockingGuardBreakDuration",5.0)
  self.guardBreakTime = 0--self.guardBreakDuration
  
  self.animationWhitelistEnabled = config.getParameter("blockingAnimationWhitelist",false)
  self.animationStateType = config.getParameter("blockableAnimationStateType","body")
  self.animationWhitelist = setupWhitelist()
  self.canBlock = false
  
  self.blockAnimBufferTimer = 0
  self.blockAnimBufferTime = 0.1 --can still trigger block after this duration, even when on diff. anim
  
  
  
  -- Listen to damage taken
  self.damageTaken = damageListener("damageTaken", function(notifications)
	local blockTriggered = false
    for _,notification in pairs(notifications) do
	
	  -- (GiC) Listen to damage "blocked"
      if self.blockEffect --if notification.healthLost <= 0 --healthLost <= 0 because wtf this can go negative lmaooooo
		and self.blocks > 0
		and self.canBlock
		and not (notification.damageSourceKind == "hidden" or notification.damageSourceKind == "noDamage") 
		and not blockTriggered then
		
        self.hadBlocked = true
		self.blockTime = self.blockTimeMax
		self.blocks = self.blocks - 1
		--sb.logInfo("parried")
		
		if self.blocks == 0 then 
			self.blockEffectBufferTime = self.blockEffectBufferTimeMax 
			
			if self.guardCanBreak then 
				self.guardBroken = true
				self.guardBreakTime = self.guardBreakDuration
			end
		end
		
        self.board:setEntity("damageSource", notification.sourceEntityId)
		
		blockTriggered = true
	  
	  -- normal damage listener stuff
	  elseif notification.healthLost > 0 and self.guardBreakTime <= 0 then
        self.damaged = true
        self.board:setEntity("damageSource", notification.sourceEntityId)
      end
    end
  end)

  self.debug = true

  message.setHandler("notify", function(_,_,notification)
      return notify(notification)
    end)
  message.setHandler("despawn", function()
      monster.setDropPool(nil)
      monster.setDeathParticleBurst(nil)
      monster.setDeathSound(nil)
      self.deathBehavior = nil
      self.shouldDie = true
      status.addEphemeralEffect("monsterdespawn")
    end)

  local deathBehavior = config.getParameter("deathBehavior")
  if deathBehavior then
    self.deathBehavior = behavior.behavior(deathBehavior, config.getParameter("behaviorConfig", {}), _ENV, self.behavior:blackboard())
  end

  self.forceRegions = ControlMap:new(config.getParameter("forceRegions", {}))
  self.damageSources = ControlMap:new(config.getParameter("damageSources", {}))
  self.touchDamageEnabled = false

  if config.getParameter("elite", false) then
    status.setPersistentEffects("elite", {"elitemonster"})
  end

  if config.getParameter("damageBar") then
    monster.setDamageBar(config.getParameter("damageBar"));
  end

  monster.setInteractive(config.getParameter("interactive", false))

  monster.setAnimationParameter("chains", config.getParameter("chains"))
end

function setupWhitelist()
	local animationStates = config.getParameter("blockableAnimationStates",jarray())
	--local animationStateType = self.animationStateType
	
	local tab = {}
	for index, animationState in pairs(animationStates) do
		tab[animationState] = true
	end

	return tab
end

function couldBlock()
	if not self.animationWhitelistEnabled then return true end

	if self.animationWhitelist[animator.animationState(self.animationStateType)] then
		
		--world.debugText("VALID ANIM " .. sb.printJson(true), vec2.add(mcontroller.position(), {0,0}), "green")
		self.couldBlock = self.canBlock
		--sb.logInfo("validState"..self.blockAnimBufferTimer)
		
		return true
	elseif (self.blockAnimBufferTimer > 0) then
		--world.debugText("BUFFERING " .. sb.printJson(true), vec2.add(mcontroller.position(), {0,0}), "red")
		self.couldBlock = false
		return true
	end
	
	if self.couldBlock and (self.blockAnimBufferTimer <= 0) then 
		--world.debugText("TRIGGER BUFFER " .. sb.printJson(true), vec2.add(mcontroller.position(), {0,-1}), "red")
		self.blockAnimBufferTimer = self.blockAnimBufferTime;
		self.couldBlock = false
		return true 
	end
	
	
	return false
end

function update(dt)
  capturable.update(dt)
  
  self.canBlock = couldBlock()
  --world.debugText("canBlock " .. sb.printJson(self.canBlock), vec2.add(mcontroller.position(), {0,1.5}), "yellow")
  --world.debugText("bufferTime " .. sb.printJson(self.blockAnimBufferTimer > 0), vec2.add(mcontroller.position(), {0,3}), "yellow")
  -- (GiC) tick block related things
  if self.guardBreakTime <= 0 then self.blockTime = self.blockTime - dt end --only can recharge when not guard-broken
  self.blockEffectBufferTime = self.blockEffectBufferTime - dt
  if self.guardCanBreak then self.guardBreakTime = self.guardBreakTime - dt end
  
  -- (GiC) recharge blocks over time
  if self.blockTime <= 0 and self.blocks < self.blockMax then
	self.blocks = self.blockMax
  end
  
  self.blockAnimBufferTimer = self.blockAnimBufferTimer - dt
  
  -- (GiC) apply blocking status effects and whatnot
  if self.blocks > 0 and not self.blockEffect and not status.resourcePositive("stunned") and self.canBlock then
	local val = jarray()
	val[1] = self.blockingStatusEffect
	status.addPersistentEffects("gic_blockingEffect", val)
	self.blockEffect = true
	--sb.logInfo("blockingEffect")
  elseif (self.blocks == 0 and self.blockEffect and not self.hadBlocked and self.blockEffectBufferTime <= 0)
	or (self.canBlock == false and self.blockEffect) then
	self.blockEffect = false
	status.clearPersistentEffects("gic_blockingEffect")
	--sb.logInfo("blockingEffectCleared")
  end
  
  self.damageTaken:update()

  if status.resourcePositive("stunned") then
    animator.setAnimationState("damage", "stunned")
    animator.setGlobalTag("hurt", "hurt")
    self.stunned = true
    mcontroller.clearControls()
    if self.damaged then
      self.suppressDamageTimer = config.getParameter("stunDamageSuppression", 0.5)
      monster.setDamageOnTouch(false)
    end
	
	self.blockEffect = false
	status.clearPersistentEffects("gic_blockingEffect")
    return
  else
    animator.setGlobalTag("hurt", "")
    animator.setAnimationState("damage", "none")
  end

  -- Suppressing touch damage
  if self.suppressDamageTimer then
    monster.setDamageOnTouch(false)
    self.suppressDamageTimer = math.max(self.suppressDamageTimer - dt, 0)
    if self.suppressDamageTimer == 0 then
      self.suppressDamageTimer = nil
    end
  elseif status.statPositive("invulnerable") then
    monster.setDamageOnTouch(false)
  else
    --monster.setDamageOnTouch(self.touchDamageEnabled)
	monster.setDamageOnTouch(false)
  end
  

  if self.behaviorTick >= self.behaviorTickRate then
    self.behaviorTick = self.behaviorTick - self.behaviorTickRate
    mcontroller.clearControls()

    self.tradingEnabled = false
    self.setFacingDirection = false
    self.moving = false
    self.rotated = false
    self.forceRegions:clear()
    self.damageSources:clear()
    self.damageParts = {}
    clearAnimation()

    if self.behavior then
      local board = self.behavior:blackboard()
      board:setEntity("self", entity.id())
      board:setPosition("self", mcontroller.position())
      board:setNumber("dt", dt * self.behaviorTickRate)
      board:setNumber("facingDirection", self.facingDirection or mcontroller.facingDirection())

      self.behavior:run(dt * self.behaviorTickRate)
    end
    BGroup:updateGroups()

    updateAnimation()

    if not self.rotated and self.rotation then
      mcontroller.setRotation(0)
      animator.resetTransformationGroup(self.rotationGroup)
      self.rotation = nil
      self.rotationGroup = nil
    end

    self.interacted = false
    self.damaged = false
	self.hadBlocked = false
	self.guardBroken = false
    self.stunned = false
    self.notifications = {}

    setDamageSources()
    setPhysicsForces()
    monster.setDamageParts(self.damageParts)
    overrideCollisionPoly()
  end
  self.behaviorTick = self.behaviorTick + 1
  
  if config.getParameter("facingMode", "control") == "transformation" then
    mcontroller.controlFace(1)
  end
end

function skillBehaviorConfig()
  local skills = config.getParameter("skills", {})
  local skillConfig = {}

  for _,skillName in pairs(skills) do
    local skillHostileActions = root.monsterSkillParameter(skillName, "hostileActions")
    if skillHostileActions then
      construct(skillConfig, "hostileActions")
      util.appendLists(skillConfig.hostileActions, skillHostileActions)
    end
  end

  return skillConfig
end

function interact(args)
  self.interacted = true
  self.board:setEntity("interactionSource", args.sourceId)
end

function shouldDie()
  return (self.shouldDie and status.resource("health") <= 0) or capturable.justCaptured
end

function die()
  if not capturable.justCaptured then
    if self.deathBehavior then
      self.deathBehavior:run(script.updateDt())
    end
    capturable.die()
  end
  spawnDrops()
end

function uninit()
  BGroup:uninit()
end

function setDamageSources()
  if self.stunned then --prevents hitbox from staying too long when stunned
	monster.setDamageSources({})
	return 
  end
  
  local partSources = {}
  for part,ds in pairs(config.getParameter("damageParts", {})) do
    local damageArea = animator.partPoly(part, "damageArea")
    if damageArea then
      ds.poly = damageArea
      table.insert(partSources, ds)
    end
  end

  local damageSources = util.mergeLists(partSources, self.damageSources:values())
  damageSources = util.map(damageSources, function(ds)
    ds.damage = ds.damage * root.evalFunction("monsterLevelPowerMultiplier", monster.level()) * status.stat("powerMultiplier")
    if ds.knockback and type(ds.knockback) == "table" then
      ds.knockback[1] = ds.knockback[1] * mcontroller.facingDirection()
    end

    local team = entity.damageTeam()
    ds.team = { type = ds.damageTeamType or team.type, team = ds.damageTeam or team.team }

    return ds
  end)
  monster.setDamageSources(damageSources)
end

function setPhysicsForces()
  local regions = util.map(self.forceRegions:values(), function(region)
    if region.type == "RadialForceRegion" then
      region.center = vec2.add(mcontroller.position(), region.center)
    elseif region.type == "DirectionalForceRegion" then
      if region.rectRegion then
        region.rectRegion = rect.translate(region.rectRegion, mcontroller.position())
        util.debugRect(region.rectRegion, "blue")
      elseif region.polyRegion then
        region.polyRegion = poly.translate(region.polyRegion, mcontroller.position())
      end
    end

    return region
  end)

  monster.setPhysicsForces(regions)
end

function overrideCollisionPoly()
  local collisionParts = config.getParameter("collisionParts", {})

  for _,part in pairs(collisionParts) do
    local collisionPoly = animator.partPoly(part, "collisionPoly")
    if collisionPoly then
      -- Animator flips the polygon by default
      -- to have it unflipped we need to flip it again
      if not config.getParameter("flipPartPoly", true) and mcontroller.facingDirection() < 0 then
        collisionPoly = poly.flip(collisionPoly)
      end
      mcontroller.controlParameters({collisionPoly = collisionPoly, standingPoly = collisionPoly, crouchingPoly = collisionPoly})
      break
    end
  end
end

function setupTenant(...)
  require("/scripts/tenant.lua")
  tenant.setHome(...)
end
