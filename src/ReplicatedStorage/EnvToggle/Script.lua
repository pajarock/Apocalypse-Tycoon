local RS = game:GetService("ReplicatedStorage")
local ev = RS:FindFirstChild("EnvToggle") or Instance.new("BindableEvent",RS); ev.Name="EnvToggle"

ev.Event:Connect(function(mode)
	if mode=="clear" then
		atm.Density=0.1; atm.Haze=0.1
		cc.TintColor=Color3.fromRGB(255,255,255)
	elseif mode=="moody" then
		atm.Density=0.28; atm.Haze=0.22
		cc.TintColor=Color3.fromRGB(255,230,210)
	end
end)
