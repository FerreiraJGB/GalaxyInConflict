-- note: almost all credit here goes to the shuttlecraft mod, I just took and modified the code (Echo)

local baseupdate = update


function update(dt)
  baseupdate(dt)
  
  --Make sure the NPC stays in the seat (default behavior makes them jump out of vehicles)
  if self.loungeShuttlecraftId ~= nil then 
	if self.loungeShuttlecraftDelay > 1 then 
		self.loungeShuttlecraftDelay = self.loungeShuttlecraftDelay - 1  
	else
		if self.loungeShuttlecraftDelay == 1 then status.addEphemeralEffect("beamin") self.loungeShuttlecraftDelay = 0 end 
		self.lounge = true
		if world.entityType(self.loungeShuttlecraftId) == "vehicle" then 
			npc.setLounging(self.loungeShuttlecraftId, self.loungeShuttlecraftAnchor)
				--if not world.callScriptedEntity(self.loungeShuttlecraftId, "checkSeatsForEntity", entity.id()) then endShuttlecraftLounge()  
				--if not npc.loungingIn() == self.loungeShuttlecraftId then endShuttlecraftLounge() 
				if not npc.isLounging() then endShuttlecraftLounge()
				else
					npc.dance("warmhands")
					--if self.loungeShuttlecraftAnchor == 1 then npc.dance("typing") end
					--if self.loungeShuttlecraftAnchor == 0 then npc.dance("warmhands") end
					if (recruitable.isFollowing() and recruitable.ownerUuid() ) or not recruitable.ownerUuid() then
						if world.callScriptedEntity(self.loungeShuttlecraftId, "vehicle.entityLoungingIn", "drivingSeat") == nil then
							--sb.logInfo("endNPCLounge")
							endShuttlecraftLounge()
						end
					end
				end
		else 
			endShuttlecraftLounge()
		end
	end
  else 
	--Crewmembers will try to board any shuttlecraft piloted by the player they belong to
	if recruitable.isFollowing() then 
		if self.disableEmbark ~= nil then 
			self.disableEmbark = self.disableEmbark - 1 
			if self.disableEmbark == 0 then 
				self.disableEmbark = nil restoreNPCWeapons() 
			end  
		end
		if recruitable.ownerUuid() ~= nil and self.disableEmbark == nil then 
			local vehicleList = world.entityQuery(entity.position(), 1.5, {includedTypes = {"vehicle"}, order = "nearest" })
			if vehicleList[1] ~= nil then 
				world.sendEntityMessage(vehicleList[1], "gic_boardGunnerFollower", recruitable.ownerUuid(), entity.id())
			end
		end
	end
  end

end


function setShuttlecraftLounge(vehicleId, seatAnchor, beamin, delay)
	if beamin then status.addEphemeralEffect("beamout") end
	self.loungeShuttlecraftId = vehicleId
	self.loungeShuttlecraftAnchor = seatAnchor
	--if beamin then self.loungeShuttlecraftDelay = 5 else self.loungeShuttlecraftDelay = 0 end
	self.loungeShuttlecraftDelay = delay or 0
	
	--sb.logInfo("triggerNPCLounge")
end

function endShuttlecraftLounge(beamdown, disableEmbark)
	self.loungeShuttlecraftId = nil
	self.loungeShuttlecraftAnchor = nil
	--npc.dance("wave")
	if beamdown then status.addEphemeralEffect("beamin") end
	if recruitable.isFollowing() or storage.shuttleId then self.disableEmbark = 5 end
	if disableEmbark then self.disableEmbark = disableEmbark end
	if self.resetSpawnPosition then storage.spawnPosition = world.lineCollision(entity.position(), {entity.position()[1],entity.position()[2]-15}) or entity.position() self.board:setPosition("spawn", storage.spawnPosition) end
	--Restore NPCs weapons in case of a lounging bug that makes the NPCs weapons disappear, may not always work
	restoreNPCWeapons()
end

function restoreNPCWeapons()
	if npc.getItemSlot("primary") == nil and self.primary then npc.setItemSlot("primary", self.primary) end
	if npc.getItemSlot("alt") == nil and self.alt then npc.setItemSlot("alt", self.alt) end
	if npc.getItemSlot("sheathedprimary") == nil and self.sheathedPrimary then npc.setItemSlot("sheathedprimary", self.sheathedPrimary) end
	if npc.getItemSlot("sheathedalt") == nil and self.sheathedAlt then npc.setItemSlot("sheathedalt", self.sheathedAlt) end
	self.lounge = false
end

function setDedicatedPassenger(uuid, resetSpawnPositionOnDisembark)
	storage.shuttleId = uuid
	if resetSpawnPositionOnDisembark then self.resetSpawnPosition = true end
end

