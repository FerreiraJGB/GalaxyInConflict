require "/scripts/util.lua"
require "/scripts/interp.lua"
require "/scripts/vec2.lua"

function init()
  self.projectileType = config.getParameter( "projectileType" )
  self.projectileTypeMiss = config.getParameter( "projectileTypeMiss" )
  self.fireTimer = config.getParameter( "fireRate" )
  self.baseDamage = config.getParameter( "baseDamage" )
  self.reloadTimer = 0
  self.projectileCount = config.getParameter( "projectileCount" )
  self.ammoCount = config.getParameter("ammoCountMax",50)
  self.textProjectileParams = config.getParameter("textProjectileParams")
  
  self.trackingDistance = config.getParameter("trackingDistance", 30)
  self.trackingAngle = config.getParameter("trackingAngle", 30)
  self.sourceEntity = entity.id()
  self.queryParameters = {
    withoutEntityId = self.sourceEntity,
    includedTypes = {"creature"},
    order = "nearest"
  }
  
  
  if mcontroller.crouching() == true then
  self.crouchingQuery = 1
  else
  self.crouchingQuery = 0
  end
  
  self.crouchTimer = 0
  self.autoReloadTimer = 0
end

function update(dt)
  self.fireTimer = math.max(0, self.fireTimer - dt)
  
 
  if mcontroller.crouching() == true then
  self.crouchingQuery = 1
  else
  self.crouchingQuery = 0
  end
  
  
  
  self.crouchTimer = math.max(0, self.crouchTimer - dt)
  
  
  findTargets()
  if self.fireTimer == 0 and self.shouldFire == true and self.ammoCount > 0 and self.reloadTimer == 0 then
	self.autoReloadTimer = 5
	self.ammoCount = self.ammoCount - 1
	animator.playSound("fire")
	effectTargets()
	--projectileType = self.projectileType
	--world.spawnProjectile(projectileType, vec2.add(mcontroller.position(), {mcontroller.facingDirection(), 0 - (0 * self.crouchingQuery)}), entity.id(), {mcontroller.facingDirection(), 0}, false, { power = 0 })
	
	
	--world.sendEntityMessage(playerId, "playAltMusic", jarray(), config.getParameter("fadeOutTime"))
	
	self.fireTimer = config.getParameter( "fireRate" )
  end
  
  --animator.resetTransformationGroup("turret")
  if self.shouldFire == false then
  self.toTarget = {mcontroller.facingDirection(),0}
  end
  
  
  self.facingDirectionActual = mcontroller.facingDirection()
  
  if self.ammoCount == 0  or
   self.ammoCount < config.getParameter("ammoCountMax",50) 
   and self.autoReloadTimer == 0 then
   if self.reloadTimer == 0 
   and self.reloadQuery == false
   then
   self.reloadTimer = config.getParameter("reloadTimer", 3)
   self.reloadQuery = true
   animator.playSound("reload")
   else
   local params = sb.jsonMerge(self.textProjectileParams, projectileParams or {})
   world.spawnProjectile("invisibleprojectile", vec2.add(mcontroller.position(), {0, 0 - (0 * self.crouchingQuery)}), entity.id(), {0,0}, false, params)
   self.ammoCount = config.getParameter("ammoCountMax",50)
   self.reloadQuery = false
   end
  end
  self.reloadTimer = math.max(0, self.reloadTimer - dt)
  
  self.autoReloadTimer = math.max(0, self.autoReloadTimer - dt)
end

function determineInaccuracy()
	if self.inaccuracyAngle > 0 then
		return math.random(self.inaccuracyAngle) - (self.inaccuracyAngle/2)
	else
		return 0
	end
end

function findTargets()
  local pos = vec2.add(mcontroller.position(),{0, 0 - (0 * self.crouchingQuery)})
  local candidates = world.entityQuery(pos, self.trackingDistance, self.queryParameters)
  
  self.targetFound = false
  self.shouldFire = false
  self.toTarget = {mcontroller.facingDirection(),0}

  if #candidates == 0 then return end

  for _, candidate in ipairs(candidates) do
    if world.entityCanDamage(self.sourceEntity, candidate) and world.entityAggressive(candidate) then
      local canPos = world.entityPosition(candidate)
        local toTarget = world.distance(canPos, pos)
		self.toTarget = toTarget
		local distPosX = toTarget[1]
		local toTargetAngle = toTarget[2]
		
		self.targetFound = true
		self.shouldFire = true
		end
  end
end

function effectTargets()
  local pos = vec2.add(mcontroller.position(),{0, 0 - (0 * self.crouchingQuery)})
  local candidates = world.entityQuery(pos, self.trackingDistance, self.queryParameters)
  
  --self.toTarget = {mcontroller.facingDirection(),0}

  if #candidates == 0 then return end

  for _, candidate in ipairs(candidates) do
    if world.entityCanDamage(self.sourceEntity, candidate) then
		--local canPos = world.entityPosition(candidate)
        --local toTarget = world.distance(canPos, pos)
		--self.toTarget = toTarget
		--local distPosX = toTarget[1]
		--local toTargetAngle = toTarget[2]
		
		
		world.sendEntityMessage(candidate, "applyStatusEffect", "gic_pinged_vengefulthirdeye", 2.0, self.sourceEntity)
	end
  end
end

function uninit()

end
