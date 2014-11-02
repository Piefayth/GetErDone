GetErDone = LibStub("AceAddon-3.0"):NewAddon("GetErDone", "AceEvent-3.0", "AceConsole-3.0")

local AceConfig = LibStub("AceConfig-3.0")
local AceConfigDialog = LibStub("AceConfigDialog-3.0")
local AceDB = LibStub("AceDB-3.0")
local AceDBOptions = LibStub("AceDBOptions-3.0")
local AceGUI = LibStub("AceGUI-3.0")
local widgetManager = {}

local events = 	{
	["monster"] = {
		{
			["event"] = "LOOT_OPENED", ["callback"] = "HandleEventMonster"
		}, 
		{
			["event"] = "OTHER_EVENT", ["callback"] = "HandleEventMonster"
		}, 
	},
	["quest"] = {
		{
			["event"] = "QUEST_TURNED_IN", ["callback"] = "HandleEventQuest"
		},
	}
}

options = {
	name = "Get Er Done",
	type = 'group',
	args = {
		general = {
			order = 1,
			type = "group",
			name = "General Settings",
			cmdInline = true,
			args = {
					trackableID = {
						order = 1,
						type = "input",
						name = "New ID",
						desc = "Add a new trackable monster, quest, or item ID",
						pattern = "(%d+)",
						set = function(k,v)
							GetErDone:ApplyOption(k,v)
						end,
						get = function(k,v)
							return GetErDone:GetOption("trackableID")
						end
					},
					typechoice = {
						order = 2,
						type = "select",
						name = "ID Type",
						desc = "What category fits this ID?",
						values = {["monster"] = "Monster", ["quest"] = "Quest", ["item"] = "Item"},
						set = function(k,v)
							GetErDone:ApplyOption(k,v)
						end,
						get = function(k,v)
							return GetErDone:GetOption("typechoice")
						end,
					},
					submitID = {
						order = 3,
						type = "execute",
						name = "Add ID",
						desc = "",
						func = function(k,v)
							GetErDone:AddTrackable(GetErDone:GetOption("trackableID"), GetErDone:GetOption("typechoice"), "some gay monster", GetErDone:GetOption("optCompound"))
						end
					},
					separator = {
						order = 4,
						type = "description",
						name = "",
					},
					frequency = {
						order = 5,
						type = "select",
						name = "Frequency",
						desc = "How often should this item reset?",
						style = "dropdown",
						values = {["daily"] = "Daily", ["weekly"] = "Weekly", ["once"] = "Once", ["monthly"] = "Monthly"},
						set = function(k,v)
							GetErDone:ApplyOption(k,v)
						end,
						get = function()
							return GetErDone:GetOption("frequency")
						end
					},
					character = {
						order = 6,
						type = "select",
						name = "Character",
						desc = "Which character is this task for? Your character will not appear in this list until you've logged in with it.",
						style = "dropdown",
						values = function()
							t = {["All"] = "All"}
							for k, v in pairs(GetErDone:GetOption("characters")) do
								t[k] = v
							end
							return t
						end,
						set = function(k,v)
							GetErDone:ApplyOption(k,v)
						end,
						get = function()
							return GetErDone:GetOption("character")
						end
					},
					quantity = {
						order = 7,
						type = "input",
						name = "Quantity",
						desc = "How many monsters/items/quests to count as complete?",
						pattern = "(%d+)",
						set = function(k,v)
							GetErDone:ApplyOption(k,v)
						end,
						get = function()
							return GetErDone:GetOption("quantity")
						end
					},
					separator2 = {
						order = 8,
						type = "description",
						name = "",
					},
					optCompound = {
						order = 9,
						type = "select",
						name = "Objective Group",
						desc = "",
						values = function()
							t = {["None"] = "None"}
							for k, v in pairs(GetErDone:GetOption("compounds")) do
								--print(k..v)
								t[k] = v.name
							end
							return t
						end,
						set = function(k,v)
							GetErDone:ApplyOption(k,v)
						end,
						get = function()
							return GetErDone:GetOption("optCompound")
						end,
					},
					newCompoundName = {
						order = 10,
						type = "input",
						name = "New Objective Group",
						set = function(k,v)
							GetErDone:ApplyOption(k,v)
						end,
						get = function()
							return GetErDone:GetOption("newCompoundName")
						end
					},
					submitGroup = {
						order = 11,
						type = "execute",
						name = "Add Group",
						desc = "",
						func = function(k,v)
							--CALL FUNCTION TO CREATE NEW COMPOUND HERE--
						end
					},
					separator2 = {
						order = 89,
						type = "description",
						name = "",
					},
					test = {
						order = 90,
						type = "toggle",
						name = "test",
						desc = "",
						set = function() GetErDone:addThing() end,
						get = function() return end,
					},
					reset = {
						order = 91,
						type = "toggle",
						name = "reset",
						desc = "",
						set = function() 
							for k in pairs (GetErDone.db.global) do
    							GetErDone.db.global[k] = nil
							end
							GetErDone:OnEnable()
						end,
						get = function() return end,
					},
					testeventkill = {
						order = 92,
						type = "toggle",
						name = "testeventkill",
						desc = "",
						set = function() GetErDone:testeventkill() end,
						get = function() end,
					},
					testeventkill1 = {
						order = 93,
						type = "toggle",
						name = "testeventkill1",
						desc = "",
						set = function() GetErDone:testeventkill_one() end,
						get = function() end,
					},
					testui = {
						order = 94,
						type = "toggle",
						name = "testui",
						desc = "",
						set = function() GetErDone:testui() end,
						get = function() end,
					},
					test_reset = {
						order = 95, 
						type = "execute",
						name = "test_reset",
						desc = "",
						func = function() GetErDone:test_reset() end,
					},
					test_increment = {
						order = 96,
						type = "execute",
						name = "test_increment",
						desc = "",
						func = function() GetErDone:test_increment() end,
					},
					test_completion = {
						order = 97,
						type = "execute",
						name = "test_completion",
						desc = "",
						func = function() GetErDone:test_completion() end,
					},
				},
			},
		},
	}


MONSTER = "monster"
QUEST = "quest"
ITEM = "item"
CUSTOM_PREFIX = "c_"
COMPOUND_LEVEL_BOTTOM = 0
COMPOUND_LEVEL_MID = 1
COMPOUND_LEVEL_TOP = 2
COMPLETE_INCREMENT = 0
COMPLETE_ZERO = 1
RESET_DAILY = "daily"
RESET_WEEKLY = "weekly"
RESET_MONTHLY = "monthly"
REGION_US = 1
REGION_KR = 2
REGION_EU = 3
REGION_TW = 4
REGION_CN = 5
COMPLETION_CACHE_ALL_CHARACTERS = 1
local debugMode = true



--ApplyOption is for option retention between sessions. If you click "Daily" then reloadui, it retains that selection--
--The default behavior makes dropdowns always blank, which is annoying--
function GetErDone:ApplyOption(k,v)
	self.db.global.options[k[2]] = v
end


function GetErDone:GetOption(v)
	local option = nil
	if v == "characters" then 
		option = self.db.global[v]
	elseif v == "compounds" then
		option = self.db.global.compounds
	else
		option = self.db.global.options[v]
	end
	if option == nil then 
		error("GetOption: unable to find option") 
	end
	return option
end

function GetErDone:getCharactersFromOptions()
	local chars = self.db.global.options.character
	if chars == "All" then
		return self:prepareNames(self.db.global.characters)
	end
	return { chars }
end

function GetErDone:addCompound()
	if self.db.global.options.newCompoundName == "" or self.db.global.options.newCompoundName == nil then return false end

	local compound = {
		["name"] = self.db.global.options.newCompoundName,
		["active"] = true,
		["comprisedOf"] = {},
		["ownedBy"] = self.db.global.options.optCompound,
		["displayChildren"] = self.db.global.options.compoundchildren,
		["childCompletionQuantity"] = tonumber(self.db.global.options.compoundquantity)
	}

	self.db.global.options.compoundquantity = ""
	self.db.global.options.newCompoundName = ""
	compound_id = self.db.global.options.compoundId or GetErDone:generateNextCompoundId()
	self.db.global.compounds[compound_id] = compound

	return true
end

function GetErDone:isCompoundId(id)
	if type(id) == "string" then
		return string.byte(id) == string.byte(CUSTOM_PREFIX)
	end
	return false
end

function GetErDone:generateNextCompoundId()
	local id = self.db.global.options.nextCompoundId + 1
	self.db.global.options.nextCompoundId = id
	return CUSTOM_PREFIX .. id
end

function GetErDone:LoadTrackableName(id, type)
	local trackables = self.db.global.trackables
	if trackables[id] ~= nil then
		if trackables[id][type] ~= nil then
			return trackables[id][type].name
		end
	end
	for k, v in pairs(trackableDb) do
		if trackableDb[id] ~= nil then
			if trackableDb[id][type] ~= nil then
				return trackableDb[id][type]
			end
		end
	end
	return type .. " not found in database."
end

function GetErDone:AddTrackable(id, type, name, owner, frequency, characters, quantity)
	if id == 0 or id == "" then error("AddTrackable: null or empty id") end

	self:ensureTrackable(id)
	if self.db.global.trackables[id][type] == nil then
		self.db.global.trackables[id][type] = {
			["name"] = name,
			["ownedBy"] = owner,
			["frequency"] = frequency,
			["reset"] = self:NextReset(frequency, self.db.global.region),
			["characters"] = characters,
			["completionQuantity"] = tonumber(quantity)
    	}
    else
    	self.db.global.trackables[id][type].ownedBy = owner
    end

    self:updateOwner(owner, id, type)

    self:refreshTrackableList()


    --Zero Out Options Fields--
	self.db.global.options.quantity = ""
	self.db.global.options.trackableID = ""
	widgetManager["trackableID"]:SetText("")
	widgetManager["trackableQuantity"]:SetText("")
end

function GetErDone:updateOwner(ownerId, childId, childType)
	if ownerId == nil or ownerId == "" then return end
	local owner = self.db.global.compounds[ownerId]
	if owner == nil then error("updateOwner: ownerId points to null compound") end
	if childType == nil then
		if not self:contains(owner.comprisedOf, childId) then
			table.insert(owner.comprisedOf, childId)
		end
	else
		local idtype = {childId, childType}
		if not self:contains(owner.comprisedOf, idtype) then
			table.insert(owner.comprisedOf, idtype)
		end
	end
end

function GetErDone:updateChild(compound_id, child_id, child_type)
	if child_type == nil then -- compound
		if self:IsNullOrEmpty(self.db.global.compounds[child_id]) then error("updateChild: null child") end
		self.db.global.compounds[child_id].ownedBy = compound_id
	else
		if self:IsNullOrEmpty(self.db.global.trackables[id]) or self:IsNullOrEmpty(self.db.global.trackables[id][type]) then
			self:AddTrackable(child_id, child_type, self:LoadTrackableName(child_id, child_type), compound_id, "", "All", 1)
		end
	end
end

function GetErDone:prepareNames(names)
	local newNames = {}
	for k, v in pairs(names) do
		table.insert(newNames, k)
	end
	return newNames
end

function GetErDone:ensureTrackable(id)
	if self.db.global.trackables[id] == nil then self.db.global.trackables[id] = {} end
end

function GetErDone:OnInitialize()
	AceConfig:RegisterOptionsTable("GetErDone", options, {"ged", "geterdone"}) --TODO: Make these slash commands just open the menu
	self.db = LibStub("AceDB-3.0"):New("GetErDoneDb")


	
	self.optionsFrames = {}
	self.optionsFrames.general = AceConfigDialog:AddToBlizOptions("GetErDone", nil, nil, "general")



	--self.optionsFrames.general.obj.frame:AddChild(btn)
	self.optionsFrames.general.obj.frame:SetScale(1)
	self:debug(self.optionsFrames.general.obj.frame:GetRegions()[0])
	for k,v in pairs(self.optionsFrames.general.obj.frame:GetRegions()) do
		self:debug(k, v)
	end
	


	--Event Registry--
	self:RegisterEvent("PLAYER_ENTERING_WORLD", "OnLogin") --Note the syntax, second parameter is a function name as a string

end

function GetErDone:OnEnable()
	---First Time Setup l---
	if self.db.global.trackables == nil then self.db.global.trackables = {} end
	if self.db.global.characters == nil then self.db.global.characters = {} end
	if self.db.global.compounds == nil then self.db.global.compounds = {} end
	if self.db.global.options == nil then self.db.global.options = {} end
	if self.db.global.options.quantity == nil then self.db.global.options.quantity = 1 end
	if self.db.global.options.frequency == nil then self.db.global.options.frequency = "" end
	if self.db.global.options.nextCompoundId == nil then self.db.global.options.nextCompoundId = 1 end
	if self.db.global.options.newCompoundName == nil then self.db.global.options.newCompoundName = "" end
	if self.db.global.region == nil then self.db.global.region = GetCurrentRegion() end
	if self.db.global.completionCache == nil then self.db.global.completionCache = {} end



	name, server = UnitFullName("player")
	if self.db.global.characters[name..server] == nil then 
		self.db.global.characters[name..server] = name .. " - " .. server
	end
	self.db.global.character = name .. server

	self:registerHandlers()
	--self:LoadDefaults()
	self:UpdateResets()
end

function GetErDone:LoadDefaults()
	if self.db.global.defaultsLoaded == nil then
		for id, type in pairs(defaults.trackables) do
			local trackable = defaults[type]
			self:AddTrackable(id, type, self:LoadTrackableName(id, type), nil, trackable.frequency, "All", trackable.quantity)
		end
		for compound_id, compound in pairs(defaults.compounds) do
			self.db.global.options.newCompoundName = compound.name
			self.db.global.options.optCompound = compound.ownedBy
			self.db.global.options.compoundchildren = compound.displayChildren
			self.db.global.options.compoundquantity = compound.childCompletionQuantity
			self.db.global.options.compoundId = compound_id
			self:addCompound()
			self.db.global.compounds[compound_id].comprisedOf = compound.comprisedOf
		end
	self.db.global.defaultsloaded = "loaded"
	end
end
			

-- EVENT HANDLING -- 

function GetErDone:registerHandlers()
	for type, eventObj in pairs(events) do
		for k, eventy in pairs(eventObj) do
			self:RegisterEvent(eventy.event, eventy.callback, eventy.event)
		end
	end
end

function GetErDone:HandleEventMonster(event) 
	if event == "LOOT_OPENED" then
		local numChecked = 0
		local numItems = GetNumLootItems()
		for slotId = 1, numItems, 1 do
			-- TODO deal with duplicate items ie multiple drops from the same mob
			mobList = { GetLootSourceInfo(slotId) }
			for k, v in pairs(mobList) do
				if v and type(v) == "string" then
					self:debug("Checking mob id " .. v)
					self:CheckEvent(MONSTER, v)
				end
			end
		end
	end
end

function GetErDone:HandleEventQuest(event)
	print("butts")
end

function GetErDone:CheckEvent(type, guid)
	if type == MONSTER then
		local id = self:getNpcId(guid)
		if id == nil then return end

		if self.db.global.trackables[id] ~= nil and self.db.global.trackables[id][type] ~= nil then
			self:CompleteTrackable(id, type, COMPLETE_INCREMENT)
		end
	end
end

--------------------------------------------------------------------
-------------------------- TRACKING --------------------------------
--------------------------------------------------------------------

function GetErDone:CompleteTrackable(id, type, status)
	local trackable = self.db.global.trackables[id][type]
	if trackable == nil then
		error("CompleteTrackable: null trackable")
	end
	local character = self.db.global.character

	if status == COMPLETE_INCREMENT then
		if trackable.characters[character] < trackable.completionQuantity then
			trackable.characters[character] = trackable.characters[character] + 1
		end
		self:InvalidateCompletionCache(character)
	elseif status == COMPLETE_ZERO then
		for k, v in pairs(trackable.characters) do
			trackable.characters[k] = 0
		end 
		self:InvalidateCompletionCache(COMPLETION_CACHE_ALL_CHARACTERS)
	end	
end

function GetErDone:IsCompoundComplete(compound_id, character)
	local compound = self.db.global.compounds[compound_id]
	if not compound.active then return false end

	if self:IsCompletionCached(compound_id, character) then
		return self:GetCompletionCache(compound_id, character)
	end

	local completedCount = 0
	for k, child_id in pairs(compound.comprisedOf) do
		if self:isCompoundId(child_id) then
			if self:IsCompoundComplete(child_id, character) then
				completedCount = completedCount + 1
			end
		else
			if self:IsTrackableComplete(child_id.id, child_id.type, character) then
				completedCount = completedCount + 1
			end
		end

		if completedCount >= compound.childCompletionQuantity then
			self:AddToCompletionCache(compound_id, character, true)
			return true
		end
	end

	self:AddToCompletionCache(compound_id, character, false)
	return false
end

function GetErDone:IsTrackableComplete(id, type, character)
	local trackable = self.db.global.trackables[id][type]
	if not trackable.active then return false end
	if trackable.characters[character] == nil then return false end

	return trackable.characters[character] >= trackable.completionQuantity
end

--------------------------------------------------------------------
----------------------- TRACKING CACHE -----------------------------
--------------------------------------------------------------------

function GetErDone:IsCompletionCached(compound_id, character)
	if not self:IsNullOrEmpty(self.db.global.completionCache[character]) then
		return self.db.global.completionCache[character][compound_id] ~= nil
	end
	return false
end

function GetErDone:GetCompletionCache(compound_id, character)
	return self.db.global.completionCache[character][compound_id]
end

function GetErDone:AddToCompletionCache(compound_id, character, completed)
	if self:IsNullOrEmpty(self.db.global.completionCache[character]) then 
		self.db.global.completionCache[character] = {} 
	end
	self.db.global.completionCache[character][compound_id] = completed
end

function GetErDone:InvalidateCompletionCache(character)
	if character == COMPLETION_CACHE_ALL_CHARACTERS then
		self.db.global.completionCache = {}
	else
		self.db.global.completionCache[character] = {}
	end
end

--------------------------------------------------------------------
----------------------- TRACKABLE RESETS ---------------------------
--------------------------------------------------------------------

function GetErDone:UpdateResets()
	-- TODO null checking
	for id, types in pairs(self.db.global.trackables) do
		for type, trackable in pairs(types) do
			local newReset = self:NextReset(trackable.frequency, self.db.global.region)
			if not self:ResetEquals(newReset, trackable.reset) then
				self:debug("Updating reset and completion on trackable " .. id .. ":" .. type)
				trackable.reset = newReset
				self:CompleteTrackable(id, type, COMPLETE_ZERO)
			end
		end
	end
end

function GetErDone:ResetEquals(a, b)
	if a == nil or b == nil then
		error("ResetEquals: null reset")
	end

	if a.day ~= b.day then return false end
	if a.month ~= b.month then return false end
	if a.hour ~= b.hour then return false end
	if a.year ~= b.year then return false end
	return true
end

function GetErDone:NextReset(frequency, region)
  currentDate = date("!*t")
  --currentDate = {["wday"] = 4, ["day"] = 1, ["month"] = 11, ["year"] = 2014, ["hour"] = 12}
  monthdays = {31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31}
  if currentDate.year % 4 == 0 then monthdays[2] = 29 end

  resetDate = {["year"] = nil, ["day"] = nil, ["month"] = nil, ["hour"] = nil}

  regionDayMap = {[REGION_US] = {["day"] = 3, ["hour"] = 11},
  				  [REGION_EU] = {["day"] = 4, ["hour"] = 2},
  				  --["AU"] = {["day"] = 2, ["hour"] = 17}
  				}

  daysRemaining = 0
  regionalResetHour = regionDayMap[region].hour
  if frequency == RESET_WEEKLY then
  	regionalResetDay = regionDayMap[region].day
    if currentDate.wday > regionalResetDay then --If it's after the resetDate day
      daysRemaining = regionalResetDay + 7 - currentDate.wday
    elseif currentDate.wday < regionalResetDay then
      daysRemaining = regionalResetDay - currentDate.wday --If it's Sunday or Monday
    elseif currentDate.wday == regionalResetDay then -- If it's Tuesday
      if currentDate.hour < regionalResetHour then daysRemaining = 0 end
      if currentDate.hour >= regionalResetHour then daysRemaining = 7 end
    end
    resetDate = GetErDone:AddDays(resetDate, currentDate, daysRemaining)
  elseif frequency == RESET_DAILY then
    resetDate = GetErDone:AddDays(resetDate, currentDate, 1)
  elseif frequency == RESET_MONTHLY then
    daysRemaining = monthdays[currentDate.month] - currentDate.day + 1
    resetDate = GetErDone:AddDays(resetDate, currentDate, daysRemaining)
  elseif frequency == "once" then
  	-- TODO
  	return 0
  else
    error("nextReset: unsupported frequency: " .. frequency)
  end
  resetDate.hour = regionalResetHour
  return resetDate
end

function GetErDone:AddDays(resetDate, currentDate, days)
  monthdays = {31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31}
  DECEMBER = 12
  JANUARY = 1
  -- leap years
  if currentDate["year"] % 4 == 0 then monthdays[2] = 29 end

  -- if we need to go to next month
  if days + currentDate["day"] > monthdays[currentDate["month"]] then
    if currentDate["month"] == DECEMBER then 
      resetDate["day"] =  (currentDate["day"] + days) - monthdays[currentDate["month"]]
      resetDate["month"] = JANUARY
      resetDate["year"] = currentDate["year"] + 1
    else
      resetDate["day"] =  (currentDate["day"] + days) - monthdays[currentDate["month"]]
      resetDate["month"] = currentDate["month"] + 1
      resetDate["year"] = currentDate["year"]
    end
  else
    resetDate["day"] = currentDate["day"] + days
    resetDate["month"] = currentDate["month"]
    resetDate["year"] = currentDate["year"]
  end
  return resetDate
end

function GetErDone:OnDisable()
	self.db.global.options.optCompound = ""
end

---Event Handlers---

---OnLogin defaults the "character" dropdown to the character you're currently logged in as.
function GetErDone:OnLogin()
	name, server = UnitFullName("player")
	self.db.global.options.character = name..server
	self.db.global.character = name..server
end


--------------------------------------------------------------------
----------------------- UTIL METHODS -------------------------------
--------------------------------------------------------------------

function GetErDone:debug(message)
	if debugMode then
		print(message)
	end
end

function GetErDone:trim(s)
  return s:match'^%s*(.*%S)' or ''
end

function GetErDone:contains(dict, value)
	if dict == nil or value == nil then 
		error("contains: null table or value")
	end
	for k, v in pairs(dict) do
		if value == v then return true end
	end
	return false
end

function GetErDone:getNpcId(guid)
	if guid then
		local unit_type, _, _, _, _, mob_id = strsplit('-', guid)
		return mob_id
	end
	return 0
end

function GetErDone:GetCompoundLevel(compound_id)
	local compound = self.db.global.compounds[compound_id]
	if compound == nil then
		error("GetCompoundLevel: null compound reference")
	end

	if compound.ownedBy == nil or compound.ownedBy == "" then
		return COMPOUND_LEVEL_TOP
	end

	if self:isCompoundId(compound.ownedBy) then
		return COMPOUND_LEVEL_MID
	end

	return COMPOUND_LEVEL_BOTTOM
end

function GetErDone:IsNullOrEmpty(dict)
	return dict == nil or next(dict) == nil
end

---------------------------------UI CODE-------------------------------------------

function GetErDone:testui()
	local f = AceGUI:Create("Frame")
	local leftLabelgroup = {}

	self.db.global.options.optCompound = ""

	f:SetCallback("OnClose",function(widget) AceGUI:Release(widget) end)
	f:SetTitle("Options")
	f:SetLayout("Flow")
	f:SetHeight(600)

	----Scroll Groups Init---
	local groupsContainer = AceGUI:Create("InlineGroup")
	local trackablesContainer = AceGUI:Create("InlineGroup")

	groupsContainer:SetLayout("Fill")
	groupsContainer:SetRelativeWidth(0.5)
	groupsContainer:SetHeight(150)

	trackablesContainer:SetLayout("Fill")
	trackablesContainer:SetRelativeWidth(0.5)
	trackablesContainer:SetHeight(170)

	f:AddChild(groupsContainer)
	f:AddChild(trackablesContainer)
	
	

	local groupsScroll = AceGUI:Create("ScrollFrame")
	local trackablesScroll = AceGUI:Create("ScrollFrame")
	groupsScroll:SetLayout("List")
	trackablesScroll:SetLayout("List")
	groupsScroll:SetRelativeWidth(0.5)
	groupsContainer:AddChild(groupsScroll)
	trackablesContainer:AddChild(trackablesScroll)

	widgetManager = {
	["trackableFrame"] = trackablesScroll,
	["compoundFrame"] = groupsScroll
	}
	---Scroll Groups Data--
	self:refreshCompoundList()
	self:refreshTrackableList()

--- New Compound Interface --- 

	local newCompoundGroup = AceGUI:Create("InlineGroup")
	local compoundSelectionLabel = AceGUI:Create("Label")
	local editCompound = AceGUI:Create("EditBox")
	local compoundQuantity = AceGUI:Create("EditBox")
	local compoundChildrenToggle = AceGUI:Create("CheckBox")
	local buttonCompound = AceGUI:Create("Button")

	buttonCompound:SetText("Add Group")
	buttonCompound:SetCallback("OnClick", function(widget, event, text) 
		local success = self:addCompound() 
		if success then
			widgetManager["editCompound"]:SetText("")
			widgetManager["compoundQuantity"]:SetText("")

			self:refreshCompoundList()
		end
	end)

	compoundSelectionLabel:SetText("Current Group: " .. self.db.global.options.optCompound)
	editCompound:SetLabel("Group Name")
	editCompound:SetCallback("OnEnterPressed", function(widget, event, text) self:submitCompoundEdit(widget, event, text) end)

	compoundQuantity:SetLabel("Quantity - 0 for all children")
	compoundQuantity:SetCallback("OnEnterPressed", function(widget, event, text) self:getCompoundQuantity(widget, event, text) end)

	compoundChildrenToggle:SetLabel("Display Children")
	compoundChildrenToggle:SetValue(true)
	compoundChildrenToggle:SetCallback("OnValueChanged", function(widget, event, value) self:getCompoundChildrenToggle(widget, event, value) end)

	newCompoundGroup:SetRelativeWidth(0.5)
	newCompoundGroup:SetLayout("List")

--- New Trackable Interface ---

	local newTrackableGroup = AceGUI:Create("InlineGroup")
	local trackableName = AceGUI:Create("Label")
	local trackableID = AceGUI:Create("EditBox")
	local trackableType = AceGUI:Create("Dropdown")
	local trackableCharacter = AceGUI:Create("Dropdown")
	local trackableFrequency = AceGUI:Create("Dropdown")
	local addTrackableButton = AceGUI:Create("Button")
	local trackableQuantity = AceGUI:Create("EditBox")


	addTrackableButton:SetText("Add ID")
	addTrackableButton:SetCallback("OnClick", function(widget, event) self:AddTrackable(
		self.db.global.options.trackableID, 
		self.db.global.options.typechoice, 
		self:LoadTrackableName(self.db.global.options.trackableID, self.db.global.options.typechoice),
		self.db.global.options.optCompound,
		self.db.global.options.frequency,
		self:prepareCharacters( { self.db.global.options.character } ), -- TODO multiple name selection
		self.db.global.options.quantity,
		trackablesScroll) end)

	trackableName:SetText(" ")

	trackableID:SetCallback("OnEnterPressed", function(widget, event, text) 
		self:submitIDEdit(widget, event, text) 
	end)
	trackableID:SetLabel("ID")

	trackableType:SetList({["monster"] = "Monster", ["item"] = "Item", ["quest"] = "Quest"})
	trackableType:SetCallback("OnValueChanged", function(widget, event, key) 
		self:getTrackableTypeDropdown(widget, event, key) 
	end)
	trackableType:SetLabel("Type")

	trackableFrequency:SetList({["daily"] = "Daily", ["weekly"] = "Weekly", ["monthly"] = "Monthly", ["once"] = "Once"})
	trackableFrequency:SetCallback("OnValueChanged", function(widget, event, key) self:getTrackableFrequencyDropdown(widget, event, key) end)
	trackableFrequency:SetLabel("Frequency")

	trackableCharacter:SetList(self:getCharacters())
	trackableCharacter:SetCallback("OnValueChanged", function(widget, event, key) self:getTrackableCharacterDropdown(widget, event, key) end)
	trackableCharacter:SetLabel("Character")

	trackableQuantity:SetCallback("OnEnterPressed", function(widget, event, text) self:getTrackableQuantity(widget, event, text) end)
	trackableQuantity:SetLabel("Quantity")

	newTrackableGroup:SetRelativeWidth(0.5)
	newTrackableGroup:SetLayout("List")



	f:AddChild(newCompoundGroup)
	newCompoundGroup:AddChild(compoundSelectionLabel)
	newCompoundGroup:AddChild(editCompound) 
	newCompoundGroup:AddChild(compoundQuantity)
	newCompoundGroup:AddChild(compoundChildrenToggle) 
	newCompoundGroup:AddChild(buttonCompound)
	
	f:AddChild(newTrackableGroup)
	newTrackableGroup:AddChild(trackableName)
	newTrackableGroup:AddChild(trackableID)
	newTrackableGroup:AddChild(trackableType)
	newTrackableGroup:AddChild(trackableFrequency)
	newTrackableGroup:AddChild(trackableCharacter)
	newTrackableGroup:AddChild(trackableQuantity)
	newTrackableGroup:AddChild(addTrackableButton)
	
	widgetManager = {
	["trackableName"] = trackableName,
	["editCompound"] = editCompound, 
	["compoundQuantity"] = compoundQuantity, 
	["trackableID"] = trackableID, 
	["trackableQuantity"] = trackableQuantity,
	["trackableFrame"] = trackablesScroll,
	["compoundFrame"] = groupsScroll,
	["compoundSelectionLabel"] = compoundSelectionLabel,
	}

	f:DoLayout() --HOLY MOTHERFUCKING SHIT IS THIS LINE IMPORTANT

	
end

function GetErDone:prepareCharacters(characters)
	local chars = {}
	if characters["All"] ~= nil then
		for name, v in pairs(self.db.global.characters) do
			chars[name] = 0
		end
	else
		for k, name in pairs(characters) do
			chars[name] = 0
		end
	end
	return chars
end

function GetErDone:refreshTrackableList()
	widgetManager["trackableFrame"]:ReleaseChildren()
	for k, v in pairs(self:getTrackableChildren(self.db.global.options.optCompound)) do
		print(self.db.global.trackables[v[1]][v[2]].name)
		local label = AceGUI:Create("InteractiveLabel")
		label:SetText(self.db.global.trackables[v[1]][v[2]].name)
		label:SetHighlight(.5, .5, 0, .5)
		label:SetCallback("OnClick", function(widgetx) self:clickTrackableLabel(widgetx, {v[1], v[2]}) end)
		widgetManager["trackableFrame"]:AddChild(label)
	end
end

function GetErDone:refreshCompoundList()
	widgetManager["compoundFrame"]:ReleaseChildren()
	self:createCompoundTree("")
end

function GetErDone:createCompoundTree(compoundid)
	children = self:getCompoundChildren(compoundid)
	for k,v in pairs(children) do
		local label = AceGUI:Create("InteractiveLabel")
		label:SetText(self:getIndent(self:compoundNumParents(v)) .. " " .. v .. " - " .. self.db.global.compounds[v].name)
		label:SetHighlight(.5, .5, 0, .5)
		label:SetCallback("OnClick", function(widgetx) self:clickGroupLabel(widgetx, v, false) end)
		widgetManager["compoundFrame"]:AddChild(label)
		self:createCompoundTree(v)
	end
end

function GetErDone:clickGroupLabel(widget, compoundID, isUp)
	widgetManager["trackableFrame"]:ReleaseChildren()
	widgetManager["compoundFrame"]:ReleaseChildren()

	self.db.global.options.optCompound = compoundID
	self:refreshCompoundList()
	self.db.global.options.optCompound  = compoundID 

	widgetManager["compoundSelectionLabel"]:SetText("Current Group: " .. self.db.global.compounds[self.db.global.options.optCompound].name)
	self:refreshTrackableList()
end

function GetErDone:clickTrackableLabel(widget, trackableID)

end

function GetErDone:getCompoundChildrenToggle(widget, event, key)
	self.db.global.options["compoundchildren"] = key
	self:setCompoundChildrenToggle(widget)
end

function GetErDone:setCompoundChildrenToggle(widget)
	widget:SetValue(self.db.global.options["compoundchildren"])
end

function GetErDone:getCompoundQuantity(widget, event, text)
	self.db.global.options["compoundquantity"] = text
	self:setCompoundQuantity(widget)
end

function GetErDone:setCompoundQuantity(widget)
	widget:SetText(self.db.global.options["compoundquantity"])
end

function GetErDone:getTrackableTypeDropdown(widget, event, key)
	self.db.global.options.typechoice = key
	self:setTrackableTypeDropdown(widget)
end

function GetErDone:setTrackableTypeDropdown(widget)
	widget:SetValue(self.db.global.options.typechoice)
	widgetManager.trackableName:SetText(self:LoadTrackableName(self.db.global.options.trackableID, self.db.global.options.typechoice))
end

function GetErDone:getTrackableFrequencyDropdown(widget, event, key)
	self.db.global.options.frequency = key
	self:setTrackableFrequencyDropdown(widget)
end

function GetErDone:setTrackableFrequencyDropdown(widget)
	widget:SetValue(self.db.global.options.frequency)
end

function GetErDone:getTrackableCharacterDropdown(widget, event, key)
	self.db.global.options.character = key
	self:setTrackableCharacterDropdown(widget)
end

function GetErDone:setTrackableCharacterDropdown(widget)
	widget:SetValue(self.db.global.options.character)
end

function GetErDone:submitIDEdit(widget, event, text)
	if string.match(text, '%d') then
		self.db.global.options.trackableID = text
	end
	self:populateIDEdit(widget)
end


function GetErDone:populateIDEdit(widget)
	widget:SetText(self.db.global.options.trackableID)
	widgetManager.trackableName:SetText(self:LoadTrackableName(self.db.global.options.trackableID, self.db.global.options.typechoice))
end

function GetErDone:getTrackableQuantity(widget, event, text)
	if string.match(text, '%d') then
		self.db.global.options.quantity = text
	end
	self:setTrackableQuantity(widget)
end

function GetErDone:setTrackableQuantity(widget)
	widget:SetText(self.db.global.options.quantity)
end

function GetErDone:submitCompoundEdit(widget, event, text)
	self.db.global.options.newCompoundName = text
	self:populateCompoundEdit(widget)
end

function GetErDone:populateCompoundEdit(widget)
	widget:SetText(self.db.global.options.newCompoundName)
end

function GetErDone:getCompoundParent(compoundID)
	return self.db.global.compounds[compoundID].ownedBy
end

function GetErDone:compoundNumParents(compoundid)
	if self.db.global.compounds[compoundid].ownedBy == "" then 
		return 0
	else
		return 1 + self:compoundNumParents(self.db.global.compounds[compoundid].ownedBy)
	end
end

function GetErDone:getTrackableChildren(owner)
	t = {}
      for k,v in pairs(self.db.global.trackables) do
      	for kk,vv in pairs(v) do
	        if vv.ownedBy == owner then
	          table.insert(t,{k, kk}) --We're making a able of {id, type}
	        end
	    end
      end
    return t
end

--Name is a little ambiguous, this is the equivalent of "getTrackableChildren"
--@owner = compoundid
function GetErDone:getCompoundChildren(owner)
	t = {}
	if owner ~= "" and owner ~= nil then
		for k,v in pairs(self.db.global.compounds) do
			if v.ownedBy == owner then
				table.insert(t,k)
			end
		end
	else
		return self:getUnownedCompounds()
	end
		return t 
end

function GetErDone:getUnownedCompounds()
	t = {}
	for k,v in pairs(self.db.global.compounds) do
		if v.ownedBy == "" then
			table.insert(t,k)
		end
	end
	return t
end

function GetErDone:getCharacters()
	t = {["All"] = "All"}
	for k, v in pairs(GetErDone:GetOption("characters")) do
		t[k] = v
	end
	return t
end

function GetErDone:getIndent(n)
	result = ""
	for i=1, n do
		result = result .. "    "
	end
	return result
end
-----------------------------
------------ TEST CODE ------
-----------------------------


function GetErDone:test_reset()
	local resettest = { 
		["resettest"] = { 
			["name"] = "test",
			["ownedBy"] = "",
			["reset"] = { 
				["hour"] = "4",
				["day"] = "11",
				["month"] = "11",
				["year"] = "2013",
			},
			["frequency"] = "weekly",
			["characters"] = {
				[self.db.global.character] = 2,
			},
			["completionQuantity"] = 2,
			["active"] = true
		}
	}
	self.db.global.trackables["resettest"] = resettest

	self:UpdateResets()

	if self.db.global.trackables["resettest"]["resettest"].characters[self.db.global.character] == 0 then
		self:debug("reset test passed!")
	end

end

function GetErDone:test_increment()
	local incrementtest = { 
		["incrementtest"] = { 
			["name"] = "test",
			["ownedBy"] = "",
			["reset"] = { 
				["hour"] = "4",
				["day"] = "11",
				["month"] = "11",
				["year"] = "2013",
			},
			["frequency"] = "weekly",
			["characters"] = {
				[self.db.global.character] = 0,
			},
			["completionQuantity"] = 2,
			["active"] = true
		}
	}
	self.db.global.trackables["incrementtest"] = incrementtest

	self:CompleteTrackable("incrementtest", "incrementtest", COMPLETE_INCREMENT)

	if self.db.global.trackables["incrementtest"]["incrementtest"].characters[self.db.global.character] == 1 then
		self:debug("increment test passed!")
	end

end


function GetErDone:testeventkill()
	local guid1 = "Creature-0-1403-870-139-1-0000D2B633"
	local guid2 = "Creature-0-1403-870-139-2-0000D2B633"
	self:checkEvent(MONSTER, guid1)
	self:checkEvent(MONSTER, guid2)
end

function GetErDone:testeventkill_one()
	self.db.global.test = {["test"] = "a"}
	local t = self.db.global.test
	t.test = "b"
	self:debug(self.db.global.test.test)
	self.db.global.test = nil
end

function GetErDone:addThing()
	local id, compound = self:createCompound()
	compound.conditions = {["quantity"] = 2}
	self.db.global.options.character = "All"
	compound.characters = self:getCharactersFromOptions()
	compound.reset = self:nextReset("daily", "EU")
	compound.name = "test compound"
	self.db.global.compounds[id] = compound
	self:AddTrackable("1", MONSTER, "test1", id)
	self:AddTrackable("2", MONSTER, "test2", id)
end

function GetErDone:test_completion()
	local trackable_incomplete = { 
		["trackable_incomplete"] = { 
			["name"] = "test",
			["ownedBy"] = "",
			["reset"] = { 
				["hour"] = 4,
				["day"] = 11,
				["month"] = 11,
				["year"] = 2020,
			},
			["frequency"] = "weekly",
			["characters"] = {
				[self.db.global.character] = 0,
			},
			["completionQuantity"] = 1,
			["active"] = true
		}
	}
	local trackable_complete = { 
		["trackable_complete"] = { 
			["name"] = "test",
			["ownedBy"] = "",
			["reset"] = { 
				["hour"] = 4,
				["day"] = 11,
				["month"] = 11,
				["year"] = 2020,
			},
			["frequency"] = "weekly",
			["characters"] = {
				[self.db.global.character] = 1,
			},
			["completionQuantity"] = 1,
			["active"] = true
		}
	}
	local trackable_inactive = { 
		["trackable_inactive"] = { 
			["name"] = "test",
			["ownedBy"] = "",
			["reset"] = { 
				["hour"] = 4,
				["day"] = 11,
				["month"] = 11,
				["year"] = 2020,
			},
			["frequency"] = "weekly",
			["characters"] = {
				[self.db.global.character] = 1,
			},
			["completionQuantity"] = 1,
			["active"] = false
		}
	}
	local compound_one_complete = {
			["name"] = "test",
			["active"] = true,
			["comprisedOf"] = {
				{["id"] = "trackable_complete", ["type"] = "trackable_complete"},
			},
			["ownedBy"] = "",
			["displayChildren"] = true,
			["childCompletionQuantity"] = 1,
	}
	local compound_half_complete = {
			["name"] = "test",
			["active"] = true,
			["comprisedOf"] = {
				{["id"] = "trackable_complete", ["type"] = "trackable_complete"},
				{["id"] = "trackable_incomplete", ["type"] = "trackable_incomplete"},
			},
			["ownedBy"] = "",
			["displayChildren"] = true,
			["childCompletionQuantity"] = 1,
	}
	local compound_quantity_two = {
			["name"] = "test",
			["active"] = true,
			["comprisedOf"] = {
				{["id"] = "trackable_complete", ["type"] = "trackable_complete"},
				{["id"] = "trackable_inactive", ["type"] = "trackable_inactive"},
			},
			["ownedBy"] = "",
			["displayChildren"] = true,
			["childCompletionQuantity"] = 2,
	}
	local compound_compound = {
			["name"] = "test",
			["active"] = true,
			["comprisedOf"] = {
				"compound_one_complete",
				"compound_quantity_two",
			},
			["ownedBy"] = "",
			["displayChildren"] = true,
			["childCompletionQuantity"] = 2,
	}
	local compound_mixed = {
			["name"] = "test",
			["active"] = true,
			["comprisedOf"] = {
				"compound_one_complete",
				{["id"] = "trackable_complete", ["type"] = "trackable_complete"},
			},
			["ownedBy"] = "",
			["displayChildren"] = true,
			["childCompletionQuantity"] = 2,
	}

	self.db.global.trackables["trackable_incomplete"] = trackable_incomplete
	self.db.global.trackables["trackable_complete"] = trackable_complete
	self.db.global.trackables["trackable_inactive"] = trackable_inactive
	self.db.global.compounds["compound_one_complete"] = compound_one_complete
	self.db.global.compounds["compound_half_complete"] = compound_half_complete
	self.db.global.compounds["compound_quantity_two"] = compound_quantity_two
	self.db.global.compounds["compound_compound"] = compound_compound
	self.db.global.compounds["compound_mixed"] = compound_mixed

	local character = self.db.global.character
	local failures = {}

	if self:IsTrackableComplete("trackable_incomplete", "trackable_incomplete", character) then
		table.insert(failures, "trackable_incomplete failed")
	end

	if not self:IsTrackableComplete("trackable_complete", "trackable_complete", character) then
		table.insert(failures, "trackable_complete failed")
	end

	if self:IsTrackableComplete("trackable_inactive", "trackable_inactive", character) then
		table.insert(failures, "trackable_inactive failed")
	end

	if not self:IsCompoundComplete("compound_one_complete", character) then
		table.insert(failures, "compound_one_complete failed")
	end

	if not self:IsCompoundComplete("compound_half_complete", character) then
		table.insert(failures, "compound_half_complete failed")
	end

	if self:IsCompoundComplete("compound_quantity_two", character) then
		table.insert(failures, "compound_quantity_two failed")
	end

	if self:IsCompoundComplete("compound_compound", character) then
		table.insert(failures, "compound_compound failed")
	end

	if not self:IsCompoundComplete("compound_mixed", character) then
		table.insert(failures, "compound_mixed failed")
	end

	for k, v in pairs(failures) do
		self:debug(v)
	end

end
