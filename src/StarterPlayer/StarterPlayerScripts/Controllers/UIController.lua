--!strict
--[[
	UI CONTROLLER - Apocalypse Tycoon
	-----------------------------------------------------------------------

	Maneja animaciones y transiciones de UI para feedback visual "jugoso".

	FEATURES:
	? Slide In/Out con direcciones configurables
	? Fade In/Out suaves
	? Hover effects (scale, glow, color)
	? Purchase feedback (bounce + particles + sound)
	? Tweens con easing profesional
	? Promise-based API para chaining

	USAGE:
		local UIController = require(script.Parent.UIController)

		-- Slide
		UIController:SlideIn(frame, "Left", 0.4)
		UIController:SlideOut(frame, "Right", 0.3)

		-- Fade
		UIController:FadeIn(frame, 0.3)
		UIController:FadeOut(frame, 0.5)

		-- Hover effects
		UIController:AddHoverEffect(button, "scale+glow")

		-- Purchase feedback
		UIController:PlayPurchaseEffect(button)

	API:
		:SlideIn(frame: GuiObject, direction: string, duration: number) ? Promise
		:SlideOut(frame: GuiObject, direction: string, duration: number) ? Promise
		:FadeIn(frame: GuiObject, duration: number) ? Promise
		:FadeOut(frame: GuiObject, duration: number) ? Promise
		:AddHoverEffect(button: GuiButton, effectType: string)
		:PlayPurchaseEffect(button: GuiButton)
		:Bounce(guiObject: GuiObject, intensity: number)
]]

local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

-------------------------------------------------------------------------
-- CONSTANTS
-------------------------------------------------------------------------

local EASING_STYLE = Enum.EasingStyle.Quad
local EASING_DIRECTION = Enum.EasingDirection.Out

local SLIDE_OFFSETS = {
	Left = UDim2.fromScale(-1.2, 0),
	Right = UDim2.fromScale(1.2, 0),
	Up = UDim2.fromScale(0, -1.2),
	Down = UDim2.fromScale(0, 1.2)
}

local HOVER_SCALE = 1.1
local HOVER_DURATION = 0.15

local DEBUG_MODE = false

-------------------------------------------------------------------------
-- TYPES
-------------------------------------------------------------------------

type Promise = {
	andThen: (Promise, (any) -> ()) -> Promise,
	catch: (Promise, (any) -> ()) -> Promise
}

-------------------------------------------------------------------------
-- MODULE
-------------------------------------------------------------------------

local UIController = {}

-------------------------------------------------------------------------
-- UTILITIES
-------------------------------------------------------------------------

-- Simple Promise implementation (no external dependencies)
local function createPromise(executor: (resolve: (any) -> (), reject: (any) -> ()) -> ()): any
	local promise = {
		status = "pending",
		value = nil,
		callbacks = {}
	}

	local function resolve(value: any)
		if promise.status ~= "pending" then return end
		promise.status = "resolved"
		promise.value = value

		for _, callback in ipairs(promise.callbacks) do
			if callback.onResolve then
				task.spawn(callback.onResolve, value)
			end
		end
	end

	local function reject(reason: any)
		if promise.status ~= "pending" then return end
		promise.status = "rejected"
		promise.value = reason

		for _, callback in ipairs(promise.callbacks) do
			if callback.onReject then
				task.spawn(callback.onReject, reason)
			end
		end
	end

	function promise:andThen(onResolve: (any) -> (), onReject: ((any) -> ())?): any
		if self.status == "resolved" then
			task.spawn(onResolve, self.value)
		elseif self.status == "rejected" and onReject then
			task.spawn(onReject, self.value)
		else
			table.insert(self.callbacks, {onResolve = onResolve, onReject = onReject})
		end
		return self
	end

	function promise:catch(onReject: (any) -> ()): any
		return self:andThen(nil, onReject)
	end

	task.spawn(executor, resolve, reject)

	return promise
end

local function tweenPromise(instance: Instance, tweenInfo: TweenInfo, properties: {[string]: any}): any
	return createPromise(function(resolve, reject)
		local tween = TweenService:Create(instance, tweenInfo, properties)

		tween.Completed:Connect(function(playbackState)
			if playbackState == Enum.PlaybackState.Completed then
				resolve(instance)
			else
				reject("Tween cancelled or paused")
			end
		end)

		tween:Play()
	end)
end

-------------------------------------------------------------------------
-- SLIDE ANIMATIONS
-------------------------------------------------------------------------

--[[
	Desliza un frame hacia adentro desde una direcciÃÂ³n.

	@param frame GuiObject - El frame a animar
	@param direction string - "Left", "Right", "Up", "Down"
	@param duration number - DuraciÃÂ³n en segundos
	@return Promise
]]
function UIController:SlideIn(frame: GuiObject, direction: string, duration: number): any
	local offset = SLIDE_OFFSETS[direction]
	if not offset then
		warn(("[UIController] DirecciÃÂ³n invÃÂ¡lida: %s"):format(direction))
		return createPromise(function(_, reject) reject("Invalid direction") end)
	end

	-- Store original position if not stored
	if not frame:GetAttribute("OriginalPosition") then
		frame:SetAttribute("OriginalPositionX", frame.Position.X.Scale)
		frame:SetAttribute("OriginalPositionY", frame.Position.Y.Scale)
		frame:SetAttribute("OriginalPositionXOffset", frame.Position.X.Offset)
		frame:SetAttribute("OriginalPositionYOffset", frame.Position.Y.Offset)
	end

	local originalPos = UDim2.new(
		frame:GetAttribute("OriginalPositionX") or 0,
		frame:GetAttribute("OriginalPositionXOffset") or 0,
		frame:GetAttribute("OriginalPositionY") or 0,
		frame:GetAttribute("OriginalPositionYOffset") or 0
	)

	-- Start from offset position
	frame.Position = originalPos + offset
	frame.Visible = true

	if DEBUG_MODE then
		print(("[UIController] SlideIn: %s from %s"):format(frame.Name, direction))
	end

	-- Tween to original position
	return tweenPromise(
		frame,
		TweenInfo.new(duration, EASING_STYLE, EASING_DIRECTION),
		{Position = originalPos}
	)
end

--[[
	Desliza un frame hacia afuera en una direcciÃÂ³n.

	@param frame GuiObject - El frame a animar
	@param direction string - "Left", "Right", "Up", "Down"
	@param duration number - DuraciÃÂ³n en segundos
	@return Promise
]]
function UIController:SlideOut(frame: GuiObject, direction: string, duration: number): any
	local offset = SLIDE_OFFSETS[direction]
	if not offset then
		warn(("[UIController] DirecciÃÂ³n invÃÂ¡lida: %s"):format(direction))
		return createPromise(function(_, reject) reject("Invalid direction") end)
	end

	local targetPos = frame.Position + offset

	if DEBUG_MODE then
		print(("[UIController] SlideOut: %s to %s"):format(frame.Name, direction))
	end

	return tweenPromise(
		frame,
		TweenInfo.new(duration, EASING_STYLE, Enum.EasingDirection.In),
		{Position = targetPos}
	):andThen(function()
		frame.Visible = false
	end)
end

-------------------------------------------------------------------------
-- FADE ANIMATIONS
-------------------------------------------------------------------------

--[[
	Fade in (aparece gradualmente).

	@param frame GuiObject - El frame a animar
	@param duration number - DuraciÃÂ³n en segundos
	@return Promise
]]
function UIController:FadeIn(frame: GuiObject, duration: number): any
	frame.Visible = true

	-- Handle different GuiObject types
	local properties = {}

	if frame:IsA("Frame") or frame:IsA("TextLabel") or frame:IsA("TextButton") or frame:IsA("ImageLabel") or frame:IsA("ImageButton") then
		if frame:IsA("TextLabel") or frame:IsA("TextButton") then
			properties.TextTransparency = 0
		end
		if frame:IsA("Frame") or frame:IsA("TextLabel") or frame:IsA("TextButton") or frame:IsA("ImageLabel") or frame:IsA("ImageButton") then
			properties.BackgroundTransparency = frame:GetAttribute("OriginalBackgroundTransparency") or 0
		end
		if frame:IsA("ImageLabel") or frame:IsA("ImageButton") then
			properties.ImageTransparency = 0
		end
	end

	if DEBUG_MODE then
		print(("[UIController] FadeIn: %s"):format(frame.Name))
	end

	return tweenPromise(
		frame,
		TweenInfo.new(duration, EASING_STYLE, EASING_DIRECTION),
		properties
	)
end

--[[
	Fade out (desaparece gradualmente).

	@param frame GuiObject - El frame a animar
	@param duration number - DuraciÃÂ³n en segundos
	@return Promise
]]
function UIController:FadeOut(frame: GuiObject, duration: number): any
	-- Store original transparency
	if frame:IsA("Frame") or frame:IsA("TextLabel") or frame:IsA("TextButton") or frame:IsA("ImageLabel") or frame:IsA("ImageButton") then
		frame:SetAttribute("OriginalBackgroundTransparency", frame.BackgroundTransparency)
	end

	local properties = {}

	if frame:IsA("TextLabel") or frame:IsA("TextButton") then
		properties.TextTransparency = 1
	end
	if frame:IsA("Frame") or frame:IsA("TextLabel") or frame:IsA("TextButton") or frame:IsA("ImageLabel") or frame:IsA("ImageButton") then
		properties.BackgroundTransparency = 1
	end
	if frame:IsA("ImageLabel") or frame:IsA("ImageButton") then
		properties.ImageTransparency = 1
	end

	if DEBUG_MODE then
		print(("[UIController] FadeOut: %s"):format(frame.Name))
	end

	return tweenPromise(
		frame,
		TweenInfo.new(duration, EASING_STYLE, Enum.EasingDirection.In),
		properties
	):andThen(function()
		frame.Visible = false
	end)
end

-------------------------------------------------------------------------
-- HOVER EFFECTS
-------------------------------------------------------------------------

--[[
	Agrega hover effect a un botÃÂ³n.

	@param button GuiButton - El botÃÂ³n
	@param effectType string - "scale", "glow", "color", "scale+glow"
]]
function UIController:AddHoverEffect(button: GuiButton, effectType: string)
	-- Store original properties
	if not button:GetAttribute("OriginalSize") then
		button:SetAttribute("OriginalSizeX", button.Size.X.Scale)
		button:SetAttribute("OriginalSizeY", button.Size.Y.Scale)
		button:SetAttribute("OriginalSizeXOffset", button.Size.X.Offset)
		button:SetAttribute("OriginalSizeYOffset", button.Size.Y.Offset)
	end

	local originalSize = UDim2.new(
		button:GetAttribute("OriginalSizeX") or 0,
		button:GetAttribute("OriginalSizeXOffset") or 0,
		button:GetAttribute("OriginalSizeY") or 0,
		button:GetAttribute("OriginalSizeYOffset") or 0
	)

	-- Mouse enter
	button.MouseEnter:Connect(function()
		if effectType:find("scale") then
			-- Scale up
			TweenService:Create(
				button,
				TweenInfo.new(HOVER_DURATION, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
				{Size = UDim2.new(
					originalSize.X.Scale * HOVER_SCALE,
					originalSize.X.Offset * HOVER_SCALE,
					originalSize.Y.Scale * HOVER_SCALE,
					originalSize.Y.Offset * HOVER_SCALE
					)}
			):Play()
		end

		if effectType:find("glow") then
			-- Add glow (increase brightness)
			if button:IsA("TextButton") or button:IsA("TextLabel") then
				local originalColor = button.BackgroundColor3
				local brighterColor = Color3.new(
					math.min(1, originalColor.R * 1.3),
					math.min(1, originalColor.G * 1.3),
					math.min(1, originalColor.B * 1.3)
				)
				TweenService:Create(
					button,
					TweenInfo.new(HOVER_DURATION, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
					{BackgroundColor3 = brighterColor}
				):Play()
			end
		end

		if effectType == "color" then
			-- Color shift (example: slightly lighter)
			if button:IsA("TextButton") or button:IsA("TextLabel") then
				local originalColor = button.BackgroundColor3
				button:SetAttribute("OriginalColorR", originalColor.R)
				button:SetAttribute("OriginalColorG", originalColor.G)
				button:SetAttribute("OriginalColorB", originalColor.B)

				TweenService:Create(
					button,
					TweenInfo.new(HOVER_DURATION, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
					{BackgroundColor3 = originalColor:Lerp(Color3.new(1, 1, 1), 0.2)}
				):Play()
			end
		end
	end)

	-- Mouse leave
	button.MouseLeave:Connect(function()
		if effectType:find("scale") then
			-- Scale effect
			local HOVER_SCALE = 1.05

			-- Store original size
			button:SetAttribute("OriginalSizeX", button.Size.X.Scale)
			button:SetAttribute("OriginalSizeY", button.Size.Y.Scale)
			button:SetAttribute("OriginalSizeXOffset", button.Size.X.Offset)
			button:SetAttribute("OriginalSizeYOffset", button.Size.Y.Offset)

			local originalSize = button.Size

			button.MouseEnter:Connect(function()
				-- ? FIX: Multiplicar componentes manualmente
				local scaledSize = UDim2.new(
					originalSize.X.Scale * HOVER_SCALE,
					originalSize.X.Offset * HOVER_SCALE,
					originalSize.Y.Scale * HOVER_SCALE,
					originalSize.Y.Offset * HOVER_SCALE
				)

				TweenService:Create(
					button,
					TweenInfo.new(HOVER_DURATION, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
					{Size = scaledSize}
				):Play()
			end)

			button.MouseLeave:Connect(function()
				-- Scale back
				TweenService:Create(
					button,
					TweenInfo.new(HOVER_DURATION, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
					{Size = originalSize}  -- Este estÃÂ¡ bien
				):Play()
			end)
		end

		if effectType:find("glow") or effectType == "color" then
			-- Restore color
			if button:IsA("TextButton") or button:IsA("TextLabel") then
				local originalColor = Color3.new(
					button:GetAttribute("OriginalColorR") or button.BackgroundColor3.R,
					button:GetAttribute("OriginalColorG") or button.BackgroundColor3.G,
					button:GetAttribute("OriginalColorB") or button.BackgroundColor3.B
				)

				TweenService:Create(
					button,
					TweenInfo.new(HOVER_DURATION, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
					{BackgroundColor3 = originalColor}
				):Play()
			end
		end
	end)

	if DEBUG_MODE then
		print(("[UIController] Added hover effect '%s' to %s"):format(effectType, button.Name))
	end
end

-------------------------------------------------------------------------
-- PURCHASE FEEDBACK
-------------------------------------------------------------------------

--[[
	Muestra feedback visual al comprar un upgrade.

	@param button GuiButton - El botÃÂ³n que se clickeÃÂ³
]]
function UIController:PlayPurchaseEffect(button: GuiButton)
	-- Bounce animation
	self:Bounce(button, 1.15)

	-- Color flash
	if button:IsA("TextButton") or button:IsA("Frame") then
		local originalColor = button.BackgroundColor3
		local flashColor = Color3.fromRGB(100, 255, 100) -- Green

		button.BackgroundColor3 = flashColor

		TweenService:Create(
			button,
			TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{BackgroundColor3 = originalColor}
		):Play()
	end

	-- Particle effect (simple UI particles)
	self:CreateParticleBurst(button, Color3.fromRGB(100, 255, 100), 8)

	if DEBUG_MODE then
		print(("[UIController] Purchase effect on %s"):format(button.Name))
	end
end

--[[
	Bounce effect (squash & stretch).

	@param guiObject GuiObject - El objeto a animar
	@param intensity number - Multiplicador de scale mÃÂ¡ximo
]]
function UIController:Bounce(guiObject: GuiObject, intensity: number)
	intensity = intensity or 1.15

	if not guiObject:GetAttribute("OriginalSizeX") then
		guiObject:SetAttribute("OriginalSizeX", guiObject.Size.X.Scale)
		guiObject:SetAttribute("OriginalSizeY", guiObject.Size.Y.Scale)
		guiObject:SetAttribute("OriginalSizeXOffset", guiObject.Size.X.Offset)
		guiObject:SetAttribute("OriginalSizeYOffset", guiObject.Size.Y.Offset)
	end

	local originalSize = UDim2.new(
		guiObject:GetAttribute("OriginalSizeX") or 0,
		guiObject:GetAttribute("OriginalSizeXOffset") or 0,
		guiObject:GetAttribute("OriginalSizeY") or 0,
		guiObject:GetAttribute("OriginalSizeYOffset") or 0
	)

	-- ? FIX: Multiplicar cada componente manualmente
	local bounceSize = UDim2.new(
		originalSize.X.Scale * intensity,
		originalSize.X.Offset * intensity,
		originalSize.Y.Scale * intensity,
		originalSize.Y.Offset * intensity
	)

	-- Bounce up
	local bounceUp = TweenService:Create(
		guiObject,
		TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{Size = bounceSize}  -- ? Ahora sÃÂ­ usa UDim2 correcto
	)

	-- Bounce down
	local bounceDown = TweenService:Create(
		guiObject,
		TweenInfo.new(0.2, Enum.EasingStyle.Elastic, Enum.EasingDirection.Out),
		{Size = originalSize}
	)

	bounceUp:Play()
	bounceUp.Completed:Connect(function()
		bounceDown:Play()
	end)
end

--[[
	Crea un burst de partÃÂ­culas UI simples.

	@param parent GuiObject - Parent donde crear partÃÂ­culas
	@param color Color3 - Color de las partÃÂ­culas
	@param count number - Cantidad de partÃÂ­culas
]]
function UIController:CreateParticleBurst(parent: GuiObject, color: Color3, count: number)
	for i = 1, count do
		local particle = Instance.new("Frame")
		particle.Size = UDim2.fromOffset(8, 8)
		particle.Position = UDim2.fromScale(0.5, 0.5)
		particle.AnchorPoint = Vector2.new(0.5, 0.5)
		particle.BackgroundColor3 = color
		particle.BorderSizePixel = 0
		particle.ZIndex = parent.ZIndex + 1
		particle.Parent = parent

		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(1, 0)
		corner.Parent = particle

		-- Random direction
		local angle = math.rad(i * (360 / count))
		local distance = math.random(30, 60)
		local targetPos = UDim2.new(
			0.5 + math.cos(angle) * 0.3,
			0,
			0.5 + math.sin(angle) * 0.3,
			0
		)

		-- Animate
		local tween = TweenService:Create(
			particle,
			TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{
				Position = targetPos,
				BackgroundTransparency = 1,
				Size = UDim2.fromOffset(2, 2)
			}
		)

		tween:Play()
		Debris:AddItem(particle, 0.6)
	end
end

-------------------------------------------------------------------------
-- INITIALIZATION
-------------------------------------------------------------------------

print("[UIController] ? MÃÂ³dulo cargado")

return UIController