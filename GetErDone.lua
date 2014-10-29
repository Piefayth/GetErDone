local GetErDone = LibStub("AceAddon-3.0"):NewAddon("GetErDone", "AceEvent-3.0", "AceConsole-3.0")

local AceConfig = LibStub("AceConfig-3.0")
local AceConfigDialog = LibStub("AceConfigDialog-3.0")
local AceDB = LibStub("AceDB-3.0")
local AceDBOptions = LibStub("AceDBOptions-3.0")

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

local options = {
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
							GetErDone:AddMonster(v)
						end
					},
					separator = {
						order = 3,
						type = "description",
						name = "",
					},
					trackquest = {
						order = 4,
						type = "input",
						name = "New Quest",
						desc = "Add a new trackable quest flag ID",
						pattern = "(%d+)",
						set = function(k,v)
							GetErDone:AddQuest(v)
						end
					},
					separator = {
						order = 5,
						type = "description",
						name = "",
					},
					frequency = {
						order = 6,
						type = "select",
						name = "Frequency",
						desc = "How often should this item reset?",
						style = "dropdown",
						values = {["daily"] = "Daily", ["weekly"] = "Weekly", ["once"] = "Once"},
						set = function(k,v)
							GetErDone:ApplyOption(k,v)
						end,
						get = function()
							return GetErDone:GetOption("frequency")
						end
					},
					character = {
						order = 7,
						type = "select",
						name = "Character",
						desc = "Which character is this task for? Your character will not appear in this list until you've logged in with it.",
						style = "dropdown",
						values = function()
							t = {["All"] = "All"}
							for k, v in pairs(GetErDone:GetOption("characters")) do
								print(k..v)
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
					}
				},
			},
		},
	}

local MONSTER = 0
local QUEST = 1

--ApplyOption is for option retention between sessions. If you click "Daily" then reloadui, it retains that selection--
--The default behavior makes dropdowns always blank, which is annoying--
function GetErDone:ApplyOption(k,v)
	if (k[2] == "frequency") then
		self.db.global.frequency = v
	elseif (k[2] == "character") then
		self.db.global.character = v
	end
end

function GetErDone:GetOption(v)
	return self.db.global[v]
end

function GetErDone:AddMonster(id)
	--NEED TO CHECK IF MONSTER ID ALREADY EXISTS FIRST, THIS ASSUMES IT DOESNT
	table.insert(self.db.global.trackables.monsters, {["monsterid"] = id, 
										["frequency"] = self.db.global.frequency,
										["characters"] = {self.db.global.character}})
end

function GetErDone:AddQuest(id)
	--NEED TO CHECK IF MONSTER ID ALREADY EXISTS FIRST, THIS ASSUMES IT DOESNT
	table.insert(self.db.global.trackables.quests, {["questid"] = id, 
										["frequency"] = self.db.global.frequency,
										["characters"] = {self.db.global.character}})
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
	print("im gay")
	---First Time Setup l---
	if self.db.global.trackables == nil then self.db.global.trackables = {} end
	if self.db.global.trackables.monsters == nil then self.db.global.trackables.monsters = {} end
	if self.db.global.trackables.quests == nil then self.db.global.trackables.quests = {} end
	if self.db.global.frequency == nil then self.db.global.frequency = "" end
	if self.db.global.characters == nil then self.db.global.characters = {} end

	table.insert(self.db.global.trackables.monsters, "58448", {
				["name"] = "DEBUG GOAT",
				["characters"] = {
					{"Ihs", "Draenor"},
				},
				["reset"] = "20141029",
				["frequency"] = "1",
				["item"] = "1111",
			})

	name, server = UnitFullName("player")
	if self.db.global.characters[name..server] == nil then 
		self.db.global.characters[name..server] = name .. " - " .. server
	end
	---

	for i, v in ipairs(self.db.global.trackables.monsters) do
		if v["monsterid"] ~= nil then
			print("Index: " .. i .. " Monster ID: " .. v.monsterid)
		end
	end
	for i, v in ipairs(self.db.global.trackables.quests) do
		if v["questid"] ~= nil then
			print("Index: " .. i .. " Quest ID: " .. v.questid)
		end
	end
	for k, v in pairs(self.db.global.characters) do --Have to use pairs over ipairs for non numerical indices, afaik
		print(k .. v)
	end

	self:registerHandlers()

end

function GetErDone:checkEvent(type, guid)
	if type == MONSTER then
		local npcId = self:getNpcId(guid)
		print(npcId)
		local dbNpcId = self.db.global.trackables.monsters[npcId]
		print(dbNpcId)
		if dbNpcId ~= nil then
			for k, character in pairs(dbNpcId.characters) do
				if character[1] .. character[2] == self.db.global.character then
					print("Setting " .. npcId .. " to completed.")
					self:setCompleted(dbNpcId)
					return
				end
			end
		end
		return
	end
end

function GetErDone:setCompleted(id)
	print("my dad fucks me")
end

-- sorry rarity guy
function GetErDone:getNpcId(guid)
	if guid then
		local unit_type, _, _, _, _, mob_id = strsplit('-', guid)
		return (guid and mob_id and tonumber(mob_id)) or 0
	end
	return 0
end

function GetErDone:registerHandlers()
	for type, eventObj in pairs(events) do
		for k, eventy in pairs(eventObj) do
			print(eventy.callback .. " registered for event " .. eventy.event)
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
					print("Checking mob id " .. v)
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
	for k, v in pairs(getAllTrackables) do
		v.reset = self:nextReset(v.reset, v.frequency)
		print("Updated " .. k .. " reset to " .. v.reset)
	end
end

function GetErDone:getAllTrackables()
	tracks = {}
	for group, groups in pairs(self.db.global.trackables) do
		if not group == "compound" then
			for id, value in pairs(groups) do
				tracks.insert(id, value)
			end
		end
	end
	return tracks
end

function GetErDone:OnDisable()
end

---Event Handlers---

---OnLogin defaults the "character" dropdown to the character you're currently logged in as.
function GetErDone:OnLogin()
	name, server = UnitFullName("player")
	print("i'm really gay")
	self.db.global.character = name..server
	self.trackables = self:getAllTrackables()
end

function GetErDone:nextReset(frequency, region)
  currentDate = os.date("!*t")
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
    resetDate = addDays(resetDate, currentDate, daysRemaining)
  elseif frequency == "daily" then
    resetDate = addDays(resetDate, currentDate, 1)
  elseif frequency == "monthly" then
    daysRemaining = monthdays[currentDate["month"]] - currentDate["day"] + 1
    resetDate = addDays(resetDate, currentDate, daysRemaining)
  else
    return nil
  end
  resetDate["hour"] = regionalResetHour
  return os.time(resetDate)
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

