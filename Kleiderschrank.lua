local K = LibStub("AceAddon-3.0"):NewAddon("Kleiderschrank", "AceEvent-3.0", "AceConsole-3.0")

local ATT = AllTheThings
local SendAddonMessage = C_ChatInfo.SendAddonMessage
local RegisterAddonMessagePrefix = C_ChatInfo.RegisterAddonMessagePrefix

local Kleiderschrank = {}

function K:OnInitialize()
	local defaults = {
		factionrealm = {
		}
	}
	self.db = LibStub("AceDB-3.0"):New("KleiderschrankDB", defaults)
end

function K:OnEnable()
	self:BuildOptionsTable()
	LibStub("AceConfig-3.0"):RegisterOptionsTable("Kleiderschrank", self.options)
	self.optionsFrame = LibStub("AceConfigDialog-3.0"):AddToBlizOptions("Kleiderschrank", "Kleiderschrank")

	RegisterAddonMessagePrefix("Kleiderschrank")

	self:RegisterEvent("CHAT_MSG_ADDON", "MessageReceived")

	self:RegisterChatCommand("Kleiderschrank", "slash")
	self:RegisterChatCommand("ks", "slash")

	function self:slash(input)
		local arg1 = string.lower(input)
		if arg1 == "" then
			SendAddonMessage("Kleiderschrank", "REQUEST", "WHISPER", GetUnitName("Party1", true))
		elseif arg1 == "o" then
			self:OfferItems(GetUnitName("Party1", true))
		end
	end
end

-- AllTheThings
local L = {
	["COLLECTED"] = "|TInterface\\Addons\\AllTheThings\\assets\\known:0|t |cff15abffCollected|r";		-- Acquired the colors and icon from CanIMogIt.
	["COLLECTED_APPEARANCE"] = "|TInterface\\Addons\\AllTheThings\\assets\\known_circle:0|t |cff15abffCollected*|r";	-- Acquired the colors and icon from CanIMogIt.
	["NOT_COLLECTED"] = "|TInterface\\Addons\\AllTheThings\\assets\\unknown:0|t |cffff9333Not Collected|r";		-- Acquired the colors and icon from CanIMogIt.
	["NOTHING"] = "Keine Items zum Tauschen"
}

local function GetCollectionText(state)
		return L[(state and (state == 2 and "COLLECTED_APPEARANCE" or "COLLECTED")) or "NOT_COLLECTED"];
end

function K:BuildOptionsTable()
	local newOrder
	do
		local current = 0
		function newOrder()
			current = current + 1
			return current
		end
	end
	self.options = {
		type = "group",
		args = {},
	}

	for k,itemSubType in pairs({"Stoff", "Leder",	"Kette", "Platte", "Zweihandschwerter",	"Stäbe", "Faustwaffen", "Zweihandäxte",	"Dolche", "Zweihandstreitkolben", "Schusswaffen", "Einhandschwerter", "Zauberstäbe", "Armbrüste", "Bogen", "Stangenwaffen", "Einhandäxte", "Einhandstreitkolben", "Schilde", "Verschiedenes", "Kriegsgleven",}) do
		self.options.args[itemSubType] = {
			name = itemSubType,
			type = "input",
			order = newOrder(),
			--width = .6,
			set = function(info,val)
	   			K.db.factionrealm[itemSubType] = (val)
	   		end,
	    	get = function() return K.db.factionrealm[itemSubType] end
		}
	end
end

local n, k, status, offer = 0, 0, false, false

function K:MessageReceived(event, prefix, text, _, sendBy,...)
	if prefix == "Kleiderschrank" then
		if text == "REQUEST" then
			self:SendItems(sendBy)
		elseif text == "NOTHING" then
			print(L["NOTHING"])
		elseif select(3,string.find(text, "OFFER(|.*)")) then
			k = k + 1
			offer = true
			text = select(3,string.find(text, "OFFER(|.*)"))
			local state = ATT.SearchForLink(text)[1].collected
			if state ~= 1 then
				if Kleiderschrank:isBoP(text) then
					if CanIMogIt:CharacterCanLearnTransmog(text) then
						status = true
						SendAddonMessage("Kleiderschrank", "ANSWER"..text.." "..GetCollectionText(state), "WHISPER", sendBy)
					end
				else
					status = true
					SendAddonMessage("Kleiderschrank", "ANSWER"..text.." "..GetCollectionText(state), "WHISPER", sendBy)
				end
			end
		elseif select(3,string.find(text, "ANSWER(.*)")) then
			text = select(3,string.find(text, "ANSWER(.*)"))
			print(text)
		elseif select(3,string.find(text, "N|(.*)")) then
			n = tonumber(select(3,string.find(text, "N|(.*)")))
			if k == n then
				if (status ~= true) and (n > 0) then
					if offer == true then
						SendAddonMessage("Kleiderschrank", "ANSWER"..L["NOTHING"], "WHISPER", sendBy)
					else
						print(L["NOTHING"])
					end
				end
				n, k = 0, 0
				status, offer = false, false
			end
		else
			k = k + 1
			local state = ATT.SearchForLink(text)[1].collected
			if state ~= 1 then
				if Kleiderschrank:isBoP(text) then
					if CanIMogIt:CharacterCanLearnTransmog(text) then	
						status = true
						print(text, GetCollectionText(state))
					end
				else
					status = true
					print(text, GetCollectionText(state))
				end
			end
		end
	end
end

function K:SendItems(target, offer)
	local n = 0
	for bagID = 0, 4 do
		for slotID = 1, GetContainerNumSlots(bagID) do
			local itemLocation = ItemLocation:CreateFromBagAndSlot(bagID, slotID)
			if C_Item.DoesItemExist(itemLocation) then
				if not C_Item.IsBound(itemLocation) or Kleiderschrank:isTradable(itemLocation) then
					local itemLink = C_Item.GetItemLink(itemLocation)
					if itemLink ~= nil and CanIMogIt:IsTransmogable(itemLink) then
						local _, _, itemRarity, _, _, _, _, _, _, _, _, itemClassID = GetItemInfo(itemLink)
						if itemClassID == 2 or itemClassID == 4 then
							if itemRarity > 1 then
								local itemID = C_Item.GetItemID(itemLocation)
								if select(3, C_Transmog.GetItemInfo(itemID)) then
									if ATT.SearchForLink(itemLink)[1].collected or (Kleiderschrank:isBoP(itemLink) and not CanIMogIt:CharacterCanLearnTransmog(itemLink)) then
										n = n + 1
										if offer then
											SendAddonMessage("Kleiderschrank", "OFFER"..itemLink, "WHISPER", target)
										else
											SendAddonMessage("Kleiderschrank", itemLink, "WHISPER", target)
										end
									end
								end
							end
						end
					end
				end
			end
		end
	end
	SendAddonMessage("Kleiderschrank", "N|"..n, "WHISPER", target)
	if n == 0 then
		if offer then
			print(L["NOTHING"])
		else
			SendAddonMessage("Kleiderschrank", "NOTHING", "WHISPER", target)
		end
	end
end

function K:OfferItems(target)
	self:SendItems(target, true)
end



Kleiderschrank.events = CreateFrame("Frame")
Kleiderschrank.events:SetScript("OnEvent", function(self, event)
	if event == "MAIL_SEND_SUCCESS" then
		self:UnregisterEvent("MAIL_SEND_SUCCESS")
		local timerMail = C_Timer.After(.5, function() Kleiderschrank:SendMail() end)
	end
end)

Kleiderschrank.events:RegisterEvent("TRANSMOG_COLLECTION_UPDATED")

--[[{
	["Stoff"] = "Sanador",
	["Leder"] = "Capra",
	["Kette"] = "María",
	["Platte"] = "Urtgard",
	["Zweihandschwerter"] = "Urtgard",
	["Stäbe"] = "Urtgard",
	["Faustwaffen"] = "Urtgard",
	["Zweihandäxte"] = "Urtgard",
	["Dolche"] = "Urtgard",
	["Zweihandstreitkolben"] = "Urtgard",
	["Schusswaffen"] = "María",
	["Einhandschwerter"] = "Urtgard",
	["Zauberstäbe"] = "Sanador",
	["Armbrüste"] = "María",
	["Bogen"] = "María",
	["Stangenwaffen"] = "Urtgard",
	["Einhandäxte"] = "Urtgard",
	["Einhandstreitkolben"] = "Urtgard",
	["Schilde"] = "Urtgard",
	["Verschiedenes"] = "Sanador",
	["Kriegsgleven"] = "Lollêk-Khaz'goroth",
}--]]

--http://www.wowinterface.com/forums/showpost.php?p=303924&postcount=3
local tip = CreateFrame("GameTooltip","Tooltip",nil,"GameTooltipTemplate")
local function SearchTooltip(bag, slot, s)
    tip:SetOwner(UIParent, "ANCHOR_NONE")
    tip:SetBagItem(bag, slot)
    tip:Show()
    for i = 1,tip:NumLines() do
        if(_G["TooltipTextLeft"..i]:GetText() == s) then
            return true
        end
    end
		
    tip:Hide()
    return false
end

local function IsUnknown (bag, slot)
	return SearchTooltip(bag, slot, TRANSMOGRIFY_TOOLTIP_APPEARANCE_UNKNOWN)
end

local function IsSoulbound(bag, slot)
	return SearchTooltip(bag, slot, ITEM_SOULBOUND)
end

--ITEM_BIND_ON_PICKUP 

--/run for k,v in pairs(_G) do if type(v) == "string" then if string.find(v, "Für die nächsten") then print(k,v) end end end

function Kleiderschrank:isBoP(itemLink)
	tip:SetOwner(UIParent, "ANCHOR_NONE")
	tip:SetHyperlink(itemLink)
	tip:Show()
	for i = 1,tip:NumLines() do
		if _G["TooltipTextLeft"..i]:GetText() == ITEM_BIND_ON_PICKUP then
			return true
		end
	end
	
	tip:Hide()
    return false
end

function Kleiderschrank:isTradable(itemLocation)
	local itemLink = C_Item.GetItemLink(itemLocation)
	tip:SetOwner(UIParent, "ANCHOR_NONE")
	tip:SetBagItem(itemLocation:GetBagAndSlot())
	tip:Show()
	for i = 1,tip:NumLines() do
		--print(i, _G["TooltipTextLeft"..i]:GetText())
		if(string.find(_G["TooltipTextLeft"..i]:GetText(), string.format(BIND_TRADE_TIME_REMAINING, ".*"))) then
			return true
		end
	end
	
	tip:Hide()
    return false
end

local cache = {}

local function EquipOldItems()
	for i, v in pairs(cache) do
		EquipItemByName(GetContainerItemLink(unpack(v)))
	end
	cache = {}
end

function Kleiderschrank:Equip()
	for bag = 0, 4 do
		for slot = 1, GetContainerNumSlots(bag) do
			local  itemLink = GetContainerItemLink(bag, slot)
			if itemLink ~= nil then
				if CanIMogIt:IsEquippable(itemLink) then
					if CanIMogIt:PlayerKnowsTransmogFromItem(itemLink) == false and CanIMogIt:CharacterCanLearnTransmog(itemLink) == true then
						EquipItemByName(itemLink)
						StaticPopup1Button1:Click()
						local _,_,_,_,_,_,_,_, equipSlot = GetItemInfo(itemLink)
						if not cache[equipSlot] then
							cache[equipSlot] = {bag, slot}
						end
					end
				end
			end
		end
	end
	local timer = C_Timer.After(1, function() EquipOldItems() end)
end

function Kleiderschrank:Sell()
	local i = 0
	for bag = 0, 4 do
		for slot = 1, GetContainerNumSlots(bag) do
			if GetContainerItemLink(bag, slot) ~= nil then
				if IsSoulbound(bag, slot) then
					local _,_,_,_,_, itemType, itemSubType,_,_,_, vendorPrice = GetItemInfo(GetContainerItemLink(bag, slot))
					if (itemType == "Rüstung" or itemType == "Waffe") and vendorPrice > 0 then
						if not IsUnknown(bag, slot) then
							UseContainerItem(bag, slot)
							i = i + 1
							if i == 12 then
								return nil
							end
						end
					end
				end
			end
		end
	end
end

local k = 0
local itemList = {}
local mailingList = {}

function Kleiderschrank:SendMail()
	if itemList ~= nil then
		for iii, vvv in pairs(itemList) do
			for ii, vv in pairs(vvv) do
				print("--------")
				for i, v in pairs(vv) do
					print(GetContainerItemLink(unpack(v)))
					PickupContainerItem(unpack(v))
					ClickSendMailItemButton()
					itemList[iii][ii][i] = nil
				end
				self.events:RegisterEvent("MAIL_SEND_SUCCESS")
				SendMail(iii, "Kleiderschrank")
				itemList[iii][ii] = nil
				return true
			end
			itemList[iii] = nil
		end
	end
end

function Kleiderschrank:Stocktake()
	local config = K.db.factionrealm
	itemList = {}
	for bag = 0, 4 do
		for slot = 1, GetContainerNumSlots(bag) do
			local itemLink = GetContainerItemLink(bag, slot)
			if itemLink ~= nil then
				if CanIMogIt:IsEquippable(itemLink) then
					if not IsSoulbound(bag, slot) then
						if CanIMogIt:PlayerKnowsTransmogFromItem(itemLink) == false then
							if not CanIMogIt:CharacterCanLearnTransmog(itemLink) then
								local _,_, itemQuality,_,_, itemType, itemSubType = GetItemInfo(itemLink)
								if itemQuality > 1 then
									local t = itemList[config[itemSubType]]
									if not t then
										t = {}
										t[1] = {}
									end
									if table.getn(t[table.getn(t)]) == 12 then
										t[table.getn(t)+1] = {}
										t[table.getn(t)][1] = {bag, slot}
									else
										t[table.getn(t)][table.getn(t[table.getn(t)])+1] = {bag, slot}
									end
									itemList[config[itemSubType]] = t
								end
							end
						end
					end
				end
			end
		end
	end
	self:SendMail()
end

--Mail button
Kleiderschrank.MailButton = CreateFrame("Button", "KleiderschrankMailButton", MailFrame, "UIPanelButtonTemplate")
Kleiderschrank.MailButton:SetPoint("TOPRIGHT", MailFrame, "BOTTOMRIGHT", -5, -5)
Kleiderschrank.MailButton:SetWidth(100)
Kleiderschrank.MailButton:SetHeight(21)
Kleiderschrank.MailButton:SetText("Kleiderschrank")
Kleiderschrank.MailButton:SetScript("OnClick", function(_, button)
	if button == "LeftButton" then
		Kleiderschrank:Stocktake()
	end end)

--Equip button
Kleiderschrank.EquipButton = CreateFrame("Button", "KleiderschrankEquipButton", CharacterFrame, "UIPanelButtonTemplate")
Kleiderschrank.EquipButton:SetPoint("TOPRIGHT", CharacterFrame, "BOTTOMRIGHT", -5, -5)
Kleiderschrank.EquipButton:SetWidth(100)
Kleiderschrank.EquipButton:SetHeight(21)
Kleiderschrank.EquipButton:SetText("Kleiderschrank")
Kleiderschrank.EquipButton:SetScript("OnClick", function(_, button)
	if button == "LeftButton" then
		Kleiderschrank:Equip()
	end end)



--[[
function Kleiderschrank_Mail(k)
	local i = 0
	for j = k or 0, table.getn(config) do
		if config[j].char ~= "" and config[j].char ~= UnitName("player") and config[j].char ~= UnitName("player").."-"..GetRealmName() then
			for bag = 0, 4 do
				for slot = 1, GetContainerNumSlots(bag) do
					if GetContainerItemLink(bag, slot) ~= nil then
						if not IsSoulbound(bag, slot) then
							if CanIMogIt:IsEquippable(GetContainerItemLink(bag, slot)) then
								if CanIMogIt:PlayerKnowsTransmog(GetContainerItemLink(bag, slot)) == false and CanIMogIt:CharacterCanLearnTransmog(GetContainerItemLink(bag, slot)) == false then
									local _,_,_,_,_, itemType, itemSubType = GetItemInfo(GetContainerItemLink(bag, slot))
									if (itemType == "Rüstung" or itemType == "Waffe") and itemSubType == config[j].type then
										print(GetContainerItemLink(bag, slot))
										PickupContainerItem(bag, slot)
										ClickSendMailItemButton()
										i = i + 1
										if i == 12 then
											events:RegisterEvent("MAIL_SEND_SUCCESS")
											k = j
										--	SendMail(config[j].char, config[j].type)
										--	return nil
										end
									end
								end
							end
						end
					end
				end
			end
			if i ~= 0 then
				events:RegisterEvent("MAIL_SEND_SUCCESS")
				k = j + 1
				--SendMail(config[j].char, config[j].type)
				--return nil
			end
		end
	end
end]]

local InventorySlots = {
    ['INVTYPE_HEAD'] = 1,
    ['INVTYPE_NECK'] = 2,
    ['INVTYPE_SHOULDER'] = 3,
    ['INVTYPE_BODY'] = 4,
    ['INVTYPE_CHEST'] = 5,
    ['INVTYPE_ROBE'] = 5,
    ['INVTYPE_WAIST'] = 6,
    ['INVTYPE_LEGS'] = 7,
    ['INVTYPE_FEET'] = 8,
    ['INVTYPE_WRIST'] = 9,
    ['INVTYPE_HAND'] = 10,
    ['INVTYPE_CLOAK'] = 15,
    ['INVTYPE_WEAPON'] = 16,
    ['INVTYPE_SHIELD'] = 17,
    ['INVTYPE_2HWEAPON'] = 16,
    ['INVTYPE_WEAPONMAINHAND'] = 16,
    ['INVTYPE_RANGED'] = 16,
    ['INVTYPE_RANGEDRIGHT'] = 16,
    ['INVTYPE_WEAPONOFFHAND'] = 17,
    ['INVTYPE_HOLDABLE'] = 17,
    -- ['INVTYPE_TABARD'] = 19,
}