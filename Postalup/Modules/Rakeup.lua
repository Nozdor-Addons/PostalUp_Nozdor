local Postalup = LibStub("AceAddon-3.0"):GetAddon("Postalup")
local Postalup_Rake = Postalup:NewModule("Rakeup", "AceEvent-3.0")
local L = LibStub("AceLocale-3.0"):GetLocale("Postalup")
Postalup_Rake.description = L["Prints the amount of money collected during a mail session."]
local Selectup = select
local money

function Postalup_Rake:OnEnable()
	self:RegisterEvent("MAIL_SHOW")
end

-- Disabling modules unregisters all events/hook automatically
--function Postalup_Rake:OnDisable()
--end

function Postalup_Rake:MAIL_SHOW()
	money = GetMoney()
	self:RegisterEvent("MAIL_CLOSED")
end

function Postalup_Rake:MAIL_CLOSED()
	self:UnregisterEvent("MAIL_CLOSED")
	money = GetMoney() - money
	if money > 0 then
		Postalup:Print(L["Collected"].." "..Postalup:GetMoneyString(money))
	end
end
