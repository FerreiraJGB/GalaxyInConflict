require "/scripts/status.lua"

function init()
  self.listener = damageListener("damageTaken", function(notifications)
	for _,notification in pairs(notifications) do
		if notification.healthLost ~= 0 then
			animator.setAnimationState("shield", "hit")
			return
		end
	end
  end)
end

function update(dt)
  self.listener:update()
end
