require "/scripts/util.lua"

function init()
  self.detectArea = config.getParameter("detectArea")
  self.detectArea[1] = object.toAbsolutePosition(self.detectArea[1])
  self.detectArea[2] = object.toAbsolutePosition(self.detectArea[2])

  animator.setAnimationState("portal", "off")
  object.setLightColor({0, 0, 0, 0})

  storage.uuid = storage.uuid or sb.makeUuid()
  object.setInteractive(true)

  message.setHandler("onTeleport", function(message, isLocal, data)
      if not config.getParameter("returnDoor") and not storage.vanishTime then
        storage.vanishTime = world.time() + config.getParameter("vanishTime")
        if not (animator.animationState("portal") == "open" or animator.animationState("portal") == "on") then
          animator.setAnimationState("portal", "open")
        end
      end
    end)


end

function update(dt)
  if self.radioMessage ~= nil then
    self.radioMessage(dt)
  end

  if animator.animationState("portal") == "gone" then
    object.smash()
    return
  elseif storage.vanishTime and world.time() > storage.vanishTime then
    animator.setAnimationState("portal", "vanish")
  end

  local players = world.entityQuery(self.detectArea[1], self.detectArea[2], {
      includedTypes = {"player"},
      boundMode = "CollisionArea"
    })

  if #players > 0 and animator.animationState("portal") == "off" then
    animator.setAnimationState("portal", "open")
    animator.playSound("on");
    object.setLightColor(config.getParameter("lightColor", {255, 255, 255}))
  elseif #players == 0 and animator.animationState("portal") == "on" and not storage.vanishTime then
    animator.setAnimationState("portal", "close")
    animator.playSound("off");
    object.setLightColor({0, 0, 0, 0})
  end
end

function onInteraction(args)
  if config.getParameter("returnDoor") then
    return { "OpenTeleportDialog", {
        canBookmark = false,
        includePlayerBookmarks = false,
        destinations = { {
          name = "Exit Portal",
          planetName = "Return to World...",
          icon = "return",
          warpAction = "Return"
        } }
      }
    }
  else
    return { "OpenTeleportDialog", {
        canBookmark = false,
        includePlayerBookmarks = false,
        destinations = { {
          name = "The Slab",
          planetName = "[ULTRAKILL PROTOCOL]",
          icon = "default",
          warpAction = string.format("InstanceWorld:gic_protectedcolony_theslab:%s:%s", storage.uuid, world.threatLevel())
        } }
      }
    }
  end
end
