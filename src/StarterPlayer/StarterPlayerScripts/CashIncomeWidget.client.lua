--!strict
--[[
	-----------------------------------------------------------------------
	CASH INCOME WIDGET - Widget unificado con estilo grafiti
	-----------------------------------------------------------------------

	Muestra:
	- Dinero actual
	- Income por segundo
	- MULTIPLIER cuando IncomeBoost estÃÂ¡ activo (2X)

	-----------------------------------------------------------------------
--]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Remotes
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local PowerUpActivated = Remotes:WaitForChild("PowerUpActivated", 10) :: RemoteEvent?
local PowerUpExpired = Remotes:WaitForChild("PowerUpExpired", 10) :: RemoteEvent?

-- Estado
local IncomeBoostActive = false
local BaseIncomePerSecond = 8

-------------------------------------------------------------------------
-- DETECTAR CUANDO INCOMEBOOST ESTÃÂ ACTIVO
-------------------------------------------------------------------------

if PowerUpActivated then
	PowerUpActivated.OnClientEvent:Connect(function(powerUpId: string, duration: number)
		if powerUpId == "IncomeBoost" then
			IncomeBoostActive = true
			print("[CashIncomeWidget] ?? IncomeBoost ACTIVO - Showing 2X")
			updateIncomeDisplay()
		end
	end)
end

if PowerUpExpired then
	PowerUpExpired.OnClientEvent:Connect(function(powerUpId: string)
		if powerUpId == "IncomeBoost" then
			IncomeBoostActive = false
			print("[CashIncomeWidget] ?? IncomeBoost EXPIRADO - Showing normal")
			updateIncomeDisplay()
		end
	end)
end

-------------------------------------------------------------------------
-- ACTUALIZAR DISPLAY DE INCOME
-------------------------------------------------------------------------

function updateIncomeDisplay()
	-- Buscar el widget existente (si existe en PlayerGui)
	-- Si no existe, esta funciÃÂ³n no harÃÂ¡ nada

	-- Buscar en todos los ScreenGuis
	for _, gui in pairs(playerGui:GetChildren()) do
		if gui:IsA("ScreenGui") then
			-- Buscar label de income
			for _, descendant in pairs(gui:GetDescendants()) do
				if descendant:IsA("TextLabel") then
					local text = descendant.Text

					-- Detectar si es el label de income (busca por patrÃÂ³n)
					if text:match("%$.*sec") or text:match("Income") or descendant.Name:match("Income") then
						print("[CashIncomeWidget] Found income label:", descendant:GetFullName())

						-- Actualizar el texto para mostrar multiplicador
						if IncomeBoostActive then
							-- Agregar indicador 2X
							if not text:match("2X") and not text:match("x2") then
								descendant.Text = "?? 2X " .. text
								descendant.TextColor3 = Color3.fromRGB(255, 215, 0) -- Dorado

								-- Bounce animation
								local originalSize = descendant.TextSize
								TweenService:Create(descendant, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
									TextSize = originalSize * 1.3
								}):Play()

								task.wait(0.2)

								TweenService:Create(descendant, TweenInfo.new(0.2, Enum.EasingStyle.Elastic, Enum.EasingDirection.Out), {
									TextSize = originalSize
								}):Play()
							end
						else
							-- Quitar indicador 2X
							descendant.Text = descendant.Text:gsub("?? 2X ", ""):gsub("2X ", ""):gsub("x2 ", "")
							descendant.TextColor3 = Color3.fromRGB(255, 255, 255) -- Blanco normal
						end
					end
				end
			end
		end
	end
end

print("[CashIncomeWidget] ? Widget de income inicializado - detectando IncomeBoost")