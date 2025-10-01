-----------------------------------------------------------------------------------------------------------------------------------------
-- VARIABLES
-----------------------------------------------------------------------------------------------------------------------------------------
local Drops = {}
local Opened = false
local Cooldown = GetGameTimer()
-----------------------------------------------------------------------------------------------------------------------------------------
-- INVENTORY:OPEN
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterNetEvent("inventory:Open")
AddEventHandler("inventory:Open",function(Table,Ignore)
	local Pid = PlayerId()
	local Ped = PlayerPedId()
	if (not Opened or Table["Force"] or Ignore) and not IsPauseMenuActive() and GetEntityHealth(Ped) > 100 and not LocalPlayer["state"]["Buttons"] and not LocalPlayer["state"]["Commands"] and not LocalPlayer["state"]["Handcuff"] and not IsPlayerFreeAiming(Pid) then
		if not Opened and not Table["Force"] then
			SetCursorLocation(0.5,0.5)
		end

		Opened = true
		SetNuiFocus(true,true)
		TransitionToBlurred(1000)
		TriggerEvent("hud:Active",false)
		SendNUIMessage({ Action = "Open", Payload = Table })
	end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- INVENTORY:CLOSE
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterNetEvent("inventory:Close")
AddEventHandler("inventory:Close",function()
	if Opened then
		Opened = false
		SetNuiFocus(false,false)
		SetCursorLocation(0.5,0.5)
		TransitionFromBlurred(1000)
		TriggerEvent("hud:Active",true)
		SendNUIMessage({ Action = "Close" })
	end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- BACKINVENTORY
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterNUICallback("BackInventory",function(Data,Callback)
	TriggerEvent("inventory:Open",{
		Type = "Inventory",
		Resource = "inventory",
		Right = "Proximidade"
	},true)

	Callback("Ok")
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- INVENTORY:BUTTONS
-----------------------------------------------------------------------------------------------------------------------------------------
AddEventHandler("inventory:Buttons",function(Table)
	SendNUIMessage({ Action = "Buttons", Payload = Table })
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- INVENTORY:CLOSEBUTTONS
-----------------------------------------------------------------------------------------------------------------------------------------
AddEventHandler("inventory:CloseButtons",function()
	SendNUIMessage({ Action = "Close" })
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- INVENTORY:NOTIFY
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterNetEvent("inventory:Notify")
AddEventHandler("inventory:Notify",function(Title,Message,Type)
	if Opened then
		SendNUIMessage({ Action = "Notify", Payload = { Title,Message,Type } })
	end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- CLOSE
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterNUICallback("Close",function(Data,Callback)
	TriggerEvent("inventory:Close")

	Callback("Ok")
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- INVENTORY:USE
-----------------------------------------------------------------------------------------------------------------------------------------
AddEventHandler("inventory:Use",function(Slot,Amount)
	vSERVER.Use(Slot,Amount or 1)
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- USE
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterNUICallback("Use",function(Data,Callback)
	if GetGameTimer() >= Cooldown then
		vSERVER.Use(Data["slot"],Data["amount"])
		Cooldown = GetGameTimer() + 1000
	end

	Callback("Ok")
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- SEND
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterNUICallback("Send",function(Data,Callback)
	if MumbleIsConnected() then
		vSERVER.Send(Data["slot"],Data["amount"])
	end

	Callback("Ok")
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- STORE
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterNUICallback("Store",function(Data,Callback)
	if MumbleIsConnected() and not TakeWeapon and not StoreWeapon and not LocalPlayer["state"]["Arena"] then
		vSERVER.Drops(Data["item"],Data["slot"],Data["amount"])
	end

	Callback("Ok")
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- TAKE
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterNUICallback("Take",function(Data,Callback)
	if MumbleIsConnected() then
		vSERVER.Pickup(Data["id"],Data["route"],Data["target"],Data["amount"])
	end

	Callback("Ok")
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- UPDATE
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterNUICallback("Update",function(Data,Callback)
	if MumbleIsConnected() then
		vRPS.invUpdate(Data["slot"],Data["target"],Data["amount"])
	end

	Callback("Ok")
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- INVENTORY:UPDATE
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterNetEvent("inventory:Update")
AddEventHandler("inventory:Update",function()
	SendNUIMessage({ Action = "Backpack" })
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- INVENTORY
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterCommand("Inventory",function()
	TriggerEvent("inventory:Open",{
		Type = "Inventory",
		Resource = "inventory",
		Right = "Proximidade"
	})
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- KEYMAPPING
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterKeyMapping("Inventory","Abrir/Fechar a mochila.","keyboard","OEM_3")
-----------------------------------------------------------------------------------------------------------------------------------------
-- DROPS
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterNetEvent("inventory:Drops")
AddEventHandler("inventory:Drops",function(Table)
	Drops = Table
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- DROPSREMOVER
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterNetEvent("inventory:DropsRemover")
AddEventHandler("inventory:DropsRemover",function(Route,Number)
	if Drops[Route] and Drops[Route][Number] then
		Drops[Route][Number] = nil
	end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- DROPSATUALIZAR
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterNetEvent("inventory:DropsAtualizar")
AddEventHandler("inventory:DropsAtualizar",function(Route,Number,Amount)
	if Drops[Route] and Drops[Route][Number] then
		Drops[Route][Number]["amount"] = Amount
	end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- DROPSADICIONAR
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterNetEvent("inventory:DropsAdicionar")
AddEventHandler("inventory:DropsAdicionar",function(Route,Number,Table)
	if not Drops[Route] then
		Drops[Route] = {}
	end

	Drops[Route][Number] = Table

	local Ped = PlayerPedId()
	local Coords = GetEntityCoords(Ped)
	if Opened and Drops[Route][Number]["coords"] and #(Coords - Drops[Route][Number]["coords"]) <= DistanceDrops then
		SendNUIMessage({ Action = "Backpack" })
	end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- MOUNT
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterNUICallback("Mount",function(Data,Callback)
	local Primary,MaxWeight = vSERVER.Mount()
	if Primary then
		local Secondary = {}
		local Ped = PlayerPedId()
		local Coords = GetEntityCoords(Ped)
		local Route = LocalPlayer["state"]["Route"]

		if not IsPedInAnyVehicle(Ped) and Drops[Route] then
			for _,v in pairs(Drops[Route]) do
				if #(Coords - v["coords"]) <= 1.0 then
					Secondary[#Secondary + 1] = v
				end
			end
		end

		Callback({ Primary = Primary, Secondary = Secondary, PrimaryMaxWeight = MaxWeight })
	end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- BLUEPRINT
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterNUICallback("Blueprint",function(Data,Callback)
	local Primary,Secondary,MaxWeight = vSERVER.Blueprint()
	if Primary then
		TriggerEvent("inventory:Open",{
			Type = "Blueprint",
			Resource = "inventory",
			Force = true,
			Primary = Primary,
			PrimaryMaxWeight = MaxWeight,
			Secondary = Secondary,
			Right = "Aprendizado"
		})
	end

	Callback("Ok")
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- CRAFTING
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterNUICallback("Crafting",function(Data,Callback)
	if MumbleIsConnected() then
		vSERVER.Crafting(Data.item,Data.slot,Data.amount)
	end

	Callback("Ok")
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- MISSIONS
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterNUICallback("Missions",function(Data,Callback)
	Callback(vSERVER.Missions())
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- RESCUEMISSION
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterNUICallback("RescueMission",function(Data,Callback)
	Callback(vSERVER.RescueMission(Data.Index))
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- INVENTORY:NOTIFYITEM
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterNetEvent("inventory:NotifyItem")
AddEventHandler("inventory:NotifyItem",function(Data)
	if not Opened then
		SendNUIMessage({ Action = "NotifyItem", Payload = Data })
	end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- THREADDROPS
-----------------------------------------------------------------------------------------------------------------------------------------
CreateThread(function()
	while true do
		local TimeDistance = 999
		local Ped = PlayerPedId()
		local Route = LocalPlayer["state"]["Route"]
		if not IsPedInAnyVehicle(Ped) and Drops[Route] then
			local Coords = GetEntityCoords(Ped)

			for _,v in pairs(Drops[Route]) do
				if #(Coords - v["coords"]) <= DistanceDrops then
					SetDrawOrigin(v["coords"]["x"],v["coords"]["y"],v["coords"]["z"] - 0.75)
					DrawSprite("Textures","Drop",0.0,0.0,0.02,0.02 * GetAspectRatio(false),0.0,255,255,255,255)
					ClearDrawOrigin()

					TimeDistance = 1
				end
			end
		end

		Wait(TimeDistance)
	end
end)