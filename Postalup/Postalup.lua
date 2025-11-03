local Postalup = LibStub("AceAddon-3.0"):NewAddon("Postalup", "AceEvent-3.0", "AceHook-3.0")
local L = LibStub("AceLocale-3.0"):GetLocale("Postalup")
_G["Postalup"] = Postalup

local Selectup = select
local TOC = Selectup(4, GetBuildInfo())

-- defaults for storage
local defaults = {
	profile = {
		ModuleEnabledState = {
			["*"] = true
		},
		OpenSpeed = 0.50,
		Selectup = {
			SpamChat = true,
			KeepFreeSpace = 1,
		},
		OpenAllup = {
			AHCancelled = true,
			AHExpired = true,
			AHOutbid = true,
			AHSuccess = true,
			AHWon = true,
			NeutralAHCancelled = true,
			NeutralAHExpired = true,
			NeutralAHOutbid = true,
			NeutralAHSuccess = true,
			NeutralAHWon = true,
			Attachments = true,
			SpamChat = true,
			KeepFreeSpace = 1,
		},
		Expressup = {
			EnableAltClick = true,
			AutoSend = true,
			MouseWheel = true,
			MultiItemTooltip = true,
		},
		BlackBookup = {
			AutoFill = true,
			contacts = {},
			recent = {},
			AutoCompleteAlts = true,
			AutoCompleteRecent = true,
			AutoCompleteContacts = true,
			AutoCompleteRealIDFriends = true,
			AutoCompleteFriends = true,
			AutoCompleteGuild = true,
			ExcludeRandoms = true,
			DisableBlizzardAutoComplete = false,
			UseAutoComplete = true,
		},
	},
	global = {
		BlackBookup = {
			alts = {},
			realID = {},
		},
	},
}
local _G = getfenv(0)
local InboxTooMuch = _G.InboxTooMuchMail
local t = {}
Postalup.keepFreeOptions = {0, 1, 2, 3, 5, 10, 15, 20, 25, 30}

-- Use a common frame and setup some common functions for the Postalup dropdown menus
local Postalup_DropDownMenu = CreateFrame("Frame", "Postalup_DropDownMenu")
Postalup_DropDownMenu.displayMode = "MENU"
Postalup_DropDownMenu.info = {}
Postalup_DropDownMenu.levelAdjust = 0
Postalup_DropDownMenu.UncheckHack = function(dropdownbutton)
	_G[dropdownbutton:GetName().."Check"]:Hide()
	if TOC >= 40000 then
		_G[dropdownbutton:GetName().."UnCheck"]:Hide()
	end
end
Postalup_DropDownMenu.HideMenu = function()
	if UIDROPDOWNMENU_OPEN_MENU == Postalup_DropDownMenu then
		CloseDropDownMenus()
	end
end

-- Functions for long subject mouseover
local function subjectHoverIn(self)
	local s = _G["MailItem"..self:GetID().."Subject"]
	if s:GetStringWidth() + 25 > s:GetWidth() then
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		GameTooltip:SetText(s:GetText())
		GameTooltip:Show()
	end
end
local function subjectHoverOut(self)
	GameTooltip:Hide()
end


---------------------------
-- Postalup Core Functions --
---------------------------

function Postalup:OnInitialize()
	-- Version number
	if not self.version then self.version = GetAddOnMetadata("Postalup", "Version") end

	-- Initialize database
	self.db = LibStub("AceDB-3.0"):New("Postalup3DB", defaults)
	self.db.RegisterCallback(self, "OnProfileChanged", "OnProfileChanged")
	self.db.RegisterCallback(self, "OnProfileCopied", "OnProfileChanged")
	self.db.RegisterCallback(self, "OnProfileReset", "OnProfileChanged")

	-- Enable/disable modules based on saved settings
	for name, module in self:IterateModules() do 
		module:SetEnabledState(self.db.profile.ModuleEnabledState[name] or false)
		if module.OnEnable then
			hooksecurefunc(module, "OnEnable", self.OnModuleEnable_Common) -- Posthook
		end
	end

	-- Register events
	self:RegisterEvent("MAIL_CLOSED")

	-- Create the Menu Button
	local Postalup_ModuleMenuButton = CreateFrame("Button", "Postalup_ModuleMenuButton", MailFrame)
	Postalup_ModuleMenuButton:SetWidth(25)
	Postalup_ModuleMenuButton:SetHeight(25)
	Postalup_ModuleMenuButton:SetPoint("TOPRIGHT", -53, -12)
	Postalup_ModuleMenuButton:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIcon-ScrollDown-Up")
	Postalup_ModuleMenuButton:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Round")
	Postalup_ModuleMenuButton:SetDisabledTexture("Interface\\ChatFrame\\UI-ChatIcon-ScrollDown-Disabled")
	Postalup_ModuleMenuButton:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIcon-ScrollDown-Down")
	Postalup_ModuleMenuButton:SetScript("OnClick", function(self, button, down)
		if Postalup_DropDownMenu.initialize ~= Postalup.Menu then
			CloseDropDownMenus()
			Postalup_DropDownMenu.initialize = Postalup.Menu
		end
		ToggleDropDownMenu(1, nil, Postalup_DropDownMenu, self:GetName(), 0, 0)
	end)
	Postalup_ModuleMenuButton:SetScript("OnHide", Postalup_DropDownMenu.HideMenu)

	-- Create 7 buttons for mouseover on long subject lines
	for i = 1, 7 do
		local b = CreateFrame("Button", "PostalupSubjectHover"..i, _G["MailItem"..i])
		b:SetID(i)
		b:SetAllPoints(_G["MailItem"..i.."Subject"])
		b:SetScript("OnEnter", subjectHoverIn)
		b:SetScript("OnLeave", subjectHoverOut)
	end

	-- To fix Blizzard's bug caused by the new "self:SetFrameLevel(2);"
	if TOC < 40000 and not IsAddOnLoaded("!BlizzBugsSuck") then
		hooksecurefunc("UIDropDownMenu_CreateFrames", Postalup.FixMenuFrameLevels)
	end

	self.OnInitialize = nil
end

function Postalup:OnProfileChanged(event, database, newProfileKey)
	for name, module in self:IterateModules() do 
		if self.db.profile.ModuleEnabledState[name] then
			module:Enable()
		else
			module:Disable()
		end
	end
end

function Postalup:OnModuleEnable_Common()
	-- If the module is enabled with the MailFrame open (at mailbox)
	-- run the MAIL_SHOW() event function
	if self.MAIL_SHOW and MailFrame:IsVisible() then
		self:MAIL_SHOW()
	end
end

-- Hides the minimap unread mail button if there are no unread mail on closing the mailbox.
-- Does not scan past the first 50 items since only the first 50 are viewable.
function Postalup:MAIL_CLOSED()
	for i = 1, GetInboxNumItems() do
		if not Selectup(9, GetInboxHeaderInfo(i)) then return end
	end
	MiniMapMailFrame:Hide()
end

function Postalup:Print(...)
	local text = "|cff33ff99Postalup|r:"
	for i = 1, Selectup("#", ...) do
		text = text.." "..tostring(Selectup(i, ...))
	end
	print(text)
end

function Postalup.SaveOption(dropdownbutton, arg1, arg2, checked)
	Postalup.db.profile[arg1][arg2] = checked
end

function Postalup.ToggleModule(dropdownbutton, arg1, arg2, checked)
	Postalup.db.profile.ModuleEnabledState[arg1] = checked
	if checked then arg2:Enable() else arg2:Disable() end
end

function Postalup.SetOpenSpeed(dropdownbutton, arg1, arg2, checked)
	Postalup.db.profile.OpenSpeed = arg1
end

function Postalup.ProfileFunc(dropdownbutton, arg1, arg2, checked)
	if arg1 == "NewProfile" then
		StaticPopup_Show("Postalup_NEW_PROFILE")
	else
		Postalup.db[arg1](Postalup.db, arg2)
	end
	CloseDropDownMenus()
end

StaticPopupDialogs["Postalup_NEW_PROFILE"] = {
	text = L["New Profile Name:"],
	button1 = ACCEPT,
	button2 = CANCEL,
	hasEditBox = 1,
	maxLetters = 128,
	hasWideEditBox = 1,  -- Not needed in Cata
	editBoxWidth = 350,  -- Needed in Cata
	OnAccept = function(self)
		if TOC < 40000 then
			Postalup.db:SetProfile(strtrim(self.wideEditBox:GetText()))
		else
			Postalup.db:SetProfile(strtrim(self.editBox:GetText()))
		end
	end,
	OnShow = function(self)
		if TOC < 40000 then
			self.wideEditBox:SetText(Postalup.db:GetCurrentProfile())
			self.wideEditBox:SetFocus()
		else
			self.editBox:SetText(Postalup.db:GetCurrentProfile())
			self.editBox:SetFocus()
		end
	end,
	OnHide = StaticPopupDialogs[TOC < 40000 and "SET_GUILDMOTD" or "SET_GUILDPLAYERNOTE"].OnHide,
	EditBoxOnEnterPressed = function(self)
		local parent = self:GetParent()
		if TOC < 40000 then
			Postalup.db:SetProfile(strtrim(parent.wideEditBox:GetText()))
		else
			Postalup.db:SetProfile(strtrim(parent.editBox:GetText()))
		end
		parent:Hide()
	end,
	EditBoxOnEscapePressed = StaticPopupDialogs[TOC < 40000 and "SET_GUILDMOTD" or "SET_GUILDPLAYERNOTE"].EditBoxOnEscapePressed,
	timeout = 0,
	exclusive = 1,
	whileDead = 1,
	hideOnEscape = 1
}

function Postalup.Menu(self, level)
	if not level then return end
	local info = self.info
	wipe(info)
	if level == 1 then
		info.isTitle = 1
		info.text = "Postalup"
		info.notCheckable = 1
		UIDropDownMenu_AddButton(info, level)

		info.disabled = nil
		info.isTitle = nil
		info.notCheckable = nil

		info.keepShownOnClick = 1
		info.isNotRadio = 1
		for name, module in Postalup:IterateModules() do 
			info.text = L[name]
			info.func = Postalup.ToggleModule
			info.arg1 = name
			info.arg2 = module
			info.checked = module:IsEnabled()
			info.hasArrow = module.ModuleMenu ~= nil
			info.value = module
			UIDropDownMenu_AddButton(info, level)
		end

		wipe(info)
		info.disabled = 1
		UIDropDownMenu_AddButton(info, level)
		info.disabled = nil

		info.text = L["Opening Speed"]
		info.func = self.UncheckHack
		info.notCheckable = 1
		info.keepShownOnClick = 1
		info.hasArrow = 1
		info.value = "OpenSpeed"
		UIDropDownMenu_AddButton(info, level)

		info.text = L["Profile"]
		info.func = self.UncheckHack
		info.value = "Profile"
		UIDropDownMenu_AddButton(info, level)

		wipe(info)
		info.notCheckable = 1
		info.text = L["Help"]
		info.func = Postalup.About
		UIDropDownMenu_AddButton(info, level)

		info.disabled = 1
		info.text = nil
		info.func = nil
		UIDropDownMenu_AddButton(info, level)

		info.disabled = nil
		info.text = CLOSE
		info.func = self.HideMenu
		info.tooltipTitle = CLOSE
		UIDropDownMenu_AddButton(info, level)

	elseif level == 2 then
		if UIDROPDOWNMENU_MENU_VALUE == "OpenSpeed" then
			local speed = Postalup.db.profile.OpenSpeed
			for i = 0, 13 do
				local s = 0.3 + i*0.05
				info.text = format("%0.2f", s)
				info.func = Postalup.SetOpenSpeed
				info.checked = s == speed
				info.arg1 = s
				UIDropDownMenu_AddButton(info, level)
			end
			for i = 0, 8 do
				local s = 1 + i*0.5
				info.text = format("%0.2f", s)
				info.func = Postalup.SetOpenSpeed
				info.checked = s == speed
				info.arg1 = s
				UIDropDownMenu_AddButton(info, level)
			end

		elseif UIDROPDOWNMENU_MENU_VALUE == "Profile" then
			-- Profile stuff
			info.hasArrow = 1
			info.keepShownOnClick = 1
			info.func = self.UncheckHack
			info.notCheckable = 1

			info.text = L["Choose"]
			info.value = "SetProfile"
			UIDropDownMenu_AddButton(info, level)

			info.text = L["Copy From"]
			info.value = "CopyProfile"
			UIDropDownMenu_AddButton(info, level)

			info.text = L["Delete"]
			info.value = "DeleteProfile"
			UIDropDownMenu_AddButton(info, level)

			info.hasArrow = nil
			info.keepShownOnClick = nil
			info.func = Postalup.ProfileFunc
			info.arg1 = "NewProfile"
			info.text = L["New Profile"]
			UIDropDownMenu_AddButton(info, level)

			info.text = L["Reset Profile"]
			info.func = Postalup.ProfileFunc
			info.arg1 = "ResetProfile"
			info.arg2 = nil
			UIDropDownMenu_AddButton(info, level)
			
		elseif type(UIDROPDOWNMENU_MENU_VALUE) == "table" and UIDROPDOWNMENU_MENU_VALUE.ModuleMenu then
			-- Submenus for modules
			self.levelAdjust = 1
			UIDROPDOWNMENU_MENU_VALUE.ModuleMenu(self, level)
			self.levelAdjust = 0
			self.module = UIDROPDOWNMENU_MENU_VALUE
		end

	elseif level == 3 then
		if UIDROPDOWNMENU_MENU_VALUE == "SetProfile" then
			local cur = Postalup.db:GetCurrentProfile()
			Postalup.db:GetProfiles(t)
			table.sort(t)
			info.func = Postalup.ProfileFunc
			info.arg1 = "SetProfile"
			for i = 1, #t do
				local s = t[i]
				info.text = s
				info.arg2 = s
				info.checked = cur == s
				UIDropDownMenu_AddButton(info, level)
			end

		elseif UIDROPDOWNMENU_MENU_VALUE == "CopyProfile" or UIDROPDOWNMENU_MENU_VALUE == "DeleteProfile" then
			local cur = Postalup.db:GetCurrentProfile()
			Postalup.db:GetProfiles(t)
			table.sort(t)
			info.func = Postalup.ProfileFunc
			info.arg1 = UIDROPDOWNMENU_MENU_VALUE
			info.notCheckable = 1
			for i = 1, #t do
				local s = t[i]
				if s ~= cur then
					info.text = s
					info.arg2 = s
					UIDropDownMenu_AddButton(info, level)
				end
			end

		elseif self.module and self.module.ModuleMenu then
			self.levelAdjust = 1
			self.module.ModuleMenu(self, level)
			self.levelAdjust = 0
		end

	elseif level > 3 then
		if self.module and self.module.ModuleMenu then
			self.levelAdjust = 1
			self.module.ModuleMenu(self, level)
			self.levelAdjust = 0
		end

	end
end

function Postalup:CreateAboutFrame()
	local aboutFrame = Postalup.aboutFrame
	if not aboutFrame and Chatter and ChatterCopyFrame then
		aboutFrame = ChatterCopyFrame
		aboutFrame.editBox = Chatter:GetModule("Chat Copy").editBox
	end
	if not aboutFrame or not aboutFrame.editBox then
		aboutFrame = CreateFrame("Frame", "PostalupAboutFrame", UIParent)
		tinsert(UISpecialFrames, "PostalupAboutFrame")
		aboutFrame:SetBackdrop({
			bgFile = [[Interface\DialogFrame\UI-DialogBox-Background]],
			edgeFile = [[Interface\DialogFrame\UI-DialogBox-Border]],
			tile = true, tileSize = 16, edgeSize = 16,
			insets = { left = 3, right = 3, top = 5, bottom = 3 }
		})
		aboutFrame:SetBackdropColor(0,0,0,1)
		aboutFrame:SetWidth(500)
		aboutFrame:SetHeight(400)
		aboutFrame:SetPoint("CENTER", UIParent, "CENTER")
		aboutFrame:Hide()
		aboutFrame:SetFrameStrata("DIALOG")
		aboutFrame:SetToplevel(true)

		local scrollArea = CreateFrame("ScrollFrame", "PostalupAboutScroll", aboutFrame, "UIPanelScrollFrameTemplate")
		scrollArea:SetPoint("TOPLEFT", aboutFrame, "TOPLEFT", 8, -30)
		scrollArea:SetPoint("BOTTOMRIGHT", aboutFrame, "BOTTOMRIGHT", -30, 8)

		local editBox = CreateFrame("EditBox", nil, aboutFrame)
		editBox:SetMultiLine(true)
		editBox:SetMaxLetters(99999)
		editBox:EnableMouse(true)
		editBox:SetAutoFocus(false)
		editBox:SetFontObject(ChatFontNormal)
		editBox:SetWidth(400)
		editBox:SetHeight(270)
		editBox:SetScript("OnEscapePressed", function() aboutFrame:Hide() end)
		aboutFrame.editBox = editBox

		scrollArea:SetScrollChild(editBox)

		local close = CreateFrame("Button", nil, aboutFrame, "UIPanelCloseButton")
		close:SetPoint("TOPRIGHT", aboutFrame, "TOPRIGHT")
	end
	Postalup.aboutFrame = aboutFrame
	Postalup.CreateAboutFrame = nil -- Kill ourselves
end

function Postalup.About()
	if Postalup.CreateAboutFrame then Postalup:CreateAboutFrame() end
	local version = GetAddOnMetadata("Postalup", "Version")
	wipe(t)
	tinsert(t, "|cFFFFCC00"..GetAddOnMetadata("Postalup", "Title").." v"..version.."|r")
	tinsert(t, "-----")
	tinsert(t, "")
	for name, module in Postalup:IterateModules() do
		tinsert(t, "|cffffcc00"..name.."|r")
		if module.description then
			tinsert(t, module.description)
		end
		if module.description2 then
			tinsert(t, "")
			tinsert(t, module.description2)
		end
		tinsert(t, "")
	end
	tinsert(t, "-----")
	tinsert(t, L["Please post bugs or suggestions at the wowace forums thread at |cFF00FFFFhttp://forums.wowace.com/showthread.php?t=3909|r. When posting bugs, indicate your locale and Postalup's version number v%s."]:format(version))
	tinsert(t, "")
	tinsert(t, "- Xinhuan (Blackrock US Alliance)")
	tinsert(t, "")
	Postalup.aboutFrame.editBox:SetText(table.concat(t, "\n"))
	Postalup.aboutFrame:Show()
	wipe(t) -- For garbage collection
end

if TOC < 40000 and not IsAddOnLoaded("!BlizzBugsSuck") then
	-- To fix Blizzard's bug caused by the new "self:SetFrameLevel(2);"
	local function FixFrameLevel(level, ...)
		for i = 1, Selectup("#", ...) do
			local button = Selectup(i, ...)
			button:SetFrameLevel(level)
		end
	end
	function Postalup.FixMenuFrameLevels()
		-- Postalup only uses up to 4 levels of menus
		for i = 1, 4 do
			local f = _G["DropDownList"..i]
			if f then
				FixFrameLevel(f:GetFrameLevel() + 2, f:GetChildren())
			end
		end
	end
end

---------------------------
-- Common Mail Functions --
---------------------------

-- Disable Inbox Clicks
local function noop() end
function Postalup:DisableInbox(disable)
	if disable then
		if not self:IsHooked("InboxFrame_OnClick") then
			self:RawHook("InboxFrame_OnClick", noop, true)
			for i = 1, 7 do
				_G["MailItem" .. i .. "ButtonIcon"]:SetDesaturated(1)
			end
		end
	else
		if self:IsHooked("InboxFrame_OnClick") then
			self:Unhook("InboxFrame_OnClick")
			for i = 1, 7 do
				_G["MailItem" .. i .. "ButtonIcon"]:SetDesaturated(nil)
			end
		end
	end
end

-- Return the type of mail a message subject is
local SubjectPatterns = {
	AHCancelled = gsub(AUCTION_REMOVED_MAIL_SUBJECT, "%%s", ".*"),
	AHExpired = gsub(AUCTION_EXPIRED_MAIL_SUBJECT, "%%s", ".*"),
	AHOutbid = gsub(AUCTION_OUTBID_MAIL_SUBJECT, "%%s", ".*"),
	AHSuccess = gsub(AUCTION_SOLD_MAIL_SUBJECT, "%%s", ".*"),
	AHWon = gsub(AUCTION_WON_MAIL_SUBJECT, "%%s", ".*"),
}
function Postalup:GetMailType(msgSubject)
	if msgSubject then
		for k, v in pairs(SubjectPatterns) do
			if msgSubject:find(v) then return k end
		end
	end
	return "NonAHMail"
end

function Postalup:GetMoneyString(money)
	local gold = floor(money / 10000)
	local silver = floor((money - gold * 10000) / 100)
	local copper = mod(money, 100)
	if gold > 0 then
		return format(GOLD_AMOUNT_TEXTURE.." "..SILVER_AMOUNT_TEXTURE.." "..COPPER_AMOUNT_TEXTURE, gold, 0, 0, silver, 0, 0, copper, 0, 0)
	elseif silver > 0 then
		return format(SILVER_AMOUNT_TEXTURE.." "..COPPER_AMOUNT_TEXTURE, silver, 0, 0, copper, 0, 0)
	else
		return format(COPPER_AMOUNT_TEXTURE, copper, 0, 0)
	end
end

function Postalup:GetMoneyStringPlain(money)
	local gold = floor(money / 10000)
	local silver = floor((money - gold * 10000) / 100)
	local copper = mod(money, 100)
	if gold > 0 then
		return gold..GOLD_AMOUNT_SYMBOL.." "..silver..SILVER_AMOUNT_SYMBOL.." "..copper..COPPER_AMOUNT_SYMBOL
	elseif silver > 0 then
		return silver..SILVER_AMOUNT_SYMBOL.." "..copper..COPPER_AMOUNT_SYMBOL
	else
		return copper..COPPER_AMOUNT_SYMBOL
	end
end

function Postalup:CountItemsAndMoney()
	local numAttach = 0
	local numGold = 0
	for i = 1, GetInboxNumItems() do
		local msgMoney, _, _, msgItem = Selectup(5, GetInboxHeaderInfo(i))
		numAttach = numAttach + (msgItem or 0)
		numGold = numGold + msgMoney
	end
	return numAttach, numGold
end
