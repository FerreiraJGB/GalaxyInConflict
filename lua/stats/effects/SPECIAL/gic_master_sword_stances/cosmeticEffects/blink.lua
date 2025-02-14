function init()
    animator.playSound("activate")
    animator.setAnimationState("blink", "blinkin")
	animator.setGlobalTag("directives", config.getParameter("directives",""))--"?hueshift=180")
end

function update(dt)
  if animator.animationState("blink") == "none" then
     effect.expire()
  end
end

function uninit()
end
