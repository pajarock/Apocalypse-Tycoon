-- VERSION LIMPIA DE InitPlayer - Copia esto a BaseModule.lua

function BaseModule.InitPlayer(userId: number)
	if BaseState[userId] then
		if DEBUG then
			warn(("[BaseModule] Usuario %d ya inicializado"):format(userId))
		end
		return
	end

	BaseState[userId] = {
		HP = Config.BASE_MAX_HP,
		MaxHP = Config.BASE_MAX_HP,
		LastDamageTime = 0,
		IsInvulnerable = false,
		ShieldLevel = 0,
		MeteorsSurvived = 0,
		RegenEnabled = true,
		DiedDuringWave = false
	}

	if DEBUG then
		print(("[BaseModule] Inicializado userId %d - HP: %d"):format(userId, Config.BASE_MAX_HP))
	end
end
