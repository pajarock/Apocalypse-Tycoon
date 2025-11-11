--!strict
--[[
	VFX CONFIG - Apocalypse Tycoon
	-----------------------------------------------------------------------

	Data-driven effect templates para el VFXManager.
	Modifica estos valores para ajustar efectos sin tocar código.

	ESTRUCTURA:
	{
		EffectName = {
			Particles = {configuración de partículas},
			Sound = {configuración de audio},
			Light = {configuración de luz},
			Duration = tiempo total del efecto
		}
	}

	PERFORMANCE:
	- Máximo 100 partículas activas simultáneamente
	- Duración: 0.5-2 segundos (cortas y punchy)
	- Emission: Burst rápidos, no continuos
]]

local VFXConfig = {}

-------------------------------------------------------------------------
-- METEOR EFFECTS (Alta prioridad)
-------------------------------------------------------------------------

VFXConfig.MeteorTrail = {
	Duration = 1.5,
	Particles = {
		-- Fire trail principal
		{
			Type = "Trail",
			Lifetime = 0.8,
			MinLength = 0.1,
			Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 150, 0)),   -- Naranja
				ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 80, 0)),  -- Rojo
				ColorSequenceKeypoint.new(1, Color3.fromRGB(50, 20, 0))      -- Negro
			}),
			Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 0.3),
				NumberSequenceKeypoint.new(1, 1)
			}),
			WidthScale = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 1),
				NumberSequenceKeypoint.new(1, 0.3)
			})
		},
		-- Spark particles
		{
			Type = "ParticleEmitter",
			Rate = 50,
			Lifetime = NumberRange.new(0.3, 0.6),
			Speed = NumberRange.new(5, 15),
			SpreadAngle = Vector2.new(30, 30),
			Color = ColorSequence.new(Color3.fromRGB(255, 200, 100)),
			Size = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 0.3),
				NumberSequenceKeypoint.new(1, 0)
			}),
			Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 0),
				NumberSequenceKeypoint.new(1, 1)
			}),
			EmissionDirection = Enum.NormalId.Back,
			Acceleration = Vector3.new(0, -20, 0)
		},
		-- Smoke trail
		{
			Type = "ParticleEmitter",
			Rate = 30,
			Lifetime = NumberRange.new(1, 1.5),
			Speed = NumberRange.new(2, 5),
			SpreadAngle = Vector2.new(20, 20),
			Color = ColorSequence.new(Color3.fromRGB(80, 80, 80)),
			Size = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 0.5),
				NumberSequenceKeypoint.new(0.5, 1),
				NumberSequenceKeypoint.new(1, 1.5)
			}),
			Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 0.5),
				NumberSequenceKeypoint.new(1, 1)
			}),
			EmissionDirection = Enum.NormalId.Back
		}
	},
	Sound = {
		SoundId = "rbxassetid://7106659874", -- Whoosh
		Volume = 0.3,
		PlaybackSpeed = 1.2
	},
	Light = {
		Color = Color3.fromRGB(255, 120, 0),
		Brightness = 5,
		Range = 15
	}
}

VFXConfig.MeteorExplosion = {
	Duration = 2,
	Particles = {
		-- Shockwave ring
		{
			Type = "ParticleEmitter",
			EmitCount = 1,
			Lifetime = NumberRange.new(0.4, 0.4),
			Speed = NumberRange.new(0, 0),
			Size = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 0),
				NumberSequenceKeypoint.new(0.5, 15),
				NumberSequenceKeypoint.new(1, 20)
			}),
			Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 0.5),
				NumberSequenceKeypoint.new(1, 1)
			}),
			Color = ColorSequence.new(Color3.fromRGB(255, 100, 0)),
			Texture = "rbxasset://textures/particles/smoke_main.dds",
			LightEmission = 0.8
		},
		-- Explosion flash
		{
			Type = "ParticleEmitter",
			EmitCount = 20,
			Lifetime = NumberRange.new(0.3, 0.6),
			Speed = NumberRange.new(20, 40),
			SpreadAngle = Vector2.new(180, 180),
			Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 200, 100)),
				ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 100, 0)),
				ColorSequenceKeypoint.new(1, Color3.fromRGB(100, 30, 0))
			}),
			Size = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 1),
				NumberSequenceKeypoint.new(1, 0)
			}),
			Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 0),
				NumberSequenceKeypoint.new(1, 1)
			}),
			Acceleration = Vector3.new(0, -30, 0),
			LightEmission = 1
		},
		-- Smoke plume
		{
			Type = "ParticleEmitter",
			EmitCount = 15,
			Lifetime = NumberRange.new(1.5, 2),
			Speed = NumberRange.new(5, 15),
			SpreadAngle = Vector2.new(30, 30),
			Color = ColorSequence.new(Color3.fromRGB(60, 60, 60)),
			Size = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 0.5),
				NumberSequenceKeypoint.new(0.5, 2),
				NumberSequenceKeypoint.new(1, 3)
			}),
			Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 0.3),
				NumberSequenceKeypoint.new(1, 1)
			}),
			Texture = "rbxasset://textures/particles/smoke_main.dds",
			Acceleration = Vector3.new(0, 10, 0)
		},
		-- Ground debris
		{
			Type = "ParticleEmitter",
			EmitCount = 12,
			Lifetime = NumberRange.new(0.8, 1.2),
			Speed = NumberRange.new(15, 30),
			SpreadAngle = Vector2.new(60, 60),
			Color = ColorSequence.new(Color3.fromRGB(100, 80, 60)),
			Size = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 0.4),
				NumberSequenceKeypoint.new(1, 0.2)
			}),
			Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 0),
				NumberSequenceKeypoint.new(0.7, 0.5),
				NumberSequenceKeypoint.new(1, 1)
			}),
			Acceleration = Vector3.new(0, -50, 0),
			RotSpeed = NumberRange.new(-200, 200),
			Rotation = NumberRange.new(0, 360)
		}
	},
	Sound = {
		SoundId = "rbxassetid://9118617342", -- Impact (del Config original)
		Volume = 0.5,
		PlaybackSpeed = 1.0
	},
	Light = {
		Color = Color3.fromRGB(255, 100, 0),
		Brightness = 15,
		Range = 40
	}
}

-------------------------------------------------------------------------
-- UI/PURCHASE EFFECTS
-------------------------------------------------------------------------

VFXConfig.PurchaseSuccess = {
	Duration = 1,
	Particles = {
		-- Green sparkles
		{
			Type = "ParticleEmitter",
			EmitCount = 15,
			Lifetime = NumberRange.new(0.5, 0.8),
			Speed = NumberRange.new(5, 15),
			SpreadAngle = Vector2.new(180, 180),
			Color = ColorSequence.new(Color3.fromRGB(100, 255, 100)),
			Size = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 0.3),
				NumberSequenceKeypoint.new(0.5, 0.5),
				NumberSequenceKeypoint.new(1, 0)
			}),
			Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 0),
				NumberSequenceKeypoint.new(1, 1)
			}),
			LightEmission = 1,
			Acceleration = Vector3.new(0, 15, 0)
		},
		-- Coin particles
		{
			Type = "ParticleEmitter",
			EmitCount = 8,
			Lifetime = NumberRange.new(0.4, 0.7),
			Speed = NumberRange.new(3, 10),
			SpreadAngle = Vector2.new(90, 90),
			Color = ColorSequence.new(Color3.fromRGB(255, 215, 0)),
			Size = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 0.4),
				NumberSequenceKeypoint.new(1, 0.2)
			}),
			Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 0),
				NumberSequenceKeypoint.new(0.8, 0.5),
				NumberSequenceKeypoint.new(1, 1)
			}),
			LightEmission = 0.8
		}
	},
	Sound = {
		SoundId = "rbxassetid://4612383453", -- Ya usado en Shop_client
		Volume = 0.4,
		PlaybackSpeed = 1.0
	}
}

VFXConfig.DamageHit = {
	Duration = 0.8,
	Particles = {
		-- Red impact flash
		{
			Type = "ParticleEmitter",
			EmitCount = 10,
			Lifetime = NumberRange.new(0.2, 0.4),
			Speed = NumberRange.new(5, 10),
			SpreadAngle = Vector2.new(180, 180),
			Color = ColorSequence.new(Color3.fromRGB(255, 80, 80)),
			Size = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 0.5),
				NumberSequenceKeypoint.new(1, 0)
			}),
			Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 0),
				NumberSequenceKeypoint.new(1, 1)
			}),
			LightEmission = 0.8
		}
	},
	Sound = {
		SoundId = "rbxassetid://9114221327", -- Hit sound
		Volume = 0.3,
		PlaybackSpeed = 1.1
	},
	Light = {
		Color = Color3.fromRGB(255, 50, 50),
		Brightness = 8,
		Range = 20
	}
}

VFXConfig.IncomePopup = {
	Duration = 1.2,
	Particles = {
		-- Golden glow
		{
			Type = "ParticleEmitter",
			EmitCount = 12,
			Lifetime = NumberRange.new(0.6, 1),
			Speed = NumberRange.new(2, 8),
			SpreadAngle = Vector2.new(60, 60),
			Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 215, 0)),
				ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 255, 150))
			}),
			Size = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 0.2),
				NumberSequenceKeypoint.new(0.5, 0.4),
				NumberSequenceKeypoint.new(1, 0)
			}),
			Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 0.3),
				NumberSequenceKeypoint.new(1, 1)
			}),
			LightEmission = 1,
			Acceleration = Vector3.new(0, 10, 0)
		}
	}
}

-------------------------------------------------------------------------
-- CONSTRUCTION EFFECTS (Para futuro)
-------------------------------------------------------------------------

VFXConfig.ConstructionBuild = {
	Duration = 1.5,
	Particles = {
		{
			Type = "ParticleEmitter",
			EmitCount = 20,
			Lifetime = NumberRange.new(0.8, 1.2),
			Speed = NumberRange.new(3, 8),
			SpreadAngle = Vector2.new(180, 180),
			Color = ColorSequence.new(Color3.fromRGB(100, 200, 255)),
			Size = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 0.3),
				NumberSequenceKeypoint.new(1, 0)
			}),
			Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 0),
				NumberSequenceKeypoint.new(1, 1)
			}),
			LightEmission = 0.6,
			Acceleration = Vector3.new(0, 8, 0)
		}
	},
	Sound = {
		SoundId = "rbxassetid://9120386436", -- Build sound
		Volume = 0.35,
		PlaybackSpeed = 1.0
	}
}

-------------------------------------------------------------------------
-- METADATA
-------------------------------------------------------------------------

VFXConfig.AvailableEffects = {
	"MeteorTrail",
	"MeteorExplosion",
	"PurchaseSuccess",
	"DamageHit",
	"IncomePopup",
	"ConstructionBuild"
}

return VFXConfig