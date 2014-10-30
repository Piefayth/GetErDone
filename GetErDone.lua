local GetErDone = LibStub("AceAddon-3.0"):NewAddon("GetErDone", "AceEvent-3.0", "AceConsole-3.0")

local AceConfig = LibStub("AceConfig-3.0")
local AceConfigDialog = LibStub("AceConfigDialog-3.0")
local AceDB = LibStub("AceDB-3.0")
local AceDBOptions = LibStub("AceDBOptions-3.0")
local AceGUI = LibStub("AceGUI-3.0")

local events = 	{
				["monster"] = {
					{["event"] = "LOOT_OPENED", ["callback"] = "handleEventMonster"}, 
					{["event"] = "OTHER_EVENT", ["callback"] = "handleEventMonster"}, 
			   	},
			  	["quest"] = {
			  		{["event"] = "QUEST_TURNED_IN", ["callback"] = "handleEventQuest"},
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
					trackmonster = {
						order = 1,
						type = "input",
						name = "New Monster",
						desc = "Add a new trackable monster ID",
						pattern = "(%d+)",
						set = function(k,v)
							GetErDone:AddTrackable(v, MONSTER, "some gay monster", "1")
						end
					},
					trackitem = {
						order = 2,
						type = "input",
						name = "New Item",
						desc = "Add a new trackable item ID",
						pattern = "(%d+)",
						set = function(k,v)
							GetErDone:AddTrackable(v, ITEM, "an item", "1")
						end
					},
					trackquest = {
						order = 3,
						type = "input",
						name = "New Quest",
						desc = "Add a new trackable quest flag ID",
						pattern = "(%d+)",
						set = function(k,v)
							GetErDone:AddTrackable(v, QUEST, "some thing", "1")
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
								--print(k..v)
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
					compound = {
						order = 9,
						type = "select",
						name = "Objective Group",
						desc = "",
						values = function()
							t = {["None"] = "None"}
							for k, v in pairs(GetErDone:GetOption("compound")) do
								print(k..v)
								t[k] = v
							end
							return t
						end,
					},
					test = {
						order = 10,
						type = "toggle",
						name = "test",
						desc = "",
						set = function() GetErDone:addThing() end,
						get = function() return end,
					},
					reset = {
						order = 11,
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
						order = 12,
						type = "toggle",
						name = "testeventkill",
						desc = "",
						set = function() GetErDone:testeventkill() end,
						get = function() end,
					},
					testeventkill1 = {
						order = 13,
						type = "toggle",
						name = "testeventkill1",
						desc = "",
						set = function() GetErDone:testeventkill_one() end,
						get = function() end,
					},
				},
			},
		},
	}


MONSTER = "monsters"
QUEST = "quest"
ITEM = "item"
CUSTOM_PREFIX = "c_"
local debugMode = true

--ApplyOption is for option retention between sessions. If you click "Daily" then reloadui, it retains that selection--
--The default behavior makes dropdowns always blank, which is annoying--
function GetErDone:ApplyOption(k,v)
	if (k[2] == "frequency") then
		self.db.global.options.frequency = v
	elseif (k[2] == "character") then
		self.db.global.options.character = v
	elseif (k[2] == "quantity") then
		self.db.global.options.quantity = v
	end
end

function GetErDone:GetOption(v)
	return self.db.global[v]
end

function GetErDone:testeventkill()
	local guid1 = "Creature-0-1403-870-139-1-0000D2B633"
	local guid2 = "Creature-0-1403-870-139-2-0000D2B633"
	self:checkEvent(MONSTER, guid1)
	self:checkEvent(MONSTER, guid2)
end

function GetErDone:testeventkill_one()
	local guid1 = "Creature-0-1403-870-139-1-0000D2B633"
	self:checkEvent(MONSTER, guid1)
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
end

function GetErDone:updateOwner(ownerId, childId)
	local owner = self.db.global.compounds[ownerId]
	if owner == nil then error() end

	if not self:contains(owner.comprisedOf, childId) then
		table.insert(owner.comprisedOf, childId)
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


	--Event Registry--
	self:RegisterEvent("PLAYER_ENTERING_WORLD", "OnLogin") --Note the syntax, second parameter is a function name as a string

end

function GetErDone:OnEnable()
	self:debug("hi")
	---First Time Setup l---
	if self.db.global.trackables == nil then self.db.global.trackables = {} end
	if self.db.global.characters == nil then self.db.global.characters = {} end
	if self.db.global.compounds == nil then self.db.global.compounds = {} end
	if self.db.global.options == nil then self.db.global.options = {} end
	if self.db.global.options.quantity == nil then self.db.global.options.quantity = 1 end
	if self.db.global.options.frequency == nil then self.db.global.options.frequency = "" end
	if self.db.global.options.nextCompoundId == nil then self.db.global.options.nextCompoundId = 1 end
	if self.db.global.tracked == nil then self.db.global.tracked = {} end


	name, server = UnitFullName("player")
	if self.db.global.characters[name..server] == nil then 
		self.db.global.characters[name..server] = name .. " - " .. server
	end

	self:registerHandlers()
end

function GetErDone:checkEvent(type, guid)
	if type == MONSTER then
		local npcId = self:getNpcId(guid)
		if npcId == nil then return end
		self:debug(npcId)
		local dbNpc = self.db.global.trackables[npcId]
		self:debug(dbNpc)
		if dbNpc ~= nil then
			local dbNpcType = dbNpc[type]
			if dbNpcId ~= nil then
				local compounds = dbNpcId.ownedBy
				if compounds ~= nil then
					for k, compound_id in pairs(compounds) do
						self:debug("Passing message to compound id " .. compound_id)
						self:informCompound(compound_id, dbNpcId)
					end
				end
			end
		return
	end
end

-- TODO need to make this deal with multiple things at once? higher quantities etc? I HAVE NO IDEA
function GetErDone:informCompound(compound_id, trackable)
	local compound = self.db.global.compounds[compound_id]

	if compound == nil then return end
	if not self:shouldTrack(compound) then return end

	self:debug("Informing compound " .. compound.name)

	-- call recursively for any compound compounds
	for k, owner in pairs(compound.ownedBy) do
		if owner ~= nil then self:informCompound(owner, compound_id) end
	end

	self:setCompleted(compound_id)
end

function GetErDone:shouldTrack(compound)
	if not compound.active then return false end
	for k, character in pairs(compound.characters) do
		if character == self.db.global.character then
			self:debug("Setting " .. compound.name .. " to completed.")
			return true
		end
	end
	return false
end

function GetErDone:setCompleted(compound_id)
	local compound = self.db.global.compounds[compound_id]
	if compound == nil then 
		self:debug("Compound id " .. compound_id .. " referred to a null compound")
		return 
	end
	self:debug("Setting " .. compound_id .. " to completed")
	local character = self.db.global.character
	self:ensureTracked(compound_id, character)

	if not self.db.global.tracked[compound_id][character].completed then
		self.db.global.tracked[compound_id][character].quantityCompleted = self.db.global.tracked[compound_id][character].quantityCompleted + 1
		if self.db.global.tracked[compound_id][character].quantityCompleted >= compound.conditions.quantity then
			self.db.global.tracked[compound_id][character].completed = true
			self:debug("compound id " .. compound_id .. " successfully completed")
		end
	end
end

function GetErDone:ensureTracked(compound_id, character_name)
	if self.db.global.tracked == nil then self.db.global.tracked = {} end
	if self.db.global.tracked[compound_id] == nil then self.db.global.tracked[compound_id] = {} end
	if self.db.global.tracked[compound_id][character_name] == nil then self.db.global.tracked[compound_id][character_name] = {} end
	if self.db.global.tracked[compound_id][character_name].completed == nil then self.db.global.tracked[compound_id][character_name].completed = false end
	if self.db.global.tracked[compound_id][character_name].quantityCompleted == nil then self.db.global.tracked[compound_id][character_name].quantityCompleted = 0 end
end


-- sorry rarity guy
function GetErDone:getNpcId(guid)
	if guid then
		local unit_type, _, _, _, _, mob_id = strsplit('-', guid)
		return mob_id
	end
	return 0
end

function GetErDone:registerHandlers()
	for type, eventObj in pairs(events) do
		for k, eventy in pairs(eventObj) do
			self:debug(eventy.callback .. " registered for event " .. eventy.event)
			self:RegisterEvent(eventy.event, eventy.callback, eventy.event)
		end
	end
end

function GetErDone:handleEventMonster(event) 
	if event == "LOOT_OPENED" then
		local numChecked = 0
		local numItems = GetNumLootItems()
		for slotId = 1, numItems, 1 do
			mobList = { GetLootSourceInfo(slotId) }
			for k, v in pairs(mobList) do
				if v and type(v) == "string" then
					self:debug("Checking mob id " .. v)
					self:checkEvent(MONSTER, v)
				end
			end
		end
	end
end

function GetErDone:handleEventQuest(event)
	-- TODO
end

function GetErDone:updateResets()
	for k, v in pairs(getAllTrackables()) do
		v.reset = self:nextReset(v.reset, v.frequency)
		self:debug("Updated " .. k .. " reset to " .. v.reset)
	end
end

function GetErDone:getAllTrackables()
	--tracks = {}
	--for group, groups in pairs(self.db.global.trackables) do
	--	if not group == "compound" then
	--		for id, value in pairs(groups) do
	--			tracks.insert(id, value)
	--		end
	--	end
	--end
	--return tracks
	return self.db.global.trackables
end

function GetErDone:OnDisable()
end

---Event Handlers---

---OnLogin defaults the "character" dropdown to the character you're currently logged in as.
function GetErDone:OnLogin()
	name, server = UnitFullName("player")
	self.db.global.options.character = name..server
	self.db.global.character = name..server
	self.trackables = self:getAllTrackables()
end

function GetErDone:nextReset(frequency, region)
  currentDate = date("!*t")
  --currentDate = {["wday"] = 4, ["day"] = 1, ["month"] = 11, ["year"] = 2014, ["hour"] = 12}
  monthdays = {31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31}
  if currentDate["year"] % 4 == 0 then monthdays[2] = 29 end

  resetDate = {["year"] = "", ["day"] = "", ["month"] = "", ["hour"] = ""}

  regionDayMap = {["US"] = {["day"] = 3, ["hour"] = 11},
  				  ["EU"] = {["day"] = 4, ["hour"] = 2},
  				  ["AU"] = {["day"] = 2, ["hour"] = 17}}

  daysRemaining = 0
  regionalResetHour = regionDayMap[region].hour
  if frequency == "weekly" then
  	regionalResetDay = regionDayMap[region].day
    if currentDate["wday"] > regionalResetDay then --If it's after the resetDate day
      daysRemaining = regionalResetDay + 7 - currentDate["wday"]
    elseif currentDate["wday"] < regionalResetDay then
      daysRemaining = regionalResetDay - currentDate["wday"] --If it's Sunday or Monday
    elseif currentDate["wday"] == regionalResetDay then -- If it's Tuesday
      if currentDate["hour"] < regionalResetHour then daysRemaining = 0 end
      if currentDate["hour"] >= regionalResetHour then daysRemaining = 7 end
    end
    resetDate = GetErDone:addDays(resetDate, currentDate, daysRemaining)
  elseif frequency == "daily" then
    resetDate = GetErDone:addDays(resetDate, currentDate, 1)
  elseif frequency == "monthly" then
    daysRemaining = monthdays[currentDate["month"]] - currentDate["day"] + 1
    resetDate = GetErDone:addDays(resetDate, currentDate, daysRemaining)
  elseif frequency == "once" then
  	return 0
  else
    error()
  end
  resetDate["hour"] = regionalResetHour
  return resetDate
end

function GetErDone:addDays(resetDate, currentDate, days)
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

function GetErDone:debug(message)
	if debugMode then
		print(message)
	end
end

function GetErDone:trim(s)
  return s:match'^%s*(.*%S)' or ''
end

function GetErDone:contains(dict, value)
	if dict == nil then 
		print("what the haps my friends")
		return false 
	end
	for k, v in pairs(dict) do
		if value == v then return true end
	end
	return false
end