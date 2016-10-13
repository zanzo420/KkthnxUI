local K, C, L = select(2, ...):unpack()
if C.Unitframe.Enable ~= true then return end

local _, ns = ...

-- Default Aura Filter
ns.defaultAuras = {
	["general"] = {},
	["boss"] = {},
	["arena"] = {},
}

do
	local l = ns.AuraList
	for _, list in pairs({l.Immunity, l.CCImmunity, l.Defensive, l.Offensive, l.Helpful, l.Misc}) do
		for i = 1, #list do
			ns.defaultAuras.arena[list[i]] = true
		end
	end
end

-- Default Settings
ns.config = {
	largePlayerAuras = true,

	showArena = true,
	showBoss = true,

	borderType = "kkthnx", -- beauty or kkthnx
	textureBorder = "Interface\\AddOns\\KkthnxUI\\Media\\Border\\2borderNormal",
	textureBorderWhite = "Interface\\AddOns\\KkthnxUI\\Media\\Border\\2borderWhite",
	textureBorderShadow = "Interface\\AddOns\\KkthnxUI\\Media\\Border\\2borderShadow",

	playerstyle = "normal",
	customPlayerTexture = "Interface\\AddOns\\KkthnxUI\\Media\\Unitframes\\CUSTOMPLAYER-FRAME",

	castbarticks = true,
	useAuraTimer = false,

	classBar = {},

	-- class stuff
	DEATHKNIGHT = {
		showRunes = true,
		showTotems = true,
	},
	DEMONHUNTER = {
	},
	DRUID = {
		showTotems = true,
		showAdditionalPower = true,
	},
	HUNTER = {
		showTotems = true,
	},
	MAGE = {
		showArcaneStacks = true,
		showTotems = true,
	},
	MONK = {
		showStagger = true,
		showChi = true,
		showTotems = true,
		showAdditionalPower = true,
	},
	PALADIN = {
		showHolyPower = true,
		showTotems = true,
		showAdditionalPower = true,
	},
	PRIEST = {
		showInsanity = true,
		showAdditionalPower = true,
	},
	ROGUE = {
	},
	SHAMAN = {
		showTotems = true,
		showAdditionalPower = true,
	},
	WARLOCK = {
		showShards = true,
		showTotems = true,
	},
	WARRIOR = {
		showTotems = true,
	},

	showComboPoints = true,

	absorbBar = true,
	absorbtexture = "Interface\\AddOns\\KkthnxUI\\Media\\Textures\\AbsorbTexture",
	absorbspark = "Interface\\AddOns\\KkthnxUI\\Media\\Textures\\AbsorbSpark",

	player = {
		HealthTag = "NUMERIC",
		PowerTag = "PERCENT",
		cbshow = true,
		cbwidth = 200,
		cbheight = 18,
		cbicon = "NONE",
	},

	pet = {
		-- style = "fat",
		-- scale = 1,
		HealthTag = "MINIMAL",
		PowerTag = "DISABLE",
		cbshow = true,
		cbwidth = 200,
		cbheight = 18,
		cbicon = "NONE",
	},

	target = {
		HealthTag = "BOTH",
		PowerTag = "PERCENT",
		buffPos = "BOTTOM",
		debuffPos = "TOP",
		cbshow = true,
		cbwidth = 200,
		cbheight = 18,
		cbicon = "NONE",
	},

	targettarget = {
		enable = true,
		enableAura = false,
		HealthTag = "DISABLE",
	},

	focus = {
		HealthTag = "BOTH",
		PowerTag = "PERCENT",
		buffPos = "NONE",
		debuffPos = "BOTTOM",
		cbshow = true,
		cbwidth = 180,
		cbheight = 20,
		cbicon = "NONE",
	},

	focustarget = {
		enable = true,
		enableAura = false,
		HealthTag = "DISABLE",
	},

	party = {
		HealthTag = "MINIMAL",
		PowerTag = "DISABLE",
	},

	boss = {
		-- scale = 1,
		HealthTag = "PERCENT",
		PowerTag = "PERCENT",
		cbshow = true,
		cboffset = {0, 0},
		cbwidth = 150,
		cbheight = 18,
		cbicon = "NONE",
	},

	arena = {
		HealthTag = "BOTH",
		PowerTag = "PERCENT",
		cboffset = {0, 0},
		cbshow = true,
		cbwidth = 150,
		cbheight = 22,
		cbicon = "NONE",
	},

	units = {
        ["raid"] = {
            showSolo = true,
            showParty = false,

            nameLength = 4,

            width = 42,
            height = 40,
            scale = 1,

            layout = {
                frameSpacing = 4,

                initialAnchor = "TOPLEFT",
                orientation = "HORIZONTAL",
            },

            smoothUpdates = true,
            showThreatText = false,
            showRolePrefix = false,
            showNotHereTimer = true,
            showMainTankIcon = true,
            showResurrectText = true,
            showMouseoverHighlight = true,

            showMainTankFrames = false,

            showTargetBorder = true,
            targetBorderColor = {1, 1, 1},

            iconSize = 22,
            indicatorSize = 7,

            horizontalHealthBars = false,
            deficitThreshold = 0.95,

            manabar = {
                show = true,
                horizontalOrientation = false,
            },
        },
    },
}