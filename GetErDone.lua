local GetErDone = LibStub("AceAddon-3.0"):NewAddon("GetErDone", "AceEvent-3.0", "AceConsole-3.0")

local AceConfig = LibStub("AceConfig-3.0")
local AceConfigDialog = LibStub("AceConfigDialog-3.0")
local AceDB = LibStub("AceDB-3.0")
local AceDBOptions = LibStub("AceDBOptions-3.0")

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
				},
			},
		},
	}

function GetErDone:AddMonster(id)
	table.insert(self.db.char.monsters, id)
	return
end

function GetErDone:AddQuest(id)
	table.insert(self.db.char.quests, id)
	return
end

function GetErDone:OnInitialize()
	AceConfig:RegisterOptionsTable("GetErDone", options, {"ged", "geterdone"})
	self.db = LibStub("AceDB-3.0"):New("GetErDoneDB")

	---First Time Setup---
	if self.db.char.monsters == nil then self.db.char.monsters = {} end
	if self.db.char.quests == nil then self.db.char.quests = {} end
	---
	
	self.optionsFrames = {}
	self.optionsFrames.general = AceConfigDialog:AddToBlizOptions("GetErDone", nil, nil, "general")
end

function GetErDone:OnEnable()
	for i, v in ipairs(self.db.char.monsters) do
		print("Index: " .. i .. " Monster ID: " .. v)
	end
	for i, v in ipairs(self.db.char.quests) do
		print("Index: " .. i .. " Quest ID: " .. v)
	end
end

function GetErDone:OnDisable()
end