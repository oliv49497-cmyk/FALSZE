-- // Servicios //
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local CoreGui = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local Player = Players.LocalPlayer
local GuiParent = (gethui and gethui()) or CoreGui or Player:WaitForChild("PlayerGui")

-- Limpiar instancias previas si ya estaba abierto
if GuiParent:FindFirstChild("PinkExecutorUI") then
	GuiParent.PinkExecutorUI:Destroy()
end

-- // Paleta de Colores Pastel //
local Colors = {
	MainPink = Color3.fromRGB(255, 209, 226),      -- #FFD1E2
	PanelBg = Color3.fromRGB(255, 232, 241),       -- #FFE8F1
	CardBg = Color3.fromRGB(255, 244, 248),        -- #FFF4F8
	AccentPink = Color3.fromRGB(244, 143, 177),    -- #F48FB1
	DarkPinkText = Color3.fromRGB(115, 42, 74),    -- #732A4A
	White = Color3.fromRGB(255, 255, 255),
	Stroke = Color3.fromRGB(248, 187, 208),        -- #F8BBD0
	LedGreen = Color3.fromRGB(76, 217, 100),
	LedRed = Color3.fromRGB(255, 59, 48)
}

-- // ScreenGui Principal //
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "PinkExecutorUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = GuiParent

-- Función auxiliar para bordes redondeados y contorno
local function StyleFrame(frame, radius, strokeThickness)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radius or 12)
	corner.Parent = frame

	if strokeThickness then
		local stroke = Instance.new("UIStroke")
		stroke.Color = Colors.Stroke
		stroke.Thickness = strokeThickness
		stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		stroke.Parent = frame
	end
end

-- Función para hacer ventanas arrastrables (Touch + Mouse)
local function MakeDraggable(frame)
	local dragging, dragInput, dragStart, startPos
	frame.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			dragStart = input.Position
			startPos = frame.Position
			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragging = false
				end
			end)
		end
	end)
	frame.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
			dragInput = input
		end
	end)
	UserInputService.InputChanged:Connect(function(input)
		if input == dragInput and dragging then
			local delta = input.Position - dragStart
			frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
		end
	end)
end

-- Función para ejecutar código o links http(s) de forma segura
local function RunLuauCode(rawCode)
	if not rawCode or rawCode:match("^%s*$") then return end
	local trimmed = rawCode:match("^%s*(.-)%s*$")

	if trimmed:match("^https?://") then
		task.spawn(function()
			local ok, content = pcall(function() return game:HttpGet(trimmed) end)
			if ok and content then
				local compileOk, fnOrErr = pcall(loadstring, content)
				if compileOk and type(fnOrErr) == "function" then
					task.spawn(fnOrErr)
				else
					warn("[PinkExec Error]:", fnOrErr)
				end
			else
				warn("[PinkExec HTTP Error]: No se pudo obtener el link.")
			end
		end)
		return
	end

	local compileOk, fnOrErr = pcall(loadstring, trimmed)
	if compileOk and type(fnOrErr) == "function" then
		task.spawn(fnOrErr)
	else
		warn("[PinkExec Syntax Error]:", fnOrErr)
	end
end

-- =========================================================================
-- 0. BOTÓN FLOTANTE DE REAPERTURA (MOVIBLE, SIN FONDO, EN LA ZONA MARCADA)
-- =========================================================================
local ReopenBtn = Instance.new("ImageButton")
ReopenBtn.Name = "ReopenToggleButton"
ReopenBtn.Size = UDim2.new(0, 52, 0, 52)
ReopenBtn.Position = UDim2.new(0.5, -26, 0.04, 0)
ReopenBtn.BackgroundTransparency = 1
ReopenBtn.BorderSizePixel = 0
ReopenBtn.Image = "rbxassetid://80509483576553"
ReopenBtn.ScaleType = Enum.ScaleType.Fit
ReopenBtn.Active = true
ReopenBtn.Visible = false
ReopenBtn.ZIndex = 50
ReopenBtn.Parent = ScreenGui

local SideBar

do
	local dragging = false
	local blockNextActivate = false
	local dragStart, startPos

	ReopenBtn.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			blockNextActivate = false
			dragStart = input.Position
			startPos = ReopenBtn.Position

			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragging = false
					task.delay(0.05, function()
						blockNextActivate = false
					end)
				end
			end)
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			local delta = input.Position - dragStart
			if delta.Magnitude > 10 then
				blockNextActivate = true
			end
			ReopenBtn.Position = UDim2.new(
				startPos.X.Scale,
				startPos.X.Offset + delta.X,
				startPos.Y.Scale,
				startPos.Y.Offset + delta.Y
			)
		end
	end)

	ReopenBtn.Activated:Connect(function()
		if blockNextActivate then
			blockNextActivate = false
			return
		end
		ReopenBtn.Visible = false
		if SideBar then
			SideBar.Visible = true
		end
	end)
end

-- =========================================================================
-- 1. BARRA LATERAL DERECHA (3 BOTONES)
-- =========================================================================
SideBar = Instance.new("Frame")
SideBar.Name = "SideBar"
SideBar.Size = UDim2.new(0, 56, 0, 184)
SideBar.Position = UDim2.new(1, -68, 0.5, -92)
SideBar.BackgroundColor3 = Colors.MainPink
SideBar.Visible = true
SideBar.ZIndex = 10
SideBar.Parent = ScreenGui
StyleFrame(SideBar, 16, 2)

local BarLayout = Instance.new("UIListLayout")
BarLayout.Padding = UDim.new(0, 10)
BarLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
BarLayout.VerticalAlignment = Enum.VerticalAlignment.Center
BarLayout.Parent = SideBar

local function CreateSidebarBtn(symbol)
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(0, 42, 0, 42)
	btn.BackgroundColor3 = Colors.CardBg
	btn.Text = symbol
	btn.TextColor3 = Colors.DarkPinkText
	btn.Font = Enum.Font.GothamBold
	btn.TextSize = 18
	btn.AutoButtonColor = true
	btn.ZIndex = 11
	btn.Parent = SideBar
	StyleFrame(btn, 12, 1.5)
	return btn
end

-- Orden de arriba hacia abajo:
-- 3er botón (arriba): Programar / Editor LuaU
local BtnCode = CreateSidebarBtn("</>")
-- 2do botón (arriba de cerrar): Buscar en ScriptBlox
local BtnSearch = CreateSidebarBtn("🔍")
-- 1er botón (abajo): Cerrar interfaz
local BtnClose = CreateSidebarBtn("✕")

-- =========================================================================
-- 2. VENTANA DE BÚSQUEDA (SCRIPTBLOX.COM)
-- =========================================================================
local SearchWindow = Instance.new("Frame")
SearchWindow.Name = "SearchWindow"
SearchWindow.Size = UDim2.new(0, 320, 0, 270)
SearchWindow.Position = UDim2.new(0.5, -160, 0.5, -135)
SearchWindow.BackgroundColor3 = Colors.PanelBg
SearchWindow.Visible = false
SearchWindow.ZIndex = 15
SearchWindow.Parent = ScreenGui
StyleFrame(SearchWindow, 16, 2)
MakeDraggable(SearchWindow)

local SearchTitle = Instance.new("TextLabel")
SearchTitle.Size = UDim2.new(1, -20, 0, 28)
SearchTitle.Position = UDim2.new(0, 12, 0, 6)
SearchTitle.BackgroundTransparency = 1
SearchTitle.Text = "♡ ScriptBlox Search ♡"
SearchTitle.TextColor3 = Colors.DarkPinkText
SearchTitle.Font = Enum.Font.GothamBold
SearchTitle.TextSize = 15
SearchTitle.TextXAlignment = Enum.TextXAlignment.Left
SearchTitle.ZIndex = 16
SearchTitle.Parent = SearchWindow

local SearchBox = Instance.new("TextBox")
SearchBox.Size = UDim2.new(1, -90, 0, 34)
SearchBox.Position = UDim2.new(0, 12, 0, 38)
SearchBox.BackgroundColor3 = Colors.White
SearchBox.PlaceholderText = "Buscar script (ej: fly, mm2)..."
SearchBox.PlaceholderColor3 = Color3.fromRGB(185, 130, 155)
SearchBox.Text = ""
SearchBox.TextColor3 = Colors.DarkPinkText
SearchBox.Font = Enum.Font.Gotham
SearchBox.TextSize = 13
SearchBox.ClearTextOnFocus = false
SearchBox.ZIndex = 16
SearchBox.Parent = SearchWindow
StyleFrame(SearchBox, 10, 1.5)

local GoSearchBtn = Instance.new("TextButton")
GoSearchBtn.Size = UDim2.new(0, 66, 0, 34)
GoSearchBtn.Position = UDim2.new(1, -78, 0, 38)
GoSearchBtn.BackgroundColor3 = Colors.AccentPink
GoSearchBtn.Text = "Buscar"
GoSearchBtn.TextColor3 = Colors.White
GoSearchBtn.Font = Enum.Font.GothamBold
GoSearchBtn.TextSize = 13
GoSearchBtn.ZIndex = 16
GoSearchBtn.Parent = SearchWindow
StyleFrame(GoSearchBtn, 10)

local ResultsScroll = Instance.new("ScrollingFrame")
ResultsScroll.Size = UDim2.new(1, -24, 1, -86)
ResultsScroll.Position = UDim2.new(0, 12, 0, 78)
ResultsScroll.BackgroundColor3 = Colors.CardBg
ResultsScroll.BorderSizePixel = 0
ResultsScroll.ScrollBarThickness = 4
ResultsScroll.ScrollBarImageColor3 = Colors.AccentPink
ResultsScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
ResultsScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
ResultsScroll.ZIndex = 16
ResultsScroll.Parent = SearchWindow
StyleFrame(ResultsScroll, 12, 1)

local ResultsLayout = Instance.new("UIListLayout")
ResultsLayout.Padding = UDim.new(0, 6)
ResultsLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
ResultsLayout.Parent = ResultsScroll

local ResultsPad = Instance.new("UIPadding")
ResultsPad.PaddingTop = UDim.new(0, 6)
ResultsPad.PaddingBottom = UDim.new(0, 6)
ResultsPad.PaddingLeft = UDim.new(0, 6)
ResultsPad.PaddingRight = UDim.new(0, 6)
ResultsPad.Parent = ResultsScroll

-- =========================================================================
-- 2.5 MINI INTERFAZ AL TOCAR UN RESULTADO (SOLO BOTÓN "EXECUTE")
-- =========================================================================
local SelectedScriptModal = Instance.new("Frame")
SelectedScriptModal.Name = "SelectedScriptModal"
SelectedScriptModal.Size = UDim2.new(0, 240, 0, 125)
SelectedScriptModal.Position = UDim2.new(0.5, -120, 0.5, -62)
SelectedScriptModal.BackgroundColor3 = Colors.MainPink
SelectedScriptModal.Visible = false
SelectedScriptModal.ZIndex = 25
SelectedScriptModal.Parent = ScreenGui
StyleFrame(SelectedScriptModal, 16, 2)
MakeDraggable(SelectedScriptModal)

local ModalClose = Instance.new("TextButton")
ModalClose.Size = UDim2.new(0, 24, 0, 24)
ModalClose.Position = UDim2.new(1, -30, 0, 6)
ModalClose.BackgroundColor3 = Colors.CardBg
ModalClose.Text = "✕"
ModalClose.TextColor3 = Colors.DarkPinkText
ModalClose.Font = Enum.Font.GothamBold
ModalClose.TextSize = 12
ModalClose.ZIndex = 26
ModalClose.Parent = SelectedScriptModal
StyleFrame(ModalClose, 8)
ModalClose.MouseButton1Click:Connect(function()
	SelectedScriptModal.Visible = false
end)

local ModalTitle = Instance.new("TextLabel")
ModalTitle.Size = UDim2.new(1, -44, 0, 42)
ModalTitle.Position = UDim2.new(0, 12, 0, 8)
ModalTitle.BackgroundTransparency = 1
ModalTitle.Text = "Script seleccionado"
ModalTitle.TextColor3 = Colors.DarkPinkText
ModalTitle.Font = Enum.Font.GothamBold
ModalTitle.TextSize = 13
ModalTitle.TextWrapped = true
ModalTitle.TextXAlignment = Enum.TextXAlignment.Left
ModalTitle.ZIndex = 26
ModalTitle.Parent = SelectedScriptModal

local ModalExecuteBtn = Instance.new("TextButton")
ModalExecuteBtn.Size = UDim2.new(1, -24, 0, 44)
ModalExecuteBtn.Position = UDim2.new(0, 12, 1, -56)
ModalExecuteBtn.BackgroundColor3 = Colors.AccentPink
ModalExecuteBtn.Text = "Execute"
ModalExecuteBtn.TextColor3 = Colors.White
ModalExecuteBtn.Font = Enum.Font.GothamBold
ModalExecuteBtn.TextSize = 16
ModalExecuteBtn.ZIndex = 26
ModalExecuteBtn.Parent = SelectedScriptModal
StyleFrame(ModalExecuteBtn, 12, 1.5)

local CurrentFetchedCode = ""
ModalExecuteBtn.MouseButton1Click:Connect(function()
	RunLuauCode(CurrentFetchedCode)
	SelectedScriptModal.Visible = false
end)

local function SearchScriptBlox(query)
	for _, child in ipairs(ResultsScroll:GetChildren()) do
		if child:IsA("TextButton") or child:IsA("TextLabel") then
			child:Destroy()
		end
	end

	if query == "" then return end

	local statusLbl = Instance.new("TextLabel")
	statusLbl.Size = UDim2.new(1, 0, 0, 30)
	statusLbl.BackgroundTransparency = 1
	statusLbl.Text = "Buscando en ScriptBlox..."
	statusLbl.TextColor3 = Colors.DarkPinkText
	statusLbl.Font = Enum.Font.Gotham
	statusLbl.TextSize = 13
	statusLbl.ZIndex = 17
	statusLbl.Parent = ResultsScroll

	task.spawn(function()
		local url = "https://scriptblox.com/api/script/search?q=" .. HttpService:UrlEncode(query) .. "&mode=free&max=15"
		local success, response = pcall(function()
			return game:HttpGet(url)
		end)

		statusLbl:Destroy()

		if not success or not response then
			local errLbl = Instance.new("TextLabel")
			errLbl.Size = UDim2.new(1, 0, 0, 30)
			errLbl.BackgroundTransparency = 1
			errLbl.Text = "Error al conectar con ScriptBlox."
			errLbl.TextColor3 = Colors.LedRed
			errLbl.Font = Enum.Font.Gotham
			errLbl.TextSize = 12
			errLbl.ZIndex = 17
			errLbl.Parent = ResultsScroll
			return
		end

		local decoded = HttpService:JSONDecode(response)
		local scripts = decoded and decoded.result and decoded.result.scripts

		if not scripts or #scripts == 0 then
			local emptyLbl = Instance.new("TextLabel")
			emptyLbl.Size = UDim2.new(1, 0, 0, 30)
			emptyLbl.BackgroundTransparency = 1
			emptyLbl.Text = "No se encontraron resultados."
			emptyLbl.TextColor3 = Colors.DarkPinkText
			emptyLbl.Font = Enum.Font.Gotham
			emptyLbl.TextSize = 12
			emptyLbl.ZIndex = 17
			emptyLbl.Parent = ResultsScroll
			return
		end

		for _, item in ipairs(scripts) do
			local itemBtn = Instance.new("TextButton")
			itemBtn.Size = UDim2.new(1, -4, 0, 44)
			itemBtn.BackgroundColor3 = Colors.White
			itemBtn.Text = ""
			itemBtn.ZIndex = 17
			itemBtn.Parent = ResultsScroll
			StyleFrame(itemBtn, 10, 1)

			local title = Instance.new("TextLabel")
			title.Size = UDim2.new(1, -16, 0, 22)
			title.Position = UDim2.new(0, 8, 0, 3)
			title.BackgroundTransparency = 1
			title.Text = item.title or "Sin título"
			title.TextColor3 = Colors.DarkPinkText
			title.Font = Enum.Font.GothamBold
			title.TextSize = 12
			title.TextXAlignment = Enum.TextXAlignment.Left
			title.TextTruncate = Enum.TextTruncate.AtEnd
			title.ZIndex = 18
			title.Parent = itemBtn

			local gameName = Instance.new("TextLabel")
			gameName.Size = UDim2.new(1, -16, 0, 16)
			gameName.Position = UDim2.new(0, 8, 0, 24)
			gameName.BackgroundTransparency = 1
			gameName.Text = "Juego: " .. ((item.game and item.game.name) or "Universal")
			gameName.TextColor3 = Color3.fromRGB(165, 95, 125)
			gameName.Font = Enum.Font.Gotham
			gameName.TextSize = 11
			gameName.TextXAlignment = Enum.TextXAlignment.Left
			gameName.TextTruncate = Enum.TextTruncate.AtEnd
			gameName.ZIndex = 18
			gameName.Parent = itemBtn

			itemBtn.MouseButton1Click:Connect(function()
				ModalTitle.Text = item.title or "Script"
				CurrentFetchedCode = item.script or ""

				if CurrentFetchedCode == "" and item.slug then
					ModalTitle.Text = "Cargando script..."
					SelectedScriptModal.Visible = true
					task.spawn(function()
						local ok2, res2 = pcall(function()
							return game:HttpGet("https://scriptblox.com/api/script/" .. item.slug)
						end)
						if ok2 and res2 then
							local data2 = HttpService:JSONDecode(res2)
							CurrentFetchedCode = (data2 and data2.script and data2.script.script) or ""
							ModalTitle.Text = item.title or "Script listo"
						end
					end)
				else
					SelectedScriptModal.Visible = true
				end
			end)
		end
	end)
end

GoSearchBtn.MouseButton1Click:Connect(function()
	SearchScriptBlox(SearchBox.Text)
end)

SearchBox.FocusLost:Connect(function(enterPressed)
	if enterPressed then
		SearchScriptBlox(SearchBox.Text)
	end
end)

-- =========================================================================
-- 3. VENTANA DE PROGRAMACIÓN / EDITOR LUAU CON LED VERDE/ROJO
-- =========================================================================
local EditorWindow = Instance.new("Frame")
EditorWindow.Name = "EditorWindow"
EditorWindow.Size = UDim2.new(0, 340, 0, 270)
EditorWindow.Position = UDim2.new(0.5, -170, 0.5, -135)
EditorWindow.BackgroundColor3 = Colors.PanelBg
EditorWindow.Visible = false
EditorWindow.ZIndex = 15
EditorWindow.Parent = ScreenGui
StyleFrame(EditorWindow, 16, 2)
MakeDraggable(EditorWindow)

local EditorTitle = Instance.new("TextLabel")
EditorTitle.Size = UDim2.new(1, -60, 0, 30)
EditorTitle.Position = UDim2.new(0, 14, 0, 6)
EditorTitle.BackgroundTransparency = 1
EditorTitle.Text = "♡ LuaU Executor & Validator ♡"
EditorTitle.TextColor3 = Colors.DarkPinkText
EditorTitle.Font = Enum.Font.GothamBold
EditorTitle.TextSize = 14
EditorTitle.TextXAlignment = Enum.TextXAlignment.Left
EditorTitle.ZIndex = 16
EditorTitle.Parent = EditorWindow

local StatusLed = Instance.new("Frame")
StatusLed.Name = "StatusLed"
StatusLed.Size = UDim2.new(0, 16, 0, 16)
StatusLed.Position = UDim2.new(1, -28, 0, 13)
StatusLed.BackgroundColor3 = Colors.LedRed
StatusLed.ZIndex = 16
StatusLed.Parent = EditorWindow
StyleFrame(StatusLed, 99, 1.5)

local LedGlow = Instance.new("UIStroke")
LedGlow.Color = Colors.LedRed
LedGlow.Thickness = 2
LedGlow.Transparency = 0.4
LedGlow.Parent = StatusLed

local CodeScroll = Instance.new("ScrollingFrame")
CodeScroll.Size = UDim2.new(1, -24, 1, -94)
CodeScroll.Position = UDim2.new(0, 12, 0, 40)
CodeScroll.BackgroundColor3 = Colors.White
CodeScroll.BorderSizePixel = 0
CodeScroll.ScrollBarThickness = 4
CodeScroll.ScrollBarImageColor3 = Colors.AccentPink
CodeScroll.AutomaticCanvasSize = Enum.AutomaticSize.XY
CodeScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
CodeScroll.ZIndex = 16
CodeScroll.Parent = EditorWindow
StyleFrame(CodeScroll, 12, 1.5)

local CodeBox = Instance.new("TextBox")
CodeBox.Size = UDim2.new(1, -12, 1, -12)
CodeBox.Position = UDim2.new(0, 6, 0, 6)
CodeBox.BackgroundTransparency = 1
CodeBox.Text = ""
CodeBox.PlaceholderText = "-- Pega tu código LuaU, loadstring o link https://..."
CodeBox.PlaceholderColor3 = Color3.fromRGB(185, 130, 155)
CodeBox.TextColor3 = Colors.DarkPinkText
CodeBox.Font = Enum.Font.Code
CodeBox.TextSize = 13
CodeBox.MultiLine = true
CodeBox.ClearTextOnFocus = false
CodeBox.TextXAlignment = Enum.TextXAlignment.Left
CodeBox.TextYAlignment = Enum.TextYAlignment.Top
CodeBox.AutomaticSize = Enum.AutomaticSize.XY
CodeBox.ZIndex = 17
CodeBox.Parent = CodeScroll

local EditorExecuteBtn = Instance.new("TextButton")
EditorExecuteBtn.Size = UDim2.new(1, -24, 0, 38)
EditorExecuteBtn.Position = UDim2.new(0, 12, 1, -46)
EditorExecuteBtn.BackgroundColor3 = Colors.AccentPink
EditorExecuteBtn.Text = "Execute"
EditorExecuteBtn.TextColor3 = Colors.White
EditorExecuteBtn.Font = Enum.Font.GothamBold
EditorExecuteBtn.TextSize = 15
EditorExecuteBtn.ZIndex = 16
EditorExecuteBtn.Parent = EditorWindow
StyleFrame(EditorExecuteBtn, 12, 1.5)

local function ValidateLuaU()
	local text = CodeBox.Text
	local isValid = false

	if text and not text:match("^%s*$") then
		local trimmed = text:match("^%s*(.-)%s*$")
		if trimmed:match("^https?://[%w-_%.%?%.:/%+=&%%]+$") then
			isValid = true
		else
			local ok, compiledFn = pcall(loadstring, trimmed)
			if ok and type(compiledFn) == "function" then
				isValid = true
			end
		end
	end

	local targetColor = isValid and Colors.LedGreen or Colors.LedRed
	TweenService:Create(StatusLed, TweenInfo.new(0.2), {BackgroundColor3 = targetColor}):Play()
	LedGlow.Color = targetColor
end

CodeBox:GetPropertyChangedSignal("Text"):Connect(ValidateLuaU)

EditorExecuteBtn.MouseButton1Click:Connect(function()
	RunLuauCode(CodeBox.Text)
end)

-- =========================================================================
-- 4. CONTROLES DE LA BARRA LATERAL Y REAPERTURA
-- =========================================================================
BtnCode.MouseButton1Click:Connect(function()
	EditorWindow.Visible = not EditorWindow.Visible
	if EditorWindow.Visible then
		SearchWindow.Visible = false
		SelectedScriptModal.Visible = false
	end
end)

BtnSearch.MouseButton1Click:Connect(function()
	SearchWindow.Visible = not SearchWindow.Visible
	if SearchWindow.Visible then
		EditorWindow.Visible = false
	else
		SelectedScriptModal.Visible = false
	end
end)

BtnClose.MouseButton1Click:Connect(function()
	SideBar.Visible = false
	SearchWindow.Visible = false
	EditorWindow.Visible = false
	SelectedScriptModal.Visible = false
	ReopenBtn.Visible = true
end)
