require "/scripts/status.lua"
require "/scripts/vec2.lua"
require "/scripts/achievements.lua"

-- math.gic_player = _ENV.player
-- mfw player table smuggling is non-functional for what I was trying to do

gic_init = init
function init()
  gic_init()
  --sb.logInfo("GiC player_primary successfully hooked")
  
  self.tick = 0
  
  -- testing afflictions --
  -- local afflictions = jarray()
  -- afflictions[1] = "gic_frenzydust"
  -- status.setStatusProperty("gic_afflictions", afflictions)
  
  self.gic_diseaseConfig = root.assetJson("/stats/gic_diseases.config")
  
  if status.statusProperty("gic_diseases",nil) == nil then status.setStatusProperty("gic_diseases",jarray()) end
  self.gic_novakid = (world.entitySpecies(entity.id()) == "gic_realisticnovakid")
  
  if self.gic_novakid then
	self.gic_unbrandedConfig = root.assetJson("/stats/gic_unbranded.config")
	
	--note: it's not that this doesn't necessarily work, it's that it doesn't work in time for the scripts in update() to pull the correct values
	
	--local needSetup = (status.statusProperty("gic_novakidTime", "invalid") == "invalid")
	--local config = self.gic_unbrandedConfig
	
	--if needSetup then
		--status.setStatusProperty("gic_novakidTime", config.stages[config.startingStage].duration) --time is in seconds for now
		--status.setStatusProperty("gic_novakidStage", config.startingStage) -- stages are from 1 to 5, or something
	--end
  end
  
  if status.statusProperty("gic_secondChanceCooldown", nil) == nil then status.setStatusProperty("gic_secondChanceCooldown", 0) end
  
  --sb.logInfo(sb.printJson(status.statusProperty("gic_diseases", nil)))
end

gic_applyDamageRequest = applyDamageRequest
function applyDamageRequest(damageRequest)
  if world.getProperty("invinciblePlayers") then
    return {}
  end
  
  -- stops all damage when in "second-chance" stage
  -- i.e. stops bleed damage and such
  if status.stat("gic_secondChanceTriggered") == 1 then
	return {}
  end
  
  
  ------------------------------ DAMAGE NULLIFIERS CODE ------------------------------
  
  -- {microgen : {"gic_hardlightmicrogenerator",false,true}, frostmoon : {"gic_frostmoon",false,true}, guardsman : {"gic_guardsmangunshield",false,false}}
  -- this should only affect the first "valid" damage nullification thingie
  local damageNullifiers = status.statusProperty("gic_damageNullifiers",{})
  if (damageRequest.damage > 0) then
	  
	  -- sb.logInfo(sb.printJson(damageNullifiers))
	  
	  -- look for damageNullifiers that only resist damage, rather than those that completely nullify it!
	  local sortedDamageNullifiers = {}
	  local sdnSize = 0 -- size of sortedDamageNullifiers
	  for key, value in pairs(damageNullifiers) do
	  
		-- look for damageNullifiers that are active and only resist damage
		if (not value[3]) and value[2] then
			sortedDamageNullifiers[key] = value
			sdnSize = sdnSize + 1
		end
	  end
	  
	  if (sdnSize == 0) then
	  
		  -- no active resistance-based damageNullifiers
		  for key, value in pairs(damageNullifiers) do
			-- local details = value; -- value = {stat,actived,nullifyDamageEntirelyBool}
			
			-- if activated, then restore status to default 'false'
			-- and update stored table
			if status.stat(value[1]) == 1 and value[2] then
				--sb.logInfo("revert to false")
				
				
				value[2] = false -- this is actually a pointer, good.
				-- damageNullifiers[key] = value
					
				-- sb.logInfo(sb.printJson(damageNullifiers))
				status.setStatusProperty("gic_damageNullifiers",damageNullifiers)
					
				-- can assume that there are no resistance-based stuff, therefore just nullify damage entirely.
				return {}
			end
		  end
		  
	  else
		
		
		-- go through resistance-based damageNullifiers first!
		-- (eventually, make some code that selects a specific resistance-based damageNullifier based on damage resisted by that specific damageNullifier...)
		
		local needToNullify = true
		for key, value in pairs (sortedDamageNullifiers) do
			
			if (status.stat(value[1]) == 1 and value[2]) then
				local selectedDamageNullifier = damageNullifiers[key] -- please be a pointer please be a pointer
				
				local elementalStat = root.elementalResistance(damageRequest.damageSourceKind)
				local expectedDamage = damageRequest.damage - (status.stat(elementalStat) * damageRequest.damage)
				local healthLost = math.min(expectedDamage, status.resource("health"))
				
				if (healthLost < status.resource("health")) then
				
					selectedDamageNullifier[2] = false -- disable status
					status.setStatusProperty("gic_damageNullifiers",damageNullifiers) -- update statusProperty
					needToNullify = false -- don't need to run invulrn stuff
					break -- process rest of applyDamageRequest
					
				else
					-- do nothing, look for next damageNullifier
				end
			end
		end
		
		-- now, only select options that do completely nullify damage!
		if (needToNullify) then
			for key, value in pairs (damageNullifiers) do
				
				if value[3] and (status.stat(value[1]) == 1 and value[2]) then
					
					value[2] = false -- disable status
					status.setStatusProperty("gic_damageNullifiers",damageNullifiers) -- update statusProperty
					needToNullify = false -- don't need to run invulrn stuff
					return {} -- nullfy damage entirely
					
				end
			end
		end
	  end
  end

  ------------------------------ DAMAGE NULLIFIERS CODE ------------------------------
  
  
  
  local dodgeStat = math.min(status.stat("gic_dodge_stat"), 0.60) -- caps dodge chance to 60%; adjust as needed
  --sb.logInfo(sb.printJson(damageRequest))
  
	--sb.logInfo("--")
	--sb.logInfo(sb.printJson(dodgeStat))
	--sb.logInfo("--")
	
  --damageRequest.sourceEntityId ~= -65536
  if dodgeStat ~= 0 
  and damageRequest.damageSourceKind ~= "falling" 
  and damageRequest.sourceEntityId ~= entity.id() 
  and status.stat("invulnerable") == 0
  --and damageRequest.hitType ~= "ShieldHit"
  --and (damageRequest.damage ~= 0 or damageRequest.statusEffects) then
  and damageRequest.damage ~= 0 then
	
	--this is kinda redundant tbh, unless there's an attack that deals damage *and* is "undodgeable".
	local undodgeable = (damageRequest.statusEffects and damageRequest.statusEffects[1] and damageRequest.statusEffects[1].effect == "gic_undodgeable")
	if not undodgeable then
		
		--sb.logInfo("")
		--sb.logInfo(sb.printJson(dodgeStat).."/"..sb.printJson(statRoll))
		--sb.logInfo("")
		local statRoll = math.random(100)/100
		
		if statRoll <= dodgeStat then
			--sb.logInfo("dodge mofo")
			status.addEphemeralEffect("gic_dodge")
			return {}
		end
	end
  end
  

  -- local returnedDamageRequest = gic_applyDamageRequest(damageRequest)
  -- -- sb.logInfo(sb.printJson(damageRequest))
  
  -- -- if returnedDamageRequest.hitType == "kill" then
  -- if not status.resourcePositive("health") then
	-- status.clearPersistentEffects("gic_afflictioneffects")
	-- status.setStatusProperty("gic_afflictions", jarray())
	-- self.gic_afflictions = nil
	
	-- -- sb.logInfo("reset afflictions on death")
  -- end
  
  
  -- "second chance" code
  -- if the stat is active and player is "killed", then activate temporary status effect
  if status.stat("gic_secondChance") == 1 then
	local elementalStat = root.elementalResistance(damageRequest.damageSourceKind)
	local resistance = status.stat(elementalStat)
	local damage = damageRequest.damage
	local expectedDamage = damage - (resistance * damage)

	local healthLost = math.min(expectedDamage, status.resource("health"))
	  if healthLost > 0 and damageRequest.damageType ~= "Knockback" then
		if (healthLost == status.resource("health")) then
			
			
			local cooldownMultiplier = math.min(1, 1 - math.max(status.stat("gic_secondChance_cooldownMod"), 0))
			-- 2 minute cooldown
			status.setStatusProperty("gic_secondChanceCooldown", 120 * cooldownMultiplier)			
			
			-- status effect triggered from "second chance"
			status.addEphemeralEffect("gic_secondchanceability", duration)
			
			-- update damage request to not deal fatal damage, or to try to
			-- should leave player at 1 hit point
			damageRequest.damage = (healthLost - 1) / (1 - resistance)
			
			-- prevent status effects from being applied (via damage) for one tick
			self.preventStatusEffects = true
		end
	  end
  end
  
  if self.preventStatusEffects or status.stat("gic_secondChanceTriggered") == 1 then
	damageRequest.statusEffects = jarray()
  end
  
  return gic_applyDamageRequest(damageRequest) --returnedDamageRequest
end

function gic_findNearbyPlayers(radius)
	local playersDetected = 0
	local newPlayers = world.playerQuery(mcontroller.position(), radius, {})
	for _, playerId in pairs(newPlayers) do
		if not entity.id() == playerId then
			playersDetected = playersDetected + 1
		end
	end
	
	return playersDetected
end

function gic_tableLen(tab)
   local cnt = 0
   for key, value in ipairs(tab) do
	 cnt = cnt + 1
   end
   return cnt
 end

function gic_tableCompare(tab,tab2)
  for key, value in ipairs(tab) do
	if tab[key] ~= tab2[key] then
		return false
	end
  end
  return true
end

function gic_tableCompareDisease(tab,tab2)
  for key, value in ipairs(tab) do
	if tab[key].statusEffect ~= tab2[key].statusEffect then
		return false
	end
  end
  return true
end

-- data type prototype example: {statusEffect: "effect", time: 0, timeLimit: 60, blockingStat : "stat", mode: "transition", target: "transitionEffect"}
-- {statusEffect: "effect", duration: 60, blockingStat : "stat", mode: "end"}
function gic_interpretDiseaseData(tab,dt)
  local statusEffects = jarray()
  local diseases = tab
  local nilAmount = 0
  local alteredDiseases = false
  
  for key, value in ipairs(diseases) do
	local disease = value
	
	if disease ~= "invalid" then -- would've been using `disease ~= nil` if it didn't break the `for` function.
	
		if disease.mode ~= "end" and not status.statPositive(disease.blockingStat) then
			disease.time = disease.time + dt
	
			if disease.time >= disease.timeLimit then
				alteredDiseases = true
				if disease.mode == "transition" then
					disease = self.gic_diseaseConfig[disease.target] -- replace current disease with new disease for transition
					statusEffects[gic_tableLen(statusEffects) + 1] = disease.statusEffect
					
					--sb.logInfo(disease.statusEffect)
				-- else
					-- disease = nil -- turn into nil
					-- nilAmount = nilAmount + 1
				end
			else
				statusEffects[gic_tableLen(statusEffects) + 1] = disease.statusEffect
			end
		else
			if disease.mode == "end" then
				status.clearPersistentEffects("gic_diseaseeffects")
				status.addEphemeralEffect(disease.statusEffect, disease.duration)
			end
			alteredDiseases = true
			disease = "invalid" -- turn into nil
		end
		
		diseases[key] = disease -- override old data to return later on; updates data and etc
	else
		nilAmount = nilAmount + 1
	end
	
  end
  
  if nilAmount > 0 and nilAmount == gic_tableLen(diseases) then
	--sb.logInfo("reset diseases")
	diseases = jarray() -- reset diseases if all values are nil
  end
  
  return {diseases,statusEffects,alteredDiseases}
end

gic_update = update
function update(dt)
  
  -- used by the "second chance" code to prevent effects (like bleed) from afflicting the player when
  -- "second chance" triggers
  self.preventStatusEffects = false
  
  if self.tick > 0 then
	self.tick = self.tick - 1
	
	-- do something; does it every other tick --
	
	
	-- reiterating here since it somehow breaks after death on occasion
	self.gic_novakid = (world.entitySpecies(entity.id()) == "gic_realisticnovakid")
	-- NOVAKID - UNBRANDED --
	if self.gic_novakid then
	
		if not status.statusProperty("gic_stopUnbrandedCycle",false) then
			self.gic_unbrandedConfig = root.assetJson("/stats/gic_unbranded.config") -- reiterating this value because shit gets weird sometimes :(
			local config = self.gic_unbrandedConfig
			
			local novakidStage = status.statusProperty("gic_novakidStage", config.startingStage) --backup params as safeguard
			local novakidTime = status.statusProperty("gic_novakidTime", config.stages[config.startingStage].duration) --backup params as safeguard
			
			novakidTime = novakidTime - dt * 2 --dt * 2 because this triggers every other tick
			if novakidTime <= 0 then
				
				if novakidStage < #config.stages then
					status.setStatusProperty("gic_novakidStage", novakidStage + 1) --next stage
					novakidStage = novakidStage + 1
				end
				
				novakidTime = config.stages[novakidStage].duration --set time to new max
			end
			
			if config.stages[novakidStage].drainHealth then
				local rate = config.stages[novakidStage].drainPercent
				status.modifyResource("health", -rate * dt * 2)
			end
			
			status.setPersistentEffects("gic_novakidEffects", config.stages[novakidStage].statusEffects) -- apply stage's effects
			status.setStatusProperty("gic_novakidTime",novakidTime) --update the stored property
			
			--world.debugText("gic_novakidTime "..novakidTime,vec2.add(mcontroller.position(),{0,0.5}),"red")
			--world.debugText("gic_novakidStage "..novakidStage,vec2.add(mcontroller.position(),{0,-0.5}),"red")
		else
			status.clearPersistentEffects("gic_novakidEffects") --clear effects
		end
	end
	
	
	self.gic_afflictions_old = self.gic_afflictions
	self.gic_afflictions = status.statusProperty("gic_afflictions", nil)
	
	-- sb.logInfo(sb.printJson(self.gic_afflictions_old))
	-- sb.logInfo(sb.printJson(self.gic_afflictions))
	
	-- TEXT WALL AHEAD, LEAVING IT IN HERE FOR FUTURE REFERENCE --
	-- and also documenting process is cool, no? --


	-- ok look this is an *attempt* to mildly optimize this process
	-- first, check if the table lengths are the sameAfflictionLengths
	-- if not, then stop. if they are the same, then manually check each value of the table
	-- problem is that should I even bother to check the lengths of each table?
	
	-- consideration 1: assuming identical affliction tables, each of length 3
	-- it would require 9 checks in total, 3+3 from checking lengths of table, and 3 from comparing table values
	
	-- consideration 2: assuming one table of length 2 and one table of lenth 3
	-- it would take 5 checks in total to determine that the two tables are *not* identical
	
	-- consideration 3: assuming both tables have a length of 3, but tables differ on the 2nd value
	-- it would require 8 checks in total, 3+3 from checking lengths of table, and 2 from comparing table values
	
	-- if I were to instead gut the table length checks, then:
	
	-- consideration 1: assuming identical affliction tables, each of length 3
	-- it would require 3 checks in total, 3 from comparing table values
	
	-- consideration 2: assuming one table of length 2 and one table of lenth 3
	-- it would take 2 checks in total to determine that the two tables are *not* identical
	
	-- consideration 3: assuming both tables have a length of 3, but tables differ on the 2nd value
	-- it would require 2 checks in total, 2 from comparing table values
	
	
	-- conclusion: it's probably better to just... not check for the same lengths of each, at least not with this method.
	
	-- edit: theory can differ from practice, as seen here. if you *only* check the values of each table and you don't consider the lengths of each table,
	-- this can backfire when the first compared table has less values than the second compared value. when this happens, my (very barebones) function
	-- doesn't properly check values with keys greater than the length of the first table; therefore, if the second table has more values than the first
	-- table, the function still thinks that both tabels are *identical* !!!
	
	-- so basically yeah i have to do less efficient method of checking both table length and table values
	-- less efficient, but it'll be significantly more reliable.
	
	if self.gic_afflictions ~= nil then
		local sameAfflictionLengths = false
		if self.gic_afflictions_old ~= nil and self.gic_afflictions ~= nil then sameAfflictionLengths = (gic_tableLen(self.gic_afflictions_old) == gic_tableLen(self.gic_afflictions)) end
		
		local sameAfflictionValues = false
		if sameAfflictionLengths then sameAfflictionValues = gic_tableCompare(self.gic_afflictions_old,self.gic_afflictions) end
		-- if (self.gic_afflictions_old ~= nil and self.gic_afflictions ~= nil) then sameAfflictionValues = gic_tableCompare(self.gic_afflictions_old,self.gic_afflictions) end
		
		local sameAfflictions = sameAfflictionLengths and sameAfflictionValues
		-- local sameAfflictions = sameAfflictionValues
		-- sb.logInfo(sb.printJson(sameAfflictions))
		
		if not sameAfflictions then
			status.clearPersistentEffects("gic_afflictioneffects")
			
			status.setPersistentEffects("gic_afflictioneffects", self.gic_afflictions)
			
			-- sb.logInfo("applied status effects")
			-- sb.logInfo(sb.printJson(self.gic_afflictions_old))
			-- sb.logInfo(sb.printJson(self.gic_afflictions))
			
			
			-- testing afflictions
			-- local afflictions = jarray()
			-- afflictions[1] = "gic_frenzydust"
			-- afflictions[2] = "gic_infiniteammo"
			-- status.setStatusProperty("gic_afflictions", afflictions)
		end
	--elseif self.gic_afflictions == nil then
	else
		status.clearPersistentEffects("gic_afflictioneffects")
	end
	
	
	-- DISEASE CODESTUFFS -- EXPERIMENTAL (as of writing) --
	-- todo - status effect code to apply disease, should be incredibly similar to gic_applyafflictions.lua, probably.
	
	self.gic_diseases_old = self.gic_diseases
	self.gic_diseases = status.statusProperty("gic_diseases", jarray())
	
	if self.gic_diseases ~= "invalid" then
		local res = gic_interpretDiseaseData(self.gic_diseases,2*dt) -- returns {updatedDiseaseData,diseaseStatusEffects}; dt is multiplied by 2 because every other tick is skipped
		status.setStatusProperty("gic_diseases", res[1])
		self.gic_diseases = res[1]
		
		local sameDiseasesLength = false
		if self.gic_diseases_old ~= nil and self.gic_diseases ~= nil then 
			sameDiseasesLength = (gic_tableLen(self.gic_diseases_old) == gic_tableLen(self.gic_diseases)) 
		end
		
		local sameDiseaseValues = false
		if sameDiseasesLength then sameDiseaseValues = gic_tableCompareDisease(self.gic_diseases_old,self.gic_diseases) end
		
		local sameDiseases = sameDiseasesLength and sameDiseaseValues
		
		if not sameDiseases or res[3] == true then
			--sb.logInfo("updateDiseaseEffects")
			status.clearPersistentEffects("gic_diseaseeffects")
			status.setPersistentEffects("gic_diseaseeffects", res[2])
		end
	--elseif self.gic_afflictions == nil then
	else
		status.clearPersistentEffects("gic_diseaseeffects")
	end
	
	
	local secondChanceCD = status.statusProperty("gic_secondChanceCooldown", 0)
	local hold = math.max(secondChanceCD - dt * 2, 0)
	
	if not (hold == secondChanceCD) then
		status.setStatusProperty("gic_secondChanceCooldown",hold)
		
		-- reapply status effect if status effect nullified
		if not (status.stat("gic_secondChanceImmunity") == 1) and hold > 0 and status.resourcePositive("health") then
			status.addEphemeralEffect("gic_secondchance_weakness", hold)
		end
	end
	
  else
	self.tick = 1
  end
  
  -- sb.logInfo("positive health: "..sb.printJson(status.resourcePositive("health")))
  
  -- if not status.resourcePositive("health") then
	-- status.clearPersistentEffects("gic_afflictioneffects")
	-- status.setStatusProperty("gic_afflictions", jarray())
	-- self.gic_afflictions = nil
	
	-- sb.logInfo("reset afflictions on death")
  -- end
  
  gic_update(dt)
end

--mfw i don't use uninit because i didn't see it used in vanilla player_main.lua
--thanks kae for pointing that out
gic_uninit = uninit
function uninit()
  
  -- since uninit() isn't used in vanilla, this hook only exists in case it is used by some other mod; just a safeguard
  if gic_uninit then gic_uninit() end
  
  if not status.resourcePositive("health") then
	-- clear afflictions
	-- status.clearPersistentEffects("gic_afflictioneffects")
	-- status.setStatusProperty("gic_afflictions", jarray())
	-- self.gic_afflictions = nil
	
	-- clear diseases
	status.clearPersistentEffects("gic_diseaseeffects")
	status.setStatusProperty("gic_diseases", jarray())
	self.gic_diseases = "invalid"
	
	-- clear "second chance" cooldown
	-- status.setStatusProperty("gic_secondChanceCooldown", 0)
	
	-- sb.logInfo("reset afflictions on death")
	
	-- reset Unbranded mechanics for GiC novakids
	if status.statusProperty("gic_novakidTime","invalid") ~= "invalid" then --(have to check weirdly because wasn't working with normal method??)
		local config = root.assetJson("/stats/gic_unbranded.config")
		local currentStage = status.statusProperty("gic_novakidStage")
		status.setStatusProperty("gic_novakidStage",config.startingStage)
		status.setStatusProperty("gic_novakidTime",config.stages[config.startingStage].duration) --update the stored property
		
		status.clearPersistentEffects("gic_novakidEffects")
		
		--sb.logInfo("unbranded stage reset to: "..sb.printJson(status.statusProperty("gic_novakidStage")))
		--sb.logInfo("unbranded stage time set to: "..sb.printJson(status.statusProperty("gic_novakidTime")))
		
		if config.stages[currentStage].explodeOnDeath then
			local projectile = config.deathExplosionProjectile
			local projectileConfig = config.deathExplosionProjectileConfig
			
			-- overrides
			if config.stages[currentStage].deathExplosionProjectile then projectile = config.stages[currentStage].deathExplosionProjectile end
			if config.stages[currentStage].deathExplosionProjectileConfig then projectileConfig = config.stages[currentStage].deathExplosionProjectileConfig end
			
			
			world.spawnProjectile(projectile, mcontroller.position(), entity.id(), {0,0}, false, projectileConfig)
		end
		
		-- disable the cycle stopper so it can be reenabled after respawn
		status.setStatusProperty("gic_stopUnbrandedCycle",false)
	end
  end
end
