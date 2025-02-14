require "/scripts/util.lua"
require "/scripts/vec2.lua"

function init()
	storage.activeProjectiles = storage.activeProjectiles or {}
	if not storage.coins then storage.coins = 4 end
	if not storage.currentTime then storage.currentTime = world.time() end
	
	self.timeDifference = world.time() - storage.currentTime
	
	self.coinRegenTime = 3.0 --seconds
	if not storage.coinRegenTimer then
		storage.coinRegenTimer = self.coinRegenTime
	end
	
	if storage.coins < 4 then
		local elaspedTime = (self.timeDifference + self.coinRegenTime - storage.coinRegenTimer)
		local coinGen = elaspedTime / self.coinRegenTime
		
		--sb.logInfo("can generate " .. math.floor(coinGen) .. " coins")
		--sb.logInfo("time elapsed: " .. elaspedTime)
		
		if coinGen >= (4 - storage.coins) then
			storage.coins = 4
		else
			if (math.floor(coinGen) < 0) then --failsafe
				coinGen = 0
			end
			
			local timeLeft = elaspedTime - math.floor(coinGen) * self.coinRegenTime
			--sb.logInfo("timer left: " .. timeLeft)
			
			storage.coins = math.floor(coinGen) + storage.coins
			storage.coinRegenTimer = self.coinRegenTime - timeLeft
			
			--sb.logInfo("timer set: " .. storage.coinRegenTimer)
		end
	end
	
	if storage.coins < 0 then
		storage.coins = 0
	end
	
	if storage.coins > 4 then
		storage.coins = 4
	end
	
	storage.currentTime = world.time()
	
	animator.setAnimationState("coin", "" .. storage.coins)
	self.primaryHeld = false
	self.timer = 0
end

function activate(fireMode, shiftHeld)
    if fireMode == "primary" and not self.primaryHeld and self.timer == 0 and storage.coins > 0 then
		spawnCoin();
		self.timer = 0.15
		storage.coins = storage.coins - 1
		storage.coinRegenTimer = self.coinRegenTime
		
		animator.setAnimationState("coin", "" .. storage.coins)
    end
end

function update(dt, fireMode)
   self.aimAngle, self.facingDirection = activeItem.aimAngleAndDirection(0, activeItem.ownerAimPosition())
   activeItem.setFacingDirection(self.facingDirection)
   
   storage.currentTime = world.time()
   self.timer = math.max(0,self.timer - dt)
   storage.coinRegenTimer = math.max(0,storage.coinRegenTimer - dt)
   
   if storage.coins < 4 and storage.coinRegenTimer == 0 then
	storage.coinRegenTimer = self.coinRegenTime
	storage.coins = storage.coins + 1
	animator.playSound("coinLoad")
	
	animator.setAnimationState("coin", "" .. storage.coins)
   end
   
   --activeItem.setArmAngle(self.aimAngle)

   self.primaryHeld = fireMode == "primary";
end

function spawnCoin()
	animator.playSound("trigger")
	
	local velX = mcontroller.xVelocity() + 18 * mcontroller.facingDirection()
	local velY = mcontroller.yVelocity() * 0.75 + 35
	local position = vec2.add(mcontroller.position(), activeItem.handPosition({-0.5,0}))
	
	world.spawnVehicle("gic_coin", position, {startingVelocity = {velX,velY}})
end