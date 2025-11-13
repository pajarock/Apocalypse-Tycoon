--[[
	═══════════════════════════════════════════════════════════════════════
	SNIPPET PARA BaseVisualsManager.lua - Eliminar Billboard (Doble Barra)
	═══════════════════════════════════════════════════════════════════════

	INSTRUCCIONES:
	1. Abre ServerStorage.Managers.BaseVisualsManager en Studio
	2. Busca la función CreateBase (línea ~431)
	3. Busca estas líneas (aprox. línea 449):

		local towers = createTowers(basePart)
		local billboard = createBillboard(basePart, playerName, userId)

	4. COMENTA la línea del billboard y pon nil:
--]]

	-- ✅ ARREGLADO: Billboard deshabilitado (usamos BaseHUD.client.lua en su lugar)
	-- local billboard = createBillboard(basePart, playerName, userId)
	local billboard = nil -- Sin billboard duplicado

--[[
	5. Ahora busca la función UpdateBaseVisuals (línea ~476)
	6. Busca estas líneas (aprox. línea 495-519):

		-- Actualizar HP bar en billboard
		local billboard = data.decorations.billboard
		if billboard then
			local hpBar = billboard:FindFirstChild("HPBar", true)
			local hpLabel = billboard:FindFirstChild("HPLabel", true)

			if hpBar then
				TweenService:Create(
					hpBar,
					TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
					{Size = UDim2.fromScale(hpPercent, 1)}
				):Play()

				-- Color bar según HP
				if hpPercent > 0.7 then
					hpBar.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
				elseif hpPercent > 0.3 then
					hpBar.BackgroundColor3 = Color3.fromRGB(255, 200, 0)
				else
					hpBar.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
				end
			end

			if hpLabel then
				hpLabel.Text = string.format("HP: %d/%d", currentHP, maxHP)
			end
		end

	7. COMENTA TODO ESE BLOQUE:
--]]

	-- ✅ ARREGLADO: Billboard deshabilitado - actualizaciones se hacen en BaseHUD.client.lua
	--[[
	local billboard = data.decorations.billboard
	if billboard then
		local hpBar = billboard:FindFirstChild("HPBar", true)
		local hpLabel = billboard:FindFirstChild("HPLabel", true)

		if hpBar then
			TweenService:Create(
				hpBar,
				TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
				{Size = UDim2.fromScale(hpPercent, 1)}
			):Play()

			-- Color bar según HP
			if hpPercent > 0.7 then
				hpBar.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
			elseif hpPercent > 0.3 then
				hpBar.BackgroundColor3 = Color3.fromRGB(255, 200, 0)
			else
				hpBar.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
			end
		end

		if hpLabel then
			hpLabel.Text = string.format("HP: %d/%d", currentHP, maxHP)
		end
	end
	--]]

--[[
	═══════════════════════════════════════════════════════════════════════
	RESULTADO ESPERADO:

	Al iniciar el juego:
	- ✅ NO hay barra flotante sobre la base física
	- ✅ SÍ hay barra en la esquina inferior derecha de la pantalla
	- ✅ La barra se actualiza correctamente con BaseStateChanged

	Si ves solo UNA barra (abajo-derecha), ¡TODO FUNCIONA! ✅
	═══════════════════════════════════════════════════════════════════════

	NOTAS:
	- El billboard NO se elimina por completo, solo se desactiva
	- Esto permite reactivarlo fácilmente si cambias de opinión
	- BaseHUD.client.lua (StarterGui) maneja toda la lógica de UI
--]]
