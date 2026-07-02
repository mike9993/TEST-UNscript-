-- ============================================================
--  UNMM2 UI  |  Executor: Velocity (Refined & Auto-Save)
--  Auto Toggle Near Murderer Edition (Replaces Anti-Die)
-- ============================================================

local Players          = game:GetService("Players")
local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService       = game:GetService("RunService")
local GuiService       = game:GetService("GuiService")
local HttpService      = game:GetService("HttpService")
local Lighting         = game:GetService("Lighting")
local StarterGui       = game:GetService("StarterGui")
local VirtualUser      = game:GetService("VirtualUser")

local LocalPlayer      = Players.LocalPlayer
local Camera           = workspace.CurrentCamera

local uiParent
do
	local ok = pcall(function() game:GetService("CoreGui"):IsA("DataModel") end)
	uiParent = ok and game:GetService("CoreGui") or LocalPlayer:WaitForChild("PlayerGui")
end

local rgb  = Color3.fromRGB
local ud2  = UDim2.new
local ud   = UDim.new
local bold = Enum.Font.GothamBold
local reg  = Enum.Font.Gotham
local semi = Enum.Font.GothamSemibold

local C = {
	bg         = rgb(25, 25, 25),
	surface    = rgb(35, 35, 35),
	part_bg    = rgb(45, 45, 45),
	surfaceAlt = rgb(40, 40, 40),
	border     = rgb(45, 45, 52),
	accent     = rgb(50, 120, 255),
	textPri    = rgb(218, 218, 222),
	textSec    = rgb(115, 115, 128),
	dot_red    = rgb(220, 80,  70),
	dot_yel    = rgb(255, 215, 0),
	dot_grn    = rgb(60,  180, 90),
	toggle_off = rgb(55,  55,  62),
	toggle_on  = rgb(50,  120, 255),
	knob       = rgb(245, 245, 248),
	white      = rgb(255, 255, 255),
}

local CFG_FOLDER = "UNMM2"
local CFG_FILE   = "settings"
local CFG_EXT    = ".cfg"

local function cfgSafely(fn, ...)
	if fn then
		local ok, res = pcall(fn, ...)
		if not ok then return nil end
		return res
	end
end

local function ensureCfgFolder()
	if isfolder and not cfgSafely(isfolder, CFG_FOLDER) then
		cfgSafely(makefolder, CFG_FOLDER)
	end
end

local function saveConfig(data)
	ensureCfgFolder()
	local ok, encoded = pcall(function() return HttpService:JSONEncode(data) end)
	if ok then
		cfgSafely(writefile, CFG_FOLDER.."/"..CFG_FILE..CFG_EXT, encoded)
	end
end

local function loadConfig()
	local path = CFG_FOLDER.."/"..CFG_FILE..CFG_EXT
	if not cfgSafely(isfile, path) then return nil end
	local content = cfgSafely(readfile, path)
	if not content then return nil end
	local ok, data = pcall(function() return HttpService:JSONDecode(content) end)
	return ok and data or nil
end

local savedCfg = loadConfig() or {}

local cfgTransparency    = savedCfg.transparency    or 0.25
local cfgNotifEnabled    = savedCfg.notifEnabled
if cfgNotifEnabled == nil then cfgNotifEnabled = true end
local cfgKeybind1Name    = savedCfg.keybind1 or "LeftControl"
local cfgKeybind2Name    = savedCfg.keybind2 or "Z"
local cfgIsExpanded      = savedCfg.isExpanded or false
local cfgFavorites       = savedCfg.favorites or {}
local cfgLightMode       = savedCfg.lightMode or false
local cfgSaveInventory   = savedCfg.saveInventory or false
local cfgSaveMode        = savedCfg.saveMode or "All"
local cfgSliderFavs      = savedCfg.sliderFavs or {}
local cfgNameESPEnabled  = savedCfg.nameESPEnabled or false
local cfgChamsEnabled    = savedCfg.chamsEnabled or false
local cfgAutoFarm        = savedCfg.autoFarm or false
local cfgAntiAfk         = savedCfg.antiAfk or false
local cfgDieAfterBag     = savedCfg.dieAfterBag or false
local cfgFarmSpeed       = savedCfg.farmSpeed or 15
local cfgExceedSpeed     = savedCfg.exceedSpeed or false
local cfgAutoToggle      = savedCfg.autoToggle or false
local cfgDetectRadius    = savedCfg.detectRadius or 60
local cfgAutoGrabGun     = savedCfg.autoGrabGun or false
local autoGrabEnabled    = false
local isGrabbing         = false
local grabConn           = nil
local resetCFrame        = nil
local silentAimEnabled   = false
local silentAimKey       = Enum.KeyCode.Period
local killAllLockConn    = nil
local killAllTargets     = {}
local stopKillAll        = function() end
local runSilentAim       = function() end
local updateSilentAimLabel = function() end

local uiTransparency      = cfgTransparency
local startupNotifEnabled = cfgNotifEnabled
local isExpanded          = cfgIsExpanded
local nameESPEnabled      = cfgNameESPEnabled
local chamsEnabled        = cfgChamsEnabled

local function keycodeFromName(name)
	local ok, kc = pcall(function() return Enum.KeyCode[name] end)
	return (ok and kc) or Enum.KeyCode.Unknown
end

local activeKeybind = {
	keycodeFromName(cfgKeybind1Name),
	keycodeFromName(cfgKeybind2Name),
}
silentAimKey = keycodeFromName(savedCfg.silentAimKey or "Period")

local function triggerAutoSave()
	saveConfig({
		transparency  = uiTransparency,
		notifEnabled  = startupNotifEnabled,
		keybind1      = activeKeybind[1].Name,
		keybind2      = activeKeybind[2].Name,
		isExpanded    = isExpanded,
		favorites     = cfgFavorites,
		sliderFavs    = cfgSliderFavs,
		lightMode     = cfgLightMode,
		saveInventory = cfgSaveInventory,
		saveMode      = cfgSaveMode,
		nameESPEnabled = nameESPEnabled,
		chamsEnabled  = chamsEnabled,
		autoFarm      = cfgAutoFarm,
		antiAfk       = cfgAntiAfk,
		dieAfterBag   = cfgDieAfterBag,
		farmSpeed     = cfgFarmSpeed,
		exceedSpeed   = cfgExceedSpeed,
		autoToggle    = cfgAutoToggle,
		detectRadius  = cfgDetectRadius,
		autoGrabGun   = cfgAutoGrabGun,
		silentAimKey  = silentAimKey.Name
	})
end

local themeRegistry = {}

local function applyTheme()
	if cfgLightMode then
		C.bg         = rgb(240, 240, 240)
		C.surface    = rgb(225, 225, 225)
		C.part_bg    = rgb(215, 215, 215)
		C.surfaceAlt = rgb(200, 200, 200)
		C.border     = rgb(180, 180, 180)
		C.textPri    = rgb(30, 30, 30)
		C.textSec    = rgb(90, 90, 90)
		C.toggle_off = rgb(170, 170, 170)
		C.knob       = rgb(255, 255, 255)
		C.white      = rgb(20, 20, 20)
	else
		C.bg         = rgb(25, 25, 25)
		C.surface    = rgb(35, 35, 35)
		C.part_bg    = rgb(45, 45, 45)
		C.surfaceAlt = rgb(40, 40, 40)
		C.border     = rgb(45, 45, 52)
		C.textPri    = rgb(218, 218, 222)
		C.textSec    = rgb(115, 115, 128)
		C.toggle_off = rgb(55,  55,  62)
		C.knob       = rgb(245, 245, 248)
		C.white      = rgb(255, 255, 255)
	end
	for _, record in ipairs(themeRegistry) do
		if record.obj and record.obj.Parent then
			for prop, cKey in pairs(record.tags) do
				if C[cKey] then
					record.obj[prop] = C[cKey]
				end
			end
		end
	end
end

local function Make(className, props)
	local inst = Instance.new(className)
	local tags = {}
	for k, v in pairs(props) do
		inst[k] = v
		if typeof(v) == "Color3" then
			for cKey, cVal in pairs(C) do
				if v == cVal then
					tags[k] = cKey
					break
				end
			end
		end
	end
	if next(tags) then
		table.insert(themeRegistry, {obj = inst, tags = tags})
	end
	return inst
end

local transparencyFrames = {}
local function applyTransparency(t)
	uiTransparency = math.clamp(t, 0, 0.85)
	for _, e in ipairs(transparencyFrames) do
		if e.frame and e.frame.Parent then
			local target = math.clamp(e.base + uiTransparency * (1 - e.base), 0, 0.90)
			e.frame.BackgroundTransparency = target
		end
	end
end

local existingGui = uiParent:FindFirstChild("UNMM2Interface")
if existingGui then existingGui:Destroy() end

local Gui = Make("ScreenGui", {
	Name           = "UNMM2Interface",
	ResetOnSpawn   = false,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	Parent         = uiParent,
})

local NORMAL_W, NORMAL_H = 360, 480

local Main = Make("Frame", {
	Size                   = ud2(0, NORMAL_W, 0, NORMAL_H),
	Position               = ud2(0.5, 0, 0.5, 0),
	AnchorPoint            = Vector2.new(0.5, 0.5),
	BackgroundColor3       = C.bg,
	BackgroundTransparency = uiTransparency,
	BorderSizePixel        = 0,
	Active                 = true,
	ClipsDescendants       = true,
	Parent                 = Gui,
})
Make("UICorner", {CornerRadius = ud(0, 16), Parent = Main})
Make("UIStroke",  {Color = rgb(255,255,255), Thickness = 1, Transparency = 0.7, Parent = Main})

local MainScale = Make("UIScale", {Scale = isExpanded and 1.4 or 1, Parent = Main})

local BorderFrame = Make("Frame", {
	Size = ud2(1,0,1,0), BackgroundTransparency = 1,
	BorderSizePixel = 0, Parent = Main,
})
Make("UICorner", {CornerRadius = ud(0,16), Parent = BorderFrame})
Make("UIStroke",  {Color = rgb(255,255,255), Thickness = 1, Transparency = 0.85, Parent = BorderFrame})

local HeaderBar = Make("Frame", {
	Size = ud2(1,0,0,42), BackgroundTransparency = 1,
	BorderSizePixel = 0, Parent = Main,
})

local function makeDot(xPos, color, parent)
	local dot = Make("TextButton", {
		Size = ud2(0,13,0,13), Position = ud2(0,xPos,0,15),
		Text = "", BackgroundColor3 = color,
		BorderSizePixel = 0, Parent = parent or HeaderBar,
	})
	Make("UICorner", {CornerRadius = ud(1,0), Parent = dot})
	return dot
end
local CloseBtn = makeDot(14, C.dot_red)
local MinBtn   = makeDot(32, C.dot_yel)
local MaxBtn   = makeDot(50, C.dot_grn)

local TitleLabel = Make("TextLabel", {
	Size = ud2(0,100,0,42), Position = ud2(0.5,-50,0,0),
	BackgroundTransparency = 1, Text = "UNMM2",
	TextColor3 = C.textPri, TextSize = 13, Font = bold,
	TextXAlignment = Enum.TextXAlignment.Center,
	TextYAlignment = Enum.TextYAlignment.Center, Parent = HeaderBar,
})

local function makeHeaderIcon(xOffset, icon)
	return Make("TextButton", {
		Size = ud2(0,28,0,28), Position = ud2(1,xOffset,0,7),
		BackgroundTransparency = 1, Text = icon,
		TextColor3 = C.textSec, TextSize = 16, Font = bold, Parent = HeaderBar,
	})
end
local ToggleBtn = makeHeaderIcon(-36, "⚙")

local PillUI = Make("TextButton", {
	Size = ud2(0,110,0,34), Position = ud2(0.5,0,0,12),
	AnchorPoint = Vector2.new(0.5,0), BackgroundColor3 = C.bg,
	BackgroundTransparency = uiTransparency, Text = "UNMM2",
	TextColor3 = C.textPri, Font = bold, TextSize = 12,
	Active = true, Visible = false, Parent = Gui,
})
Make("UICorner", {CornerRadius = ud(1,0), Parent = PillUI})
Make("UIStroke", {Color = C.border, Thickness = 1, Transparency = 0.4, Parent = PillUI})
local PillScale = Make("UIScale", {Scale = 1, Parent = PillUI})

local MainPage = Make("Frame", {
	Size = ud2(1,0,1,-42), Position = ud2(0,0,0,42),
	BackgroundTransparency = 1, ClipsDescendants = true, Parent = Main,
})
local SetPage = Make("Frame", {
	Size = ud2(1,0,1,-42), Position = ud2(0,0,0,42),
	BackgroundTransparency = 1, ClipsDescendants = true,
	Visible = false, Parent = Main,
})

local partState      = {}
local originalToggles = {}
local proxyToggles    = {}

local UninstallOverlay = Make("Frame", {
	Size = ud2(1,0,1,0), Position = ud2(0,0,0,0),
	BackgroundColor3       = C.bg,
	BackgroundTransparency = 0.05,
	BorderSizePixel        = 0,
	ZIndex                 = 100,
	Visible                = false,
	Parent                 = Main,
})
Make("UICorner", {CornerRadius = ud(0, 16), Parent = UninstallOverlay})

Make("TextLabel", {
	Size = ud2(0,48,0,48), Position = ud2(0.5,-24,0,56),
	BackgroundTransparency = 1, Text = "⚠",
	TextColor3 = C.dot_yel, TextSize = 36, Font = bold,
	TextXAlignment = Enum.TextXAlignment.Center, Parent = UninstallOverlay,
})
Make("TextLabel", {
	Size = ud2(1,-40,0,26), Position = ud2(0,20,0,110),
	BackgroundTransparency = 1, Text = "Remove UNMM2?",
	TextColor3 = C.white, TextSize = 16, Font = bold,
	TextXAlignment = Enum.TextXAlignment.Center, Parent = UninstallOverlay,
})
Make("TextLabel", {
	Size = ud2(1,-40,0,60), Position = ud2(0,20,0,144),
	BackgroundTransparency = 1,
	Text = "This will permanently destroy the interface.\nYour saved settings will also be cleared.\nThis action cannot be undone.",
	TextColor3 = C.textSec, TextSize = 12, Font = reg,
	TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Center, Parent = UninstallOverlay,
})
Make("TextLabel", {
	Size = ud2(1,-40,0,18), Position = ud2(0,20,0,212),
	BackgroundTransparency = 1, Text = "[ Enter ] = Yes      [ Backspace ] = No",
	TextColor3 = C.textSec, TextSize = 10, Font = reg,
	TextXAlignment = Enum.TextXAlignment.Center, Parent = UninstallOverlay,
})
Make("Frame", {
	Size = ud2(0,200,0,1), Position = ud2(0.5,-100,0,238),
	BackgroundColor3 = C.border, BackgroundTransparency = 0.3,
	BorderSizePixel = 0, Parent = UninstallOverlay,
})

local UninstallYesBtn = Make("TextButton", {
	Size = ud2(0,120,0,34), Position = ud2(0.5,-128,0,252),
	BackgroundColor3 = C.dot_red, BackgroundTransparency = 0.1,
	Text = "Yes, Remove", TextColor3 = C.white,
	TextSize = 12, Font = bold, Parent = UninstallOverlay,
})
Make("UICorner", {CornerRadius = ud(1,0), Parent = UninstallYesBtn})

local UninstallNoBtn = Make("TextButton", {
	Size = ud2(0,120,0,34), Position = ud2(0.5,8,0,252),
	BackgroundColor3 = C.surfaceAlt, BackgroundTransparency = 0.1,
	Text = "No, Cancel", TextColor3 = C.textPri,
	TextSize = 12, Font = bold, Parent = UninstallOverlay,
})
Make("UICorner", {CornerRadius = ud(1,0), Parent = UninstallNoBtn})

local function runFullUninstall()
	UninstallOverlay.Visible = false
	pcall(function()
		local path = CFG_FOLDER.."/"..CFG_FILE..CFG_EXT
		if cfgSafely(isfile, path) then cfgSafely(delfile, path) end
	end)
	if Gui and Gui.Parent then Gui:Destroy() end
end

UninstallYesBtn.MouseButton1Click:Connect(runFullUninstall)
UninstallNoBtn.MouseButton1Click:Connect(function() UninstallOverlay.Visible = false end)

UserInputService.InputBegan:Connect(function(input, processed)
	if not UninstallOverlay.Visible then return end
	if input.KeyCode == Enum.KeyCode.Return or input.KeyCode == Enum.KeyCode.KeypadEnter then
		runFullUninstall()
	elseif input.KeyCode == Enum.KeyCode.Backspace then
		UninstallOverlay.Visible = false
	end
end)

local activeTab   = "Home"
local tabs        = {}
local tabSections = {Home = {}, ESP = {}, Farm = {}, Combat = {}}
local tabTween    = TweenInfo.new(0.22, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
local sectionTween= TweenInfo.new(0.28, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)

local TabBar = Make("Frame", {
	Size = ud2(1,-24,0,30), Position = ud2(0,12,0,8),
	BackgroundTransparency = 1, Parent = MainPage,
})
Make("UIListLayout", {
	FillDirection = Enum.FillDirection.Horizontal,
	HorizontalAlignment = Enum.HorizontalAlignment.Center,
	Padding = ud(0,6), Parent = TabBar,
})

local function makeTab(name)
	local btn = Make("TextButton", {
		Size = ud2(0,64,0,26), BackgroundColor3 = C.surfaceAlt,
		BackgroundTransparency = 0.5, Text = name,
		TextColor3 = C.textSec, TextSize = 12, Font = bold, Parent = TabBar,
	})
	Make("UICorner", {CornerRadius = ud(1,0), Parent = btn})
	local pill = Make("Frame", {
		Size = ud2(0,0,0,2), Position = ud2(0.5,0,1,-2),
		AnchorPoint = Vector2.new(0.5,0), BackgroundColor3 = C.accent,
		BorderSizePixel = 0, Parent = btn,
	})
	Make("UICorner", {CornerRadius = ud(1,0), Parent = pill})
	return {Button = btn, Pill = pill, Name = name}
end

tabs.Home   = makeTab("Home")
tabs.ESP    = makeTab("ESP")
tabs.Farm   = makeTab("Farm")
tabs.Combat = makeTab("Combat")

local CollapseAllBtn = Make("TextButton", {
	Size = ud2(0,26,0,26), BackgroundColor3 = C.surfaceAlt,
	BackgroundTransparency = 0.3, Text = "^", TextColor3 = C.textSec,
	TextSize = 14, Font = bold, LayoutOrder = 10, Visible = false, Parent = TabBar,
})
Make("UICorner", {CornerRadius = ud(0,6), Parent = CollapseAllBtn})
Make("UIStroke", {Color = C.border, Thickness = 1, Transparency = 0.4, Parent = CollapseAllBtn})

local TabContent = Make("Frame", {
	Size = ud2(1,-24,1,-44), Position = ud2(0,12,0,44),
	BackgroundTransparency = 1, ClipsDescendants = true, Parent = MainPage,
})
local SectionScroll = Make("ScrollingFrame", {
	Size = ud2(1,0,1,0), BackgroundTransparency = 1, BorderSizePixel = 0,
	ScrollBarThickness = 2, ScrollBarImageColor3 = C.border,
	CanvasSize = ud2(0,0,0,0), AutomaticCanvasSize = Enum.AutomaticSize.Y,
	Active = true, Parent = TabContent,
})
Make("UIListLayout", {SortOrder = Enum.SortOrder.LayoutOrder, Padding = ud(0,0), Parent = SectionScroll})

local toggleTween = TweenInfo.new(0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)

local function makeToggle(parent, yPos, callback, initOn)
	local track = Make("Frame", {
		Size = ud2(0,36,0,18), Position = ud2(1,-46,0,yPos),
		BackgroundColor3 = initOn and C.toggle_on or C.toggle_off,
		BorderSizePixel = 0, Parent = parent,
	})
	Make("UICorner", {CornerRadius = ud(1,0), Parent = track})

	local knob = Make("Frame", {
		Size = ud2(0,14,0,14),
		Position = initOn and ud2(0,20,0,2) or ud2(0,2,0,2),
		BackgroundColor3 = C.knob, BorderSizePixel = 0, Parent = track,
	})
	Make("UICorner", {CornerRadius = ud(1,0), Parent = knob})
	Make("UIStroke", {Color = rgb(0,0,0), Thickness = 1, Transparency = 0.7, Parent = knob})

	local isOn = initOn == true
	local hitbox = Make("TextButton", {
		Size = ud2(1,0,1,0), BackgroundTransparency = 1, Text = "",
		ZIndex = knob.ZIndex + 1, Parent = track,
	})

	local function setOn(state, silent)
		isOn = state
		track.BackgroundColor3 = isOn and C.toggle_on or C.toggle_off
		knob.Position = isOn and ud2(0,20,0,2) or ud2(0,2,0,2)
		TweenService:Create(knob, toggleTween, {
			Position = isOn and ud2(0,20,0,2) or ud2(0,2,0,2)
		}):Play()
		TweenService:Create(track, toggleTween, {
			BackgroundColor3 = isOn and C.toggle_on or C.toggle_off
		}):Play()
		if callback and not silent then callback(isOn) end
	end

	hitbox.MouseButton1Click:Connect(function()
		setOn(not isOn, false)
	end)
	return {Track = track, Knob = knob, IsOn = function() return isOn end, SetOn = setOn}
end

local PART_H = 32
local SECTION_H = 38
local SLIDER_H = 48
local LABEL_H = 22

local sliderFavObj = {}
local sliderParams = {}
local buttonParams = {}

local function makeButton(parent, label, callback, uid, isProxy, layoutOrder)
	local pill = Make("Frame", {
		Size = ud2(1,-8,0,PART_H), BackgroundColor3 = C.surfaceAlt,
		BackgroundTransparency = 0.1, BorderSizePixel = 0,
		LayoutOrder = layoutOrder or 0, Parent = parent,
	})
	pill:SetAttribute("SearchName", label)
	Make("UICorner", {CornerRadius = ud(1,0), Parent = pill})
	Make("UIStroke", {Color = C.border, Thickness = 1, Transparency = 0.4, Parent = pill})

	local lbl = Make("TextLabel", {
		Size = ud2(0,120,1,0), Position = ud2(0,14,0,0),
		BackgroundTransparency = 1, Text = label,
		TextColor3 = C.textPri, TextSize = 11, Font = semi,
		TextXAlignment = Enum.TextXAlignment.Left, Parent = pill,
	})

	local btn = Make("TextButton", {
		Size = ud2(0,70,0,22), Position = ud2(1,-80,0.5,-11),
		BackgroundColor3 = C.accent, BackgroundTransparency = 0.1,
		Text = "Run", TextColor3 = C.white,
		TextSize = 10, Font = bold, Parent = pill,
	})
	Make("UICorner", {CornerRadius = ud(0,4), Parent = btn})
	btn.MouseButton1Click:Connect(function()
		if callback then callback() end
		btn.Text = "Done!"
		task.delay(0.8, function() btn.Text = "Run" end)
	end)

	if uid then
		if isProxy then
			local star = Make("TextButton", {
				Size = ud2(0,24,0,24), Position = ud2(1,-102,0,4),
				BackgroundTransparency = 1, Text = "★",
				TextColor3 = C.dot_yel,
				TextSize = 18, Font = bold, Parent = pill,
			})
			star.MouseButton1Click:Connect(function()
				cfgFavorites[uid] = false
				if buttonParams[uid] and buttonParams[uid].star then
					buttonParams[uid].star.TextColor3 = C.textSec
				end
				triggerAutoSave()
				if rebuildFavorites then rebuildFavorites() end
			end)
		else
			local star = Make("TextButton", {
				Size = ud2(0,22,0,22), Position = ud2(1,-100,0,5),
				BackgroundTransparency = 1, Text = "★",
				TextColor3 = cfgFavorites[uid] and C.dot_yel or C.textSec,
				TextSize = 18, Font = bold, Parent = pill,
			})
			buttonParams[uid] = { name = label, callback = callback, star = star }
			star.MouseButton1Click:Connect(function()
				cfgFavorites[uid] = not cfgFavorites[uid]
				local color = cfgFavorites[uid] and C.dot_yel or C.textSec
				star.TextColor3 = color
				triggerAutoSave()
				if rebuildFavorites then rebuildFavorites() end
			end)
		end
	end

	return pill
end

local function makeLabel(parent, text, uid, layoutOrder)
	local lbl = Make("TextLabel", {
		Size = ud2(1,-8,0,LABEL_H), BackgroundTransparency = 1,
		Text = " -- " .. text .. " --", TextColor3 = C.textSec,
		TextSize = 10, Font = bold, LayoutOrder = layoutOrder,
		TextXAlignment = Enum.TextXAlignment.Center, Parent = parent,
	})
	lbl:SetAttribute("SearchName", text)
	return lbl
end

local favSectionObj   = nil
local rebuildFavorites
local activeSectionObj = nil
local rebuildActive

local function createTogglePart(parent, pName, uid, layoutOrder, isProxy, extraCallback)
	local partPill = Make("Frame", {
		Size = ud2(1,-8,0,PART_H), BackgroundColor3 = C.part_bg,
		BackgroundTransparency = 0.3, BorderSizePixel = 0,
		LayoutOrder = layoutOrder, Parent = parent,
	})
	partPill:SetAttribute("SearchName", pName)
	Make("UICorner", {CornerRadius = ud(1,0), Parent = partPill})
	Make("TextLabel", {
		Size = ud2(1,-80,1,0), Position = ud2(0,14,0,0),
		BackgroundTransparency = 1, Text = pName,
		TextColor3 = C.textPri, TextSize = 11, Font = reg,
		TextXAlignment = Enum.TextXAlignment.Left, Parent = partPill,
	})

	local toggle
	toggle = makeToggle(partPill, (PART_H-18)/2, function(state)
		partState[uid] = state

		if isProxy then
			if originalToggles[uid] then originalToggles[uid].toggle.SetOn(state, false) end
		else
			if proxyToggles[uid] then proxyToggles[uid].toggle.SetOn(state, true) end
		end

		if not isProxy and extraCallback then extraCallback(state) end

		if rebuildActive then rebuildActive() end
		if rebuildFavorites then rebuildFavorites() end
	end, partState[uid] or false)

	local star = Make("TextButton", {
		Size = ud2(0,22,0,22), Position = ud2(1,-74,0,5),
		BackgroundTransparency = 1, Text = "★",
		TextColor3 = cfgFavorites[uid] and C.dot_yel or C.textSec,
		TextSize = 18, Font = bold, Parent = partPill,
	})

	star.MouseButton1Click:Connect(function()
		cfgFavorites[uid] = not cfgFavorites[uid]
		local color = cfgFavorites[uid] and C.dot_yel or C.textSec
		star.TextColor3 = color
		if isProxy then
			if originalToggles[uid] then originalToggles[uid].star.TextColor3 = color end
		else
			if proxyToggles[uid] then proxyToggles[uid].star.TextColor3 = color end
		end
		triggerAutoSave()
		rebuildFavorites()
	end)

	if isProxy then
		proxyToggles[uid] = { toggle = toggle, star = star, pill = partPill }
	else
		originalToggles[uid] = { toggle = toggle, star = star, name = pName, pill = partPill }
	end
	return partPill
end

function rebuildFavorites()
	if not favSectionObj then return end
	for _, child in ipairs(favSectionObj.Content:GetChildren()) do
		if child:IsA("Frame") or child:IsA("TextLabel") or child:IsA("TextButton") then
			child:Destroy()
		end
	end
	proxyToggles = {}

	local count = 0
	local favList = {}
	for uid, isFav in pairs(cfgFavorites) do
		if isFav == true and uid ~= "" then
			local hasSource = originalToggles[uid] or buttonParams[uid]
			if hasSource then
				table.insert(favList, uid)
			end
		end
	end
	table.sort(favList)

	for i, uid in ipairs(favList) do
		local rendered = false
		if originalToggles[uid] then
			local pName = originalToggles[uid].name
			createTogglePart(favSectionObj.Content, pName, uid, i, true)
			count = count + 1
			rendered = true
		end
		if not rendered and buttonParams[uid] then
			local bData = buttonParams[uid]
			makeButton(favSectionObj.Content, bData.name, bData.callback, uid, true, i)
			count = count + 1
			rendered = true
		end
	end

	local emptyLabel = favSectionObj.Content:FindFirstChild("FavEmptyLabel")
	if count == 0 then
		if not emptyLabel then
			Make("TextLabel", {
				Name = "FavEmptyLabel",
				Size = ud2(1,-8,0,28), BackgroundTransparency = 1,
				Text = "No favorites", TextColor3 = C.textSec,
				TextSize = 11, Font = reg, LayoutOrder = 0, Parent = favSectionObj.Content,
			})
		end
	else
		if emptyLabel then emptyLabel:Destroy() end
	end

	favSectionObj.resizeToContent()

	local ch = favSectionObj.Content.Size.Y.Offset
	local totalH = SECTION_H + 4 + ch
	if favSectionObj.IsOpen() then
		favSectionObj.Wrapper.Size = ud2(1,-16,0,totalH)
	end

	task.delay(0.15, function()
		if favSectionObj then
			favSectionObj.resizeToContent()
			local ch2 = favSectionObj.Content.Size.Y.Offset
			local totalH2 = SECTION_H + 4 + ch2
			if favSectionObj.IsOpen() then
				favSectionObj.Wrapper.Size = ud2(1,-16,0,totalH2)
			end
		end
	end)
end

function rebuildActive()
	if not activeSectionObj then return end
	for _, child in ipairs(activeSectionObj.Content:GetChildren()) do
		if child:IsA("Frame") then child:Destroy() end
	end

	local count = 0
	local activeList = {}
	for uid, isOn in pairs(partState) do
		if isOn and originalToggles[uid] then
			table.insert(activeList, uid)
		end
	end
	table.sort(activeList)

	for i, uid in ipairs(activeList) do
		local data = originalToggles[uid]
		local pName = data.name

		local item = Make("Frame", {
			Size = ud2(1,-8,0,PART_H), BackgroundColor3 = C.part_bg,
			BackgroundTransparency = 0.3, BorderSizePixel = 0,
			LayoutOrder = i, Parent = activeSectionObj.Content,
		})
		item:SetAttribute("SearchName", pName)
		Make("UICorner", {CornerRadius = ud(1,0), Parent = item})

		local statusDot = Make("Frame", {
			Size = ud2(0,8,0,8), Position = ud2(0,14,0,12),
			BackgroundColor3 = C.dot_grn, BorderSizePixel = 0, Parent = item,
		})
		Make("UICorner", {CornerRadius = ud(1,0), Parent = statusDot})

		Make("TextLabel", {
			Size = ud2(1,-100,1,0), Position = ud2(0,30,0,0),
			BackgroundTransparency = 1, Text = pName,
			TextColor3 = C.textPri, TextSize = 11, Font = reg,
			TextXAlignment = Enum.TextXAlignment.Left, Parent = item,
		})

		local disableBtn = Make("TextButton", {
			Size = ud2(0,52,0,20), Position = ud2(1,-66,0,6),
			BackgroundColor3 = C.dot_red, BackgroundTransparency = 0.15,
			Text = "Disable", TextColor3 = C.white,
			TextSize = 10, Font = bold, Parent = item,
		})
		Make("UICorner", {CornerRadius = ud(0,4), Parent = disableBtn})

		disableBtn.MouseButton1Click:Connect(function()
			partState[uid] = false
			if data.toggle then data.toggle.SetOn(false, false) end
			if proxyToggles[uid] then proxyToggles[uid].toggle.SetOn(false, false) end
			rebuildActive()
		end)

		count = count + 1
	end

	local emptyLabel = activeSectionObj.Content:FindFirstChild("ActiveEmptyLabel")
	if count == 0 then
		if not emptyLabel then
			Make("TextLabel", {
				Name = "ActiveEmptyLabel",
				Size = ud2(1,-8,0,28), BackgroundTransparency = 1,
				Text = "No active features", TextColor3 = C.textSec,
				TextSize = 11, Font = reg, LayoutOrder = 0, Parent = activeSectionObj.Content,
			})
		end
	else
		if emptyLabel then emptyLabel:Destroy() end
	end

	activeSectionObj.resizeToContent()

	if activeSectionObj.IsOpen() then
		local ch = activeSectionObj.Content.Size.Y.Offset
		local totalH = SECTION_H + 4 + ch
		TweenService:Create(activeSectionObj.Wrapper, sectionTween, { Size = ud2(1,-16,0,totalH) }):Play()
	end

	task.delay(0.15, function()
		if activeSectionObj then
			activeSectionObj.resizeToContent()
			if activeSectionObj.IsOpen() then
				local ch2 = activeSectionObj.Content.Size.Y.Offset
				local totalH2 = SECTION_H + 4 + ch2
				activeSectionObj.Wrapper.Size = ud2(1,-16,0,totalH2)
			end
		end
	end)
end

local function updateCollapseAllVisibility()
	if not activeTab then CollapseAllBtn.Visible = false; return end
	local n = 0
	for _, sec in ipairs(tabSections[activeTab]) do
		if sec.IsOpen() then n = n + 1 end
	end
	CollapseAllBtn.Visible = (n > 1)
end

local function makeSection(sectionName, parentContainer, tabKey, isFavSection, isActiveSection)
	local wrapper = Make("Frame", {
		Size = ud2(1,-16,0,SECTION_H), BackgroundTransparency = 1,
		ClipsDescendants = true, Parent = parentContainer,
	})
	local header = Make("Frame", {
		Size = ud2(1,-2,0,SECTION_H - 2), Position = ud2(0,1,0,1),
		BackgroundColor3 = C.surface,
		BackgroundTransparency = 0.3, BorderSizePixel = 0, Parent = wrapper,
	})
	Make("UICorner", {CornerRadius = ud(1,0), Parent = header})
	Make("UIStroke", {Color = rgb(255,255,255), Thickness = 1, Transparency = 0.85, Parent = header})
	local arrow = Make("TextLabel", {
		Size = ud2(0,28,1,0), Position = ud2(0,10,0,0),
		BackgroundTransparency = 1, Text = "+", TextColor3 = C.textSec,
		TextSize = 18, Font = bold, Parent = header,
	})
	local titleLbl = Make("TextLabel", {
		Size = ud2(1,-50,1,0), Position = ud2(0,32,0,0),
		BackgroundTransparency = 1, Text = sectionName,
		TextColor3 = C.textPri, TextSize = 12, Font = bold,
		TextXAlignment = Enum.TextXAlignment.Left, Parent = header,
	})

	local content = Make("Frame", {
		Size = ud2(1,0,0,0), Position = ud2(0,0,0,SECTION_H+4),
		BackgroundTransparency = 1, ClipsDescendants = true, Parent = wrapper,
	})
	Make("UIListLayout", {SortOrder = Enum.SortOrder.LayoutOrder, Padding = ud(0,5), Parent = content})

	local isOpen = false
	local obj = {
		Wrapper = wrapper, Content = content, TitleLabel = titleLbl,
		IsOpen = function() return isOpen end, Name = sectionName,
		resizeToContent = function()
			local layout = content:FindFirstChildOfClass("UIListLayout")
			local h = layout and layout.AbsoluteContentSize.Y or 0
			if h <= 0 then
				h = 0
				local pad = (layout and layout.Padding.Offset) or 5
				for _, child in ipairs(content:GetChildren()) do
					if child:IsA("GuiObject") and child.Visible then
						local sy = child.Size.Y.Offset
						if sy <= 0 then
							if child:IsA("Frame") then sy = PART_H
							elseif child:IsA("TextLabel") then sy = LABEL_H
							else sy = 32 end
						end
						h = h + sy + pad
					end
				end
			end
			content.Size = ud2(1,0,0, h)
		end,
	}

	if isActiveSection then
		activeSectionObj = obj
	elseif isFavSection then
		favSectionObj = obj
	end

	local function setOpen(state)
		isOpen = state
		arrow.Text = isOpen and "-" or "+"
		if isOpen then obj.resizeToContent() end
		local ch = content.Size.Y.Offset
		local totalH = SECTION_H + 4 + ch
		if isOpen then
			wrapper.Size = ud2(1,-16,0,totalH)
		else
			TweenService:Create(wrapper, sectionTween, {
				Size = ud2(1,-16,0,SECTION_H)
			}):Play()
		end
		if isOpen then
			task.delay(0.15, function()
				obj.resizeToContent()
				local ch2 = content.Size.Y.Offset
				local totalH2 = SECTION_H + 4 + ch2
				wrapper.Size = ud2(1,-16,0,totalH2)
			end)
		end
		updateCollapseAllVisibility()
	end
	obj.SetOpen = setOpen

	local hBtn = Make("TextButton", {
		Size = ud2(1,0,1,0), BackgroundTransparency = 1, Text = "", Parent = header,
	})
	hBtn.MouseButton1Click:Connect(function() setOpen(not isOpen) end)

	table.insert(tabSections[tabKey], obj)
	return obj
end

-- ============================================================
-- FIXED ESP IMPLEMENTATION - Instant Detection Fix
-- ============================================================

local playerHighlights = {}
local highlightConnections = {}
local rolesData = nil
local espEnabled = false

local function getRoleColor(role)
	if role == "Murderer" then return C.dot_red end
	if role == "Sheriff" then return rgb(0, 120, 255) end
	if role == "Hero" then return rgb(255, 215, 0) end
	return C.dot_grn
end

-- INSTANT ROLE FIX: Checks inventory BEFORE game server catches up
local function getActualRole(player)
	if player.Character and player.Character:FindFirstChild("Knife") then return "Murderer" end
	if player.Character and player.Character:FindFirstChild("Gun") then return "Sheriff" end
	if player:FindFirstChild("Backpack") then
		if player.Backpack:FindFirstChild("Knife") then return "Murderer" end
		if player.Backpack:FindFirstChild("Gun") then return "Sheriff" end
	end
	
	if rolesData and rolesData[player.Name] then
		return rolesData[player.Name].Role or "Innocent"
	end
	
	return "Innocent"
end

local ESPFolder = Instance.new("Folder")
ESPFolder.Name = "ESP_Holder"
ESPFolder.Parent = game:GetService("CoreGui")

local playerBillboards = {}

local function createBillboard(player)
	if player == LocalPlayer or playerBillboards[player] then return end

	local billboard = Instance.new("BillboardGui")
	billboard.Name = player.Name .. "_Billboard"
	billboard.AlwaysOnTop = true
	billboard.Size = UDim2.new(0, 200, 0, 50)
	billboard.ExtentsOffset = Vector3.new(0, 3, 0)
	billboard.Enabled = nameESPEnabled and player ~= LocalPlayer
	billboard.Parent = ESPFolder

	local label = Instance.new("TextLabel")
	label.Name = "PlayerNameLabel"
	label.TextSize = 16
	label.Text = player.Name
	label.Font = Enum.Font.GothamBold
	label.BackgroundTransparency = 1
	label.Size = UDim2.new(1, 0, 1, 0)
	label.TextStrokeTransparency = 0
	label.TextStrokeColor3 = Color3.new(0, 0, 0)
	label.Parent = billboard

	local function update()
		if not player.Parent or not billboard.Parent then
			if billboard.Parent then billboard:Destroy() end
			playerBillboards[player] = nil
			return
		end
		local char = player.Character
		if char and char:FindFirstChild("Head") then
			billboard.Adornee = char.Head
			local role = getActualRole(player)
			label.TextColor3 = getRoleColor(role)
			billboard.Enabled = nameESPEnabled and player ~= LocalPlayer
		end
	end

	task.spawn(function()
		while player and player.Parent and billboard and billboard.Parent do
			update()
			task.wait(0.5)
		end
		if billboard and billboard.Parent then
			billboard:Destroy()
		end
		if playerBillboards[player] == billboard then
			playerBillboards[player] = nil
		end
	end)

	playerBillboards[player] = billboard
end

local function removeBillboard(player)
	local bb = playerBillboards[player]
	if bb then
		bb:Destroy()
	end
	playerBillboards[player] = nil
end

local function createHighlightForCharacter(player, character)
	if player == LocalPlayer or not character or character:FindFirstChild("RoleHighlight") then return end

	local highlight = Instance.new("Highlight")
	highlight.Name = "RoleHighlight"
	highlight.FillTransparency = 0.5
	highlight.OutlineColor = Color3.fromRGB(0, 0, 0)
	highlight.Parent = character
	highlight.Enabled = chamsEnabled

	local role = getActualRole(player)
	highlight.FillColor = getRoleColor(role)

	if not playerHighlights[player] then
		playerHighlights[player] = {}
	end
	playerHighlights[player][character] = highlight
end

local function removeHighlightsForPlayer(player)
	local highlights = playerHighlights[player]
	if highlights then
		for _, highlight in pairs(highlights) do
			if highlight and highlight.Parent then
				highlight:Destroy()
			end
		end
		playerHighlights[player] = nil
	end
	local conn = highlightConnections[player]
	if conn then
		conn:Disconnect()
		highlightConnections[player] = nil
	end
end

local function setupPlayer(player)
	if player == LocalPlayer then return end

	local function onCharacterAdded(character)
		createHighlightForCharacter(player, character)
	end

	if player.Character then
		onCharacterAdded(player.Character)
	end

	local conn = player.CharacterAdded:Connect(onCharacterAdded)
	highlightConnections[player] = conn
end

local function cleanupPlayer(player)
	removeHighlightsForPlayer(player)
	removeBillboard(player)
end

for _, player in ipairs(Players:GetPlayers()) do
	createBillboard(player)
	setupPlayer(player)
end

Players.PlayerAdded:Connect(function(player)
	createBillboard(player)
	setupPlayer(player)
end)
Players.PlayerRemoving:Connect(cleanupPlayer)

task.spawn(function()
	while task.wait(2) do
		if espEnabled or chamsEnabled or nameESPEnabled then
			pcall(function()
				local remote = game.ReplicatedStorage:FindFirstChild("GetPlayerData", true)
				if remote then
					rolesData = remote:InvokeServer()
				end
			end)
		end
	end
end)

RunService.RenderStepped:Connect(function()
	if not (espEnabled or chamsEnabled or nameESPEnabled) then return end

	for _, player in ipairs(Players:GetPlayers()) do
		if player == LocalPlayer then continue end

		local character = player.Character
		if not character then continue end

		local role = getActualRole(player)

		local highlight = character:FindFirstChild("RoleHighlight")
		if highlight then
			highlight.FillColor = getRoleColor(role)
			highlight.Enabled = chamsEnabled
		end

		local billboard = playerBillboards[player]
		if billboard and billboard.Parent then
			local label = billboard:FindFirstChild("PlayerNameLabel")
			if label then
				label.TextColor3 = getRoleColor(role)
			end
			billboard.Enabled = nameESPEnabled and player ~= LocalPlayer
		end
	end
end)

-- ============================================================
-- AUTO TOGGLE NEAR MURDERER LOGIC (Displacement Invisibility)
-- ============================================================
local invisActive = false
local invisParts = {}
local invisConn = nil
local charConn = nil
local toolConn = nil
local autoDetectConn = nil
local autoTriggered = false
local lastNearTime = 0
local realPlayerCFrame = nil 

local function setupInvisParts()
	invisParts = {}
	local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
	if char then
		for _, v in pairs(char:GetDescendants()) do
			if v:IsA("BasePart") and v.Transparency == 0 then table.insert(invisParts, v) end
		end

		if toolConn then toolConn:Disconnect() end
		toolConn = char.DescendantAdded:Connect(function(v)
			if v:IsA("BasePart") and v.Transparency == 0 then
				table.insert(invisParts, v)
				if invisActive then v.Transparency = 0.5 end
			end
		end)
	end
end

local function setInvisState(state)
	invisActive = state
	for _, v in pairs(invisParts) do
		if v.Parent then v.Transparency = state and 0.5 or 0 end
	end
end

local function startInvisLoop()
	if invisConn then invisConn:Disconnect() end
	local u8, u7
	invisConn = RunService.Heartbeat:Connect(function()
		if not invisActive then return end
		local char = LocalPlayer.Character
		if not char then return end

		u8 = char:FindFirstChild("HumanoidRootPart")
		u7 = char:FindFirstChildOfClass("Humanoid")
		if not u8 or not u7 or u7.Health <= 0 then return end
		
		local _CFrame = u8.CFrame
		realPlayerCFrame = _CFrame 
		
		local _CameraOffset = u7.CameraOffset
		local v40 = _CFrame * CFrame.new(0, -200000, 0)
		local _Position = v40:ToObjectSpace(CFrame.new(_CFrame.Position)).Position
		u8.CFrame = v40
		u7.CameraOffset = _Position
		
		RunService.RenderStepped:Wait()
		
		if u8 and u7 and u8.Parent and u7.Health > 0 then
			u8.CFrame = _CFrame
			u7.CameraOffset = _CameraOffset
		end
		
		realPlayerCFrame = nil
	end)
end

local function stopInvisLoop()
	if invisConn then invisConn:Disconnect(); invisConn = nil end
	realPlayerCFrame = nil
end

local function isMurdererNearby()
	local char = LocalPlayer.Character
	if not char then return false end
	local hrp = char:FindFirstChild("HumanoidRootPart")
	if not hrp then return false end

	local myPos = hrp.Position
	if invisActive and realPlayerCFrame then
		myPos = realPlayerCFrame.Position
	end

	for _, obj in ipairs(workspace:GetChildren()) do
		if obj.Name:lower():find("knife") then
			local objPos = nil
			if obj:IsA("BasePart") then
				objPos = obj.Position
			elseif obj:IsA("Model") and obj.PrimaryPart then
				objPos = obj.PrimaryPart.Position
			elseif obj:IsA("Model") then
				local part = obj:FindFirstChildWhichIsA("BasePart", true)
				if part then objPos = part.Position end
			end
			
			if objPos and (myPos - objPos).Magnitude <= cfgDetectRadius then
				return true
			end
		end
	end

	for _, p in ipairs(Players:GetPlayers()) do
		if p ~= LocalPlayer and p.Character then
			local mHRP = p.Character:FindFirstChild("HumanoidRootPart")
			if mHRP then
				local mPos = mHRP.Position
				if mPos.Y < -50000 then mPos = mPos + Vector3.new(0, 200000, 0) end
				
				if (myPos - mPos).Magnitude <= cfgDetectRadius then
					for _, item in ipairs(p.Character:GetChildren()) do
						if item:IsA("Tool") and item.Name:lower():find("knife") then return true end
					end
					local bp = p:FindFirstChild("Backpack")
					if bp then
						for _, item in ipairs(bp:GetChildren()) do
							if item:IsA("Tool") and item.Name:lower():find("knife") then return true end
						end
					end
				end
			end
		end
	end
	return false
end

local function startAutoDetect()
	if autoDetectConn then return end
	autoDetectConn = RunService.Heartbeat:Connect(function()
		if not cfgAutoToggle then return end
		
		local near = isMurdererNearby()
		
		if near then
			lastNearTime = tick()
			if not invisActive then
				autoTriggered = true
				startInvisLoop()
				setInvisState(true)
			end
		else
			if autoTriggered and invisActive and (tick() - lastNearTime > 0.5) then
				autoTriggered = false
				stopInvisLoop()
				setInvisState(false)
			elseif not invisActive then
				autoTriggered = false
			end
		end
	end)
end

local function stopAutoDetect()
	if autoDetectConn then autoDetectConn:Disconnect(); autoDetectConn = nil end
	autoTriggered = false
	if invisActive then
		stopInvisLoop()
		setInvisState(false)
	end
end

task.spawn(setupInvisParts)
charConn = LocalPlayer.CharacterAdded:Connect(function()
	invisActive = false
	stopInvisLoop()
	autoTriggered = false
	lastNearTime = 0
	realPlayerCFrame = nil
	isGrabbing = false
	stopKillAll()
	for _, tool in ipairs(LocalPlayer.Backpack:GetChildren()) do
		if tool:IsA("Tool") and tool.Name:lower():find("gun") then tool:Destroy() end
	end
	if autoGrabEnabled and grabConn then
		grabConn:Disconnect()
		grabConn = nil
		task.defer(function() toggleGrabber(true) end)
	end
	task.wait(0.5)
	setupInvisParts()
	if resetCFrame then
		local newChar = LocalPlayer.Character
		if newChar then
			local hrp = newChar:WaitForChild("HumanoidRootPart", 5)
			if hrp then
				hrp.CFrame = resetCFrame
			end
		end
		resetCFrame = nil
	end
end)

if cfgAutoToggle then
	task.defer(startAutoDetect)
end

-- ============================================================
-- AUTO GRAB GUN LOGIC
-- ============================================================

local function grabGunOnce()
	if isGrabbing then return end
	local char = LocalPlayer.Character
	if char then
		for _, t in ipairs(char:GetChildren()) do
			if t:IsA("Tool") and t.Name:lower():find("gun") then return end
		end
		for _, t in ipairs(LocalPlayer.Backpack:GetChildren()) do
			if t:IsA("Tool") and t.Name:lower():find("gun") then return end
		end
	end
	local gunDrop = workspace:FindFirstChild("GunDrop", true)
	if not gunDrop then return end
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	if not hrp then return end
	isGrabbing = true
	task.spawn(function()
		if type(firetouchinterest) == "function" then
			local touchPart = gunDrop:IsA("BasePart") and gunDrop or gunDrop:FindFirstChildWhichIsA("BasePart", true)
			if touchPart then
				firetouchinterest(hrp, touchPart, 0)
				task.wait()
				firetouchinterest(hrp, touchPart, 1)
			end
		else
			local cam = workspace.CurrentCamera
			local oldCamType = cam.CameraType
			local oldCamCFrame = cam.CFrame
			local originalCFrame = hrp.CFrame
			local originalVelocity = hrp.AssemblyLinearVelocity
			cam.CameraType = Enum.CameraType.Scriptable
			cam.CFrame = oldCamCFrame
			hrp.CFrame = gunDrop:IsA("Model") and gunDrop:GetPivot() or gunDrop.CFrame
			task.wait(0.2)
			if hrp.Parent then
				hrp.CFrame = originalCFrame
				hrp.AssemblyLinearVelocity = originalVelocity
			end
			cam.CameraType = oldCamType
			cam.CFrame = oldCamCFrame
		end
		task.wait(0.3)
		isGrabbing = false
	end)
end

local function toggleGrabber(state)
	autoGrabEnabled = state
	if autoGrabEnabled then
		if not grabConn then
			grabConn = RunService.Heartbeat:Connect(function()
				if not autoGrabEnabled or isGrabbing then return end
				local char = LocalPlayer.Character
				if char and char:FindFirstChildWhichIsA("Tool", true) then
					local hasGun = false
					for _, t in ipairs(char:GetChildren()) do
						if t:IsA("Tool") and t.Name:lower():find("gun") then hasGun = true; break end
					end
					if not hasGun then
						for _, t in ipairs(LocalPlayer.Backpack:GetChildren()) do
							if t:IsA("Tool") and t.Name:lower():find("gun") then hasGun = true; break end
						end
					end
					if hasGun then return end
				end
				local gunDrop = workspace:FindFirstChild("GunDrop", true)
				if gunDrop then
					local char = LocalPlayer.Character
					local hrp = char and char:FindFirstChild("HumanoidRootPart")
					if hrp then
						isGrabbing = true
						task.spawn(function()
							if type(firetouchinterest) == "function" then
								local touchPart = gunDrop:IsA("BasePart") and gunDrop or gunDrop:FindFirstChildWhichIsA("BasePart", true)
								if touchPart then
									firetouchinterest(hrp, touchPart, 0)
									task.wait()
									firetouchinterest(hrp, touchPart, 1)
								end
							else
								local cam = workspace.CurrentCamera
								local oldCamType = cam.CameraType
								local oldCamCFrame = cam.CFrame
								local originalCFrame = hrp.CFrame
								local originalVelocity = hrp.AssemblyLinearVelocity
								cam.CameraType = Enum.CameraType.Scriptable
								cam.CFrame = oldCamCFrame
								hrp.CFrame = gunDrop:IsA("Model") and gunDrop:GetPivot() or gunDrop.CFrame
								task.wait(0.2)
								if hrp.Parent then
									hrp.CFrame = originalCFrame
									hrp.AssemblyLinearVelocity = originalVelocity
								end
								cam.CameraType = oldCamType
								cam.CFrame = oldCamCFrame
							end
							while autoGrabEnabled and workspace:FindFirstChild("GunDrop", true) do
								task.wait(0.1)
							end
							isGrabbing = false
						end)
					end
				end
			end)
		end
	else
		if grabConn then grabConn:Disconnect(); grabConn = nil end
		isGrabbing = false
	end
end

-- ============================================================
-- BUILD TAB CONTAINERS
-- ============================================================

local homeContainer = Make("Frame", {
	Size = ud2(1,0,0,0), BackgroundTransparency = 1,
	AutomaticSize = Enum.AutomaticSize.Y,
	Visible = true, Parent = SectionScroll,
})
Make("UIListLayout", {SortOrder = Enum.SortOrder.LayoutOrder, Padding = ud(0,5), Parent = homeContainer})

local espContainer = Make("Frame", {
	Size = ud2(1,0,0,0), BackgroundTransparency = 1,
	AutomaticSize = Enum.AutomaticSize.Y,
	Visible = false, Parent = SectionScroll,
})
Make("UIListLayout", {SortOrder = Enum.SortOrder.LayoutOrder, Padding = ud(0,5), Parent = espContainer})

makeSection("Active", homeContainer, "Home", false, true)
makeSection("Favorites", homeContainer, "Home", true, false)

-- PICK MAP SECTION
do
	local mapPickSection = makeSection("Pick Map", homeContainer, "Home", false, false)

	local function tpToDetector(name)
		local detector = workspace:FindFirstChild(name, true)
		if not detector then return end
		local char = LocalPlayer.Character
		local hrp = char and char:FindFirstChild("HumanoidRootPart")
		if not hrp then return end
		local pos
		if detector:IsA("BasePart") then
			pos = detector.Position + Vector3.new(0, detector.Size.Y / 2 + 3, 0)
		elseif detector:IsA("Model") and detector.PrimaryPart then
			pos = detector.PrimaryPart.Position + Vector3.new(0, 3, 0)
		else
			local part = detector:FindFirstChildWhichIsA("BasePart", true)
			if not part then return end
			pos = part.Position + Vector3.new(0, part.Size.Y / 2 + 3, 0)
		end
		hrp.CFrame = CFrame.new(pos)
	end

	makeButton(mapPickSection.Content, "TP to Map 1", function()
		tpToDetector("Detector3")
	end, nil, false, 1)

	makeButton(mapPickSection.Content, "TP to Map 2", function()
		tpToDetector("Detector2")
	end, nil, false, 2)

	makeButton(mapPickSection.Content, "TP to Map 3", function()
		tpToDetector("Detector1")
	end, nil, false, 3)

	makeButton(mapPickSection.Content, "Reset", function()
		local char = LocalPlayer.Character
		local hrp = char and char:FindFirstChild("HumanoidRootPart")
		if hrp then
			resetCFrame = hrp.CFrame
		end
		local humanoid = char and char:FindFirstChildOfClass("Humanoid")
		if humanoid and humanoid.Health > 0 then
			humanoid.Health = 0
		elseif char then
			char:BreakJoints()
		end
	end, nil, false, 4)

	local infoBtn = Make("TextButton", {
		Size = ud2(0,24,0,24), Position = ud2(0,14,0,2),
		BackgroundColor3 = C.surfaceAlt, Text = "?",
		TextColor3 = C.textSec, TextSize = 16, Font = bold,
		Parent = mapPickSection.Content,
	})
	Make("UICorner", {CornerRadius = ud(1,0), Parent = infoBtn})
	Make("UIStroke", {Color = C.border, Thickness = 1, Transparency = 0.4, Parent = infoBtn})

	local infoLabel = Make("TextLabel", {
		Size = ud2(1,-8,0,60), BackgroundTransparency = 1,
		Text = "This is used to pick the map that you wish. Simply teleport to the map, reset, teleport again, and a new vote will be added on top of your previous others.",
		TextColor3 = C.textSec, TextSize = 11, Font = reg, TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		Visible = false, Parent = mapPickSection.Content,
	})

	infoBtn.MouseButton1Click:Connect(function()
		infoLabel.Visible = not infoLabel.Visible
		mapPickSection.resizeToContent()
		local ch = mapPickSection.Content.Size.Y.Offset
		local totalH = SECTION_H + 4 + ch
		mapPickSection.Wrapper.Size = ud2(1,-16,0,totalH)
	end)
end

-- ESP TAB CONTENT
local espMainSection = makeSection("ESP Features", espContainer, "ESP", false, false)

partState["nameESP"] = nameESPEnabled
createTogglePart(espMainSection.Content, "Name ESP", "nameESP", 1, false, function(state)
	nameESPEnabled = state
	espEnabled = nameESPEnabled or chamsEnabled
	for _, billboard in pairs(playerBillboards) do
		if billboard and billboard.Parent then
			billboard.Enabled = state
		end
	end
	triggerAutoSave()
end)

partState["chamsESP"] = chamsEnabled
createTogglePart(espMainSection.Content, "Chams ESP", "chamsESP", 2, false, function(state)
	chamsEnabled = state
	espEnabled = nameESPEnabled or chamsEnabled
	for _, highlights in pairs(playerHighlights) do
		for _, highlight in pairs(highlights) do
			if highlight and highlight.Parent then
				highlight.Enabled = state
			end
		end
	end
	triggerAutoSave()
end)

Make("Frame", {Size = ud2(1,0,0,10), BackgroundTransparency = 1, Parent = homeContainer})
Make("Frame", {Size = ud2(1,0,0,10), BackgroundTransparency = 1, Parent = espContainer})

-- ============================================================
-- FARM TAB CONTENT
-- ============================================================

local farmContainer
do
	farmContainer = Make("Frame", {
		Size = ud2(1,0,0,0), BackgroundTransparency = 1,
		AutomaticSize = Enum.AutomaticSize.Y,
		Visible = false, Parent = SectionScroll,
	})
	Make("UIListLayout", {SortOrder = Enum.SortOrder.LayoutOrder, Padding = ud(0,5), Parent = farmContainer})

	local farmMainSection = makeSection("Farm Controls", farmContainer, "Farm", false, false)
	partState["autoFarm"] = cfgAutoFarm
	partState["antiAFK"] = cfgAntiAfk
	partState["dieAfterBag"] = cfgDieAfterBag

	local speedCard = Make("Frame", {
		Size = ud2(1,-8,0,195), BackgroundColor3 = C.part_bg,
		BackgroundTransparency = 0.3, BorderSizePixel = 0,
		LayoutOrder = 4, Parent = farmMainSection.Content,
	})
	Make("UICorner", {CornerRadius = ud(0,12), Parent = speedCard})
	Make("UIStroke", {Color = C.border, Thickness = 1, Transparency = 0.4, Parent = speedCard})

	local speedMin = 10
	local function getSpeedMax() return cfgExceedSpeed and 40 or 25 end
	local flySpeed = math.clamp(cfgFarmSpeed, speedMin, getSpeedMax())

	local dialFrame = Make("Frame", {
		Size = ud2(0,92,0,92), Position = ud2(0.5,-46,0,10),
		BackgroundColor3 = C.surface, BackgroundTransparency = 0.4,
		BorderSizePixel = 0, Parent = speedCard,
	})
	Make("UICorner", {CornerRadius = ud(1,0), Parent = dialFrame})
	local dialStroke = Make("UIStroke", {Color = C.accent, Thickness = 5, Transparency = 0.2, Parent = dialFrame})

	local dialTicks = {}
	local tickCount = 16
	for i = 1, tickCount do
		local angle = math.rad(-135 + (i-1) * 270 / (tickCount-1))
		local r = 40
		local cx, cy = 46, 46
		local tick = Make("Frame", {
			Size = ud2(0,3,0,8),
			Position = ud2(0, cx + math.cos(angle)*r - 1.5, 0, cy + math.sin(angle)*r - 4),
			BackgroundColor3 = C.toggle_off,
			BackgroundTransparency = 0.4,
			BorderSizePixel = 0,
			Parent = dialFrame,
		})
		Make("UICorner", {CornerRadius = ud(1,0), Parent = tick})
		dialTicks[i] = tick
	end

	local valLabel = Make("TextLabel", {
		Size = ud2(0,70,0,30), Position = ud2(0.5,-35,0.5,-22),
		BackgroundTransparency = 1, Text = tostring(flySpeed),
		TextColor3 = C.white, TextSize = 26, Font = bold,
		TextXAlignment = Enum.TextXAlignment.Center,
		Parent = dialFrame,
	})

	Make("TextLabel", {
		Size = ud2(0,70,0,14), Position = ud2(0.5,-35,0.5,6),
		BackgroundTransparency = 1, Text = "FARM SPEED",
		TextColor3 = C.textSec, TextSize = 8, Font = semi,
		TextXAlignment = Enum.TextXAlignment.Center,
		Parent = dialFrame,
	})

	Make("TextLabel", {
		Size = ud2(0,30,0,12), Position = ud2(0,14,0,108),
		BackgroundTransparency = 1, Text = tostring(speedMin),
		TextColor3 = C.textSec, TextSize = 9, Font = semi,
		TextXAlignment = Enum.TextXAlignment.Left, Parent = speedCard,
	})
	local maxLabel = Make("TextLabel", {
		Size = ud2(0,30,0,12), Position = ud2(1,-42,0,108),
		BackgroundTransparency = 1, Text = tostring(getSpeedMax()),
		TextColor3 = C.textSec, TextSize = 9, Font = semi,
		TextXAlignment = Enum.TextXAlignment.Right, Parent = speedCard,
	})

	local sliderTrack = Make("Frame", {
		Size = ud2(1,-56,0,4), Position = ud2(0,28,0,114),
		BackgroundColor3 = C.toggle_off, BackgroundTransparency = 0.2,
		BorderSizePixel = 0, Parent = speedCard,
	})
	Make("UICorner", {CornerRadius = ud(1,0), Parent = sliderTrack})

	local sliderFill = Make("Frame", {
		Size = ud2((flySpeed-speedMin)/(getSpeedMax()-speedMin),0,1,0),
		BackgroundColor3 = C.accent, BorderSizePixel = 0, Parent = sliderTrack,
	})
	Make("UICorner", {CornerRadius = ud(1,0), Parent = sliderFill})

	local sliderKnob = Make("TextButton", {
		Size = ud2(0,14,0,14),
		Position = ud2((flySpeed-speedMin)/(getSpeedMax()-speedMin),-7,0,-5),
		BackgroundColor3 = C.knob, BorderSizePixel = 0, Text = "",
		ZIndex = 3, Parent = sliderTrack,
	})
	Make("UICorner", {CornerRadius = ud(1,0), Parent = sliderKnob})
	Make("UIStroke", {Color = rgb(0,0,0), Thickness = 1, Transparency = 0.7, Parent = sliderKnob})

	local sliderHitbox = Make("TextButton", {
		Size = ud2(1,0,0,20), Position = ud2(0,0,0,-8),
		BackgroundTransparency = 1, Text = "", ZIndex = 2, Parent = sliderTrack,
	})

	local speedInput = Make("TextBox", {
		Size = ud2(0,56,0,24), Position = ud2(0.5,-28,0,128),
		BackgroundColor3 = C.surface, BackgroundTransparency = 0.3,
		Text = tostring(flySpeed), TextColor3 = C.textPri,
		Font = semi, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Center,
		ClearTextOnFocus = false, Parent = speedCard,
	})
	Make("UICorner", {CornerRadius = ud(0,6), Parent = speedInput})
	Make("UIStroke", {Color = C.border, Thickness = 1, Transparency = 0.4, Parent = speedInput})

	local decBtn = Make("TextButton", {
		Size = ud2(0,24,0,24), Position = ud2(0.5,-92,0,128),
		BackgroundColor3 = C.surfaceAlt, BackgroundTransparency = 0.15,
		Text = "-", TextColor3 = C.textPri,
		TextSize = 16, Font = bold, Parent = speedCard,
	})
	Make("UICorner", {CornerRadius = ud(0,6), Parent = decBtn})

	local incBtn = Make("TextButton", {
		Size = ud2(0,24,0,24), Position = ud2(0.5,68,0,128),
		BackgroundColor3 = C.surfaceAlt, BackgroundTransparency = 0.15,
		Text = "+", TextColor3 = C.textPri,
		TextSize = 16, Font = bold, Parent = speedCard,
	})
	Make("UICorner", {CornerRadius = ud(0,6), Parent = incBtn})

	local exceedPill = Make("Frame", {
		Size = ud2(1,-16,0,28), Position = ud2(0,8,0,158),
		BackgroundColor3 = C.surfaceAlt, BackgroundTransparency = 0.15,
		BorderSizePixel = 0, Parent = speedCard,
	})
	Make("UICorner", {CornerRadius = ud(0,8), Parent = exceedPill})
	Make("TextLabel", {
		Size = ud2(0,140,1,0), Position = ud2(0,10,0,0),
		BackgroundTransparency = 1, Text = "Exceed Speed Limit",
		TextColor3 = C.textPri, TextSize = 11, Font = semi,
		TextXAlignment = Enum.TextXAlignment.Left, Parent = exceedPill,
	})

	local speedDragging = false

	local function setFlySpeed(value, skipSave)
		flySpeed = math.clamp(math.floor(value + 0.5), speedMin, getSpeedMax())
		valLabel.Text = tostring(flySpeed)
		speedInput.Text = tostring(flySpeed)
		local ratio = (flySpeed - speedMin) / (getSpeedMax() - speedMin)
		sliderFill.Size = ud2(ratio, 0, 1, 0)
		sliderKnob.Position = ud2(ratio, -7, 0, -5)
		cfgFarmSpeed = flySpeed
		local litCount = math.floor(ratio * tickCount)
		for i, tick in ipairs(dialTicks) do
			local r, g, b = 50, 120, 255
			if i <= litCount then
				local p = i / tickCount
				if p > 0.5 then
					p = (p - 0.5) * 2
					r = 50 + 170 * p
					g = 120 - 40 * p
					b = 255 - 185 * p
				end
				tick.BackgroundColor3 = rgb(r, g, b)
				tick.BackgroundTransparency = 0
			else
				tick.BackgroundColor3 = C.toggle_off
				tick.BackgroundTransparency = 0.4
			end
		end
		local sr, sg, sb = 50, 120, 255
		if ratio > 0.5 then
			local p = (ratio - 0.5) * 2
			sr = 50 + 170 * p
			sg = 120 - 40 * p
			sb = 255 - 185 * p
		end
		dialStroke.Color = rgb(sr, sg, sb)
		maxLabel.Text = tostring(getSpeedMax())
		if not skipSave then triggerAutoSave() end
	end

	local function refreshSliderPosition(x)
		local trackWidth = sliderTrack.AbsoluteSize.X
		if trackWidth <= 0 then return end
		local localX = math.clamp(x - sliderTrack.AbsolutePosition.X, 0, trackWidth)
		setFlySpeed(speedMin + (localX / trackWidth) * (getSpeedMax() - speedMin))
	end

	sliderKnob.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			speedDragging = true
		end
	end)

	sliderHitbox.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			speedDragging = true
			refreshSliderPosition(input.Position.X)
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if not speedDragging then return end
		if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
			refreshSliderPosition(input.Position.X)
		end
	end)

	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			if speedDragging then speedDragging = false; triggerAutoSave() end
		end
	end)

	speedInput.FocusLost:Connect(function()
		local value = tonumber(speedInput.Text)
		if value then setFlySpeed(value) else speedInput.Text = tostring(flySpeed) end
	end)

	decBtn.MouseButton1Click:Connect(function() setFlySpeed(flySpeed - 1) end)
	incBtn.MouseButton1Click:Connect(function() setFlySpeed(flySpeed + 1) end)

	makeToggle(exceedPill, 5, function(state)
		cfgExceedSpeed = state
		triggerAutoSave()
		if not state then
			local maxV = getSpeedMax()
			if flySpeed > maxV then setFlySpeed(maxV) end
		end
		setFlySpeed(flySpeed)
	end, cfgExceedSpeed)

	setFlySpeed(flySpeed, true)


	-- Auto Toggle Near Murderer Section
	local autoToggleSection = makeSection("Auto Toggle Near Murderer", farmContainer, "Farm", false, false)

	partState["autoToggle"] = cfgAutoToggle
	createTogglePart(autoToggleSection.Content, "Enable Auto Toggle", "autoToggle", 1, false, function(state)
		cfgAutoToggle = state
		triggerAutoSave()
		if state then
			startAutoDetect()
		else
			stopAutoDetect()
		end
	end)

	local radiusCard = Make("Frame", {
		Size = ud2(1,-8,0,185), BackgroundColor3 = C.part_bg,
		BackgroundTransparency = 0.3, BorderSizePixel = 0,
		LayoutOrder = 2, Parent = autoToggleSection.Content,
	})
	Make("UICorner", {CornerRadius = ud(0,12), Parent = radiusCard})
	Make("UIStroke", {Color = C.border, Thickness = 1, Transparency = 0.4, Parent = radiusCard})

	local radiusMin, radiusMax = 10, 120
	local detectRadius = math.clamp(cfgDetectRadius, radiusMin, radiusMax)

	local rDialFrame = Make("Frame", {
		Size = ud2(0,85,0,85), Position = ud2(0.5,-42,0,8),
		BackgroundColor3 = C.surface, BackgroundTransparency = 0.4,
		BorderSizePixel = 0, Parent = radiusCard,
	})
	Make("UICorner", {CornerRadius = ud(1,0), Parent = rDialFrame})
	local rDialStroke = Make("UIStroke", {Color = C.accent, Thickness = 5, Transparency = 0.2, Parent = rDialFrame})

	local rTicks = {}
	local rTickCount = 16
	for i = 1, rTickCount do
		local angle = math.rad(-135 + (i-1) * 270 / (rTickCount-1))
		local r = 37
		local cx, cy = 42.5, 42.5
		local tick = Make("Frame", {
			Size = ud2(0,3,0,8),
			Position = ud2(0, cx + math.cos(angle)*r - 1.5, 0, cy + math.sin(angle)*r - 4),
			BackgroundColor3 = C.toggle_off,
			BackgroundTransparency = 0.4,
			BorderSizePixel = 0,
			Parent = rDialFrame,
		})
		Make("UICorner", {CornerRadius = ud(1,0), Parent = tick})
		rTicks[i] = tick
	end

	local rValLabel = Make("TextLabel", {
		Size = ud2(0,70,0,28), Position = ud2(0.5,-35,0.5,-20),
		BackgroundTransparency = 1, Text = tostring(detectRadius),
		TextColor3 = C.white, TextSize = 24, Font = bold,
		TextXAlignment = Enum.TextXAlignment.Center,
		Parent = rDialFrame,
	})

	Make("TextLabel", {
		Size = ud2(0,70,0,12), Position = ud2(0.5,-35,0.5,6),
		BackgroundTransparency = 1, Text = "STUDS",
		TextColor3 = C.textSec, TextSize = 8, Font = semi,
		TextXAlignment = Enum.TextXAlignment.Center,
		Parent = rDialFrame,
	})

	Make("TextLabel", {
		Size = ud2(0,30,0,12), Position = ud2(0,14,0,100),
		BackgroundTransparency = 1, Text = tostring(radiusMin),
		TextColor3 = C.textSec, TextSize = 9, Font = semi,
		TextXAlignment = Enum.TextXAlignment.Left, Parent = radiusCard,
	})
	Make("TextLabel", {
		Size = ud2(0,30,0,12), Position = ud2(1,-42,0,100),
		BackgroundTransparency = 1, Text = tostring(radiusMax),
		TextColor3 = C.textSec, TextSize = 9, Font = semi,
		TextXAlignment = Enum.TextXAlignment.Right, Parent = radiusCard,
	})

	local rSliderTrack = Make("Frame", {
		Size = ud2(1,-56,0,4), Position = ud2(0,28,0,106),
		BackgroundColor3 = C.toggle_off, BackgroundTransparency = 0.2,
		BorderSizePixel = 0, Parent = radiusCard,
	})
	Make("UICorner", {CornerRadius = ud(1,0), Parent = rSliderTrack})

	local rSliderFill = Make("Frame", {
		Size = ud2((detectRadius-radiusMin)/(radiusMax-radiusMin),0,1,0),
		BackgroundColor3 = C.accent, BorderSizePixel = 0, Parent = rSliderTrack,
	})
	Make("UICorner", {CornerRadius = ud(1,0), Parent = rSliderFill})

	local rSliderKnob = Make("TextButton", {
		Size = ud2(0,14,0,14),
		Position = ud2((detectRadius-radiusMin)/(radiusMax-radiusMin),-7,0,-5),
		BackgroundColor3 = C.knob, BorderSizePixel = 0, Text = "",
		ZIndex = 3, Parent = rSliderTrack,
	})
	Make("UICorner", {CornerRadius = ud(1,0), Parent = rSliderKnob})
	Make("UIStroke", {Color = rgb(0,0,0), Thickness = 1, Transparency = 0.7, Parent = rSliderKnob})

	local rSliderHitbox = Make("TextButton", {
		Size = ud2(1,0,0,20), Position = ud2(0,0,0,-8),
		BackgroundTransparency = 1, Text = "", ZIndex = 2, Parent = rSliderTrack,
	})

	local rInput = Make("TextBox", {
		Size = ud2(0,56,0,24), Position = ud2(0.5,-28,0,120),
		BackgroundColor3 = C.surface, BackgroundTransparency = 0.3,
		Text = tostring(detectRadius), TextColor3 = C.textPri,
		Font = semi, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Center,
		ClearTextOnFocus = false, Parent = radiusCard,
	})
	Make("UICorner", {CornerRadius = ud(0,6), Parent = rInput})
	Make("UIStroke", {Color = C.border, Thickness = 1, Transparency = 0.4, Parent = rInput})

	local rDecBtn = Make("TextButton", {
		Size = ud2(0,24,0,24), Position = ud2(0.5,-92,0,120),
		BackgroundColor3 = C.surfaceAlt, BackgroundTransparency = 0.15,
		Text = "-", TextColor3 = C.textPri,
		TextSize = 16, Font = bold, Parent = radiusCard,
	})
	Make("UICorner", {CornerRadius = ud(0,6), Parent = rDecBtn})

	local rIncBtn = Make("TextButton", {
		Size = ud2(0,24,0,24), Position = ud2(0.5,68,0,120),
		BackgroundColor3 = C.surfaceAlt, BackgroundTransparency = 0.15,
		Text = "+", TextColor3 = C.textPri,
		TextSize = 16, Font = bold, Parent = radiusCard,
	})
	Make("UICorner", {CornerRadius = ud(0,6), Parent = rIncBtn})

	local radiusDragging = false

	local function setDetectRadius(value, skipSave)
		detectRadius = math.clamp(math.floor(value + 0.5), radiusMin, radiusMax)
		rValLabel.Text = tostring(detectRadius)
		rInput.Text = tostring(detectRadius)
		local ratio = (detectRadius - radiusMin) / (radiusMax - radiusMin)
		rSliderFill.Size = ud2(ratio, 0, 1, 0)
		rSliderKnob.Position = ud2(ratio, -7, 0, -5)
		cfgDetectRadius = detectRadius
		local litCount = math.floor(ratio * rTickCount)
		for i, tick in ipairs(rTicks) do
			local r, g, b = 50, 120, 255
			if i <= litCount then
				local p = i / rTickCount
				if p > 0.5 then
					p = (p - 0.5) * 2
					r = 50 + 170 * p
					g = 120 - 40 * p
					b = 255 - 185 * p
				end
				tick.BackgroundColor3 = rgb(r, g, b)
				tick.BackgroundTransparency = 0
			else
				tick.BackgroundColor3 = C.toggle_off
				tick.BackgroundTransparency = 0.4
			end
		end
		local sr, sg, sb = 50, 120, 255
		if ratio > 0.5 then
			local p = (ratio - 0.5) * 2
			sr = 50 + 170 * p
			sg = 120 - 40 * p
			sb = 255 - 185 * p
		end
		rDialStroke.Color = rgb(sr, sg, sb)
		if not skipSave then triggerAutoSave() end
	end

	local function refreshRadiusPosition(x)
		local trackWidth = rSliderTrack.AbsoluteSize.X
		if trackWidth <= 0 then return end
		local localX = math.clamp(x - rSliderTrack.AbsolutePosition.X, 0, trackWidth)
		setDetectRadius(radiusMin + (localX / trackWidth) * (radiusMax - radiusMin))
	end

	rSliderKnob.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			radiusDragging = true
		end
	end)

	rSliderHitbox.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			radiusDragging = true
			refreshRadiusPosition(input.Position.X)
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if not radiusDragging then return end
		if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
			refreshRadiusPosition(input.Position.X)
		end
	end)

	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			if radiusDragging then radiusDragging = false; triggerAutoSave() end
		end
	end)

	rInput.FocusLost:Connect(function()
		local value = tonumber(rInput.Text)
		if value then setDetectRadius(value) else rInput.Text = tostring(detectRadius) end
	end)

	rDecBtn.MouseButton1Click:Connect(function() setDetectRadius(detectRadius - 1) end)
	rIncBtn.MouseButton1Click:Connect(function() setDetectRadius(detectRadius + 1) end)

	setDetectRadius(detectRadius, true)

	local isFarmActive = false
	local farmCharacter = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
	local farmRootPart = farmCharacter:WaitForChild("HumanoidRootPart")
	local visitedPositions = {}
	local collectedCoins = 0

	local function resetFarmState()
		collectedCoins = 0
		visitedPositions = {}
	end

	LocalPlayer.CharacterAdded:Connect(function(char)
		farmCharacter = char
		farmRootPart = char:WaitForChild("HumanoidRootPart")
		farmRootPart.Anchored = false
		visitedPositions = {}
	end)

	RunService.Stepped:Connect(function()
		if isFarmActive and farmCharacter then
			for _, v in ipairs(farmCharacter:GetDescendants()) do
				if v:IsA("BasePart") then
					v.CanCollide = false
				end
			end
		end
	end)

	LocalPlayer.Idled:Connect(function()
		if cfgAntiAfk then
			VirtualUser:Button2Down(Vector2.new(0,0), Camera.CFrame)
			task.wait(1)
			VirtualUser:Button2Up(Vector2.new(0,0), Camera.CFrame)
		end
	end)

	local function findClosestCoin()
		if not farmRootPart then return nil end
		local closest, shortest = nil, math.huge
		
		local container = workspace:FindFirstChild("Normal") and workspace.Normal:FindFirstChild("CoinContainer")
		local searchArea = container and container:GetDescendants() or workspace:GetDescendants()
		
		for _, obj in ipairs(searchArea) do
			if obj.Name == "Coin_Server" and not visitedPositions[obj] then
				local part = obj:IsA("BasePart") and obj or obj:FindFirstChildWhichIsA("BasePart", true)
				if part then
					local dist = (part.Position - farmRootPart.Position).Magnitude
					if dist < shortest and dist < 250 then
						closest = obj
						shortest = dist
					end
				end
			end
		end
		return closest
	end

	local function stopFarm()
		isFarmActive = false
		if farmRootPart then
			farmRootPart.Anchored = false
		end
	end

	local function startFarm()
		if isFarmActive then return end
		isFarmActive = true
		resetFarmState()

		task.spawn(function()
			while isFarmActive do
				farmCharacter = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
				farmRootPart = farmCharacter:FindFirstChild("HumanoidRootPart")
				
				if farmRootPart then
					local coin = findClosestCoin()
					
					if coin and coin.Parent and coin:IsDescendantOf(workspace) then
						local coinPart = coin:IsA("BasePart") and coin or coin:FindFirstChildWhichIsA("BasePart", true)
						
						if coinPart then
							local distance = (coinPart.Position - farmRootPart.Position).Magnitude
							local duration = math.max(0.04, distance / flySpeed)
							local tweenInfo = TweenInfo.new(duration, Enum.EasingStyle.Linear)
							local goal = {CFrame = coinPart.CFrame}
							
							local tween = TweenService:Create(farmRootPart, tweenInfo, goal)
							tween:Play()
							tween.Completed:Wait()
							
							if isFarmActive and coin and coin.Parent then
								if firetouchinterest then
									firetouchinterest(farmRootPart, coinPart, 0)
									firetouchinterest(farmRootPart, coinPart, 1)
								end
								
								visitedPositions[coin] = true
								collectedCoins = collectedCoins + 1
								
								task.spawn(function()
									local sound = Instance.new("Sound")
									sound.SoundId = "rbxassetid://12221967"
									sound.Volume = 0.5
									sound.Parent = Gui
									sound:Play()
									task.wait(1)
									sound:Destroy()
								end)
								
								if cfgDieAfterBag then
									local threshold = collectedCoins
									local ls = LocalPlayer:FindFirstChild("leaderstats")
									if ls then
										for _, name in ipairs({"Coins", "Points", "Money", "Cash", "Currency"}) do
											local s = ls:FindFirstChild(name)
											if s then threshold = s.Value; break end
										end
									end
									if threshold >= 40 then
										local humanoid = farmCharacter:FindFirstChildOfClass("Humanoid")
										farmRootPart.Anchored = false
										if humanoid and humanoid.Health > 0 then
											humanoid.Health = 0
										elseif farmCharacter:FindFirstChild("HumanoidRootPart") then
											farmCharacter:BreakJoints()
										end
										resetFarmState()
										task.wait(4)
									end
								end
							end
						else
							task.wait(0.1)
						end
					else
						task.wait(0.2)
					end
				else
					task.wait(0.2)
				end
			end
			if farmRootPart then
				farmRootPart.Anchored = false
			end
		end)
	end

	createTogglePart(farmMainSection.Content, "Auto Farm", "autoFarm", 1, false, function(state)
		cfgAutoFarm = state
		triggerAutoSave()
		if state then
			startFarm()
		else
			stopFarm()
		end
	end)

	createTogglePart(farmMainSection.Content, "Anti-AFK", "antiAFK", 2, false, function(state)
		cfgAntiAfk = state
		triggerAutoSave()
	end)

	createTogglePart(farmMainSection.Content, "Die After Full Bag", "dieAfterBag", 3, false, function(state)
		cfgDieAfterBag = state
		triggerAutoSave()
	end)

	if cfgAutoFarm then
		task.defer(startFarm)
	end

	Make("Frame", {Size = ud2(1,0,0,10), BackgroundTransparency = 1, Parent = farmContainer})
end

-- ============================================================
-- COMBAT TAB CONTENT
-- ============================================================

local combatContainer
do
	combatContainer = Make("Frame", {
		Size = ud2(1,0,0,0), BackgroundTransparency = 1,
		AutomaticSize = Enum.AutomaticSize.Y,
		Visible = false, Parent = SectionScroll,
	})
	Make("UIListLayout", {SortOrder = Enum.SortOrder.LayoutOrder, Padding = ud(0,5), Parent = combatContainer})

	-- MURDERER SECTION
	local murdererSection = makeSection("Murderer", combatContainer, "Combat", false, false)

	stopKillAll = function()
		if killAllLockConn then
			killAllLockConn:Disconnect()
			killAllLockConn = nil
		end
		killAllTargets = {}
	end

	makeButton(murdererSection.Content, "Kill All", function()
		local char = LocalPlayer.Character
		local hrp = char and char:FindFirstChild("HumanoidRootPart")
		if not hrp then return end

		local hasKnife = false
		for _, t in ipairs(char:GetChildren()) do
			if t:IsA("Tool") and t.Name:lower():find("knife") then hasKnife = true; break end
		end
		if not hasKnife then
			local knifeDrop = workspace:FindFirstChild("KnifeDrop", true)
			if knifeDrop then
				local knPart = knifeDrop:IsA("BasePart") and knifeDrop or knifeDrop:FindFirstChildWhichIsA("BasePart", true)
				if knPart and type(firetouchinterest) == "function" then
					hrp.CFrame = knPart.CFrame * CFrame.new(0, 3, 0)
					task.wait(0.1)
					firetouchinterest(hrp, knPart, 0)
					task.wait()
					firetouchinterest(hrp, knPart, 1)
				end
			end
			task.wait(0.3)
			for _, t in ipairs(char:GetChildren()) do
				if t:IsA("Tool") and t.Name:lower():find("knife") then hasKnife = true; break end
			end
		end
		if not hasKnife then return end

		local targetPos = hrp.Position + hrp.CFrame.LookVector * 4
		killAllTargets = {}
		for _, p in ipairs(Players:GetPlayers()) do
			if p ~= LocalPlayer and p.Character then
				local mHRP = p.Character:FindFirstChild("HumanoidRootPart")
				if mHRP then
					mHRP.CFrame = CFrame.new(targetPos)
					mHRP.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
					killAllTargets[p] = CFrame.new(targetPos)
				end
			end
		end

		stopKillAll()
		killAllLockConn = RunService.Heartbeat:Connect(function()
			for player, targetCF in pairs(killAllTargets) do
				if player and player.Character then
					local mHRP = player.Character:FindFirstChild("HumanoidRootPart")
					if mHRP then
						mHRP.CFrame = targetCF
						mHRP.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
					end
				end
			end
		end)
	end, "killAll", false, 1)

	-- SHERIFF SECTION
	local sheriffSection = makeSection("Sheriff", combatContainer, "Combat", false, false)

	runSilentAim = function()
		local char = LocalPlayer.Character
		local hrp = char and char:FindFirstChild("HumanoidRootPart")
		if not hrp then return end

		local gun = nil
		for _, t in ipairs(char:GetChildren()) do
			if t:IsA("Tool") and t.Name:lower():find("gun") then gun = t; break end
		end
		if not gun then
			local gunDrop = workspace:FindFirstChild("GunDrop", true)
			if gunDrop then
				local gPart = gunDrop:IsA("BasePart") and gunDrop or gunDrop:FindFirstChildWhichIsA("BasePart", true)
				if gPart and type(firetouchinterest) == "function" then
					hrp.CFrame = gPart.CFrame * CFrame.new(0, 3, 0)
					task.wait(0.1)
					firetouchinterest(hrp, gPart, 0)
					task.wait()
					firetouchinterest(hrp, gPart, 1)
				end
			end
			task.wait(0.3)
			for _, t in ipairs(char:GetChildren()) do
				if t:IsA("Tool") and t.Name:lower():find("gun") then gun = t; break end
			end
		end
		if not gun then return end

		local murderer = nil
		for _, p in ipairs(Players:GetPlayers()) do
			if p ~= LocalPlayer and p.Character then
				for _, t in ipairs(p.Character:GetChildren()) do
					if t:IsA("Tool") and t.Name:lower():find("knife") then murderer = p; break end
				end
				if not murderer and p:FindFirstChild("Backpack") then
					for _, t in ipairs(p.Backpack:GetChildren()) do
						if t:IsA("Tool") and t.Name:lower():find("knife") then murderer = p; break end
					end
				end
				if murderer then break end
			end
		end
		if not murderer or not murderer.Character then return end

		local mHRP = murderer.Character:FindFirstChild("HumanoidRootPart")
		if not mHRP then return end

		mHRP.CFrame = hrp.CFrame * CFrame.new(0, 0, -6)
		mHRP.AssemblyLinearVelocity = Vector3.new(0, 0, 0)

		task.wait(0.1)
		gun:Activate()
		task.wait(0.05)
		gun:Deactivate()
	end

	updateSilentAimLabel = function()
		for _, child in ipairs(sheriffSection.Content:GetChildren()) do
			if child:IsA("Frame") then
				local lbl = child:FindFirstChildOfClass("TextLabel")
				if lbl and lbl.Text:find("Silent Aim") then
					lbl.Text = "Silent Aim [" .. silentAimKey.Name .. "]"
					break
				end
			end
		end
	end

	partState["silentAim"] = silentAimEnabled
	createTogglePart(sheriffSection.Content, "Silent Aim [" .. silentAimKey.Name .. "]", "silentAim", 1, false, function(state)
		silentAimEnabled = state
	end)

	-- INNOCENT SECTION
	local innocentSection = makeSection("Innocent", combatContainer, "Combat", false, false)

	partState["autoGrabGun"] = cfgAutoGrabGun
	createTogglePart(innocentSection.Content, "Auto Grab Gun", "autoGrabGun", 1, false, function(state)
		cfgAutoGrabGun = state
		toggleGrabber(state)
		triggerAutoSave()
	end)

	makeButton(innocentSection.Content, "Pick Up Gun", function()
		grabGunOnce()
	end, "grabGunOnce", false, 2)

	Make("Frame", {Size = ud2(1,0,0,10), BackgroundTransparency = 1, Parent = combatContainer})
end

rebuildFavorites()
rebuildActive()

CollapseAllBtn.MouseButton1Click:Connect(function()
	if not activeTab then return end
	for _, sec in ipairs(tabSections[activeTab]) do
		if sec.IsOpen() then sec.SetOpen(false) end
	end
end)

local switchTab

local ShortcutModal = Make("Frame", {
	Size = ud2(0,260,0,160), Position = ud2(0.5,0,0.5,0),
	AnchorPoint = Vector2.new(0.5,0.5), BackgroundColor3 = C.bg,
	BackgroundTransparency = uiTransparency, BorderSizePixel = 0,
	Active = true, Visible = false, ZIndex = 50, Parent = Gui,
})
Make("UICorner", {CornerRadius = ud(0,16), Parent = ShortcutModal})
Make("UIStroke", {Color = C.border, Thickness = 1, Transparency = 0.5, Parent = ShortcutModal})
local ModalScale  = Make("UIScale", {Scale = 1, Parent = ShortcutModal})
local ModalHeader = Make("Frame", {
	Size = ud2(1,0,0,32), BackgroundTransparency = 1,
	BorderSizePixel = 0, Parent = ShortcutModal,
})
local ModalCloseBtn = makeDot(14, C.dot_red, ModalHeader)
local ModalMaxBtn   = makeDot(32, C.dot_grn, ModalHeader)
local ShortcutModalText = Make("TextLabel", {
	Size = ud2(1,-40,1,-32), Position = ud2(0,20,0,32),
	BackgroundTransparency = 1, Text = "",
	TextColor3 = C.textPri, TextSize = 13, Font = reg,
	TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left, Parent = ShortcutModal,
})

local function updateModalText()
	local t = "[ " .. activeKeybind[1].Name .. " + " .. activeKeybind[2].Name .. " ]"
	ShortcutModalText.Text = "Shortcut Info:\n\nCurrent Bind: " .. t .. "\n\nHold the first key then press the second key to toggle the main interface open or closed dynamically."
end
updateModalText()

local modalExpanded = false
ModalCloseBtn.MouseButton1Click:Connect(function() ShortcutModal.Visible = false end)
ModalMaxBtn.MouseButton1Click:Connect(function()
	modalExpanded = not modalExpanded
	TweenService:Create(ModalScale, TweenInfo.new(0.2,Enum.EasingStyle.Quart,Enum.EasingDirection.Out),
		{Scale = modalExpanded and 1.2 or 1}):Play()
end)

local isListeningForKeybind = false
local tempKeys              = {}

Make("TextLabel", {
	Size = ud2(1,0,0,42), BackgroundTransparency = 1, Text = "Settings",
	TextColor3 = C.textPri, TextSize = 16, Font = bold,
	TextXAlignment = Enum.TextXAlignment.Center, Parent = SetPage,
})

local SettingsTabBar = Make("Frame", {
	Size = ud2(1,-24,0,30), Position = ud2(0,12,0,42),
	BackgroundTransparency = 1, Parent = SetPage,
})
Make("UIListLayout", {
	FillDirection = Enum.FillDirection.Horizontal,
	HorizontalAlignment = Enum.HorizontalAlignment.Center,
	Padding = ud(0,6), Parent = SettingsTabBar,
})

local function makeSettingsTab(name, width)
	local btn = Make("TextButton", {
		Size = ud2(0,width or 75,0,26), BackgroundColor3 = C.surfaceAlt,
		BackgroundTransparency = 0.5, Text = name,
		TextColor3 = C.textSec, TextSize = 10, Font = bold, Parent = SettingsTabBar,
	})
	Make("UICorner", {CornerRadius = ud(1,0), Parent = btn})
	local pill = Make("Frame", {
		Size = ud2(0,0,0,2), Position = ud2(0.5,0,1,-2),
		AnchorPoint = Vector2.new(0.5,0), BackgroundColor3 = C.accent,
		BorderSizePixel = 0, Parent = btn,
	})
	Make("UICorner", {CornerRadius = ud(1,0), Parent = pill})
	return {Button = btn, Pill = pill}
end

local sTab = {}
sTab.Shortcuts     = makeSettingsTab("Shortcuts")
sTab.Themes        = makeSettingsTab("Themes")

local function makeSetScroll(visible)
	local s = Make("ScrollingFrame", {
		Size = ud2(1,-24,1,-78), Position = ud2(0,12,0,78),
		BackgroundTransparency = 1, BorderSizePixel = 0,
		ScrollBarThickness = 2, ScrollBarImageColor3 = C.border,
		CanvasSize = ud2(0,0,0,0), AutomaticCanvasSize = Enum.AutomaticSize.Y,
		Active = true, Visible = visible, Parent = SetPage,
	})
	Make("UIListLayout", {SortOrder = Enum.SortOrder.LayoutOrder, Padding = ud(0,5), Parent = s})
	return s
end

local ScrollShortcuts     = makeSetScroll(true)
local ScrollThemes        = makeSetScroll(false)

local activeSettingsTab = "Shortcuts"

local function switchSettingsTab(name)
	if activeSettingsTab == name then return end
	activeSettingsTab = name
	ScrollShortcuts.Visible     = (name == "Shortcuts")
	ScrollThemes.Visible        = (name == "Themes")
	for key, tab in pairs(sTab) do
		local active = (key == name)
		TweenService:Create(tab.Pill, tabTween, { Size = active and ud2(0,40,0,2) or ud2(0,0,0,2) }):Play()
		TweenService:Create(tab.Button, tabTween, { TextColor3 = active and C.textPri or C.textSec, BackgroundTransparency = active and 0.2 or 0.5 }):Play()
	end
end

sTab.Shortcuts.Button.MouseButton1Click:Connect(function()     switchSettingsTab("Shortcuts") end)
sTab.Themes.Button.MouseButton1Click:Connect(function()        switchSettingsTab("Themes") end)

local function makeSetSection(parent, title, contentH, startOpen)
	local wrapper = Make("Frame", {
		Size = ud2(1,-16,0,SECTION_H), BackgroundTransparency = 1,
		ClipsDescendants = true, Parent = parent,
	})
	local header = Make("Frame", {
		Size = ud2(1,-2,0,SECTION_H - 2), Position = ud2(0,1,0,1),
		BackgroundColor3 = C.surface,
		BackgroundTransparency = 0.3, BorderSizePixel = 0, Parent = wrapper,
	})
	Make("UICorner", {CornerRadius = ud(1,0), Parent = header})
	Make("UIStroke", {Color = rgb(255,255,255), Thickness = 1, Transparency = 0.85, Parent = header})
	local arrow = Make("TextLabel", {
		Size = ud2(0,28,1,0), Position = ud2(0,10,0,0),
		BackgroundTransparency = 1, Text = startOpen and "-" or "+",
		TextColor3 = C.textSec, TextSize = 18, Font = bold, Parent = header,
	})
	Make("TextLabel", {
		Size = ud2(1,-50,1,0), Position = ud2(0,32,0,0),
		BackgroundTransparency = 1, Text = title,
		TextColor3 = C.textPri, TextSize = 12, Font = bold,
		TextXAlignment = Enum.TextXAlignment.Left, Parent = header,
	})
	local totalH = SECTION_H + 4 + contentH
	if startOpen then wrapper.Size = ud2(1,-16,0,totalH) end
	local isOpen = startOpen == true
	local hBtn = Make("TextButton", {
		Size = ud2(1,0,1,0), BackgroundTransparency = 1, Text = "", Parent = header,
	})
	hBtn.MouseButton1Click:Connect(function()
		isOpen = not isOpen
		arrow.Text = isOpen and "-" or "+"
		TweenService:Create(wrapper, sectionTween, {
			Size = ud2(1,-16,0, isOpen and totalH or SECTION_H)
		}):Play()
	end)
	local content = Make("Frame", {
		Size = ud2(1,0,0,contentH), Position = ud2(0,0,0,SECTION_H+4),
		BackgroundTransparency = 1, ClipsDescendants = true, Parent = wrapper,
	})
	return wrapper, content
end

local _, ShortcutSecContent = makeSetSection(ScrollShortcuts, "Keybinds", PART_H*2+10, true)
local ShortcutItemPill = Make("Frame", { Size = ud2(1,-8,0,PART_H), BackgroundColor3 = C.part_bg, BackgroundTransparency = 0.3, BorderSizePixel = 0, Parent = ShortcutSecContent })
Make("UICorner", {CornerRadius = ud(1,0), Parent = ShortcutItemPill})
Make("TextLabel", { Size = ud2(0,120,1,0), Position = ud2(0,14,0,0), BackgroundTransparency = 1, Text = "Toggle UI Keybind", TextColor3 = C.textPri, TextSize = 11, Font = reg, TextXAlignment = Enum.TextXAlignment.Left, Parent = ShortcutItemPill })
local KeybindBtn = Make("TextButton", { Size = ud2(0,110,0,22), Position = ud2(1,-145,0,5), BackgroundColor3 = C.surfaceAlt, BackgroundTransparency = 0.1, Text = "[ " .. activeKeybind[1].Name .. " + " .. activeKeybind[2].Name .. " ]", TextColor3 = C.textPri, TextSize = 11, Font = bold, Parent = ShortcutItemPill })
Make("UICorner", {CornerRadius = ud(0,4), Parent = KeybindBtn})
Make("UIStroke", {Color = C.border, Thickness = 1, Transparency = 0.4, Parent = KeybindBtn})
KeybindBtn.MouseButton1Click:Connect(function()
	if not isListeningForKeybind then
		isListeningForKeybind = true
		tempKeys = {}
		KeybindBtn.Text = "[ Press 1st Key ]"
		KeybindBtn.TextColor3 = C.dot_yel
	end
end)

local SilentAimPill = Make("Frame", { Size = ud2(1,-8,0,PART_H), BackgroundColor3 = C.part_bg, BackgroundTransparency = 0.3, BorderSizePixel = 0, Parent = ShortcutSecContent })
Make("UICorner", {CornerRadius = ud(1,0), Parent = SilentAimPill})
Make("TextLabel", { Size = ud2(0,140,1,0), Position = ud2(0,14,0,0), BackgroundTransparency = 1, Text = "Silent Aim Keybind", TextColor3 = C.textPri, TextSize = 11, Font = reg, TextXAlignment = Enum.TextXAlignment.Left, Parent = SilentAimPill })
local SilentAimKeyBtn = Make("TextButton", { Size = ud2(0,80,0,22), Position = ud2(1,-90,0.5,-11), BackgroundColor3 = C.surfaceAlt, BackgroundTransparency = 0.1, Text = "[" .. silentAimKey.Name .. "]", TextColor3 = C.textPri, TextSize = 11, Font = bold, Parent = SilentAimPill })
Make("UICorner", {CornerRadius = ud(0,4), Parent = SilentAimKeyBtn})
Make("UIStroke", {Color = C.border, Thickness = 1, Transparency = 0.4, Parent = SilentAimKeyBtn})
local isListeningSilentAim = false
SilentAimKeyBtn.MouseButton1Click:Connect(function()
	if not isListeningSilentAim then
		isListeningSilentAim = true
		SilentAimKeyBtn.Text = "[ Press Key ]"
		SilentAimKeyBtn.TextColor3 = C.dot_yel
	end
end)

local themeContentH = 90
local _, ThemeSecContent = makeSetSection(ScrollThemes, "Appearance", themeContentH, true)

local ModePill = Make("Frame", { Size = ud2(1,-8,0,PART_H), BackgroundColor3 = C.part_bg, BackgroundTransparency = 0.3, BorderSizePixel = 0, Parent = ThemeSecContent })
Make("UICorner", {CornerRadius = ud(1,0), Parent = ModePill})
Make("TextLabel", { Size = ud2(0,120,1,0), Position = ud2(0,14,0,0), BackgroundTransparency = 1, Text = "Light Mode", TextColor3 = C.textPri, TextSize = 11, Font = reg, TextXAlignment = Enum.TextXAlignment.Left, Parent = ModePill })
makeToggle(ModePill, (PART_H-18)/2, function(on)
	cfgLightMode = on
	applyTheme()
	triggerAutoSave()
end, cfgLightMode)

local SliderPill = Make("Frame", { Size = ud2(1,-8,0,45), Position=ud2(0,0,0,PART_H+5), BackgroundColor3 = C.part_bg, BackgroundTransparency = 0.3, BorderSizePixel = 0, Parent = ThemeSecContent })
Make("UICorner", {CornerRadius = ud(1,0), Parent = SliderPill})
Make("TextLabel", { Size = ud2(0,120,0,20), Position = ud2(0,14,0,6), BackgroundTransparency = 1, Text = "Menu Transparency", TextColor3 = C.textPri, TextSize = 11, Font = reg, TextXAlignment = Enum.TextXAlignment.Left, Parent = SliderPill })
local SliderValueLbl = Make("TextLabel", { Size = ud2(0,36,0,20), Position = ud2(1,-50,0,6), BackgroundTransparency = 1, Text = math.floor(cfgTransparency/0.85*100+0.5).."%", TextColor3 = C.textSec, TextSize = 10, Font = bold, TextXAlignment = Enum.TextXAlignment.Right, Parent = SliderPill })
local SliderTrack = Make("Frame", { Size = ud2(1,-28,0,6), Position = ud2(0,14,0,32), BackgroundColor3 = C.toggle_off, BackgroundTransparency = 0.2, BorderSizePixel = 0, Parent = SliderPill })
Make("UICorner", {CornerRadius = ud(1,0), Parent = SliderTrack})
local initFrac = cfgTransparency / 0.85
local SliderFill = Make("Frame", { Size = ud2(initFrac,0,1,0), BackgroundColor3 = C.accent, BackgroundTransparency = 0, BorderSizePixel = 0, Parent = SliderTrack })
Make("UICorner", {CornerRadius = ud(1,0), Parent = SliderFill})
local SliderKnob = Make("TextButton", { Size = ud2(0,14,0,14), Position = ud2(initFrac,-7,0,-4), BackgroundColor3 = C.knob, BorderSizePixel = 0, Text = "", Parent = SliderTrack })
Make("UICorner", {CornerRadius = ud(1,0), Parent = SliderKnob})
Make("UIStroke", {Color = rgb(80,80,80), Thickness = 1, Transparency = 0.3, Parent = SliderKnob})

local sliderDragging = false

local function updateSlider(inputX)
	local relX   = inputX - SliderTrack.AbsolutePosition.X
	local frac   = math.clamp(relX / SliderTrack.AbsoluteSize.X, 0, 1)
	SliderFill.Size = ud2(frac, 0, 1, 0)
	SliderKnob.Position = ud2(frac, -7, 0, -4)
	SliderValueLbl.Text = math.floor(frac * 100 + 0.5).."%"
	applyTransparency(frac * 0.85)
end

SliderKnob.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		sliderDragging = true
	end
end)

local SliderHitbox = Make("TextButton", { Size = ud2(1,0,1,20), Position = ud2(0,0,0,-7), BackgroundTransparency = 1, Text = "", ZIndex = SliderKnob.ZIndex - 1, Parent = SliderTrack })
SliderHitbox.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		sliderDragging = true; updateSlider(input.Position.X)
	end
end)

UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		if sliderDragging then sliderDragging = false; triggerAutoSave() end
	end
end)
UserInputService.InputChanged:Connect(function(input)
	if sliderDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
		updateSlider(input.Position.X)
	end
end)

transparencyFrames = {
	{frame = Main,          base = 0,    radius = UDim.new(0, 16)},
	{frame = PillUI,        base = 0,    radius = UDim.new(1, 0)},
	{frame = ShortcutModal, base = 0,    radius = UDim.new(0, 16)},
}
applyTransparency(cfgTransparency)
applyTheme()

local function makeDraggableReal(object, handle)
	local dragging = false
	local relative = Vector2.zero
	local insetOff = Vector2.zero
	local sg = object:FindFirstAncestorWhichIsA("ScreenGui")
	if sg and sg.IgnoreGuiInset then
		local ok, inset = pcall(function() return GuiService:GetGuiInset() end)
		if ok then insetOff = insetOff + inset end
	end
	handle.InputBegan:Connect(function(input, processed)
		if processed then return end
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			relative = Vector2.new(object.AbsolutePosition.X, object.AbsolutePosition.Y)
			+ Vector2.new(object.AbsoluteSize.X * object.AnchorPoint.X, object.AbsoluteSize.Y * object.AnchorPoint.Y)
			- UserInputService:GetMouseLocation()
		end
	end)
	local ec = UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = false
		end
	end)
	local rc = RunService.RenderStepped:Connect(function()
		if dragging then
			local pos = UserInputService:GetMouseLocation() + relative + insetOff
			object.Position = UDim2.fromOffset(pos.X, pos.Y)
		end
	end)
	object.Destroying:Connect(function() ec:Disconnect(); rc:Disconnect() end)
end

makeDraggableReal(Main, Main)
makeDraggableReal(PillUI, PillUI)

local tweenInfo   = TweenInfo.new(0.28, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
local pillUsed    = false
local lastMainPos = Main.Position
local isAnimating = false

CloseBtn.MouseButton1Click:Connect(function() UninstallOverlay.Visible = true end)

local function shrinkToPill()
	if not Main.Visible or isAnimating then return end
	isAnimating = true
	lastMainPos = Main.Position
	PillUI.Size = ud2(0,0,0,34)
	if not pillUsed then PillUI.Position = ud2(0.5,0,0,12); pillUsed = true end
	PillUI.Visible  = true
	PillScale.Scale = 0
	TweenService:Create(PillUI,    tweenInfo, {Size = ud2(0,110,0,34)}):Play()
	TweenService:Create(PillScale, tweenInfo, {Scale = 1}):Play()
	TweenService:Create(MainScale, tweenInfo, {Scale = 0}):Play()
	TweenService:Create(Main, tweenInfo, {
		Position = ud2(PillUI.Position.X.Scale, PillUI.Position.X.Offset,
		PillUI.Position.Y.Scale, PillUI.Position.Y.Offset + 17)
	}):Play()
	task.delay(0.32, function()
		if Main and Main.Parent then Main.Visible = false end
		isAnimating = false
	end)
end

local function expandFromPill()
	if not PillUI.Visible or isAnimating then return end
	isAnimating   = true
	Main.Position = lastMainPos
	Main.Visible  = true
	TweenService:Create(PillScale, tweenInfo, {Scale = 0}):Play()
	TweenService:Create(MainScale, tweenInfo, {Scale = isExpanded and 1.4 or 1}):Play()
	task.delay(0.32, function()
		if PillUI and PillUI.Parent then PillUI.Visible = false; PillScale.Scale = 1 end
		isAnimating = false
	end)
end

MinBtn.MouseButton1Click:Connect(shrinkToPill)

MaxBtn.MouseButton1Click:Connect(function()
	isExpanded = not isExpanded
	TweenService:Create(MainScale, tweenInfo, {Scale = isExpanded and 1.4 or 1}):Play()
	triggerAutoSave()
end)

local pillDragStart = nil
PillUI.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		pillDragStart = input.Position
	end
end)
PillUI.InputEnded:Connect(function(input)
	if (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) and pillDragStart then
		if (input.Position - pillDragStart).Magnitude < 6 then expandFromPill() end
		pillDragStart = nil
	end
end)

ToggleBtn.MouseButton1Click:Connect(function()
	local inSettings = not SetPage.Visible
	ToggleBtn.Text   = inSettings and "📄" or "⚙"
	MainPage.Visible = not inSettings
	SetPage.Visible  = inSettings
	if inSettings then CollapseAllBtn.Visible = false else updateCollapseAllVisibility() end
end)

function switchTab(tabName)
	if activeTab == tabName then return end
	activeTab = tabName
	for key, tab in pairs(tabs) do
		local active = (key == tabName)
		TweenService:Create(tab.Pill, tabTween, { Size = active and ud2(0,40,0,2) or ud2(0,0,0,2) }):Play()
		TweenService:Create(tab.Button, tabTween, { TextColor3 = active and C.textPri or C.textSec, BackgroundTransparency = active and 0.2 or 0.5 }):Play()
	end
	homeContainer.Visible = (tabName == "Home")
	espContainer.Visible = (tabName == "ESP")
	farmContainer.Visible = (tabName == "Farm")
	combatContainer.Visible = (tabName == "Combat")
	updateCollapseAllVisibility()
end

tabs.Home.Button.MouseButton1Click:Connect(function() switchTab("Home") end)
tabs.ESP.Button.MouseButton1Click:Connect(function() switchTab("ESP") end)
tabs.Farm.Button.MouseButton1Click:Connect(function() switchTab("Farm") end)
tabs.Combat.Button.MouseButton1Click:Connect(function() switchTab("Combat") end)
switchTab("Home")

local keybindConn
keybindConn = UserInputService.InputBegan:Connect(function(input, processed)
	if not Gui or not Gui.Parent then keybindConn:Disconnect(); return end
	if UninstallOverlay.Visible then return end

	if isListeningForKeybind and input.UserInputType == Enum.UserInputType.Keyboard then
		if input.KeyCode ~= Enum.KeyCode.Unknown then
			table.insert(tempKeys, input.KeyCode)
			if #tempKeys == 1 then
				KeybindBtn.Text = "[ " .. tempKeys[1].Name .. " + ? ]"
			elseif #tempKeys == 2 then
				activeKeybind         = {tempKeys[1], tempKeys[2]}
				isListeningForKeybind = false
				KeybindBtn.TextColor3 = C.textPri
				KeybindBtn.Text = "[ " .. tempKeys[1].Name .. " + " .. tempKeys[2].Name .. " ]"
				updateModalText()
				triggerAutoSave()
			end
		end
		return
	end

	if isListeningSilentAim and input.UserInputType == Enum.UserInputType.Keyboard then
		if input.KeyCode ~= Enum.KeyCode.Unknown then
			silentAimKey = input.KeyCode
			isListeningSilentAim = false
			SilentAimKeyBtn.TextColor3 = C.textPri
			SilentAimKeyBtn.Text = "[" .. silentAimKey.Name .. "]"
			triggerAutoSave()
			updateSilentAimLabel()
		end
		return
	end

	if not processed and not isListeningForKeybind and not isListeningSilentAim and input.UserInputType == Enum.UserInputType.Keyboard then
		if #activeKeybind == 2 then
			if (input.KeyCode == activeKeybind[2] and UserInputService:IsKeyDown(activeKeybind[1]))
			or (input.KeyCode == activeKeybind[1] and UserInputService:IsKeyDown(activeKeybind[2])) then
				if Main.Visible then shrinkToPill()
				elseif PillUI.Visible then expandFromPill() end
			end
		end
		if silentAimEnabled and input.KeyCode == silentAimKey then
			runSilentAim()
		end
	end
end)

print("[UNMM2] Loaded Successfully - Auto Toggle Near Murderer Edition")