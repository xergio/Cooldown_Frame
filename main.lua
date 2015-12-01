
local AddOnName, Engine = ...
local up, cd = {}, {}
local frame
local tick = 0


local function CreateAura(i)
	local button = CreateFrame("Button", "Cooldown_Frame_"..i, Cooldown_Frame_UP)

	button.t = button:CreateTexture(nil, "OVERLAY")
	button.t:SetTexCoord(.08, .92, .08, .92)
	button.t:ClearAllPoints()
	button.t:SetPoint('TOPLEFT', button, 'TOPLEFT', -2, 2)
	button.t:SetPoint('BOTTOMRIGHT', button, 'BOTTOMRIGHT', 2, -2)
	button.t:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")

	button.cd = CreateFrame('Cooldown', nil, button, 'CooldownFrameTemplate')
	button.cd:ClearAllPoints()
	button.cd:SetPoint('TOPLEFT', button, 'TOPLEFT', -2, 2)
	button.cd:SetPoint('BOTTOMRIGHT', button, 'BOTTOMRIGHT', 2, -2)
	button.cd.noOCC = true;
	button.cd.noCooldownCount = true;
	button.cd:SetHideCountdownNumbers(true)

	button.timer = button.cd:CreateFontString(nil, 'OVERLAY')
	button.timer:SetPoint('CENTER')

	local ButtonData = {
		FloatingBG = nil,
		Icon = button.t,
		Cooldown = button.cd,
		Flash = nil,
		Pushed = nil,
		Normal = nil,
		Disabled = nil,
		Checked = nil,
		Border = nil,
		AutoCastable = nil,
		Highlight = nil,
		HotKey = nil,
		Count = nil,
		Name = nil,
		Duration = false,
		AutoCast = nil,
	}

	button:SetID(i)
	button:Show()

	return button
end


local function OnEvent(self, event, ...)
	--print(event)
	if event == "SPELL_UPDATE_COOLDOWN" then
		if GetTime()-tick > 1 then
			for spellID, data in pairs(cd) do
				print(data.name)
				print((data.basecooldown/1000) - (GetTime() - data.start) )
			end
			tick = GetTime()
		end

	elseif event == "UNIT_SPELLCAST_SUCCEEDED" then
		local unitID, spell, rank, lineID, spellID = ...
		if unitID == "player" then
			local name, rank, icon, castingTime, minRange, maxRange, spellID = GetSpellInfo(spellID)
			if spellID == 75 then
				return
			end

			local start, duration, enable = GetSpellCooldown(spellID)
			local basecooldown = GetSpellBaseCooldown(spellID)
			--print(name)
			--print(basecooldown)
			if basecooldown > 1 then
				cd[spellID] = {
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
					basecooldown = basecooldown
				}
				CreateAura(spellID)
			end
		end
	end
end


function init()
	local frame = CreateFrame('Frame', 'Cooldown_Frame_UP', UIParent)

	local background = frame:CreateTexture("Cooldown_Frame_BG", "BACKGROUND")
	background:SetTexture(1, 1, 1, 0.25)
	background:SetAllPoints()

	frame:SetPoint("TOPLEFT", 5, 15)

	frame:SetWidth(300)
	frame:SetHeight(300)
	
	frame:RegisterEvent("SPELL_UPDATE_COOLDOWN")
	frame:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
	--frame:RegisterEvent("UNIT_AURA")
	frame:SetScript("OnEvent", OnEvent)
end


init()