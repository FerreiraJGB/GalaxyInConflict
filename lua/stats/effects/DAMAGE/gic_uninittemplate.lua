-- note: the most stable method of triggering a status effect on expiration is by modifying the status effect's lua; otherwise, things could be funky if durations aren't appropriate
-- stuff to copy & paste is in update(dt)

function init()
end

-- note: when coppying and pasting this stuff, make sure the target `update` function is `update(dt)` and not merely `update()`! if function is the latter, update to look like the former.
function update(dt)

  --"stat" should be set to 1 in the persistent status effect to trigger
  if effect.duration() <= dt and status.stat("stat") == 1 then
	local duration = 3
	status.addEphemeralEffect("statusEffect",duration)
  end
end

function uninit()
end
