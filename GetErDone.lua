local GetErDone = LibStub("AceAddon-3.0"):NewAddon("GetErDone", "AceEvent-3.0", "AceConsole-3.0")

local AceConfig = LibStub("AceConfig-3.0")
local AceConfigDialog = LibStub("AceConfigDialog-3.0")
local AceDB = LibStub("AceDB-3.0")
local AceDBOptions = LibStub("AceDBOptions-3.0")

local events = 	{
				["monster"] = {
					{["event"] = "LOOT_OPENED", ["callback"] = "handleEventMonster"}, 
					{["event"] = "OTHER_EVENT", ["callback"] = "handleEventMonster"}, 
			   	}
			  	["quest"] = {
			  		{["event"] = "QUEST_TURNED_IN", ["callback"] = "handleEventQuest"},
			  	}
			 }

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
	self.db = LibStub("AceDB-3.0"):New("GetErDoneDB")


	
	self.optionsFrames = {}
	self.optionsFrames.general = AceConfigDialog:AddToBlizOptions("GetErDone", nil, nil, "general")


	--Event Registry--
	self:RegisterEvent("PLAYER_ENTERING_WORLD", "OnLogin") --Note the syntax, second parameter is a function name as a string

end

function GetErDone:OnEnable()

	---First Time Setup l---
	if self.db.global.trackables.monsters == nil then self.db.global.trackables.monsters = {} end
	if self.db.global.trackables.quests == nil then self.db.global.trackables.quests = {} end
	if self.db.global.frequency == nil then self.db.global.frequency = "" end
	if self.db.global.characters == nil then self.db.global.characters = {} end
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


end

function GerErDone:registerHandlers()
	for type, eventObj in pairs(events) do
		for eventy in eventObj do
			AceEvent:RegisterEvent(eventy.event, eventy.callback)
		end
	end
end

function GetErDone:handleEventMonster() 
	-- TODO
end

function GetErDone:handleEventQuest()
	-- TODO
end

function GetErDone:updateResets()
	for k, v in pairs(getAllTrackables) do
		v.repeat = GetErDoneUtils:nextReset(v.repeat, v.frequency)
	end
end

function GetErDone:getAllTrackables()
	table = {}
	for group, groups in pairs(self.db.global.trackables) do
		if group != "compound" then
			for id, value in pairs(groups) do
				table.insert(id, value)
			end
		end
	end
	return table
end

function GetErDone:OnDisable()
end

---Event Handlers---

---OnLogin defaults the "character" dropdown to the character you're currently logged in as.
function GetErDone:OnLogin()
	name, server = UnitFullName("player")
	self.db.global.character = name..server
end

