
-- BIG CoolLine inspiration http://www.curse.com/addons/wow/coolline-cooldowns

local CF = CreateFrame('Frame', 'Cooldown_Frame', UIParent) -- main frame
CF:SetScript("OnEvent", function(self, event, ...)
	self[event](self, ...)
end)

-- api functions
local _G, pairs, tinsert, tremove, GetTime, tostring, random = _G, pairs, table.insert, table.remove, GetTime, tostring, math.random

local cache = {} -- spell cache
local ignoreSpellID = {
	[75] = true, -- autoshot
	[836] = true -- ramdom spell "LOGINEFFECT" or something like this
}
local debug = true

CF.tick = 0.0

local function log(data)
	if debug then
		print("|cff88ffffCooldown_Frame|r |cffffff00LOG|r: ".. tostring(data))
	end
end


-- Snippet1: http://www.wowinterface.com/forums/showpost.php?p=167071&postcount=17
FrameHandler = {
	free = {},
	used = {},
	scripts = {
		OnDragStart = true,
		OnDragStop = true,
		OnEnter = true,
		OnEvent = true,
		OnKeyDown = true,
		OnKeyUp = true,
		OnLeave = true,
		OnLoad = true,
		OnMouseDown = true,
		OnMouseUp = true,
		OnMouseWheel = true,
		OnReceiveDrag = true,
		OnSizeChanged = true,
		OnUpdate = true,
	},

	AcquireButton = function(this, spellID)
		local parent = "Cooldown_Frame" --parent or UIParent
		local name = "Cooldown_Frame_"..tostring(spellID)
		
		local f = tremove(FrameHandler.free) or CreateFrame("Button", name)

		f:SetParent(parent)
		f.t = f.t or f:CreateTexture(nil, "OVERLAY")
		f.cd = f.cd or CreateFrame('Cooldown', nil, f, 'CooldownFrameTemplate')
		f.timer = f.timer or f.cd:CreateFontString(nil, 'OVERLAY')

		f:SetID(spellID)
		f:Hide()

		f:SetScript("OnEnter", function()
			GameTooltip:Hide()
			GameTooltip:SetOwner(f)
			GameTooltip:ClearLines()

			GameTooltip:SetSpellByID(spellID)

			GameTooltip:Show()
		end)
		f:SetScript("OnLeave", function() GameTooltip:Hide() end)

		--[[v1 f:SetScript('OnUpdate',  function(self, ...) CF:UpdateCD(self, ...) end)
		f:SetScript("OnEvent", function(self, event, ...) CF[event](self, ...) end)]]

		tinsert(FrameHandler.used, f)

		log(("Frame Acquired (cd) %s (%if %iu)"):format(name, #FrameHandler.free, #FrameHandler.used))

		return f
	end,
 
	ReleaseButton = function(this, f)
		local name = f:GetName()
		local spellID = f:GetID()

		f.timer:SetText("")

		f:Hide()
		f:SetParent(nil)
		f:UnregisterAllEvents()
		f:ClearAllPoints()

		for script, _ in pairs(FrameHandler.scripts) do
			f:SetScript(script, nil)
		end
		if name then
			_G[name] = nil
		end

		f.cache = nil
		local i
		for i = 1, #FrameHandler.used do
			if FrameHandler.used[i]:GetName() == name then
				tinsert(FrameHandler.free, tremove(FrameHandler.used, i))
				break
			end
		end

		log(("Frame Released (ready) %s (%if %iu)"):format(name, #FrameHandler.free, #FrameHandler.used))
	end
}
-- /Snippet1


---------------------
function CF:Reorder()
	local now = GetTime()
	table.sort(FrameHandler.used, function(a, b)
		return (a.cache.start + a.cache.duration - now) < (b.cache.start + b.cache.duration - now)
	end)
end


------------------------------------
function CF:UpdateCDs(self, elapsed)
	self.tick = self.tick + elapsed
	if self.tick < 0.1 then return end
	--log(self.tick)
	self.tick = 0.0

	local now = GetTime()
	for i, frame in pairs(FrameHandler.used) do
		repeat
			if frame.cache == nil then break end -- we need the cache info

			local remaining = frame.cache.start + frame.cache.duration - now

			if remaining <= 0 then
				FrameHandler:ReleaseButton(frame)

				if #FrameHandler.used == 0 then
					log("Stop updates!")
					self:UnregisterEvent("SPELL_UPDATE_COOLDOWN")
					self:SetScript("OnUpdate", nil)
					return
				end
				self:Reorder()
				--self:SPELL_UPDATE_COOLDOWN() -- force 1 last update to stop updates if no frames used

			elseif remaining > 60 then
				local mins = (remaining / 60) % 60
				local secs = remaining % 60
				frame.timer:SetText(("%i:%i"):format(mins,  secs))

			elseif remaining > 3 then
				frame.timer:SetText(("%i"):format(remaining))

			else
				frame.timer:SetText(("%.1f"):format(remaining))
			end

			frame:SetPoint("RIGHT", Cooldown_Frame, "RIGHT", (35*(i-1))*-1, 0)
		until true
	end
end


--------------------
function CF:AddCD(i)
	local button = FrameHandler:AcquireButton(i)

	--button.t = button:CreateTexture(nil, "OVERLAY")
	button.t:SetTexCoord(0, 1, 0, 1)
	button.t:ClearAllPoints()
	button.t:SetAllPoints(button)
	button.t:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")

	--button.cd = CreateFrame('Cooldown', nil, button, 'CooldownFrameTemplate')
	button.cd:SetAllPoints(button)
	button.cd:SetHideCountdownNumbers(true)
	button.cd:SetCooldown(GetTime(), 10)

	--button.timer = button.cd:CreateFontString(nil, 'OVERLAY')
	button.timer:SetPoint('CENTER')
	button.timer:SetFont("Fonts\\FRIZQT__.TTF", 16, "THINOUTLINE")
	button.timer:SetJustifyH("CENTER")
	--button.timer:SetText("...")

	button.t:SetAlpha(1)
	button:ClearAllPoints()
	button:SetSize(30, 30)
	button:SetPoint("RIGHT", Cooldown_Frame, "RIGHT", (35*(#FrameHandler.used-1))*-1, 0)

	button.nexttick = GetTime()+0.1
	--button:Show() -- we'll wait until 1st update cd

	--[[v1 button:RegisterEvent("SPELL_UPDATE_COOLDOWN")]]
	--[[v2]]
	self:RegisterEvent("SPELL_UPDATE_COOLDOWN")
	self:SetScript("OnUpdate",  function(self, elapsed) CF:UpdateCDs(self, elapsed) end)

	return button
end


--------------------------------------
function CF:SPELL_UPDATE_COOLDOWN(...)
	for _, frame in pairs(FrameHandler.used) do
		local spellID = frame:GetID()
		if frame.cache == nil then -- only the 1st update
			local name, rank, icon, castingTime, minRange, maxRange, spellID = GetSpellInfo(spellID)
			local start, duration, enable = GetSpellCooldown(spellID)
			--local basecooldown = GetSpellBaseCooldown(spellID)
			if duration > 1.5 then -- gCD
				log(("duration:%f %s %i"):format(duration, name, spellID))
				frame.t:SetTexture(icon)
				frame.cd:SetCooldown(start, duration)
				frame.cache = {
					name = name, 
					rank = rank, 
					icon = icon, 
					castingTime = castingTime, 
					minRange = minRange, 
					maxRange = maxRange, 
					spellID = spellID,
					start = start, 
					duration = duration, 
					enable = enable,
					--basecooldown = basecooldown
				}
				self:Reorder()
				frame:Show()

			else -- there is no way to get the CD before this event, so... we'll create more auras than needed :(
				log(("duration:NO %s %i"):format(name, spellID))
				FrameHandler:ReleaseButton(frame)
			end
		end
	end
end


-----------------------------------------
function CF:UNIT_SPELLCAST_SUCCEEDED(...)
	local unitID, spellName, rank, lineID, spellID = ...
	if unitID ~= "player" then return end
	if ignoreSpellID[spellID] then return end

	self:AddCD(spellID) -- ok, the spell should be valid
end


------------------------------ init
function CF:ADDON_LOADED(name)
	if name ~= "Cooldown_Frame" then return end
	self:UnregisterEvent("ADDON_LOADED")

	SlashCmdList.CF = self.Options
	SLASH_CF1 = "/cf"

	-- http://wowprogramming.com/docs/widgets/Frame/CreateTexture
	-- http://wowprogramming.com/docs/widgets/Texture/SetTexture
	local background = self:CreateTexture("Cooldown_Frame_BG", "BACKGROUND")
	background:SetTexture(0, 0, 0, 0.25)
	background:SetAllPoints()

	self:SetPoint("CENTER", 0, 200)
	self:SetWidth(300)
	self:SetHeight(50)
	
	self:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED") -- trigger for new icons
	--self:RegisterEvent("SPELL_UPDATE_COOLDOWN") -- trigger for update cd (and show the aura)
	--self:RegisterEvent("UNIT_AURA")
end


-------------------------- options maybe
CF.Options = function(opt)
	print("|cff88ffffCooldown_Frame|r: |cffffff00"..opt.."|r hi!")
end


-------------------------------- lets go!
CF:RegisterEvent("ADDON_LOADED")
