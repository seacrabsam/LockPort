local LockPortOptions_DefaultSettings = {
	whisper = true,
	zone    = true,
    shards  = true,
    sound  = true,
}

local function LockPort_Initialize()
	if not LockPortOptions  then
		LockPortOptions = {}
	end
	for i in LockPortOptions_DefaultSettings do
		if LockPortOptions[i] == false then
			LockPortOptions[i] = false
		else
			LockPortOptions[i] = LockPortOptions_DefaultSettings[i]
		end
	end
	if LockPortOptions["whisper"] == true then
		WhisperCheckButton:SetChecked(true)
	else
		WhisperCheckButton:SetChecked(false)
	end
	if LockPortOptions["zone"] == true then
		ZoneCheckButton:SetChecked(true)
	else
		ZoneCheckButton:SetChecked(false)
	end
	if LockPortOptions["shards"] == true then
		ShardsCheckButton:SetChecked(true)
	else
		ShardsCheckButton:SetChecked(false)
	end
	if LockPortOptions["sound"] == true then
		SoundCheckButton:SetChecked(true)
	else
		SoundCheckButton:SetChecked(false)
	end
end

function LockPort_EventFrame_OnLoad()
	DEFAULT_CHAT_FRAME:AddMessage(string.format("|CFFB700B7L|CFFFF00FFo|CFFFF50FFc|CFFFF99FFk|CFFFFC4FFP|cffffffffort|r version %s by %s. Type /lockport to show.", GetAddOnMetadata("LockPort", "Version"), GetAddOnMetadata("LockPort", "Author")))
    this:RegisterEvent("VARIABLES_LOADED")
    this:RegisterEvent("CHAT_MSG_ADDON")
    this:RegisterEvent("CHAT_MSG_RAID")
	this:RegisterEvent("CHAT_MSG_RAID_LEADER")
    this:RegisterEvent("CHAT_MSG_SAY")
    this:RegisterEvent("CHAT_MSG_YELL")
    this:RegisterEvent("CHAT_MSG_WHISPER")
    -- Commands
	SlashCmdList["LockPort"] = LockPort_SlashCommand
	SLASH_LockPort1 = "/lockport"
	SLASH_LockPort2 = "/gurky"
	MSG_PREFIX_ADD		= "RSAdd"
	MSG_PREFIX_REMOVE	= "RSRemove"
	LockPortDB = {}
	-- Sync Summon Table between raiders ? (if in raid & raiders with unempty table)
	--localization
	LockPortLoc_Header = "|CFFB700B7L|CFFFF00FFo|CFFFF50FFc|CFFFF99FFk|CFFFFC4FFP|cffffffffort|r"
	LockPortLoc_Settings_Header = "|CFFB700B7L|CFFFF00FFo|CFFFF50FFc|CFFFF99FFk|CFFFFC4FFP|cffffffffort|r Settings"
	LockPortLoc_Settings_Chat_Header = "|CFFB700B7C|CFFFF00FFh|CFFFF50FFa|CFFFF99FFt|CFFFFC4FF S|cffffffffett|rings"
end

function LockPort_EventFrame_OnEvent()
	if event == "VARIABLES_LOADED" then
		this:UnregisterEvent("VARIABLES_LOADED")
		LockPort_Initialize()
	elseif event == "CHAT_MSG_SAY" or event == "CHAT_MSG_RAID" or event == "CHAT_MSG_RAID_LEADER" or event == "CHAT_MSG_YELL" or event == "CHAT_MSG_WHISPER" then	
		-- if (string.find(arg1, "^123") and UnitClass("player")~=arg2) then
		if string.find(arg1, "^123") then
			-- DEFAULT_CHAT_FRAME:AddMessage("CHAT_MSG")
			SendAddonMessage(MSG_PREFIX_ADD, arg2, "RAID")
		end
	elseif event == "CHAT_MSG_ADDON" then
		if arg1 == MSG_PREFIX_ADD then
			-- DEFAULT_CHAT_FRAME:AddMessage("CHAT_MSG_ADDON - RSAdd : " .. arg2)
			if not LockPort_hasValue(LockPortDB, arg2) and UnitName("player")~=arg2 and UnitClass("player") == "Warlock" then
				table.insert(LockPortDB, arg2)
				LockPort_UpdateList()
				if LockPortOptions.sound then
					PlaySoundFile("Sound\\Creature\\Necromancer\\NecromancerReady1.wav")
				end
			end
		elseif arg1 == MSG_PREFIX_REMOVE then
			if LockPort_hasValue(LockPortDB, arg2) then
				-- DEFAULT_CHAT_FRAME:AddMessage("CHAT_MSG_ADDON - RSRemove : " .. arg2)
				for i, v in ipairs (LockPortDB) do
					if v == arg2 then
						table.remove(LockPortDB, i)
						LockPort_UpdateList()
					end
				end
			end
		end
	end
end

function LockPort_hasValue (tab, val)
    for i, v in ipairs (tab) do
        if v == val then
            return true
        end
    end
    return false
end

--GUI
function LockPort_NameListButton_OnClick(button)
	local name = getglobal(this:GetName().."TextName"):GetText()
	local message, base_message, whisper_message, base_whisper_message, whisper_eviltwin_message, zone_message, subzone_message = ""
	local bag,slot,texture,count = FindItem("Soul Shard")
	local eviltwin_debuff = "Spell_Shadow_Charm"
	local has_eviltwin = false

	if button  == "LeftButton" and IsControlKeyDown() then
		LockPort_GetRaidMembers()
		if LockPort_UnitIDDB then
			for i, v in ipairs (LockPort_UnitIDDB) do
				if v.rName == name then
					UnitID = "raid"..v.rIndex
				end
			end
			if UnitID then
				TargetUnit(UnitID)
			end
		else
			DEFAULT_CHAT_FRAME:AddMessage("|CFFB700B7L|CFFFF00FFo|CFFFF50FFc|CFFFF99FFk|CFFFFC4FFP|cffffffffort|r : no raid found")
		end
	elseif button == "LeftButton" and not IsControlKeyDown() then
		LockPort_GetRaidMembers()
		if LockPort_UnitIDDB then
			for i, v in ipairs (LockPort_UnitIDDB) do
				if v.rName == name then
					UnitID = "raid"..v.rIndex
				end
			end
			if UnitID then
				playercombat = UnitAffectingCombat("player")
				targetcombat = UnitAffectingCombat(UnitID)
			
				if not playercombat and not targetcombat then
					count = count-1
					base_message 			= "Summoning " .. name .. ""
					base_whisper_message    = "Summoning you"
					zone_message            = " to " .. GetZoneText()
					subzone_message         = " - " .. GetSubZoneText()
					shards_message          = " [" .. count .. " shards left]"
					message                 = base_message
					whisper_message         = base_whisper_message

					-- Evil Twin check
					for i=1,16 do
						s=UnitDebuff("target", i)
						if(s) then
							if (strfind(strlower(s), strlower(eviltwin_debuff))) then
						        has_eviltwin = true
							end
						end
					end

					TargetUnit(UnitID)

					if (has_eviltwin) then
						whisper_eviltwin_message = "Can't summon you because of Evil Twin Debuff, you need either to die or to run by yourself"
						SendChatMessage(whisper_eviltwin_message, "WHISPER", nil, name)
						DEFAULT_CHAT_FRAME:AddMessage("|CFFB700B7L|CFFFF00FFo|CFFFF50FFc|CFFFF99FFk|CFFFFC4FFP|cffffffffort|r : <" .. name .. "> has |cffff0000Evil Twin|r !")
						for i, v in ipairs (LockPortDB) do
							if v == name then
								SendAddonMessage(MSG_PREFIX_REMOVE, name, "RAID")
								table.remove(LockPortDB, i)
							end
						end
					elseif (Check_TargetInRange()) then
						DEFAULT_CHAT_FRAME:AddMessage("|CFFB700B7L|CFFFF00FFo|CFFFF50FFc|CFFFF99FFk|CFFFFC4FFP|cffffffffort|r : <" .. name .. "> has been summoned already (|cffff0000in range|r)")
						-- Remove the already summoned target
						for i, v in ipairs (LockPortDB) do
							if v == name then
						    	SendAddonMessage(MSG_PREFIX_REMOVE, name, "RAID")
						    	table.remove(LockPortDB, i)
						    	LockPort_UpdateList()
						    end
						end
					else
						-- TODO: Detect if spell is aborted/cancelled : use SpellStopCasting if sit ("You must be standing to do that")
						CastSpellByName("Ritual of Summoning")

						-- Send Raid Message
						if LockPortOptions.zone then
							if GetSubZoneText() == "" then
						    	message         = message .. zone_message
						    	whisper_message = base_whisper_message .. zone_message
							else
						    	message         = message .. zone_message .. subzone_message
						    	whisper_message = whisper_message .. zone_message .. subzone_message
							end
						end
						if LockPortOptions.shards then
					    	message = message .. shards_message
						end
						SendChatMessage(message, "SAY")

						-- Send Whisper Message
						if LockPortOptions.whisper then
							SendChatMessage(whisper_message, "WHISPER", nil, name)
						end

						-- Remove the summoned target
						for i, v in ipairs (LockPortDB) do
							if v == name then
						    	SendAddonMessage(MSG_PREFIX_REMOVE, name, "RAID")
						    	table.remove(LockPortDB, i)
						    	LockPort_UpdateList()
						    end
						end
					end
				else
					DEFAULT_CHAT_FRAME:AddMessage("|CFFB700B7L|CFFFF00FFo|CFFFF50FFc|CFFFF99FFk|CFFFFC4FFP|cffffffffort|r : Player is in combat")
				end
			else
				DEFAULT_CHAT_FRAME:AddMessage("|CFFB700B7L|CFFFF00FFo|CFFFF50FFc|CFFFF99FFk|CFFFFC4FFP|cffffffffort|r : <" .. tostring(name) .. "> not found in raid. UnitID: " .. tostring(UnitID))
				SendAddonMessage(MSG_PREFIX_REMOVE, name, "RAID")
				LockPort_UpdateList()
			end
		else
			DEFAULT_CHAT_FRAME:AddMessage("|CFFB700B7L|CFFFF00FFo|CFFFF50FFc|CFFFF99FFk|CFFFFC4FFP|cffffffffort|r : no raid found")
		end
	elseif button == "RightButton" then
		for i, v in ipairs (LockPortDB) do
			if v == name then
				SendAddonMessage(MSG_PREFIX_REMOVE, name, "RAID")
				table.remove(LockPortDB, i)
				LockPort_UpdateList()
			end
		end
	end
	LockPort_UpdateList()
end

function LockPort_UpdateList()
	LockPort_BrowseDB = {}
	--only Update and show if Player is Warlock
	 if (UnitClass("player") == "Warlock") then
		--get raid member data
		local raidnum = GetNumRaidMembers()
		if (raidnum > 0) then
			for raidmember = 1, raidnum do
				local rName, rRank, rSubgroup, rLevel, rClass = GetRaidRosterInfo(raidmember)
				--check raid data for LockPort data
				for i, v in ipairs (LockPortDB) do 
					--if player is found fill BrowseDB
					if v == rName then
						LockPort_BrowseDB[i] = {}
						LockPort_BrowseDB[i].rName = rName
						LockPort_BrowseDB[i].rClass = rClass
						LockPort_BrowseDB[i].rIndex = i
						if rClass == "Warlock" or rName == "Bennylava" then
							LockPort_BrowseDB[i].rVIP = true
						else
							LockPort_BrowseDB[i].rVIP = false
						end
					end
				end
			end

			--sort warlocks first
			table.sort(LockPort_BrowseDB, function(a,b) return tostring(a.rVIP) > tostring(b.rVIP) end)
		end
		
		for i=1,10 do
			if LockPort_BrowseDB[i] then
				getglobal("LockPort_NameList"..i.."TextName"):SetText(LockPort_BrowseDB[i].rName)
				
				--set class color
				if LockPort_BrowseDB[i].rClass == "Druid" then
					local c = LockPort_GetClassColour("DRUID")
					getglobal("LockPort_NameList"..i.."TextName"):SetTextColor(c.r, c.g, c.b, 1)
				elseif LockPort_BrowseDB[i].rClass == "Hunter" then
					local c = LockPort_GetClassColour("HUNTER")
					getglobal("LockPort_NameList"..i.."TextName"):SetTextColor(c.r, c.g, c.b, 1)
				elseif LockPort_BrowseDB[i].rClass == "Mage" then
					local c = LockPort_GetClassColour("MAGE")
					getglobal("LockPort_NameList"..i.."TextName"):SetTextColor(c.r, c.g, c.b, 1)
				elseif LockPort_BrowseDB[i].rClass == "Paladin" then
					local c = LockPort_GetClassColour("PALADIN")
					getglobal("LockPort_NameList"..i.."TextName"):SetTextColor(c.r, c.g, c.b, 1)
				elseif LockPort_BrowseDB[i].rClass == "Priest" then
					local c = LockPort_GetClassColour("PRIEST")
					getglobal("LockPort_NameList"..i.."TextName"):SetTextColor(c.r, c.g, c.b, 1)
				elseif LockPort_BrowseDB[i].rClass == "Rogue" then
					local c = LockPort_GetClassColour("ROGUE")
					getglobal("LockPort_NameList"..i.."TextName"):SetTextColor(c.r, c.g, c.b, 1)
				elseif LockPort_BrowseDB[i].rClass == "Shaman" then
					local c = LockPort_GetClassColour("SHAMAN")
					getglobal("LockPort_NameList"..i.."TextName"):SetTextColor(c.r, c.g, c.b, 1)
				elseif LockPort_BrowseDB[i].rClass == "Warlock" then
					local c = LockPort_GetClassColour("WARLOCK")
					getglobal("LockPort_NameList"..i.."TextName"):SetTextColor(c.r, c.g, c.b, 1)
				elseif LockPort_BrowseDB[i].rClass == "Warrior" then
					local c = LockPort_GetClassColour("WARRIOR")
					getglobal("LockPort_NameList"..i.."TextName"):SetTextColor(c.r, c.g, c.b, 1)
				end				
				
				getglobal("LockPort_NameList"..i):Show()
			else
				getglobal("LockPort_NameList"..i):Hide()
			end
		end
		
		if not LockPortDB[1] then
			if LockPort_RequestFrame:IsVisible() then
				LockPort_RequestFrame:Hide()
			end
		else
			ShowUIPanel(LockPort_RequestFrame, 1)
		end
	end	
end

--Slash Handler
function LockPort_SlashCommand(msg)
	if msg == "help" then
		DEFAULT_CHAT_FRAME:AddMessage("|CFFB700B7L|CFFFF00FFo|CFFFF50FFc|CFFFF99FFk|CFFFFC4FFP|cffffffffort|r usage:")
		DEFAULT_CHAT_FRAME:AddMessage("/lockport { help | show | zone | whisper | shards | settings | sound }")
		DEFAULT_CHAT_FRAME:AddMessage(" - |cff9482c9help|r: prints out this help")
		DEFAULT_CHAT_FRAME:AddMessage(" - |cff9482c9show|r: shows the current summon list")
		DEFAULT_CHAT_FRAME:AddMessage(" - |cff9482c9zone|r: toggles zoneinfo")
		DEFAULT_CHAT_FRAME:AddMessage(" - |cff9482c9whisper|r: toggles the usage of /w")
		DEFAULT_CHAT_FRAME:AddMessage(" - |cff9482c9shards|r: toggles shards count when you summon")
		DEFAULT_CHAT_FRAME:AddMessage(" - |cff9482c9settings|r: shows the settings window")
		DEFAULT_CHAT_FRAME:AddMessage(" - |cff9482c9sound|r: toggles sound on summon request")
		DEFAULT_CHAT_FRAME:AddMessage("To drag the frame use left mouse button")
	elseif msg == "show" then
		for i, v in ipairs(LockPortDB) do
			DEFAULT_CHAT_FRAME:AddMessage(tostring(v))
		end
	elseif msg == "zone" then
		if LockPortOptions["zone"] == true then
			LockPortOptions["zone"] = false
			ZoneCheckButton:SetChecked(false)
			DEFAULT_CHAT_FRAME:AddMessage("|CFFB700B7L|CFFFF00FFo|CFFFF50FFc|CFFFF99FFk|CFFFFC4FFP|cffffffffort|r - zoneinfo: |cffff0000disabled|r")
		elseif LockPortOptions["zone"] == false then
			LockPortOptions["zone"] = true
			ZoneCheckButton:SetChecked(true)
			DEFAULT_CHAT_FRAME:AddMessage("|CFFB700B7L|CFFFF00FFo|CFFFF50FFc|CFFFF99FFk|CFFFFC4FFP|cffffffffort|r - zoneinfo: |cff00ff00enabled|r")
		end
	elseif msg == "whisper" then
		if LockPortOptions["whisper"] == true then
			LockPortOptions["whisper"] = false
			WhisperCheckButton:SetChecked(false)
			DEFAULT_CHAT_FRAME:AddMessage("|CFFB700B7L|CFFFF00FFo|CFFFF50FFc|CFFFF99FFk|CFFFFC4FFP|cffffffffort|r - whisper: |cffff0000disabled|r")
		elseif LockPortOptions["whisper"] == false then
			LockPortOptions["whisper"] = true
			WhisperCheckButton:SetChecked(true)
			DEFAULT_CHAT_FRAME:AddMessage("|CFFB700B7L|CFFFF00FFo|CFFFF50FFc|CFFFF99FFk|CFFFFC4FFP|cffffffffort|r - whisper: |cff00ff00enabled|r")
		end
	 elseif msg == "shards" then
		if LockPortOptions["shards"] == true then
	       LockPortOptions["shards"] = false
		   ShardsCheckButton:SetChecked(false)
	       DEFAULT_CHAT_FRAME:AddMessage("|CFFB700B7L|CFFFF00FFo|CFFFF50FFc|CFFFF99FFk|CFFFFC4FFP|cffffffffort|r - shards: |cffff0000disabled|r")
		elseif LockPortOptions["shards"] == false then
	       LockPortOptions["shards"] = true
		   ShardsCheckButton:SetChecked(true)
	       DEFAULT_CHAT_FRAME:AddMessage("|CFFB700B7L|CFFFF00FFo|CFFFF50FFc|CFFFF99FFk|CFFFFC4FFP|cffffffffort|r - shards: |cff00ff00enabled|r")
		end
	 elseif msg == "sound" then
		if LockPortOptions["sound"] == true then
	       LockPortOptions["sound"] = false
		   SoundCheckButton:SetChecked(false)
	       DEFAULT_CHAT_FRAME:AddMessage("|CFFB700B7L|CFFFF00FFo|CFFFF50FFc|CFFFF99FFk|CFFFFC4FFP|cffffffffort|r - sound: |cffff0000disabled|r")
		elseif LockPortOptions["sound"] == false then
	       LockPortOptions["sound"] = true
		   SoundCheckButton:SetChecked(true)
	       DEFAULT_CHAT_FRAME:AddMessage("|CFFB700B7L|CFFFF00FFo|CFFFF50FFc|CFFFF99FFk|CFFFFC4FFP|cffffffffort|r - sound: |cff00ff00enabled|r")
		end
		elseif msg == "settings" then
		if LockPort_SettingsFrame:IsVisible() then
			LockPort_SettingsFrame:Hide()
		else
			LockPort_SettingsFrame:Show()
		end
	else
		if LockPort_RequestFrame:IsVisible() then
			LockPort_RequestFrame:Hide()
		else
			LockPort_UpdateList()
			ShowUIPanel(LockPort_RequestFrame, 1)
		end
	end
end

--class color
function LockPort_GetClassColour(class)
	if (class) then
		local color = RAID_CLASS_COLORS[class]
		if (color) then
			return color
		end
	end
	return {r = 0.5, g = 0.5, b = 1}
end

--raid member
function LockPort_GetRaidMembers()
    local raidnum = GetNumRaidMembers()
    if (raidnum > 0) then
		LockPort_UnitIDDB = {}
		for i = 1, raidnum do
		    local rName, rRank, rSubgroup, rLevel, rClass = GetRaidRosterInfo(i)
			LockPort_UnitIDDB[i] = {}
			if (not rName) then 
			    rName = "unknown"..i
			end
			LockPort_UnitIDDB[i].rName    = rName
			LockPort_UnitIDDB[i].rClass   = rClass
			LockPort_UnitIDDB[i].rIndex   = i
	    end
	end
end

-- FindItem function from SuperMacro to get the total number of Soul Shards
function FindItem(item)
	if (not item) then return end
	item = string.lower(ItemLinkToName(item))
	local link
	for i = 1,23 do
       link = GetInventoryItemLink("player",i)
       if (link) then
           if (item == string.lower(ItemLinkToName(link))) then
                return i, nil, GetInventoryItemTexture('player', i), GetInventoryItemCount('player', i)
           end
       end
	end
	local count, bag, slot, texture
	local totalcount = 0
	for i = 0,NUM_BAG_FRAMES do
       for j = 1,MAX_CONTAINER_ITEMS do
           link = GetContainerItemLink(i,j)
           if (link) then
               if (item == string.lower(ItemLinkToName(link))) then
	               bag, slot = i, j
	               texture, count = GetContainerItemInfo(i,j)
	               totalcount = totalcount + count
               end
           end
       end
	end
	return bag, slot, texture, totalcount
end

function ItemLinkToName(link)
	if ( link ) then
   	return gsub(link,"^.*%[(.*)%].*$","%1");
	end
end

-- Checks if the target is in range (28 yards)
function Check_TargetInRange()
   if not (GetUnitName("target")==nil) then
       local t = UnitName("target")
       if (CheckInteractDistance("target", 4)) then
           return true
       else
           return false
       end
   end
end

-- Settings Window
function LockPort_Settings_Toggle()
	if LockPort_SettingsFrame:IsVisible() then
		LockPort_SettingsFrame:Hide()
	else
		LockPort_SettingsFrame:Show()
	end
end

function WhisperCheckButton_OnClick()
	if WhisperCheckButton:GetChecked() then
		LockPortOptions["whisper"] = true
		DEFAULT_CHAT_FRAME:AddMessage("|CFFB700B7L|CFFFF00FFo|CFFFF50FFc|CFFFF99FFk|CFFFFC4FFP|cffffffffort|r - whisper: |cff00ff00enabled|r")
	elseif not WhisperCheckButton:GetChecked() then
		LockPortOptions["whisper"] = false
	    DEFAULT_CHAT_FRAME:AddMessage("|CFFB700B7L|CFFFF00FFo|CFFFF50FFc|CFFFF99FFk|CFFFFC4FFP|cffffffffort|r - whisper: |cffff0000disabled|r")
	end
end

function ZoneCheckButton_OnClick()
	if ZoneCheckButton:GetChecked() then
		LockPortOptions["zone"] = true
		DEFAULT_CHAT_FRAME:AddMessage("|CFFB700B7L|CFFFF00FFo|CFFFF50FFc|CFFFF99FFk|CFFFFC4FFP|cffffffffort|r - zoneinfo: |cff00ff00enabled|r")
	elseif not ZoneCheckButton:GetChecked() then
		LockPortOptions["zone"] = false
		DEFAULT_CHAT_FRAME:AddMessage("|CFFB700B7L|CFFFF00FFo|CFFFF50FFc|CFFFF99FFk|CFFFFC4FFP|cffffffffort|r - zoneinfo: |cffff0000disabled|r")
	end
end

function ShardsCheckButton_OnClick()
	if ShardsCheckButton:GetChecked() then
		LockPortOptions["shards"] = true
		DEFAULT_CHAT_FRAME:AddMessage("|CFFB700B7L|CFFFF00FFo|CFFFF50FFc|CFFFF99FFk|CFFFFC4FFP|cffffffffort|r - shards: |cff00ff00enabled|r")
	elseif not ShardsCheckButton:GetChecked() then
		LockPortOptions["shards"] = false
	    DEFAULT_CHAT_FRAME:AddMessage("|CFFB700B7L|CFFFF00FFo|CFFFF50FFc|CFFFF99FFk|CFFFFC4FFP|cffffffffort|r - shards: |cffff0000disabled|r")
	end
end

function SoundCheckButton_OnClick()
	if SoundCheckButton:GetChecked() then
		LockPortOptions["sound"] = true
		DEFAULT_CHAT_FRAME:AddMessage("|CFFB700B7L|CFFFF00FFo|CFFFF50FFc|CFFFF99FFk|CFFFFC4FFP|cffffffffort|r - sound: |cff00ff00enabled|r")
	elseif not SoundCheckButton:GetChecked() then
		LockPortOptions["sound"] = false
	    DEFAULT_CHAT_FRAME:AddMessage("|CFFB700B7L|CFFFF00FFo|CFFFF50FFc|CFFFF99FFk|CFFFFC4FFP|cffffffffort|r - sound: |cffff0000disabled|r")
	end
end

--pfUI.api.strsplit
function hcstrsplit(delimiter, subject)
  if not subject then return nil end
  local delimiter, fields = delimiter or ":", {}
  local pattern = string.format("([^%s]+)", delimiter)
  string.gsub(subject, pattern, function(c) fields[table.getn(fields)+1] = c end)
  return unpack(fields)
end

--Update announcing code taken from pfUI
local major, minor, fix = hcstrsplit(".", tostring(GetAddOnMetadata("LockPort", "Version")))

local alreadyshown = false
local localversion  = tonumber(major*10000 + minor*100 + fix)
local remoteversion = tonumber(lpupdateavailable) or 0
local loginchannels = { "BATTLEGROUND", "RAID", "GUILD", "PARTY" }
local groupchannels = { "BATTLEGROUND", "RAID", "PARTY" }
  
lpupdater = CreateFrame("Frame")
lpupdater:RegisterEvent("CHAT_MSG_ADDON")
lpupdater:RegisterEvent("PLAYER_ENTERING_WORLD")
lpupdater:RegisterEvent("PARTY_MEMBERS_CHANGED")
lpupdater:SetScript("OnEvent", function()
	if event == "CHAT_MSG_ADDON" and arg1 == "lp" then
		local v, remoteversion = hcstrsplit(":", arg2)
		local remoteversion = tonumber(remoteversion)
		if v == "VERSION" and remoteversion then
			if remoteversion > localversion then
				lpupdateavailable = remoteversion
				if not alreadyshown then
					DEFAULT_CHAT_FRAME:AddMessage("|CFFB700B7L|CFFFF00FFo|CFFFF50FFc|CFFFF99FFk|CFFFFC4FFP|cffffffffort|r New version available! https://github.com/Gurky-Turtle/LockPort")
					alreadyshown = true
				end
			end
		end
		--This is a little check that I can use to see if people are actually using the addon.
		if v == "PING?" then
			for _, chan in pairs(loginchannels) do
				SendAddonMessage("lp", "PONG!:"..GetAddOnMetadata("LockPort", "Version"), chan)
			end
		end
		if v == "PONG!" then
			--print(arg1 .." "..arg2.." "..arg3.." "..arg4)
		end
	end

	if event == "PARTY_MEMBERS_CHANGED" then
		local groupsize = GetNumRaidMembers() > 0 and GetNumRaidMembers() or GetNumPartyMembers() > 0 and GetNumPartyMembers() or 0
		if ( this.group or 0 ) < groupsize then
			for _, chan in pairs(groupchannels) do
				SendAddonMessage("lp", "VERSION:" .. localversion, chan)
			end
		end
		this.group = groupsize
	end

    if event == "PLAYER_ENTERING_WORLD" then
      if not alreadyshown and localversion < remoteversion then
        DEFAULT_CHAT_FRAME:AddMessage("|CFFB700B7L|CFFFF00FFo|CFFFF50FFc|CFFFF99FFk|CFFFFC4FFP|cffffffffort|r New version available! https://github.com/Gurky-Turtle/LockPort")
        lpupdateavailable = localversion
        alreadyshown = true
      end

      for _, chan in pairs(loginchannels) do
        SendAddonMessage("lp", "VERSION:" .. localversion, chan)
      end
    end
  end)