local GetErDone = LibStub("AceAddon-3.0"):NewAddon("GetErDone", "AceEvent-3.0", "AceConsole-3.0")

local AceConfig = LibStub("AceConfig-3.0")
local AceConfigDialog = LibStub("AceConfigDialog-3.0")
local AceDB = LibStub("AceDB-3.0")
local AceDBOptions = LibStub("AceDBOptions-3.0")
local AceGUI = LibStub("AceGUI-3.0")

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


local trackables = {}

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


function GetErDone:addCompound(compound_id)
	local compound
	if compound_id == nil then
		compound_id, compound = self:addNewCompound()
	else
		compound = self.db.global.compounds[compound_id]
		if compound == nil then
			error("addCompound: compound present in db but null")
		end
	end

	compound.name = self:GetOption("newCompoundName")
end

function GetErDone:addNewCompound()
	local id, compound = self:createCompound()
	self.db.global.compounds[id] = compound
end

function GetErDone:getCharactersFromOptions()
	local chars = self.db.global.options.character
	if chars == "All" then
		return self:prepareNames(self.db.global.characters)
	end
	return { chars }
end

function GetErDone:createCompound()
	local compound = {
		["name"] = "",
		["active"] = true,
		["characters"] = {},
		["reset"] = {},
		["frequency"] = "daily",
		["comprisedOf"] = {},
		["ownedBy"] = {},
		["conditions"] = {},
	}
	local id = GetErDone:generateNextCompoundId()
	return id, compound
end

function GetErDone:disableCompound(compound_id, propagate, direction)
	self.db.global.compounds[compound_id].active = false
	if propagate then 
		-- upstream
		if direction == UP or direction == BOTH then
			for k, id in pairs(self.db.global.compounds[compound_id].ownedBy) do
				self:disableCompound(id, propagate, UP)
			end
		elseif direction == DOWN or direction == BOTH then
			-- downstream
			for k, id in pairs(self.db.global.compounds[compound_id].comprisedOf) do
				if self:isCompoundId(id) then
					self:disableCompound(id, propagate, DOWN)
				end
			end
		end
	end
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

function GetErDone:AddTrackable(id, type, name, owner)
	self:ensureTrackable(id)
	if self.db.global.trackables[id][type] == nil then
		self.db.global.trackables[id][type] = {
			["name"] = name,
			["ownedBy"] = { owner },
    	}
    else
    	if not self:contains(self.db.global.trackables[id][type].ownedBy, owner) then
    		table.insert(self.db.global.trackables[id][type].ownedBy, owner)
    	end
    end
    self:updateOwner(owner, id)

    --Zero Out Options Fields--
	self.db.global.options.quantity = 0
	self.db.global.options.trackableID = 0
end

function GetErDone:updateOwner(ownerId, childId, childType)
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
	print(self.optionsFrames.general.obj.frame:GetRegions()[0])
	for k,v in pairs(self.optionsFrames.general.obj.frame:GetRegions()) do
		print(k, v)
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


	name, server = UnitFullName("player")
	if self.db.global.characters[name..server] == nil then 
		self.db.global.characters[name..server] = name .. " - " .. server
	end

	self:registerHandlers()
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

	if status == COMPLETE_INCREMENT then
		if trackable.characters[self.db.global.character] < trackable.completionQuantity then
			trackable.characters[self.db.global.character] = trackable.characters[self.db.global.character] + 1
		end
	elseif status == COMPLETE_ZERO then
		for k, v in pairs(trackable.characters) do
			trackable.characters[k] = 0
		end 
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
	--self.trackables = self:getAllTrackables()
end

-- UTILS -- 

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

	if compound.ownedBy == nil or compound.ownedBy == {} then
		return COMPOUND_LEVEL_TOP
	end

	for k, v in pairs(compound.ownedBy) do
		if self:isCompoundId(v) then
			return COMPOUND_LEVEL_MID
		end
	end
	return COMPOUND_LEVEL_BOTTOM
end

function GetErDone:GetNestedDepth(compound_id)
	if self:GetCompoundLevel(compound_id) == COMPOUND_LEVEL_TOP then
		return 0
	else
		return 1 + GetErDone:GetNestedDepth(self.db.global.compounds[compound_id].ownedBy)
	end
end



---------------------------------UI CODE-------------------------------------------

function GetErDone:testui()
	local f = AceGUI:Create("Frame")
	local leftLabelgroup = {}

	f:SetCallback("OnClose",function(widget) AceGUI:Release(widget) end)
	f:SetTitle("Options")
	f:SetLayout("Flow")
	f:SetHeight(600)

	----Scroll Groups Init---
	local groupsContainer = AceGUI:Create("InlineGroup")
	local trackablesContainer = AceGUI:Create("InlineGroup")

	groupsContainer:SetLayout("Fill")
	groupsContainer:SetRelativeWidth(0.5)
	groupsContainer:SetHeight(350)

	trackablesContainer:SetLayout("Fill")
	trackablesContainer:SetRelativeWidth(0.5)
	trackablesContainer:SetHeight(370)

	f:AddChild(groupsContainer)
	f:AddChild(trackablesContainer)
	
	

	local groupsScroll = AceGUI:Create("ScrollFrame")
	local trackablesScroll = AceGUI:Create("ScrollFrame")
	groupsScroll:SetLayout("List")
	trackablesScroll:SetLayout("List")
	groupsScroll:SetRelativeWidth(0.5)
	groupsContainer:AddChild(groupsScroll)
	trackablesContainer:AddChild(trackablesScroll)
	---Scroll Groups Data--
	for k, v in pairs(self:getUnownedCompounds()) do
		local label = AceGUI:Create("InteractiveLabel")
		label:SetText(v .. " - " .. self.db.global.compounds[v].name)
		label:SetHighlight(.5, .5, 0, .5)
		label:SetCallback("OnClick", function(widget) self:clickGroupLabel(widget, v, groupsScroll, trackablesScroll) end) --v is the id of the compound
		groupsScroll:AddChild(label)
		table.insert(leftLabelgroup, label)
	end

	---Adding New Trackable and a group to contain them---

	local newCompoundGroup = AceGUI:Create("InlineGroup")
	local editCompound = AceGUI:Create("EditBox")
	local dropdownCompound = AceGUI:Create("Dropdown")
	local buttonCompound = AceGUI:Create("Button")

	buttonCompound:SetText("Add Group")

	editCompound:SetCallback("OnEnterPressed", function(widget, event, text) self:submitCompoundEdit(editCompound, text) end)

	newCompoundGroup:SetRelativeWidth(0.5)
	newCompoundGroup:SetLayout("List")

	local newTrackableGroup = AceGUI:Create("InlineGroup")
	local editID = AceGUI:Create("EditBox")
	local dropdownID = AceGUI:Create("Dropdown")
	local buttonID = AceGUI:Create("Button")

	buttonID:SetText("Add ID")

	editID:SetCallback("OnEnterPressed", function(widget, event, text) self:submitIDEdit(editID, text) end)

	newTrackableGroup:SetRelativeWidth(0.5)
	newTrackableGroup:SetLayout("List")



	f:AddChild(newCompoundGroup)
	newCompoundGroup:AddChild(editCompound) 
	newCompoundGroup:AddChild(dropdownCompound) 
	newCompoundGroup:AddChild(buttonCompound)
	
	f:AddChild(newTrackableGroup)
	newTrackableGroup:AddChild(editID)
	newTrackableGroup:AddChild(dropdownID)
	newTrackableGroup:AddChild(buttonID)
	
	f:DoLayout() --HOLY MOTHERFUCKING SHIT IS THIS LINE IMPORTANT

	
end

function GetErDone:clickGroupLabel(widget, compoundID, groupFrame, trackableFrame, isUp)
	trackableFrame:ReleaseChildren()
	groupFrame:ReleaseChildren()

	if isUp then
		if compoundID == nil then 
			self.db.global.options.optCompound = ""
		else
			self.db.global.options.optCompound = self.db.global.compounds[compoundID].ownedBy
		end
	else
		self.db.global.options.optCompound = compoundID
	end

	cid = self.db.global.options.optCompound

	--Repopulate Left Window
	for k, v in pairs(self:getCompoundChildren(cid)) do
		local label = AceGUI:Create("InteractiveLabel")
		label:SetText(v .. " - " .. self.db.global.compounds[v].name)
		label:SetHighlight(.5, .5, 0, .5)
		label:SetCallback("OnClick", function(widgetx) self:clickGroupLabel(widgetx, v, groupFrame, trackableFrame, false) end)
		groupFrame:AddChild(label)
	end

	--Add an "up one level" button if we're not at the top level
	if cid ~= "" then
		local label = AceGUI:Create("InteractiveLabel")
		label:SetText("Up One Level ^")
		label:SetHighlight(.5, .5, 0, .5)
		label:SetCallback("OnClick", function(widgetx) self:clickGroupLabel(widgetx, cid, groupFrame, trackableFrame, true) end)
		groupFrame:AddChild(label)
	end

	--Repopulate Right Window
	if not isUp then 
		target = compoundID 
	else 
		target = self:getTrackableChildren(self:getCompoundParent(compoundID))
	end

	for k, v in pairs(self:getTrackableChildren(target)) do
		local label = AceGUI:Create("InteractiveLabel")
		label:SetText(self.db.global.trackables[v[1]][v[2]].name)
		label:SetHighlight(.5, .5, 0, .5)
		label:SetCallback("OnClick", function(widgetx) self:clickTrackableLabel(widgetx, {v[1], v[2]}, trackableFrame) end)
		trackableFrame:AddChild(label)
	end
end

function GetErDone:clickTrackableLabel(widget, trackableID, trackableFrame)

end

function GetErDone:submitIDEdit(widget, text)
	if string.match(text, '%d') then
		self.db.global.options.trackableID = text
	end
	self:populateIDEdit(widget)
end

function GetErDone:populateIDEdit(widget)
	widget:SetText(self.db.global.options.trackableID)
end

function GetErDone:submitCompoundEdit(widget, text)
	self.db.global.options.newCompoundName = text
end

function GetErDone:populateCompoundEdit(widget)
	widget:SetText(self.db.global.options.newCompoundName)
end

function GetErDone:getCompoundParent(compoundID)
	return self.db.global.compounds[compoundID]["ownedBy"]
end

function GetErDone:getTrackableChildren(owner)
	t = {}
      for k,v in pairs(self.db.global.trackables) do
      	for kk,vv in pairs(v) do
	        if vv["ownedBy"] == owner then
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
	for k,v in pairs(self.db.global.compounds) do
		if v["ownedBy"] == owner then
			table.insert(t,k)
		end
	end
	if t == {} then 
		return self:getUnownedCompounds()
	else 
		return t 
	end
end

function GetErDone:getUnownedCompounds()
	t = {}
	for k,v in pairs(self.db.global.compounds) do
		if v["ownedBy"] == "" then
			table.insert(t,k)
		end
	end
	return t
end

-----------------------------
------------ TEST CODE ------
-----------------------------


function GetErDone:test_reset()
	local resettest = { 
		["resettest"] = { 
			["name"] = "test",
			["ownedBy"] = {},
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
		print("reset test passed!")
	end

	self.db.global.trackables["resettest"] = nil
end

function GetErDone:test_increment()
	local incrementtest = { 
		["incrementtest"] = { 
			["name"] = "test",
			["ownedBy"] = {},
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
		print("increment test passed!")
	end

	self.db.global.trackables["incrementtest"] = nil
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
	print(self.db.global.test.test)
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