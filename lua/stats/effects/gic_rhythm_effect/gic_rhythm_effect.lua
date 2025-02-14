function init()
	self.bpm = effect.getParameter("bpm", 120)
	self.rhythmEffects = effect.getParameter("effects", jarray())
	
	
	self.beatTime = 60 / self.bpm
	self.timer = self.beatTime
end

function update(dt)
	self.timer = self.timer - dt
	
	if (self.timer < 0) then
		status.addEphemeralEffects(self.rhythmEffects)
		self.timer = self.beatTime + 2 * dt
	end
end

function uninit()
end
