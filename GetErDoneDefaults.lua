defaults = {
	["compounds"] = {
		["d_argent_tournament"] = {
			["name"] = "Argent Tournament",
			["comprisedOf"] = {
				"d_trial_of_the_champion",
				"d_argent_tournament_dailies",
			},
			["ownedBy"] = "d_northrend_dailies",
			["childCompletionQuantity"] = 10,
			["displayChildren"] = true,
		},
		["d_argent_tournament_dailies"] = {
			["name"] = "Argent Tournament Dailies",
			["comprisedOf"] = {
				{["id"] = "14105", ["type"] = "quest"},
				{["id"] = "14101", ["type"] = "quest"},
				{["id"] = "14102", ["type"] = "quest"},
				{["id"] = "14104", ["type"] = "quest"},
				{["id"] = "14107", ["type"] = "quest"},
				{["id"] = "14108", ["type"] = "quest"},
				{["id"] = "13809", ["type"] = "quest"},
				{["id"] = "13862", ["type"] = "quest"},
				{["id"] = "13811", ["type"] = "quest"},
				{["id"] = "13810", ["type"] = "quest"},
				{["id"] = "14092", ["type"] = "quest"},
				{["id"] = "14141", ["type"] = "quest"},
				{["id"] = "14156", ["type"] = "quest"},
				{["id"] = "14142", ["type"] = "quest"},
				{["id"] = "14143", ["type"] = "quest"},
				{["id"] = "14136", ["type"] = "quest"},
				{["id"] = "14140", ["type"] = "quest"},
				{["id"] = "14144", ["type"] = "quest"},
				{["id"] = "14105", ["type"] = "quest"},
			},
			["ownedBy"] = "d_argent_tournament_dailies",
			["childCompletionQuantity"] = 10,
			["displayChildren"] = true,
		},
		["d_trial_of_the_champion"] = {
			["name"] = "Trial of the Champion",
			["comprisedOf"] = {			
				{["id"] = "35119", ["type"] = "monster"},
				{["id"] = "34928", ["type"] = "monster"},
				{["id"] = "35451", ["type"] = "monster"},
				{["id"] = "34705", ["type"] = "monster"},
				{["id"] = "34702", ["type"] = "monster"},
				{["id"] = "34701", ["type"] = "monster"},
				{["id"] = "34657", ["type"] = "monster"},
				{["id"] = "34703", ["type"] = "monster"},
				{["id"] = "35569", ["type"] = "monster"},
				{["id"] = "35571", ["type"] = "monster"},
				{["id"] = "35570", ["type"] = "monster"},
				{["id"] = "35617", ["type"] = "monster"},
			},
			["ownedBy"] = "d_argent_tournament",
			["childCompletionQuantity"] = 5,
			["displayChildren"] = false,
		},
	},
	["trackables"] = {

	},
}