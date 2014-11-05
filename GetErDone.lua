GetErDone = LibStub("AceAddon-3.0"):NewAddon("GetErDone", "AceEvent-3.0", "AceConsole-3.0")

local AceConfig = LibStub("AceConfig-3.0")
local AceConfigDialog = LibStub("AceConfigDialog-3.0")
local AceDB = LibStub("AceDB-3.0")
local AceDBOptions = LibStub("AceDBOptions-3.0")
local AceGUI = LibStub("AceGUI-3.0")
local widgetManager = {}
local frameManager = {}

local events = 	{
	{ ["event"] = "LOOT_OPENED", ["callback"] = "handleEventMonster" }, 
	{ ["event"] = "QUEST_TURNED_IN", ["callback"] = "handleEventQuest" },
	{ ["event"] = "QUEST_COMPLETE", ["callback"] = "handleEventQuest" },
	{ ["event"] = "UNIT_SPELLCAST_SUCCEEDED", ["callback"] = "handleEventSpell" },
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
							t = {["All"] = CHARACTERS_ALL}
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
					debug = {
						order = 50,
						type = "execute",
						name = "toggle debug",
						desc = "",
						func = function() 
							print("debug disabled")
							debugMode = false 
						end,
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
					testtree = {
						order = 98,
						type = "execute",
						name = "testtree",
						desc = "",
						func = function() GetErDone:createIngameList() end,
					},
					testtreechar = {
						order = 98,
						type = "execute",
						name = "testtreechar",
						desc = "",
						func = function() GetErDone:createIngameListChar() end,
					},
					ui = {
						order = 1000,
						type = "execute",
						name = "ui",
						desc = "",
						func = function() GetErDone:createTestInGameList() end,
					},
					uitest_set = {
						order = 1001,
						type = "execute",
						name = "uitest_set",
						desc = "",
						func = function() GetErDone:uitest_set() end,
					},
					uitest_test = {
						order = 1002,
						type = "execute",
						name = "uitest_test",
						desc = "",
						func = function() GetErDone:uitest_test() end,
					},
				},
			},
		},
	}


TYPE_MONSTER = "Creature"
TYPE_QUEST = "quest"
TYPE_ITEM = "item"
TYPE_SPELL = "spell"
TYPE_OBJECT = "GameObject"
TYPE_VEHICLE = "Vehicle"
TYPE_LIST = {[TYPE_MONSTER] = "Monster", [TYPE_ITEM] = "Item", [TYPE_QUEST] = "Quest", [TYPE_SPELL] = "Spell", [TYPE_OBJECT] = "Object"}
CUSTOM_PREFIX = "default_"
COMPOUND_LEVEL_BOTTOM = 0
COMPOUND_LEVEL_MID = 1
COMPOUND_LEVEL_TOP = 2
COMPLETE_INCREMENT = 0
COMPLETE_ZERO = 1
RESET_DAILY = "daily"
RESET_WEEKLY = "weekly"
RESET_MONTHLY = "monthly"
UNIT_PLAYER = "player"
REGION_US = 1
REGION_KR = 2
REGION_EU = 3
REGION_TW = 4
REGION_CN = 5
COMPLETION_CACHE_ALL_CHARACTERS = 1
TRACKABLE_DB_PREFIX = "trackable_"
CHARACTERS_ALL = "all"
NESTING_INDENT = "    "
MERGED_DELIMITER = ":"
TREE_CHARACTER_STRING_LENGTH = 80
debugMode = true



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


function GetErDone:addCompound()
	if self.db.global.options.newCompoundName == "" or self.db.global.options.newCompoundName == nil then error("addCompound: empty compound name") end
	local compound = {
		["name"] = self.db.global.options.newCompoundName,
		["active"] = true,
		["comprisedOf"] = {},
		["ownedBy"] = self.db.global.options.optCompound,
		["displayChildren"] = self.db.global.options.compoundchildren,
		["childCompletionQuantity"] = tonumber(self.db.global.options.compoundquantity) or 0
	}

	self.db.global.options.compoundquantity = ""
	self.db.global.options.newCompoundName = ""
	local compound_id = self.db.global.options.compoundId or GetErDone:generateNextCompoundId()
	self.db.global.compounds[compound_id] = compound
	self:updateOwner(compound.ownedBy, compound_id, nil)

	self:invalidateAceTree()
	self:updateUI()
	return true
end


function GetErDone:prepareCharacters(characters)
	local chars = {}
	if type(characters) ~= "table" then return { [characters] = 0 } end
	if characters == CHARACTERS_ALL then
		for name, v in pairs(self.db.global.characters) do
			chars[name] = 0
		end
	else
		for name, v in pairs(characters) do
			chars[name] = 0
		end
	end
	return chars
end

function GetErDone:isCompoundId(id)
	return type(id) == "string"
end

function GetErDone:generateNextCompoundId()
	local id = self.db.global.options.nextCompoundId + 1
	self.db.global.options.nextCompoundId = id
	return CUSTOM_PREFIX .. id
end

function GetErDone:LoadTrackableName(id, type)
	if id == nil or type == nil then
		return COULD_NOT_FIND_TRACKABLE_IN_DB
	end
	local trackables = self.db.global.trackables
	if trackables[id] ~= nil then
		if trackables[id][type] ~= nil then
			return trackables[id][type].name
		end
	end
	
	self:debug(type .. " not found in database")
	return COULD_NOT_FIND_TRACKABLE_IN_DB
end

function GetErDone:AddTrackable(id, type, name, owner, frequency, characters, quantity)
	if id == 0 or id == "" then error("AddTrackable: null or empty id") end

	self:ensureTrackable(id)
	if self.db.global.trackables[id][type] == nil then
		self.db.global.trackables[id][type] = {
			["active"] = true,
			["name"] = name,
			["ownedBy"] = owner,
			["frequency"] = frequency,
			["reset"] = self:NextReset(frequency, self.db.global.region),
			["characters"] = self:prepareCharacters(characters),
			["completionQuantity"] = tonumber(quantity)
    	}
    else
    	self.db.global.trackables[id][type].ownedBy = owner -- TODO let us update more than this
    end

    self:updateOwner(owner, id, type)

    self:refreshTrackableList()
	self:invalidateAceTree()
	self:updateUI()

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
	if childType == nil then -- compound
		if not self:contains(owner.comprisedOf, childId) then
			table.insert(owner.comprisedOf, childId)
		end
	else -- trackable
		local idtype = { ["id"] = childId, ["type"] = childType }
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
			self:AddTrackable(child_id, child_type, self:LoadTrackableName(child_id, child_type), compound_id, "", CHARACTERS_ALL, 1)
		end
	end
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
	---First Time Setup l---
	if self.db.global.trackables == nil then self.db.global.trackables = {} end
	if self.db.global.characters == nil then self.db.global.characters = {} end
	if self.db.global.compounds == nil then self.db.global.compounds = {} end
	if self.db.global.options == nil then self.db.global.options = {} end
	if self.db.global.options.quantity == nil then self.db.global.options.quantity = 1 end
	if self.db.global.options.frequency == nil then self.db.global.options.frequency = "" end
	if self.db.global.options.nextCompoundId == nil then self.db.global.options.nextCompoundId = 1 end
	if self.db.global.options.newCompoundName == nil then self.db.global.options.newCompoundName = "" end
	if self.db.global.options.ignoredNames == nil then self.db.global.options.ignoredNames = {} end
	if self.db.global.options.compoundchildren == nil then self.db.global.options.compoundchildren = true end
	if self.db.global.region == nil then self.db.global.region = GetCurrentRegion() end
	if self.db.global.completionCache == nil then self.db.global.completionCache = {} end



	name, server = UnitFullName("player")
	if self.db.global.characters[name .. server] == nil then 
		self.db.global.characters[name .. server] = {["name"] = name, ["server"] = server}
	end
	self.db.global.character = name .. server

	self:registerHandlers()
	--self:LoadDefaults()
	self:UpdateResets()
	self:InvalidateCompletionCache(COMPLETION_CACHE_ALL_CHARACTERS)
	self:invalidateAceTree()
	self:collapseUIToTopLevel()
	self:createTestInGameList()
end


function GetErDone:OnUpdate()
end

function GetErDone:LoadDefaults()
	if self.db.global.defaultsLoaded == nil then
		for id, type in pairs(defaults.trackables) do
			local trackable = defaults[type]
			self:AddTrackable(id, type, self:LoadTrackableName(id, type), nil, trackable.frequency, CHARACTERS_ALL, trackable.quantity)
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
	for type, event in pairs(events) do
		self:RegisterEvent(event.event, event.callback, event.event)
	end
end

function GetErDone:handleEventMonster(event) 
	if event == "LOOT_OPENED" then
		local numItems = GetNumLootItems()
		for slotId = 1, numItems, 1 do
			local mobList = { GetLootSourceInfo(slotId) }
			local itemId = self:getItemIdFromLink(GetLootSlotLink(slotId))
			self:checkEvent(itemId, TYPE_ITEM)
			-- create set to deal with duplicate items
			local mobSet = self:createSet(self:getSpawnUidIdPairs(mobList))
			for k, v in pairs(mobSet) do
				local id, type = self:fromMergedId(v)
				if type == TYPE_VEHICLE then
					type = TYPE_MONSTER
				end
				self:checkEvent(id, type)
			end
		end
	end
end

function GetErDone:handleEventSpell(event, ...)
	if event == "UNIT_SPELLCAST_SUCCEEDED" then
		local _, unit, _, _, _, spellId = ...
		if unit == UNIT_PLAYER then
			local d = debugMode
			debugMode = false
			self:checkEvent(tostring(spellId), TYPE_SPELL)
			debugMode = d
		end
	end
end

function GetErDone:handleEventItem(event)
	-- nil
end

local questCompleteList = {}

function GetErDone:handleEventQuest(event)
	if event == "QUEST_COMPLETE" then
		local questCompleteList = {} -- blank out the current quests that are to be completed
		local quests = { GetGossipAvailableQuests() }
	end
	-- TODO finish lol
end

function GetErDone:checkEvent(id, type)
	if id == nil then return end
	self:debug("Checking " .. type .. " id " .. id .. " for completion...")
	if not self:IsNullOrEmpty(self.db.global.trackables[id]) and not self:IsNullOrEmpty(self.db.global.trackables[id][type]) then
		self:CompleteTrackable(id, type, COMPLETE_INCREMENT)
	end
end


-----------------------------------------------------------------
--------------------- GED TREE TO ACE TREE ----------------------
-----------------------------------------------------------------

local aceTree = {}
local aceTreeCharacter = {}

function GetErDone:invalidateAceTree()
	aceTree = {}
	aceTreeCharacter = {}
end

----------------- normal tree -----------------

function GetErDone:getAceTree(showAll)
	if not self:IsNullOrEmpty(aceTree) then
		return aceTree
	end

	for k, topLevelCompoundId in pairs(self:getUnownedCompounds()) do
		table.insert(aceTree, { value = topLevelCompoundId, text = self:createCompoundTextForAceTree(topLevelCompoundId), 
					visible = self:getTreeDisplay(topLevelCompoundId, nil, showAll), children = self:createAceTree(topLevelCompoundId, showAll) } )
	end

	for k, merged in pairs(self:getUnownedTrackables()) do
		local id, type = self:fromMergedId(merged)
		local trackable = self:createTrackableTree(id, type, showAll)
		table.insert(aceTree, trackable)
	end

	return aceTree
end

function GetErDone:createAceTree(compound_id, showAll)
	local tree = {}
	for k, child_id in pairs(self.db.global.compounds[compound_id].comprisedOf) do
		if self:isCompoundId(child_id) then
			table.insert(tree, { value = child_id, text = self:createCompoundTextForAceTree(child_id), visible = self:getTreeDisplay(child_id, nil, showAll), children = self:createAceTree(child_id, showAll) } )
		else
			table.insert(tree, self:createTrackableTree(child_id.id, child_id.type))
		end
	end
	return tree
end

function GetErDone:createTrackableTree(id, type, showAll)
	local characters = {}
	local visibleVar = self:getTreeDisplay(id, type, showAll, character)
	for character, v in pairs(self.db.global.trackables[id][type].characters) do
		table.insert(characters, { value = character, text = self:createCharacterCompletionText(id, type, character), visible = visibleVar })
	end
	if self:IsNullOrEmpty(characters) then characters = nil end
	local trackable = { value = self:toMergedId(id, type), text = self:createTrackableTextForAceTree(id, type), 
						visible = visibleVar, children = characters}
	return trackable
end

function GetErDone:getTreeDisplay(id, type, showAll)
	if showAll then return true end

	local item
	if type == nil then 
		item = self.db.global.compounds[id]
	else
		item = self.db.global.trackables[id][type]
	end

	-- active check
	if not item.active then
		return false
	end

	-- completion check
	if self:IsCompleteOnAllCharacters(id, type) then
		return false
	end

	-- displayChildren check
	if item.ownedBy ~= "" then
		if self.db.global.compounds[item.ownedBy].displayChildren ~= nil then -- default to true
			return self.db.global.compounds[item.ownedBy].displayChildren
		end
	end

	return true
end

function GetErDone:createTrackableTextForAceTree(id, type)
	local trackable = self.db.global.trackables[id][type]
	return trackable.name
end

------------------- character tree ---------------------

function GetErDone:getAceTreeCharacter(showAll, character)
	if not self:IsNullOrEmpty(aceTreeCharacter) then
		return aceTreeCharacter
	end

	if character == CHARACTERS_ALL then
		for char, v in pairs(self.db.global.characters) do
			self:getAceTreeCharacterPrivate(showAll, char)
		end
	else
		self:getAceTreeCharacterPrivate(showAll, character)
	end

	return aceTreeCharacter
end

-- do not call this directly
function GetErDone:getAceTreeCharacterPrivate(showAll, character)
	for k, topLevelCompoundId in pairs(self:getUnownedCompounds()) do
		local visibleVar = self:getTreeDisplayCharacter(topLevelCompoundId, nil, showAll, character)
		if visibleVar then 
			table.insert(aceTreeCharacter, { value = topLevelCompoundId, text = self:createCompoundTextForAceTree(topLevelCompoundId), 
				children = self:createAceTreeCharacter(topLevelCompoundId, showAll, character) } )
		end
	end
	for k, merged in pairs(self:getUnownedTrackables()) do
		local id, type = self:fromMergedId(merged)
		local trackable = self:createTrackableTreeCharacter(id, type, showAll, character)
		if trackable ~= nil then
			table.insert(aceTreeCharacter, trackable)
		end
	end
end

function GetErDone:createAceTreeCharacter(compound_id, showAll, character)
	local tree = {}
	for k, child_id in pairs(self.db.global.compounds[compound_id].comprisedOf) do
		if self:isCompoundId(child_id) then
			local visibleVar = self:getTreeDisplayCharacter(child_id, nil, showAll, character)
			if visibleVar then
				table.insert(tree, { value = child_id, text = self:createCompoundTextForAceTree(child_id), children = self:createAceTreeCharacter(child_id, showAll, character) } )
			end
		else
			local trackable = self:createTrackableTreeCharacter(child_id.id, child_id.type, showAll, character)
			if trackable ~= nil then
				table.insert(tree, trackable)
			end
		end
	end
	return tree
end

function GetErDone:createTrackableTreeCharacter(id, type, showAll, character)
	local visibleVar = self:getTreeDisplayCharacter(id, type, showAll, character)
	if not visibleVar then return end

	return { value = self:toMergedId(id, type), text = self:createTrackableTextForAceTreeCharacter(id, type, character)}
end

function GetErDone:getTreeDisplayCharacter(id, type, showAll, character)
	if showAll then return true end
	local item
	if type == nil then 
		item = self.db.global.compounds[id]
	else
		item = self.db.global.trackables[id][type]
	end

	if item == nil then
		return false
	end

	-- active check
	if not item.active then
		return false
	end

	-- completion check
	if self:IsComplete(id, type, character) then
		return false
	end

	-- displayChildren check
	if item.ownedBy ~= "" then
		if self.db.global.compounds[item.ownedBy].displayChildren ~= nil then -- default to true
			return self.db.global.compounds[item.ownedBy].displayChildren
		end
	end

	return true
end

function GetErDone:createTrackableTextForAceTreeCharacter(id, type, character)
	local trackable = self.db.global.trackables[id][type]
	local name = self.db.global.characters[character].name
	if self:isDuplicateName(name) then
		name = name .. " (" .. self.db.global.characters[character].server .. ")"
	end
	local completion = trackable.characters[character] .. "/" .. trackable.completionQuantity
	return self:padTrackableName(trackable.name, completion)
end

----------------- shared ----------------------

function GetErDone:padTrackableName(name, completion)
	local len = TREE_CHARACTER_STRING_LENGTH - #(name) - #(completion)
	return name .. string.rep(" ", len) .. completion
end

function GetErDone:createCharacterCompletionText(id, type, character) 
	local trackable = self.db.global.trackables[id][type]
	return character .. " " .. tostring(trackable.characters[character]) .. "/" .. trackable.completionQuantity
end

function GetErDone:createCompoundTextForAceTree(compound_id)
	local compound = self.db.global.compounds[compound_id]
	return compound.name
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

	self:debug("Completing trackable " .. id .. " with status: " .. status)

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

	self:invalidateAceTree()
	self:updateUI()
end

function GetErDone:IsComplete(id, type, character)
	if type == nil then
		return self:IsCompoundComplete(id, character)
	else
		return self:IsTrackableComplete(id, type, character)
	end
end

function GetErDone:IsCompleteOnAllCharacters(id, type)
	for character, v in pairs(self.db.global.characters) do
		if type == nil then
			if not self:IsCompoundComplete(id, character) then
				return false
			end
		else
			if not self:IsTrackableComplete(id, type, character) then
				return false
			end
		end
	end
	return true
end

function GetErDone:IsCompoundComplete(compound_id, character)
	local compound = self.db.global.compounds[compound_id]
	if not compound.active then return false end

	if self:IsCompletionCached(compound_id, character) then
		return self:GetCompletionCache(compound_id, character)
	end

	local completionPoint = compound.childCompletionQuantity
	if completionPoint == 0 then
		completionPoint = #(compound.comprisedOf)
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

		if completedCount >= completionPoint then
			self:AddToCompletionCache(compound_id, character, true)
			return true
		end
	end

	-- incomplete
	self:AddToCompletionCache(compound_id, character, false)
	return false
end

function GetErDone:IsTrackableComplete(id, type, character)
	local trackable = self.db.global.trackables[id][type]
	if trackable.active == nil then error("IsTrackableComplete: null active") end
	if not trackable.active then return true end -- note changed this from false
	if trackable.characters[character] == nil then return true end -- this too

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
			if not self:ResetCompare(newReset, trackable.reset) then
				self:debug("Updating reset and completion on trackable " .. id .. ":" .. type)
				trackable.reset = newReset
				self:CompleteTrackable(id, type, COMPLETE_ZERO)
			end
		end
	end
end

function GetErDone:ResetCompare(a, b)
	if a == nil or b == nil then
		error("ResetEquals: null reset")
	end

	if a.year > b.year then return false end
	if a.month > b.month then return false end
	if a.day > b.day then return false end
	if a.hour > b.hour then return false end
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


--------------------------------------------------------------------
--------------------------- DELETION -------------------------------
--------------------------------------------------------------------

function GetErDone:delete(id, type)
	if type == nil then
		self:deleteCompound(id)
	else
		self:deleteTrackable(id, type)
	end
end

function GetErDone:deleteCompound(compound_id)
	local compound = self.db.global.compounds[compound_id]
	if compound == nil then return end
	local children = compound.comprisedOf
	if children ~= "" then
		for k, child_id in pairs(children) do
			if self:isCompoundId(child_id) then
				self:deleteCompound(child_id)
			else
				self:deleteTrackable(child_id.id, child_id.type)
			end
		end
	end

	self.db.global.compounds[compound_id] = nil
end

function GetErDone:deleteTrackable(id, type)
	self.db.global.trackables[id][type] = nil
	if self:IsNullOrEmpty(self.db.global.trackables[id]) then
		self.db.global.trackables[id] = nil
	end
end

--------------------------------------------------------------------
----------------------- UTIL METHODS -------------------------------
--------------------------------------------------------------------

-- Takes a list of GUIDs and splits them into { [spawn_uid] = [mob_id] }
-- spawn_uid uniquely identifies the particular mob
function GetErDone:getSpawnUidIdPairs(moblist)
	local ret = {}
	for k, guid in pairs(moblist) do
		local type, mob_id, spawn_uid = self:getNpcId(guid)
		if mob_id ~= 0 and spawn_uid ~= nil then
			ret[spawn_uid] = self:toMergedId(mob_id, type)
		end
	end 
	return ret
end

function GetErDone:isDuplicateName(name)
	local matchesFound = 0
	for dbname, nameServerPair in pairs(self.db.global.characters) do
		if nameServerPair.name == name then
			-- we allow one match, since we'll obviously find the character we're searching for
			if matchesFound == 1 then 
				return true
			end
			matchesFound = matchesFound + 1
		end
	end
end

-- creates a set where the keys are unique
-- the values can be whatever you like, they won't get checked
-- uses == for equality testing - so probably don't use on anything with a table as a key
function GetErDone:createSet(dict)
	local set = {}
	for k, v in pairs(dict) do
		local add = true
		for kCheck, vCheck in pairs(set) do
			if kCheck == k then 
				add = false
				break
			end
		end

		if add then
			set[k] = v
		end
	end
	return set
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
	if dict == nil or value == nil then 
		error("contains: null table or value")
	end
	for k, v in pairs(dict) do
		if value == v then return true end
	end
	return false
end

function GetErDone:getNpcId(guid)
	--  [Unit type]-0-[server ID]-[instance ID]-[zone UID]-[ID]-[Spawn UID]
	if guid then
		local unit_type, _, server_id, instance_id, zone_uid, mob_id, spawn_uid = strsplit('-', guid)
		return unit_type, mob_id, spawn_uid
	end
	return 0
end

function GetErDone:getItemIdFromLink(link)
	if link ~= nil then
		local _, _, Color, Ltype, Id, Enchant, Gem1, Gem2, Gem3, Gem4, Suffix, Unique, LinkLvl, reforging, Name = string.find(link, "|?c?f?f?(%x*)|?H?([^:]*):?(%d+):?(%d*):?(%d*):?(%d*):?(%d*):?(%d*):?(%-?%d*):?(%-?%d*):?(%d*):?(%d*)|?h?%[?([^%[%]]*)%]?|?h?|?r?")
	end
	return Id
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

-- only works on tables
function GetErDone:IsNullOrEmpty(dict)
	return dict == nil or next(dict) == nil
end

function GetErDone:toMergedId(id, type)
	if type == nil then
		return id.id .. MERGED_DELIMITER .. id.type
	end
	return id .. MERGED_DELIMITER .. type
end

function GetErDone:fromMergedId(merged)
	return strsplit(MERGED_DELIMITER, merged)
end

----------------------------------------------------------------
------------------ UI FUNCTIONS THAT SHOULDNT BE ---------------
----------------------------------------------------------------

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
	local children = {}
	local compound = self.db.global.compounds[owner]
	if compound == nil then return children end
	if compound.comprisedOf == nil then return children end
	for k, id in pairs(compound.comprisedOf) do
		if not self:isCompoundId(id) then
			table.insert(children, id)
		end
	end
	return children
end

--Name is a little ambiguous, this is the equivalent of "getTrackableChildren"
--@owner = compoundid
function GetErDone:getCompoundChildren(owner)
	if owner == "" or owner == nil then
		return self:getUnownedCompounds()
	else
		local children = {}
		local compound = self.db.global.compounds[owner]
		if compound == nil then return children end
		if compound.comprisedOf == nil then return children end
		for k, id in pairs(compound.comprisedOf) do
			if self:isCompoundId(id) then
				table.insert(children, id)
			end
		end
		return children
	end
end

function GetErDone:getUnownedCompounds()
	local t = {}
	for k,v in pairs(self.db.global.compounds) do
		if v.ownedBy == "" then
			table.insert(t,k)
		end
	end
	return t
end

function GetErDone:getUnownedTrackables()
	local t = {}
	for id, v in pairs(self.db.global.trackables) do
		for type, vv in pairs(v) do
			if vv.ownedBy == "" then
				table.insert(t, self:toMergedId(id, type))
			end
		end
	end
	return t
end


function GetErDone:getCharacters()
	local t = {["All"] = CHARACTERS_ALL}
	for k, v in pairs(GetErDone:GetOption("characters")) do
		t[k] = k
	end
	return t
end

function GetErDone:getIndent(n)
	return string.rep(NESTING_INDENT, n)
end


-----------------------------------------------------
------------------ IGNORE NAMES ---------------------
-----------------------------------------------------

function GetErDone:addIgnoredName(name)
	self.db.global.options.ignoredNames[name] = true
end

function GetErDone:removeIgnoredName(name)
	self.db.global.options.ignoredNames[name] = nil
end

function GetErDone:isNameIgnored(name)
	local dbname = self.db.global.options.ignoredNames[name]
	if dbname ~= nil and dbname == true then
		return false
	end
	return true
end

function GetErDone:getAvailableNames()
	local names = {}
	for name, v in pairs(self.db.global.characters) do
		if not self:isNameIgnored(name) then
			table.insert(names, name)
		end
	end
	return names
end

---------------------------------UI CODE-------------------------------------------

function GetErDone:testui()
	local f = AceGUI:Create("Frame")
	local leftLabelgroup = {}

	self.db.global.options.optCompound = ""

	f:SetCallback("OnClose",function(widget) AceGUI:Release(widget) end)
	f:SetTitle("Options")
	f:SetLayout("Flow")
	f:SetHeight(800)

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
			self.db.global.options.compoundquantity = ""
			self.db.global.options.newCompoundName = ""
			widgetManager["buttonCompound"]:SetDisabled(true)
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

	buttonCompound:SetDisabled(true)

--- New Trackable Interface ---

	local newTrackableGroup = AceGUI:Create("InlineGroup")
	local trackableType = AceGUI:Create("Dropdown")
	local trackableID = AceGUI:Create("EditBox")
	local trackableName = AceGUI:Create("EditBox")
	local trackableSpacer = AceGUI:Create("Heading")
	local trackableCharacter = AceGUI:Create("Dropdown")
	local trackableFrequency = AceGUI:Create("Dropdown")
	local addTrackableButton = AceGUI:Create("Button")
	local trackableQuantity = AceGUI:Create("EditBox")


	addTrackableButton:SetText("Add ID")
	addTrackableButton:SetCallback("OnClick", 
		function(widget, event) self:AddTrackable(
				self.db.global.options.trackableID, 
				self.db.global.options.typechoice, 
				self.db.global.options.trackablename,
				self.db.global.options.optCompound,
				self.db.global.options.frequency,
				self.db.global.options.character, -- TODO multiple name selection
				self.db.global.options.quantity
			) 
			widgetManager["addTrackableButton"]:SetDisabled(true)
		end)

	trackableSpacer:SetText("")

	trackableName:SetText("")
	trackableName:SetCallback("OnEnterPressed", function(widget, event, text) self:submitTrackableNameEdit(widget, event, text) end)

	trackableID:SetCallback("OnEnterPressed", function(widget, event, text) 
		self:submitIDEdit(widget, event, text) 
	end)
	trackableID:SetLabel("ID")

	trackableType:SetList(TYPE_LIST)
	trackableType:SetCallback("OnValueChanged", function(widget, event, key) 
		self:getTrackableTypeDropdown(widget, event, key) 
	end)
	trackableType:SetLabel("Type")
	trackableType:SetValue(self.db.global.options.typechoice)

	trackableFrequency:SetList({["daily"] = "Daily", ["weekly"] = "Weekly", ["monthly"] = "Monthly", ["once"] = "Once"})
	trackableFrequency:SetCallback("OnValueChanged", function(widget, event, key) self:getTrackableFrequencyDropdown(widget, event, key) end)
	trackableFrequency:SetLabel("Frequency")
	trackableFrequency:SetValue(self.db.global.options.frequency)

	trackableCharacter:SetList(self:getCharacters())
	trackableCharacter:SetCallback("OnValueChanged", function(widget, event, key) self:getTrackableCharacterDropdown(widget, event, key) end)
	trackableCharacter:SetLabel("Character")
	trackableCharacter:SetValue(self.db.global.options.character)

	trackableQuantity:SetCallback("OnEnterPressed", function(widget, event, text) self:getTrackableQuantity(widget, event, text) end)
	trackableQuantity:SetLabel("Quantity")

	newTrackableGroup:SetRelativeWidth(0.5)
	newTrackableGroup:SetLayout("List")

	addTrackableButton:SetDisabled(true)


	f:AddChild(newCompoundGroup)
	newCompoundGroup:AddChild(compoundSelectionLabel)
	newCompoundGroup:AddChild(editCompound) 
	newCompoundGroup:AddChild(compoundQuantity)
	newCompoundGroup:AddChild(compoundChildrenToggle) 
	newCompoundGroup:AddChild(buttonCompound)
	

	f:AddChild(newTrackableGroup)
	newTrackableGroup:AddChild(trackableType)
	newTrackableGroup:AddChild(trackableID)
	newTrackableGroup:AddChild(trackableName)
	--newTrackableGroup:AddChild(trackableSpacer)
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
	["buttonCompound"] = buttonCompound,
	["addTrackableButton"] = addTrackableButton
	}

	f:DoLayout() --HOLY MOTHERFUCKING SHIT IS THIS LINE IMPORTANT

	
end

function GetErDone:buttonCheck(t)
	if t == "compound" then
		if self.db.global.options.newCompoundName ~= "" and
			self.db.global.options.compoundquantity ~= "" then
			widgetManager["buttonCompound"]:SetDisabled(false)
		end
	elseif t == "trackable" then
		if self.db.global.options.trackableid ~= "" and
			self.db.global.options.typechoice ~= "" and
			self.db.global.options.frequency ~= "" and
			self.db.global.options.character ~= "" and
			self.db.global.options.quantity ~= "" then
			widgetManager["addTrackableButton"]:SetDisabled(false)
		end
	end
end


function GetErDone:refreshTrackableList()
	widgetManager["trackableFrame"]:ReleaseChildren()
	for k, v in pairs(self:getTrackableChildren(self.db.global.compounds[self.db.global.options.optCompound])) do
		local label = AceGUI:Create("InteractiveLabel")
		label:SetText(self.db.global.trackables[k][v].name)
		label:SetHighlight(.5, .5, 0, .5)
		label:SetCallback("OnClick", function(widgetx) self:clickTrackableLabel(widgetx, {k, v}) end)
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
		if self.db.global.compounds[v] == self.db.global.compounds[self.db.global.options.optCompound] then label:SetColor(1, 0, 0) end
		widgetManager["compoundFrame"]:AddChild(label)
		self:createCompoundTree(v)
	end
end

function GetErDone:clickGroupLabel(widget, compoundID, isUp)
	widgetManager["trackableFrame"]:ReleaseChildren()
	widgetManager["compoundFrame"]:ReleaseChildren()

	self.db.global.options.optCompound = compoundID
	self:refreshCompoundList()

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
	GetErDone:buttonCheck("compound")
end

function GetErDone:getTrackableTypeDropdown(widget, event, key)
	self.db.global.options.typechoice = key
	self:setTrackableTypeDropdown(widget)
end

function GetErDone:setTrackableTypeDropdown(widget)
	widget:SetValue(self.db.global.options.typechoice)
	GetErDone:buttonCheck("trackable")
end

function GetErDone:getTrackableFrequencyDropdown(widget, event, key)
	self.db.global.options.frequency = key
	self:setTrackableFrequencyDropdown(widget)
end

function GetErDone:setTrackableFrequencyDropdown(widget)
	widget:SetValue(self.db.global.options.frequency)
	GetErDone:buttonCheck("trackable")
end

function GetErDone:getTrackableCharacterDropdown(widget, event, key)
	self.db.global.options.character = key
	self:setTrackableCharacterDropdown(widget)
end

function GetErDone:setTrackableCharacterDropdown(widget)
	widget:SetValue(self.db.global.options.character)
	GetErDone:buttonCheck("trackable")
end

function GetErDone:submitIDEdit(widget, event, text)
	if string.match(text, '%d') then
		self.db.global.options.trackableID = text
	end
	self:populateIDEdit(widget)
end

function GetErDone:submitTrackableNameEdit(widget, event, text)
	self.db.global.options.trackablename = text
	print(text)
	print(event)
	widget:SetText(text)
	GetErDone:buttonCheck("trackable")
end

function GetErDone:populateIDEdit(widget)
	widget:SetText(self.db.global.options.trackableID)
	GetErDone:buttonCheck("trackable")
end

function GetErDone:getTrackableQuantity(widget, event, text)
	if string.match(text, '%d') then
		self.db.global.options.quantity = text
	end
	self:setTrackableQuantity(widget)
end

function GetErDone:setTrackableQuantity(widget)
	widget:SetText(self.db.global.options.quantity)
	GetErDone:buttonCheck("trackable")
end

function GetErDone:submitCompoundEdit(widget, event, text)
	self.db.global.options.newCompoundName = text
	self:populateCompoundEdit(widget)
end

function GetErDone:populateCompoundEdit(widget)
	widget:SetText(self.db.global.options.newCompoundName)
	GetErDone:buttonCheck("compound")
end

function GetErDone:createIngameList()
    local f = AceGUI:Create("Frame")
    f:SetCallback("OnClose",function(widget) AceGUI:Release(widget) end)
    f:SetLayout("Fill")
    f:SetHeight(800)
    

    local mainTree = AceGUI:Create("TreeGroup")
    mainTree:SetTree(self:getAceTree(false))

    local gayTree = AceGUI:Create("Button")
   
    mainTree:AddChild(gayTree)

    f:AddChild(mainTree)

    widgetManager["mainTree"] = mainTree
end

function GetErDone:createIngameListChar()
    local f = AceGUI:Create("Frame")
    f:SetCallback("OnClose",function(widget) AceGUI:Release(widget) end)
    f:SetLayout("Fill")
    f:SetHeight(800)
    
    local mainTree = AceGUI:Create("TreeGroup")
    mainTree:SetTree(self:getAceTreeCharacter(false, self.db.global.character))
    
    f:AddChild(mainTree)
    
    widgetManager["mainTreeChar"] = mainTree
end

function GetErDone:redrawUi()
	local f = CreateFrame("Frame", "GetErDoneTracker", UIParent)
	f:SetWidth(400)
	f:SetHeight(1000)
	f:SetMovable(true)
	f:EnableMouse(true)
	f:SetHitRectInsets(0,0,0,975)
	f:RegisterForDrag("LeftButton")
	f:SetClampedToScreen(true) -- don't let it be dragged off the screen
	f:SetScript("OnDragStart", f.StartMoving)
	f:SetScript("OnDragStop", function() GetErDone:saveUiPosition() end)
	if self.db.global.options.uipositionx ~= nil and self.db.global.options.uipositiony ~= nil and self.db.global.options.uipositionpoint ~= nil then
		f:SetPoint(self.db.global.options.uipositionpoint, self.db.global.options.uipositionx, self.db.global.options.uipositiony)
	else
		f:SetPoint("LEFT", 0, 0)
	end

	topIndicator = CreateFrame("Frame", "GEDTrackerDragIndicator", f)
	topIndicator:SetWidth(20)
	topIndicator:SetHeight(20)
	topIndicator:SetPoint("TOPRIGHT", 0, 0)
	topIndicator:SetBackdrop({
		bgFile = "Interface\\DialogFrame\\UI-DialogBox-Gold-Background",
		})

	titlefontstring = f:CreateFontString("TestString", "ARTWORK","GameFontNormal") --GameFontWhite
	titlefontstring:SetText("Get Er Done")
	titlefontstring:SetPoint("TOPLEFT", 0, -10)
	titlefontstring:SetHeight(100)
	titlefontstring:SetWidth(200)

	frameManager["f"] = f
	frameManager["previousString"] = titlefontstring

	self:generateIngameCompoundTree("")
end

function GetErDone:saveUiPosition()
	local ui = frameManager.f
	if ui == nil then error("saveUiPosition: null frame") end

	ui:StopMovingOrSizing()

	local point, _, _, x, y = ui:GetPoint()
	self.db.global.options.uipositionpoint = point
	self.db.global.options.uipositionx = floor(x + 0.5) -- round
	self.db.global.options.uipositiony = floor(y + 0.5)
end

function GetErDone:createTestInGameList()
	if frameManager["f"] ~= nil then
		if frameManager["f"]:IsShown() then
			frameManager["f"]:Hide()
			return
		end
	end
	self:redrawUi()
end

local textFrames = {}

function GetErDone:generateIngameCompoundTree(compoundid)
	if frameManager.f == nil then return end -- if we're calling before we've loaded the ui for the first time - on login, usually
	local children = self:getCompoundChildren(compoundid)
	local character = self.db.global.character -- TODO make this selectable

	for k, child_compound_id in pairs(children) do
		if self:getTreeDisplayCharacter(child_compound_id, nil, false, character) then
			local tempString = frameManager["f"]:CreateFontString(child_compound_id, "ARTWORK", "GameFontNormal")
			tempString:SetText(self:getIndent(self:compoundNumParents(child_compound_id)) .. self.db.global.compounds[child_compound_id].name)
			tempString:SetPoint("BOTTOM", frameManager["previousString"], 0, -20, 0)
			tempString:SetHeight(20)
			tempString:SetWidth(300)
			tempString:SetJustifyH("LEFT")

			-- create the invisible button
			local button = CreateFrame("Button", child_compound_id, frameManager.f)
			button:SetHeight(30)
        	button:SetNormalTexture("Interface\\Addons\\GetErDone\\textures\\clear.tga", "BLEND")
        	button:SetHighlightTexture("Interface\\Addons\\GetErDone\\textures\\highlight.tga", "BLEND")
        	button:SetPushedTexture("Interface\\Addons\\GetErDone\\textures\\highlight.tga", "BLEND")
			button:SetWidth(tempString:GetStringWidth() * 2)
			local point, relativeTo, relativePoint, xOfs, yOfs = tempString:GetPoint()
			button:SetPoint("TOPLEFT", relativeTo, relativePoint, 0 - (tempString:GetWidth() / 2) - 15, 4) -- shuffle button to the left so it's on top of the text
			button:SetBackdropColor(0, 0, 0, 0) -- seethrough
			button:SetBackdropBorderColor(0, 0, 0, 0) -- seethrough
			button:RegisterForClicks("AnyUp")
			button:SetFrameStrata("MEDIUM")
			button:SetScript("OnClick", function() GetErDone:uiCompoundToggle(child_compound_id) end)
			button:SetAlpha(0.5)
			button:Enable()

			frameManager["previousString"] = tempString
			textFrames[child_compound_id] = tempString

			for kk, child_id in pairs(self.db.global.compounds[child_compound_id].comprisedOf) do
				if not self:isCompoundId(child_id) and self:uiShowCompound(child_compound_id) then
					if self:getTreeDisplayCharacter(child_id.id, child_id.type, false, character) then
						tempString = frameManager["f"]:CreateFontString(child_compound_id, "ARTWORK", "GameFontWhite")
						tempString:SetText(self:getIndent(self:compoundNumParents(child_compound_id))  .. NESTING_INDENT .. self.db.global.trackables[child_id.id][child_id.type].name or "test")
						tempString:SetPoint("BOTTOM", frameManager["previousString"], 0, -15, 0)
						tempString:SetHeight(15)
						tempString:SetWidth(300)
						tempString:SetJustifyH("LEFT")
						tempString:SetShadowOffset(1,-1)
						frameManager["previousString"] = tempString
						textFrames[self:toMergedId(child_id)] = tempString
					end
				end
			end
			if self:uiShowCompound(child_compound_id) then
				self:generateIngameCompoundTree(child_compound_id)
			end
		end
	end
end

function GetErDone:updateUI()
	if frameManager.f ~= nil then
		frameManager.f:Hide()
		frameManager.f = nil
		self:redrawUi()
	end
end

local compoundsNotToShow = {}

function GetErDone:uiShowCompound(compound_id)
	return compoundsNotToShow[compound_id] == nil
end

function GetErDone:uiCompoundSetShow(compound_id)
	compoundsNotToShow[compound_id] = nil
end

function GetErDone:uiCompoundSetHide(compound_id)
	compoundsNotToShow[compound_id] = 1
end

function GetErDone:uiCompoundToggle(compound_id)
	if self:uiShowCompound(compound_id) then
		self:uiCompoundSetHide(compound_id)
	else
		self:uiCompoundSetShow(compound_id)
	end
	self:updateUI()
end

function GetErDone:collapseUIToTopLevel()
	for k, compound_id in pairs(self:getCompoundChildren("")) do
		self:uiCompoundSetHide(compound_id)
	end
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
				["hour"] = 4,
				["day"] = 11,
				["month"] = 11,
				["year"] = 2013,
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

	self.db.global.trackables["resettest"] = nil
end

function GetErDone:test_increment()
	local incrementtest = { 
		["incrementtest"] = { 
			["name"] = "test",
			["ownedBy"] = "",
			["reset"] = { 
				["hour"] = 4,
				["day"] = 11,
				["month"] = 11,
				["year"] = 2013,
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

	self.db.global.trackables["incrementtest"] = nil
end


function GetErDone:testeventkill()
	local guid1 = "Creature-0-1403-870-139-1-0000D2B633"
	local guid2 = "Creature-0-1403-870-139-2-0000D2B633"
	--self:checkEvent(guid1TYPE_MONSTER, )
	--self:checkEvent(TYPE_MONSTER, guid2)
end

function GetErDone:testeventkill_one()
	self.db.global.test = {["test"] = "a"}
	local t = self.db.global.test
	t.test = "b"
	self:debug(self.db.global.test.test)
	self.db.global.test = nil
end

function GetErDone:addThing()
	
end

function GetErDone:test_completion()
	local trackable_incomplete = { 
		["trackable_incomplete"] = { 
			["name"] = "trackable_incomplete",
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
			["name"] = "trackable_complete",
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
			["name"] = "trackable_inactive",
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
			["name"] = "compound_one_complete",
			["active"] = true,
			["comprisedOf"] = {
				{["id"] = "trackable_complete", ["type"] = "trackable_complete"},
			},
			["ownedBy"] = "",
			["displayChildren"] = true,
			["childCompletionQuantity"] = 1,
	}
	local compound_half_complete = {
			["name"] = "compound_half_complete",
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
			["name"] = "compound_quantity_two",
			["active"] = true,
			["comprisedOf"] = {
				{["id"] = "trackable_complete", ["type"] = "trackable_complete"},
				{["id"] = "trackable_incomplete", ["type"] = "trackable_incomplete"},
			},
			["ownedBy"] = "",
			["displayChildren"] = true,
			["childCompletionQuantity"] = 2,
	}
	local compound_compound = {
			["name"] = "compound_compound",
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
			["name"] = "compound_mixed",
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

	if not self:IsTrackableComplete("trackable_inactive", "trackable_inactive", character) then
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


	self.db.global.trackables["trackable_incomplete"] = nil
	self.db.global.trackables["trackable_complete"] = nil
	self.db.global.trackables["trackable_inactive"] = nil
	self.db.global.compounds["compound_one_complete"] = nil
	self.db.global.compounds["compound_half_complete"] = nil
	self.db.global.compounds["compound_quantity_two"] = nil
	self.db.global.compounds["compound_compound"] = nil
	self.db.global.compounds["compound_mixed"] = nil

end

function GetErDone:uitest_set()
	local t = { 
		["t"] = { 
			["name"] = "trackable_inactive",
			["ownedBy"] = "default_2",
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
	self.db.global.trackables["1"] = t
	table.insert(self.db.global.compounds["default_2"].comprisedOf, { ["id"] = "1", ["type"] = "t" })
end

function GetErDone:uitest_test()
	self:CompleteTrackable("1", "t", COMPLETE_INCREMENT)
end