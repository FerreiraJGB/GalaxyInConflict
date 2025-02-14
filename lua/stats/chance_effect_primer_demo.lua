function init()
	self.duration = effect.duration() --duration of this primer status effect determines duration of resultant status effect, if successful in triggering
end

function update()
   local statRoll = math.random(100)/100
   local value = config.getParameter("chance",0.5) -- either configurate "chance" under effectConfig for the .statuseffect, or change the value of 0.5
   -- a value of 0.5 represents a 50% chance, 0.2 represents a 20% chance, etc
   
   if statRoll >= value then
   --if status.stat("demo_triggerStat") == 1 then  //leaving in this option in case it's needed; uncomment this tidbit (and delete this text) to enable.
      status.addEphemeralEffect("statusEffect",self.duration) --replace "statusEffect" with target effect for primer to enable
   --end
   end
   
   effect.expire()
end

function uninit()
end
