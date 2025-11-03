local Postalup = LibStub("AceAddon-3.0"):GetAddon("Postalup")
local Postalup_CarbonCopy = Postalup:NewModule("CarbonCopyup", "AceHook-3.0")
local L = LibStub("AceLocale-3.0"):GetLocale("Postalup")
local Selectup = select
Postalup_CarbonCopy.description = L["Allows you to copy the contents of a mail."]

function Postalup_CarbonCopy:OnEnable()
	self:Hook("OpenMail_Update", true)
	if OpenMailScrollFrame:IsVisible() then
		self:OpenMail_Update()
	end
end

-- Disabling modules unregisters all events/hook automatically
function Postalup_CarbonCopy:OnDisable()
	if self.button then
		self.button:Hide()
	end
end

function Postalup_CarbonCopy:OpenMail_Update()
	if not InboxFrame.openMailID then return end
	local bodyText, _, _, isInvoice = GetInboxText(InboxFrame.openMailID)

	-- Show or hide the button as necessary
	if isInvoice or (bodyText and #bodyText > 0) then
		if self.CreateButton then
			self:CreateButton()
		end
		self.button:Show()
	else
		if self.button then
			self.button:Hide()
		end
	end
end

function Postalup_CarbonCopy:CopyMail()
	-- Build the string
	local _, _, sender, subject = GetInboxHeaderInfo(InboxFrame.openMailID)
	sender = FROM.." "..(sender or UNKNOWN).."\r\n"
	subject = MAIL_SUBJECT_LABEL.." "..subject.."\r\n\r\n"
	local bodyText, _, _, isInvoice = GetInboxText(InboxFrame.openMailID)
	bodyText = bodyText or ""
	if isInvoice then
		local invoiceType, itemName, playerName, bid, buyout, deposit, consignment = GetInboxInvoiceInfo(InboxFrame.openMailID)
		if playerName then
			if invoiceType == "buyer" then
				bodyText = bodyText..ITEM_PURCHASED_COLON.." "..itemName
				if bid == buyout then
					bodyText = bodyText.." ("..BUYOUT..")\r\n"
				else
					bodyText = bodyText.." ("..HIGH_BIDDER..")\r\n"
				end
				bodyText = bodyText..SOLD_BY_COLON.." "..playerName.."\r\n"
					.."----------------------------------------\r\n"
					..AMOUNT_PAID_COLON.." "..Postalup:GetMoneyStringPlain(bid)
			elseif invoiceType == "seller" then
				bodyText = bodyText..ITEM_SOLD_COLON.." "..itemName.."\r\n"
				..PURCHASED_BY_COLON.." "..playerName
				if bid == buyout then
					bodyText = bodyText.." ("..BUYOUT..")\r\n\r\n"
				else
					bodyText = bodyText.." ("..HIGH_BIDDER..")\r\n\r\n"
				end
				bodyText = bodyText..SALE_PRICE_COLON.." "..Postalup:GetMoneyStringPlain(bid).."\r\n"
					..DEPOSIT_COLON.." "..Postalup:GetMoneyStringPlain(deposit).."\r\n"
					..AUCTION_HOUSE_CUT_COLON.." "..Postalup:GetMoneyStringPlain(consignment).."\r\n"
					.."----------------------------------------\r\n"
					..AMOUNT_RECEIVED_COLON.." "..Postalup:GetMoneyStringPlain(bid+deposit-consignment)
			end
		end
	end

	-- Copy to frame
	if Postalup.CreateAboutFrame then
		Postalup:CreateAboutFrame()
	end
	Postalup.aboutFrame:Show()
	Postalup.aboutFrame.editBox:SetText(sender..subject..bodyText.."\r\n")
	Postalup.aboutFrame.editBox:HighlightText(0)
	Postalup.aboutFrame.editBox:SetFocus()
end

function Postalup_CarbonCopy:CreateButton()
	local button = CreateFrame("Button", nil, OpenMailScrollFrame)
	button:SetPoint("TOPRIGHT", OpenMailScrollFrame, "TOPRIGHT", 0, 0)
	button:SetHeight(10)
	button:SetWidth(10)
	button:SetNormalTexture(Selectup(3, GetSpellInfo(586)))
	button:SetHighlightTexture([[Interface\Buttons\ButtonHilight-Square]])
	button:SetScript("OnClick", function()
		Postalup_CarbonCopy:CopyMail()
	end)
	button:SetScript("OnEnter", function(self)
		self:SetHeight(28)
		self:SetWidth(28)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		GameTooltip:ClearLines()
		GameTooltip:AddLine(L["Copy this mail"])
		GameTooltip:Show()
	end)
	button:SetScript("OnLeave", function(self)
		self:SetHeight(10)
		self:SetWidth(10)
		GameTooltip:Hide()
	end)
	self.button = button
	OpenMailScrollFrame.PostalupCarbonCopyButton = button
	self.CreateButton = nil -- Kill ourselves
end
