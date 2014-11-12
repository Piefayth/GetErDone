-- roadmap goals
-- 
-- lock button
-- QUEST HANDLING IN ITS ENTIRITY
-- 

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
	{ ["event"] = "COMBAT_LOG_EVENT_UNFILTERED", ["callback"] = "handleEventCombatLog" },
}

options = {
	name = "Get Er Done",
	type = 'group',
	cmdInline = true,
	args = {
		debug = {
			order = 50,
			type = "execute",
			name = "toggle debug",
			desc = "",
			func = function() 
				print("debug disabled")
				debugMode = false --TODO change to true 
			end,
			hidden = true,
		},
		options = {
			order = 98,
			type = "execute",
			name = "options",
			desc = "Options Menu",
			func = function() GetErDone:createIngameList() end,
			hidden = false,
		},
		testtreechar = {
			order = 98,
			type = "execute",
			name = "testtreechar",
			desc = "",
			func = function() GetErDone:createIngameListChar() end,
			hidden = true,
		},
		ui = {
			order = 1000,
			type = "execute",
			name = "ui",
			desc = "Show/Hide the UI",
			func = function() 
				GetErDone.db.global.options.showui = true
				GetErDone:createTestInGameList()
			end,
		},
	}
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
EVENT_LEFT_BUTTON = "LeftButton"
EVENT_RIGHT_BUTTON = "RightButton"
CHARACTER_BUTTON_LEFT = 1
CHARACTER_BUTTON_RIGHT = 2
COMPOUND_TREE_ROOT_ELEMENT = "top_level"
UI_CLOSED_STRING = "Get Er Done UI closed. To show again, type\n/ged ui"
debugMode = true -- TODO change to false



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
	self:InvalidateCompletionCache(COMPLETION_CACHE_ALL_CHARACTERS)
	self:updateUI()
	return true
end


function GetErDone:prepareCharacters(id, trackable_type, characters)
	if self.db.global.trackables[id][type] == nil then
		-- adding fresh
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
	else
		local chars = self.db.global.trackables[id][trackable_type].characters
		if type(characters) ~= "table" then return { [characters] = 0 } end
		if characters == CHARACTERS_ALL then
			for name, v in pairs(self.db.global.characters) do
				if chars[name] == nil then
					chars[name] = 0
				end
			end
		else
			for name, v in pairs(characters) do
				if chars[name] == nil then
					chars[name] = 0
				end
			end
		end
		return chars
	end
end

function GetErDone:isCompoundId(id)
	--Modified slightly to deal with the OnGroupSelect workaround, I'm getting Trackable IDs as "12345:Butts"
	if type(id) == "table" then
		return false
	elseif string.match(id, '%d+:%a+') then 
		return false
	elseif self.db.global.characters[id] ~= nil then
		return false
	else
		return type(id) == "string"
	end
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
	if self.db.global.trackables[id] ~= nil and self.db.global.trackables[id][type] ~= nil then
		print("GetErDone: trackable updated. Please ensure this was the intended operation.")
	end

	if self.db.global.trackables[id] ~= nil and self.db.global.trackables[id][type] ~= nil and self.db.global.trackables[id][type].ownedBy ~= owner then
		print("GetErDone: attempted to change owner of a trackable. Disallowed operation; cancelling.")
		return
	end

	self:ensureTrackable(id)
	self.db.global.trackables[id][type] = {
			["active"] = true,
			["name"] = name,
			["ownedBy"] = owner,
			["frequency"] = frequency,
			["reset"] = self:NextReset(frequency, self.db.global.region),
			["characters"] = self:prepareCharacters(id, type, characters),
			["completionQuantity"] = tonumber(quantity)
    }


    self:updateOwner(owner, id, type)

    --self:refreshTrackableList()
	self:invalidateAceTree()
	self:InvalidateCompletionCache(COMPLETION_CACHE_ALL_CHARACTERS)
	self:updateUI()

    --Zero Out Options Fields--
	self.db.global.options.quantity = ""
	self.db.global.options.trackableID = ""
	self.db.global.options.trackablename = ""

	widgetManager["trackableID"]:SetText("")
	widgetManager["trackableQuantity"]:SetText("")
	widgetManager["trackableName"]:SetText("")
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
		if not self:containsTrackable(owner.comprisedOf, idtype) then
			table.insert(owner.comprisedOf, idtype)
		end
	end
end

function GetErDone:ensureTrackable(id)
	if self.db.global.trackables[id] == nil then self.db.global.trackables[id] = {} end
end

function GetErDone:OnInitialize()
	AceConfig:RegisterOptionsTable("GetErDone", options, {"ged", "geterdone"}) 
	self.db = LibStub("AceDB-3.0"):New("GetErDoneDb")


	
	self.optionsFrames = {}
	--self.optionsFrames.general = AceConfigDialog:AddToBlizOptions("GetErDone", nil, nil, "general")


	--Event Registry--
	self:RegisterEvent("PLAYER_ENTERING_WORLD", "OnLogin") --Note the syntax, second parameter is a function name as a string

end

function GetErDone:OnEnable()
	local name, server = UnitFullName("player")
	if self.db.global.characters == nil then self.db.global.characters = {} end
	if self.db.global.characters[name .. server] == nil then 
		self.db.global.characters[name .. server] = {["name"] = name, ["server"] = server}
	end
	self.db.global.character = name .. server
	---First Time Setup l---
	if self.db.global.trackables == nil then self.db.global.trackables = {} end
	if self.db.global.compounds == nil then self.db.global.compounds = { ["top_level"] = {
				["name"] = "Get Er Done",
				["active"] = true,
				["childCompletionQuantity"] = 0,
				["displayChildren"] = true,
				["ownedBy"] = "",
				["comprisedOf"] = {
				},
			},} end
	if self.db.global.options == nil then self.db.global.options = {} end
	if self.db.global.options.quantity == nil then self.db.global.options.quantity = "" end
	if self.db.global.options.compoundquantity == nil then self.db.global.options.compoundquantity = "" end
	if self.db.global.options.frequency == nil then self.db.global.options.frequency = "" end
	if self.db.global.options.optCompound == nil then self.db.global.options.optCompound = "" end
	if self.db.global.options.nextCompoundId == nil then self.db.global.options.nextCompoundId = 1 end
	if self.db.global.options.newCompoundName == nil then self.db.global.options.newCompoundName = "" end
	if self.db.global.options.ignoredNames == nil then self.db.global.options.ignoredNames = {} end
	if self.db.global.options.compoundchildren == nil then self.db.global.options.compoundchildren = true end
	if self.db.global.options.uichararacterlistcurrent == nil then self.db.global.options.uichararacterlistcurrent = self.db.global.characters[self.db.global.character] end
	if self.db.global.options.showui == nil then self.db.global.options.showui = true end
	if self.db.global.region == nil then self.db.global.region = GetCurrentRegion() end
	if self.db.global.completionCache == nil then self.db.global.completionCache = {} end
	if self.db.global.hiddenCompounds == nil then self.db.global.hiddenCompounds = {} end
	

	self:removeUnwantedChildren()
	self:removeOrphans()
	self:generateUiCharacterList()
	self:registerHandlers()
	self:LoadDefaults()
	self:UpdateResets()
	self:InvalidateCompletionCache(COMPLETION_CACHE_ALL_CHARACTERS)
	self:invalidateAceTree()
	self:createTestInGameList()
end

function GetErDone:removeOrphans()
	local removed = false
	local compounds = self.db.global.compounds
	for compound_id, compound in pairs(compounds) do
		if compound_id ~= COMPOUND_TREE_ROOT_ELEMENT then
			if compound.ownedBy == nil or compound.ownedBy == "" or compounds[compound.ownedBy] == nil then
				self.db.global.compounds[compound_id] = nil
				self:debug("removed " .. compound_id)
				removed = true
			end
		end
	end

	local trackables = self.db.global.trackables
	for id, typeTable in pairs(trackables) do
		for type, trackable in pairs(typeTable) do
			if trackable.ownedBy == nil or trackable.ownedBy == "" or compounds[trackable.ownedBy] == nil then
				self.db.global.trackables[id][type] = nil
				self:debug("removed " .. id .. ":" .. type)
				removed = true
			end
		end
		if self:IsNullOrEmpty(self.db.global.trackables[id]) then
			self.db.global.trackables[id] = nil
			removed = true
			self:debug("removed empty trackable " .. id)
		end
	end

	if removed then
		self:debug("remove orphans recursing")
		self:removeOrphans()
	end
end

function GetErDone:removeUnwantedChildren()
	local compounds = self.db.global.compounds
	for compound_id, compound in pairs(compounds) do
		if type(compound.comprisedOf) == "table" then
			for k, child_id in ipairs(compound.comprisedOf) do
				if self:isCompoundId(child_id) then
					if compounds[child_id] == nil then
						table.remove(self.db.global.compounds[compound_id].comprisedOf, k)
					end
				else
					if self.db.global.trackables[child_id.id] == nil or self.db.global.trackables[child_id.id][child_id.type] == nil then
						table.remove(self.db.global.compounds[compound_id].comprisedOf, k)
					end
				end
			end
		end
	end
end

function GetErDone:OnUpdate()
end

function GetErDone:LoadDefaults()
	--if debug then return end TODO uncomment for release

	if self.db.global.defaultsloaded == nil then
		self.db.global.compounds = defaults.compounds
		self.db.global.trackables = defaults.trackables

		for id, typeTree in pairs(self.db.global.trackables) do
			for type, trackable in pairs(typeTree) do
				trackable["characters"] = { [self.db.global.character] = 0 }
				trackable["reset"] = self:NextReset(trackable.frequency, self.db.global.region)
			end
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
				if type == TYPE_MONSTER or type == TYPE_VEHICLE then
					return
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

local COMBATLOG_OBJECT_AFFILIATION_MINE = _G.COMBATLOG_OBJECT_AFFILIATION_MINE
local COMBATLOG_OBJECT_AFFILIATION_PARTY = _G.COMBATLOG_OBJECT_AFFILIATION_PARTY
local COMBATLOG_OBJECT_AFFILIATION_RAID = _G.COMBATLOG_OBJECT_AFFILIATION_RAID
local bit_band = _G.bit.band

function GetErDone:handleEventCombatLog(event, _, _, eventType, _, srcGuid, _, srcFlags, _, dstGuid, ...)
	if eventType == "UNIT_DIED" then
		local unitType, npcId, _ = self:getNpcId(dstGuid)
		if self.db.global.trackables[npcId] ~= nil and self.db.global.trackables[npcId][unitType] ~= nil then
			if bit_band(srcFlags, COMBATLOG_OBJECT_AFFILIATION_MINE) or bit_band(srcFlags, COMBATLOG_OBJECT_AFFILIATION_PARTY) or bit_band(srcFlags, COMBATLOG_OBJECT_AFFILIATION_RAID) then
				if unitType == TYPE_VEHICLE then
					unitType = TYPE_MONSTER
				end
				self:checkEvent(npcId, unitType)
			end
		end
	end
end


function GetErDone:handleEventItem(event)
	-- handled by handleEventMonster
end

function GetErDone:handleEventQuest(event)
    if event == "QUEST_TURNED_IN" then
        for id, typeTable in pairs(self.db.global.trackables) do
            if self.db.global.trackables[id][TYPE_QUEST] ~= nil then
            	if IsQuestFlaggedCompleted(id) then
            		self:checkEvent(id, TYPE_QUEST)
            	end
            end
        end
    end
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
	local name = self:getServerAwareName(character)
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
	if self.db.global.trackables[id][type].characters == nil then return end

	self:debug("Completing trackable " .. id .. " with status: " .. status)
	if status == COMPLETE_INCREMENT then
		if trackable.characters[character] ~= nil then
			if trackable.characters[character] < trackable.completionQuantity then
				trackable.characters[character] = trackable.characters[character] + 1
			end
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
	if self:IsNullOrEmpty(compound.comprisedOf) then return true end

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

	if a == 0 or b == 0 then return false end
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
	self:InvalidateCompletionCache(COMPLETION_CACHE_ALL_CHARACTERS)
end

function GetErDone:deleteCompound(compound_id)
	local compound = self.db.global.compounds[compound_id]
	if compound == nil then return end
	local children = compound.comprisedOf
	if children ~= "" and children ~= nil then
		for k, child_id in ipairs(children) do
			if self:isCompoundId(child_id) then
				self:deleteCompound(child_id)
			else
				self:deleteTrackable(child_id.id, child_id.type)
			end
		end
	end
	local parent = self.db.global.compounds[compound.ownedBy]
	if parent ~= nil then
		for i, v in ipairs(parent.comprisedOf) do
			if v == compound_id then
				table.remove(self.db.global.compounds[compound.ownedBy].comprisedOf, i)
				break
			end
		end
	end
	self.db.global.compounds[compound_id] = nil
end

function GetErDone:deleteTrackable(id, type)
	if self.db.global.trackables[id][type].ownedBy ~= "" then
		for i,v in ipairs(self.db.global.compounds[self.db.global.trackables[id][type].ownedBy].comprisedOf) do
			if v["id"] == id and v["type"] == type then
				table.remove(self.db.global.compounds[self.db.global.trackables[id][type].ownedBy].comprisedOf, i)
				break
			end
		end
	end
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

function GetErDone:containsTrackable(dict, trackable)
	local id = trackable.id
	local type = trackable.type

	if dict == nil then 
		error("contains: null table or value")
	end
	for k, v in pairs(dict) do
		if v.id == id and v.type == type then return true end
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

function GetErDone:getServerAwareName(character)
	local name = self.db.global.characters[character].name
	if self:isDuplicateName(name) then
		name = name .. " (" .. self.db.global.characters[character].server .. ")"
	end
	return name
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
	local t = {[CHARACTERS_ALL] = "All Characters"}
	for k, v in pairs(GetErDone:GetOption("characters")) do
		if not self:isNameIgnored(v.name .. v.server) then
			t[k] = v["name"] .. " - " .. v["server"]
		end
	end
	return t
end

function GetErDone:getIndent(n)
	return string.rep(NESTING_INDENT, n)
end

function GetErDone:generateUiCharacterList()
	self.db.global.options.uicharacterlist = {}
	local charList = self.db.global.options.uicharacterlist

	for character, charTable in pairs(self.db.global.characters) do
		if charList[character] == nil then
			table.insert(charList, charTable)
		end
	end

	self.db.global.options.uichararacterlistcurrent = self.db.global.characters[self.db.global.character]
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
		return true
	end
	return false
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

function GetErDone:buttonCheck(t)
	if t == "compound" then
		if self.db.global.options.newCompoundName ~= "" and
			self.db.global.options.compoundquantity ~= "" then
			widgetManager["buttonCompound"]:SetDisabled(false)
		end
	elseif t == "trackable" then
		if self.db.global.options.trackableID ~= "" and
			self.db.global.options.typechoice ~= "" and
			self.db.global.options.frequency ~= "" and
			self.db.global.options.character ~= "" and
			self.db.global.options.trackablename ~= "" and
			self.db.global.options.quantity ~= "" then
			widgetManager["addTrackableButton"]:SetDisabled(false)
		end
	end
	self:tryUpdateTrackableCharacterDropdown()
end

function GetErDone:tryUpdateTrackableCharacterDropdown()
	if self.db.global.trackables[self.db.global.options.trackableID] ~= nil and self.db.global.trackables[self.db.global.options.trackableID][self.db.global.options.typechoice] ~= nil then
		local dropDownTrackable = self.db.global.trackables[self.db.global.options.trackableID][self.db.global.options.typechoice]
		charDropdownList = {}
		for k, v in pairs(self:getCharacters()) do
			frameManager.trackableCharacter:SetItemValue(k, false)
		end
		for dropDownTrackableCharacter, v in pairs(dropDownTrackable.characters) do
			charDropdownList[dropDownTrackableCharacter] = dropDownTrackableCharacter
			frameManager.trackableCharacter:SetItemValue(dropDownTrackableCharacter, true)
		end
	end
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

--[[function GetErDone:getTrackableCharacterDropdown(widget, event, key)
	self.db.global.options.character = key
	self:setTrackableCharacterDropdown(widget)
end

function GetErDone:setTrackableCharacterDropdown(widget)
	widget:SetValue(self.db.global.options.character)
	GetErDone:buttonCheck("trackable")
end]]--

function GetErDone:submitIDEdit(widget, event, text)
	if string.match(text, '%d') then
		self.db.global.options.trackableID = text
	end
	self:populateIDEdit(widget)
end

function GetErDone:submitTrackableNameEdit(widget, event, text)
	self.db.global.options.trackablename = text
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

local charDropdownList = {}

function GetErDone:createIngameList()
    local f = AceGUI:Create("Frame")
    f:SetCallback("OnClose",function(widget) AceGUI:Release(widget) end)
    f:SetLayout("Fill")
    f:SetHeight(800)
    

    local mainTree = AceGUI:Create("TreeGroup")
    mainTree:SetTree(self:getAceTree(false))
    mainTree:SetCallback("OnButtonEnter", 
    	function(widget, event, path, frame)
			self.db.global.options["treeMouseover"] = frame["value"]
    	end)
    mainTree:SetCallback("OnGroupSelected",
    	function(widget, event, group)
    		if self:isCompoundId(self.db.global.options.treeMouseover) then
    			self.db.global.options.optCompound = self.db.global.options.treeMouseover
    			widgetManager["compoundSelectionLabel"]:SetText("Current Group: " .. self.db.global.compounds[self.db.global.options.optCompound].name)
    			widgetManager["deleteCompoundButton"]:SetDisabled(false)
    			if self.db.global.options.optCompound == "top_level" then widgetManager["deleteCompoundButton"]:SetDisabled(true) end
    			self:clearTrackableFields()
    			self:buttonCheck("compound")
			elseif string.find(self.db.global.options.treeMouseover, ':') then
				local id, type = self:fromMergedId(self.db.global.options.treeMouseover)
				self.db.global.options.optTrackable = {["id"] = id, ["type"] = type}
				widgetManager["compoundSelectionLabel"]:SetText("Current Group: " .. self.db.global.compounds[self.db.global.trackables[id][type].ownedBy].name)
				self.db.global.options.optCompound = self.db.global.trackables[id][type].ownedBy
				widgetManager["trackableSelectionLabel"]:SetText("Current Item: " .. self.db.global.trackables[id][type].name)
				widgetManager["deleteTrackableButton"]:SetDisabled(false)
				widgetManager["addTrackableButton"]:SetText("Update Item")
				widgetManager["addTrackableButton"]:SetCallback("OnClick", 
				function(widget, event, text) 
					self:delete(id, type)
					self:AddTrackable(
						self.db.global.options.trackableID, 
						self.db.global.options.typechoice, 
						self.db.global.options.trackablename,
						self.db.global.options.optCompound,
						self.db.global.options.frequency,
						charDropdownList,
						self.db.global.options.quantity
					)
					mainTree:SetTree(self:getAceTree(false))
					widgetManager["addTrackableButton"]:SetDisabled(true)
					self:populateTrackableFields(id, type)
				end)
				self:populateTrackableFields(id, type)
				self:buttonCheck("trackable")
			end
		end)

	function GetErDone:populateTrackableFields(id, type)
		widgetManager["trackableFrequency"]:SetValue(self.db.global.trackables[id][type].frequency)
		self.db.global.options.frequency = self.db.global.trackables[id][type].frequency
		widgetManager["trackableType"]:SetValue(type)
		self.db.global.options.typechoice = type
		widgetManager["trackableID"]:SetText(id)
		self.db.global.options.trackableID = id
		widgetManager["trackableName"]:SetText(self.db.global.trackables[id][type].name)
		self.db.global.options.trackablename = self.db.global.trackables[id][type].name
		widgetManager["trackableQuantity"]:SetText(self.db.global.trackables[id][type].completionQuantity)
		self.db.global.options.quantity = self.db.global.trackables[id][type].completionQuantity
	end

	function GetErDone:clearTrackableFields()
		widgetManager["trackableSelectionLabel"]:SetText("Current Item: ")
		widgetManager["trackableID"]:SetText("")
		widgetManager["trackableName"]:SetText("")
		widgetManager["trackableQuantity"]:SetText("")
		self.db.global.options.trackableID = ""
		self.db.global.options.trackablename = ""
		self.db.global.options.quantity = ""
		widgetManager["addTrackableButton"]:SetDisabled(true)
		widgetManager["deleteTrackableButton"]:SetDisabled(true)
		self.db.global.options.optTrackable = {}
		widgetManager["addTrackableButton"]:SetText("Add Item")
		widgetManager["addTrackableButton"]:SetCallback("OnClick", 
		function(widget, event) self:AddTrackable(
				self.db.global.options.trackableID, 
				self.db.global.options.typechoice, 
				self.db.global.options.trackablename,
				self.db.global.options.optCompound,
				self.db.global.options.frequency,
				charDropdownList,
				self.db.global.options.quantity)
			mainTree:SetTree(self:getAceTree(false))
			widgetManager["addTrackableButton"]:SetDisabled(true)
		end)
	end
    ---Copy Pasted Shit---

	local newCompoundGroup = AceGUI:Create("InlineGroup")
	local compoundSelectionLabel = AceGUI:Create("Label")
	local editCompound = AceGUI:Create("EditBox")
	local compoundQuantity = AceGUI:Create("EditBox")
	local compoundChildrenToggle = AceGUI:Create("CheckBox")
	local buttonCompound = AceGUI:Create("Button")
	local deleteCompoundButton = AceGUI:Create("Button")

	buttonCompound:SetText("Add Group")
	buttonCompound:SetCallback("OnClick", function(widget, event, text) 
		local success = self:addCompound() 
		if success then
			widgetManager["editCompound"]:SetText("")
			widgetManager["compoundQuantity"]:SetText("")
			self.db.global.options.compoundquantity = ""
			self.db.global.options.newCompoundName = ""
			widgetManager["buttonCompound"]:SetDisabled(true)

			mainTree:SetTree(self:getAceTree(false))
		end
	end)

	if self.db.global.options.optCompound ~= "" then
		compoundSelectionLabel:SetText("Current Group: " .. self.db.global.compounds[self.db.global.options.optCompound].name)
	else
		compoundSelectionLabel:SetText("Current Group: ")
	end

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

	deleteCompoundButton:SetText("Delete Group")
	if self.db.global.options.optCompound == "" then deleteCompoundButton:SetDisabled(true) end
	deleteCompoundButton:SetCallback("OnClick", function(widget, event, text)
			self:delete(self.db.global.options.optCompound)
			self.db.global.options.optCompound = ""
			self.db.global.options.treeMouseover = ""
			self:updateUI()
			self:invalidateAceTree()
			mainTree:SetTree(self:getAceTree(false))
			compoundSelectionLabel:SetText("Current Group: ")
		end)

--- New Trackable Interface ---

	local newTrackableGroup = AceGUI:Create("InlineGroup")
	local trackableSelectionLabel = AceGUI:Create("Label")
	local trackableType = AceGUI:Create("Dropdown")
	local trackableID = AceGUI:Create("EditBox")
	local trackableName = AceGUI:Create("EditBox")
	local trackableSpacer = AceGUI:Create("Heading")
	local trackableCharacter = AceGUI:Create("Dropdown")
	local trackableFrequency = AceGUI:Create("Dropdown")
	local addTrackableButton = AceGUI:Create("Button")
	local trackableQuantity = AceGUI:Create("EditBox")
	local deleteTrackableButton = AceGUI:Create("Button")

	addTrackableButton:SetText("Add ID")
	addTrackableButton:SetCallback("OnClick", 
		function(widget, event) 
			self:AddTrackable(
				self.db.global.options.trackableID, 
				self.db.global.options.typechoice, 
				self.db.global.options.trackablename,
				self.db.global.options.optCompound,
				self.db.global.options.frequency,
				charDropdownList,
				self.db.global.options.quantity
			)
			self:invalidateAceTree()
			mainTree:SetTree(self:getAceTree(false))
			widgetManager["addTrackableButton"]:SetDisabled(true)
		end)

	trackableSpacer:SetText("")

	if self.db.global.options.optCompound ~= "" then
		trackableSelectionLabel:SetText("Current Item: " .. self.db.global.compounds[self.db.global.options.optCompound].name)
	else
		trackableSelectionLabel:SetText("Current Item: ")
	end

	trackableName:SetText("")
	trackableName:SetLabel("Name")
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
	trackableCharacter:SetCallback("OnValueChanged", function(widget, event, key, checked)

		if checked and key == "all" then
			for k, v in pairs(self.db.global.characters) do
				trackableCharacter:SetItemValue(v["name"]..v["server"], true)
				charDropdownList[k] = k
			end
		elseif checked then
			charDropdownList[key] = key
		elseif key == "all" then
			for k, v in pairs(self.db.global.characters) do
				trackableCharacter:SetItemValue(v["name"]..v["server"], false)
				charDropdownList[k] = nil
			end
		else
			charDropdownList[key] = nil
		end

		if self.db.global.options.optTrackable ~= nil then
			addTrackableButton:SetDisabled(false)
		end

	end)
	trackableCharacter:SetLabel("Character")
	trackableCharacter:SetMultiselect(true)
	frameManager["trackableCharacter"] = trackableCharacter

	trackableQuantity:SetCallback("OnEnterPressed", function(widget, event, text) self:getTrackableQuantity(widget, event, text) end)
	trackableQuantity:SetLabel("Quantity")

	newTrackableGroup:SetRelativeWidth(0.5)
	newTrackableGroup:SetLayout("List")

	deleteTrackableButton:SetText("Delete Item")
	deleteTrackableButton:SetDisabled(true)
	deleteTrackableButton:SetCallback("OnClick", function(widget, event, text)
			self:delete(self.db.global.options.optTrackable.id, self.db.global.options.optTrackable.type)
			self.db.global.options.optTrackable = {}
			self.db.global.options.treeMouseover = ""
			self:updateUI()
			self:invalidateAceTree()
			mainTree:SetTree(self:getAceTree(false))
			self:clearTrackableFields()
		end)

	addTrackableButton:SetDisabled(true)



	mainTree:AddChild(newCompoundGroup)
	newCompoundGroup:AddChild(compoundSelectionLabel)
	newCompoundGroup:AddChild(editCompound) 
	newCompoundGroup:AddChild(compoundQuantity)
	newCompoundGroup:AddChild(compoundChildrenToggle) 
	newCompoundGroup:AddChild(buttonCompound)
	newCompoundGroup:AddChild(deleteCompoundButton)

	mainTree:AddChild(newTrackableGroup)
	newTrackableGroup:AddChild(trackableSelectionLabel)
	newTrackableGroup:AddChild(trackableType)
	newTrackableGroup:AddChild(trackableID)
	newTrackableGroup:AddChild(trackableName)
	--newTrackableGroup:AddChild(trackableSpacer)
	newTrackableGroup:AddChild(trackableFrequency)
	newTrackableGroup:AddChild(trackableCharacter)
	newTrackableGroup:AddChild(trackableQuantity)
	newTrackableGroup:AddChild(addTrackableButton)
	newTrackableGroup:AddChild(deleteTrackableButton)
	
	widgetManager = {
	["trackableName"] = trackableName,
	["editCompound"] = editCompound, 
	["compoundQuantity"] = compoundQuantity, 
	["trackableID"] = trackableID, 
	["trackableQuantity"] = trackableQuantity,
	["trackableFrequency"] = trackableFrequency,
	["trackableCharacter"] = trackableCharacter,
	["trackableFrame"] = trackablesScroll,
	["trackableType"] = trackableType,
	["compoundFrame"] = groupsScroll,
	["compoundSelectionLabel"] = compoundSelectionLabel,
	["buttonCompound"] = buttonCompound,
	["addTrackableButton"] = addTrackableButton,
	["deleteCompoundButton"] = deleteCompoundButton,
	["trackableSelectionLabel"] = trackableSelectionLabel,
	["deleteTrackableButton"] = deleteTrackableButton,
	}

	f:DoLayout() --HOLY MOTHERFUCKING SHIT IS THIS LINE IMPORTANT
    ---Copy Pasted Shit---

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
	f:SetWidth(250)
	f:SetHeight(1000)
	f:SetMovable(true)
	f:EnableMouse(true)
	f:SetHitRectInsets(0,0,0,975)
	f:RegisterForDrag("LeftButton")
	f:SetClampedToScreen(false) -- don't let it be dragged off the screen
	f:SetScript("OnDragStart", f.StartMoving)
	f:SetScript("OnDragStop", function() GetErDone:saveUiPosition() end)
	if self.db.global.options.uipositionx ~= nil and self.db.global.options.uipositiony ~= nil and self.db.global.options.uipositionpoint ~= nil then
		f:SetPoint(self.db.global.options.uipositionpoint, self.db.global.options.uipositionx, self.db.global.options.uipositiony)
	else
		f:SetPoint("CENTER", 0, 0)
	end

	local frameTitle = f:CreateTitleRegion()
	local titlefontstring = f:CreateFontString("GetErDoneTitle", "ARTWORK", "GameFontNormal") --GameFontWhite
	titlefontstring:SetText("Get Er Done")
	titlefontstring:SetPoint("TOPLEFT", 0, 0)
	titlefontstring:SetHeight(20)
	titlefontstring:SetWidth(200)

	local closeButton = CreateFrame("Button", "ui_close_button", f)
	closeButton:SetHeight(13)
	closeButton:SetWidth(13)
	closeButton:SetPoint("TOPRIGHT", -1, 0) -- shuffle button to the left so it's on top of the text
    closeButton:SetNormalTexture("Interface\\Addons\\GetErDone\\textures\\close.tga", "BLEND")
   	closeButton:SetHighlightTexture("Interface\\Addons\\GetErDone\\textures\\close_highlight.tga", "BLEND")
   	closeButton:SetPushedTexture("Interface\\Addons\\GetErDone\\textures\\close_highlight.tga", "BLEND")
	closeButton:RegisterForClicks("LeftButtonUp")
	closeButton:SetFrameStrata("MEDIUM")
	closeButton:SetScript("OnClick", function(...) 
		print(UI_CLOSED_STRING)
		GetErDone:createTestInGameList() 
	end)
	closeButton:Enable()


	local character = self:getServerAwareName(self.db.global.options.uichararacterlistcurrent.name .. self.db.global.options.uichararacterlistcurrent.server)
	local currentCharacterDisplay = f:CreateFontString("currentCharacter", "ARTWORK", "GameFontWhite") --GameFontWhite
	currentCharacterDisplay:SetText(character)
	currentCharacterDisplay:SetPoint("TOPLEFT", 0, -20)
	currentCharacterDisplay:SetHeight(20)
	currentCharacterDisplay:SetWidth(200)
	currentCharacterDisplay:SetShadowOffset(1,-1)
	frameManager["currentCharacterDisplay"] = currentCharacterDisplay

	local leftButton = CreateFrame("Button", "ui_left_button", f)
	leftButton:SetPoint("TOPLEFT", -40, -25) -- shuffle button to the left so it's on top of the text
    leftButton:SetNormalTexture("Interface\\Addons\\GetErDone\\textures\\left.tga", "BLEND")
   	leftButton:SetHighlightTexture("Interface\\Addons\\GetErDone\\textures\\left_highlight.tga", "BLEND")
   	leftButton:SetPushedTexture("Interface\\Addons\\GetErDone\\textures\\left_highlight.tga", "BLEND")
	leftButton:SetHeight(15)
	leftButton:SetWidth(15)
	leftButton:RegisterForClicks("LeftButtonUp")
	leftButton:SetFrameStrata("MEDIUM")
	leftButton:SetScript("OnClick", function(a, event, b) GetErDone:handleUiCharacterButtonClick(CHARACTER_BUTTON_LEFT) end)
	leftButton:Enable()

	local rightButton = CreateFrame("Button", "ui_right_button", f)
	rightButton:SetPoint("TOPRIGHT", -1, -25) -- shuffle button to the left so it's on top of the text
    rightButton:SetNormalTexture("Interface\\Addons\\GetErDone\\textures\\right.tga", "BLEND")
   	rightButton:SetHighlightTexture("Interface\\Addons\\GetErDone\\textures\\right_highlight.tga", "BLEND")
   	rightButton:SetPushedTexture("Interface\\Addons\\GetErDone\\textures\\right_highlight.tga", "BLEND")
	rightButton:SetHeight(15)
	rightButton:SetWidth(15)
	rightButton:RegisterForClicks("LeftButtonUp")
	rightButton:SetFrameStrata("MEDIUM")
	rightButton:SetScript("OnClick", function(a, event, b) GetErDone:handleUiCharacterButtonClick(CHARACTER_BUTTON_RIGHT) end)
	rightButton:Enable()


	frameManager["f"] = f
	frameManager["previousString"] = currentCharacterDisplay

	self:generateIngameCompoundTree(COMPOUND_TREE_ROOT_ELEMENT)
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
			self.db.global.options.showui = false
			return
		end
	end
	if self.db.global.options.showui then
		self:redrawUi()
	end
end

function GetErDone:getTrimmedCharacterList()
	result = {}
	for k, v in pairs(self.db.global.compounds) do
		for kk, vv in pairs(v["comprisedOf"]) do
			if not self:isCompoundId(vv) then
				for nameserver, quantcomplete in pairs(self.db.global.trackables[vv["id"]][vv["type"]].characters) do
					if not self:contains(result, self.db.global.characters[nameserver]) then
						table.insert(result, self.db.global.characters[nameserver])
					end
				end
			end
		end
	end
	return result
end

function GetErDone:generateIngameCompoundTree(compoundid)
	if frameManager.f == nil then return end -- if we're calling before we've loaded the ui for the first time - on login, usually
	local children = self:getCompoundChildren(compoundid)
	local character = self.db.global.options.uichararacterlistcurrent.name .. self.db.global.options.uichararacterlistcurrent.server

	for k, child_compound_id in pairs(children) do
		if self:getTreeDisplayCharacter(child_compound_id, nil, false, character) then
			local displayChildren = self.db.global.compounds[child_compound_id].displayChildren
			local fontType = displayChildren and "GameFontNormal" or "GameFontWhite"
			local tempString = frameManager["f"]:CreateFontString(child_compound_id, "ARTWORK", fontType)
			tempString:SetText(self:createUiCompoundText(child_compound_id, character))
			if displayChildren then
				tempString:SetPoint("BOTTOM", frameManager["previousString"], 0, -20, 0)
				tempString:SetHeight(20)
			else
				tempString:SetPoint("BOTTOM", frameManager["previousString"], 0, -15, 0)
				tempString:SetHeight(15)
				tempString:SetShadowOffset(1,-1)
			end
			tempString:SetWidth(300)
			tempString:SetJustifyH("LEFT")

			frameManager["previousString"] = tempString
			-- create the invisible button
			if displayChildren then
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
				button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
				button:SetFrameStrata("MEDIUM")
				button:SetScript("OnClick", function(a, event, b) GetErDone:handleUiButtonClick(event, child_compound_id) end)
				button:SetAlpha(0.2)
				button:Enable()


				for kk, child_id in pairs(self.db.global.compounds[child_compound_id].comprisedOf) do
					if not self:isCompoundId(child_id) and self:uiShowCompound(child_compound_id) then
						if self:getTreeDisplayCharacter(child_id.id, child_id.type, false, character) then
							tempString = frameManager["f"]:CreateFontString(child_compound_id, "ARTWORK", "GameFontWhite")
							tempString:SetText(self:createUiTrackableText(child_compound_id, child_id.id, child_id.type, character))
							tempString:SetPoint("BOTTOM", frameManager["previousString"], 0, -15, 0)
							tempString:SetHeight(15)
							tempString:SetWidth(300)
							tempString:SetJustifyH("LEFT")
							tempString:SetShadowOffset(1,-1)
							frameManager["previousString"] = tempString
						end
					end
				end
			end
			if self:uiShowCompound(child_compound_id) then
				self:generateIngameCompoundTree(child_compound_id)
			end
		end
	end
end

function GetErDone:createUiTrackableText(parent_compound_id, id, type, character)
	local completionText = ""
	local trackable = self.db.global.trackables[id][type]

	if trackable.completionQuantity > 1 then
		completionText = string.format(" (%i/%i)", trackable.characters[character], trackable.completionQuantity)
	end
	return self:getIndent(self:compoundNumParents(parent_compound_id) + 1) .. trackable.name .. completionText
end

function GetErDone:createUiCompoundText(compound_id, character)
	local completionText = ""
	local compound = self.db.global.compounds[compound_id]

	if compound.childCompletionQuantity > 1 then
		local numberCompleted = 0
		for k, child in pairs(compound.comprisedOf) do
			local id, type
			id = child
			if not self:isCompoundId(child) then
				id = child.id
				type = child.type
			end

			if self:IsComplete(id, type, character) then
				numberCompleted = numberCompleted + 1
			end
		end

		completionText = string.format(" (%i/%i)", numberCompleted, compound.childCompletionQuantity)
	end

	return self:getIndent(self:compoundNumParents(compound_id)) .. compound.name .. completionText
end

function GetErDone:updateUI()
	if frameManager.f ~= nil then
		frameManager.f:Hide()
		frameManager.f = nil
		self:redrawUi()
	end
end

function GetErDone:uiShowCompound(compound_id)
	return self.db.global.hiddenCompounds[compound_id] == nil
end

function GetErDone:uiCompoundSetShow(compound_id)
	self.db.global.hiddenCompounds[compound_id] = nil
end

function GetErDone:uiCompoundSetHide(compound_id)
	self.db.global.hiddenCompounds[compound_id] = 1
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

function GetErDone:handleUiButtonClick(event, child_compound_id)
	if event == EVENT_LEFT_BUTTON then
		self:uiCompoundToggle(child_compound_id)
	elseif event == EVENT_RIGHT_BUTTON then
		self:debug(event) -- TODO bring up context menu
	end
end

function GetErDone:handleUiCharacterButtonClick(direction, recurseIfThisIsNil)
	local found = false -- flag to find when we've got the current name
	local currentName = self.db.global.options.uichararacterlistcurrent
	if direction == CHARACTER_BUTTON_RIGHT  then
		for i, nameTable in ipairs(self:getTrimmedCharacterList()) do

			if found == true or recurseIfThisIsNil ~= nil then -- if we're recursing, we know that we've found a name and want to pick the next available one
				if not self:isNameIgnored(nameTable.name .. nameTable.server) then
					self.db.global.options.uichararacterlistcurrent = { ["name"] = nameTable.name, ["server"] = nameTable.server }
					self:updateUI()
					return
				end
			end

			if nameTable.name == currentName.name and nameTable.server == currentName.server then
				found = true -- set the found flag if the name matches
			end
		end
		-- if we need to go back to the start
		self.db.global.options.uichararacterlistcurrent = self.db.global.options.uicharacterlist[1] -- set the current name to the first one in the list
	elseif direction == CHARACTER_BUTTON_LEFT then
		local list = self:getTrimmedCharacterList()
		for i = #(list), 1, -1 do
			local nameTable = list[i]

			if found == true or recurseIfThisIsNil ~= nil then
				if not self:isNameIgnored(nameTable.name .. nameTable.server) then
					self.db.global.options.uichararacterlistcurrent = { ["name"] = nameTable.name, ["server"] = nameTable.server }
					self:updateUI()
					return
				end
			end

			if nameTable.name == currentName.name and nameTable.server == currentName.server then
				found = true
			end
		end
		-- if we need to go back to the start
		self.db.global.options.uichararacterlistcurrent = self.db.global.options.uicharacterlist[#(list)] -- set the current name to the last in the list
	end
	if recurseIfThisIsNil == nil then
		self:handleUiCharacterButtonClick(direction, 1) -- recurse once only - prefer to do nothing than stack overflow
	end
end