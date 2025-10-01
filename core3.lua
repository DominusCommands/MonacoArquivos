-----------------------------------------------------------------------------------------------------------------------------------------
-- VRP
-----------------------------------------------------------------------------------------------------------------------------------------
local Tunnel = module("vrp","lib/Tunnel")
local Proxy = module("vrp","lib/Proxy")
vRP = Proxy.getInterface("vRP")
-----------------------------------------------------------------------------------------------------------------------------------------
-- CONNECTION
-----------------------------------------------------------------------------------------------------------------------------------------
Creative = {}
Tunnel.bindInterface("player",Creative)
-----------------------------------------------------------------------------------------------------------------------------------------
-- VARIABLES
-----------------------------------------------------------------------------------------------------------------------------------------
local Trunked = false
local Trashed = false
local BoostFPS = false
local Residuals = false
local LastCameraView = 2
local DeathUpdate = false
local CruiseEnabled = false
local CruiseVehicle = false
----------------------------------------------------------------------------------------------------------------------------------------
-- RELATIONSHIP
----------------------------------------------------------------------------------------------------------------------------------------
AddRelationshipGroup("PLAYER")
AddRelationshipGroup("POLICIA")
-----------------------------------------------------------------------------------------------------------------------------------------
-- THREADROPE
-----------------------------------------------------------------------------------------------------------------------------------------
CreateThread(function()
	local ArmyHash = GetHashKey("ARMY")
	local PoliceHash = GetHashKey("COP")
	local PlayerHash = GetHashKey("POLICIA")
	local PrisonerHash = GetHashKey("PRISONER")

	SetRelationshipBetweenGroups(1,ArmyHash,PlayerHash)
	SetRelationshipBetweenGroups(1,PlayerHash,ArmyHash)

	SetRelationshipBetweenGroups(1,PoliceHash,PlayerHash)
	SetRelationshipBetweenGroups(1,PlayerHash,PoliceHash)

	SetRelationshipBetweenGroups(1,PrisonerHash,PlayerHash)
	SetRelationshipBetweenGroups(1,PlayerHash,PrisonerHash)

	while true do
		local TimeDistance = 999
		local Ped = PlayerPedId()
		if LocalPlayer.state.Carry or LocalPlayer.state.Handcuff or IsEntityPlayingAnim(Ped,"missfinale_c2mcs_1","fin_c2_mcs_1_camman",3) then
			for _,v in ipairs({ 18,21,22,23,24,25,55,75,76,102,140,142,143,179,203,243,257,263,311 }) do
				DisableControlAction(0,v,true)
			end

			DisablePlayerFiring(Ped,true)
			TimeDistance = 1
		end

		Wait(TimeDistance)
	end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- GETPLAYERVEHICLESEAT
-----------------------------------------------------------------------------------------------------------------------------------------
function GetPlayerVehicleSeat(Ped,Vehicle)
	if not IsPedInAnyVehicle(Ped) then
		return false
	end

	for Number = -1,GetVehicleModelNumberOfSeats(GetEntityModel(Vehicle)) - 1 do
		if GetPedInVehicleSeat(Vehicle,Number) == Ped then
			return Number
		end
	end

	return false
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- THREADSYSTEM
-----------------------------------------------------------------------------------------------------------------------------------------
CreateThread(function()
	while true do
		local TimeDistance = 999
		local Ped = PlayerPedId()
		if IsPedInAnyVehicle(Ped) then
			TimeDistance = 100

			SetPedConfigFlag(Ped,184,true)
			if GetIsTaskActive(Ped,165) then
				local Vehicle = GetVehiclePedIsIn(Ped)
				local Seating = GetPlayerVehicleSeat(Ped,Vehicle)

				SetPedIntoVehicle(Ped,Vehicle,Seating)
			end
		else
			if LocalPlayer.state.Handcuff and not LocalPlayer.state.Carry and GetEntityHealth(Ped) > 100 and not IsEntityPlayingAnim(Ped,"mp_arresting","idle",3) and LoadAnim("mp_arresting") then
				TaskPlayAnim(Ped,"mp_arresting","idle",8.0,8.0,-1,49,1,false,false,false)
			end

			if CruiseEnabled and CruiseVehicle then
				if DoesEntityExist(CruiseVehicle) then
					SetEntityMaxSpeed(CruiseVehicle,GetVehicleHandlingFloat(CruiseVehicle,"CHandlingData","fInitialDriveMaxFlatVel"))
				end

				CruiseEnabled,CruiseVehicle = false,false
			end
		end

		Wait(TimeDistance)
	end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- FPS
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterCommand("fps",function()
	BoostFPS = not BoostFPS

	if BoostFPS then
		SetTimecycleModifier("cinema")
		TriggerEvent("Notify","Otimização","Sistema ativado.","amarelo",5000)
	else
		ClearTimecycleModifier()
		TriggerEvent("Notify","Otimização","Sistema desativado.","amarelo",5000)
	end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- PLAYER:VEHICLEHOOD
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterNetEvent("player:VehicleHood")
AddEventHandler("player:VehicleHood",function(Network,Active)
	if not NetworkDoesNetworkIdExist(Network) then
		return false
	end

	local Vehicle = NetToEnt(Network)
	if not DoesEntityExist(Vehicle) then
		return false
	end

	if Active == "open" then
		SetVehicleDoorOpen(Vehicle,4,0,0)
	elseif Active == "close" then
		SetVehicleDoorShut(Vehicle,4,0)
	end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- PLAYER:VEHICLEDOORS
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterNetEvent("player:VehicleDoors")
AddEventHandler("player:VehicleDoors",function(Network,Active)
	if not NetworkDoesNetworkIdExist(Network) then
		return false
	end

	local Vehicle = NetToEnt(Network)
	if not DoesEntityExist(Vehicle) then
		return false
	end

	if Active == "open" then
		SetVehicleDoorOpen(Vehicle,5,0,0)
	elseif Active == "close" then
		SetVehicleDoorShut(Vehicle,5,0)
	end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- WINDOWS
-----------------------------------------------------------------------------------------------------------------------------------------
AddEventHandler("player:Windows",function()
	local Ped = PlayerPedId()
	if not IsPedInAnyVehicle(Ped) then
		return false
	end

	local Vehicle = GetVehiclePedIsUsing(Ped)
	local EntityState = Entity(Vehicle).state

	EntityState:set("Windows",not EntityState.Windows,true)
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- ADDSTATEBAGCHANGEHANDLER
-----------------------------------------------------------------------------------------------------------------------------------------
AddStateBagChangeHandler("Windows",nil,function(Name,Key,Value)
	local Network = parseInt(Name:gsub("entity:",""))
	if not NetworkDoesNetworkIdExist(Network) then
		return false
	end

	local Vehicle = NetToVeh(Network)
	if not DoesEntityExist(Vehicle) then
		return false
	end

	for Number = 0,3 do
		if Value then
			RollDownWindow(Vehicle,Number)
		else
			RollUpWindow(Vehicle,Number)
		end
	end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- DOORNUMBER
-----------------------------------------------------------------------------------------------------------------------------------------
local DoorNumber = {
	["1"] = 0,
	["2"] = 1,
	["3"] = 2,
	["4"] = 3,
	["5"] = 5,
	["6"] = 4
}
-----------------------------------------------------------------------------------------------------------------------------------------
-- SYNCDOORS
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterNetEvent("player:syncDoors")
AddEventHandler("player:syncDoors",function(Network,Active)
	if not NetworkDoesNetworkIdExist(Network) then
		return false
	end

	local Vehicle = NetToEnt(Network)
	if not DoesEntityExist(Vehicle) then
		return false
	end

	if GetVehicleDoorLockStatus(Vehicle) > 1 then
		return false
	end

	local Door = DoorNumber[Active]
	if not Door then
		return false
	end

	if GetVehicleDoorAngleRatio(Vehicle,Door) == 0 then
		SetVehicleDoorOpen(Vehicle,Door,false,false)
	else
		SetVehicleDoorShut(Vehicle,Door,false)
	end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- SEATPLAYER
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterNetEvent("player:seatPlayer")
AddEventHandler("player:seatPlayer",function(Index)
	local Ped = PlayerPedId()
	if not IsPedInAnyVehicle(Ped) then
		return false
	end

	local Seating = nil
	local Vehicle = GetVehiclePedIsUsing(Ped)

	if Index == "0" then
		Seating = -1
	elseif Index == "1" then
		Seating = 0
	else
		for Seat = 1,10 do
			if IsVehicleSeatFree(Vehicle,Seat) then
				Seating = Seat
				break
			end
		end
	end

	if Seating then
		if IsVehicleSeatFree(Vehicle,Seating) then
			SetPedIntoVehicle(Ped,Vehicle,Seating)
		else
			TriggerEvent("Notify","Atenção","Já tem alguém nesse banco.","amarelo",5000)
		end
	end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- RESIDUALS
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.Residuals()
	return Residuals
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- PLAYER:RESIDUALS
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterNetEvent("player:Residual")
AddEventHandler("player:Residual",function(Informations)
	if Informations then
		Residuals = Residuals or {}
		Residuals[Informations] = true
	else
		Residuals = false
	end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- REMOVEVEHICLE
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.RemoveVehicle()
	if LocalPlayer.state.Bennys then
		return false
	end

	local Ped = PlayerPedId()
	if IsPedInAnyVehicle(Ped) then
		TaskLeaveVehicle(Ped,GetVehiclePedIsUsing(Ped),0)
	end
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- PLACEVEHICLE
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.PlaceVehicle(Network)
	if LocalPlayer.state.Bennys or not NetworkDoesNetworkIdExist(Network) then
		return false
	end

	local Vehicle = NetToEnt(Network)
	if not DoesEntityExist(Vehicle) then
		return false
	end

	local Ped = PlayerPedId()
	for Seating = 9,0,-1 do
		if IsVehicleSeatFree(Vehicle,Seating) then
			SetPedIntoVehicle(Ped,Vehicle,Seating)
			vRP.Destroy()

			break
		end
	end
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- CRUISER
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterCommand("ControlCruiser",function(source,Message)
	local Ped = PlayerPedId()
	if not IsPedInAnyVehicle(Ped) then
		return false
	end

	local Vehicle = GetVehiclePedIsIn(Ped)
	if GetPedInVehicleSeat(Vehicle,-1) ~= Ped or IsEntityInAir(Vehicle) then
		return false
	end

	CruiseEnabled = not CruiseEnabled
	CruiseVehicle = CruiseEnabled and Vehicle or false

	if CruiseEnabled then
		SetEntityMaxSpeed(Vehicle,GetEntitySpeed(Vehicle))
		TriggerEvent("Notify","Sucesso","Controle de cruzeiro ativado.","verde",5000)
	else
		TriggerEvent("Notify","Sucesso","Controle de cruzeiro desativado.","verde",5000)
		SetEntityMaxSpeed(Vehicle,GetVehicleHandlingFloat(Vehicle,"CHandlingData","fInitialDriveMaxFlatVel"))
	end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- KEYMAPPING
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterKeyMapping("ControlCruiser","Ativar/Desativar controle de cruzeiro.","keyboard","F4")
-----------------------------------------------------------------------------------------------------------------------------------------
-- PLAYER:DEATHUPDATE
-----------------------------------------------------------------------------------------------------------------------------------------
AddEventHandler("player:DeathUpdate",function(Status)
	DeathUpdate = Status
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- GAMEEVENTTRIGGERED
-----------------------------------------------------------------------------------------------------------------------------------------
AddEventHandler("gameEventTriggered",function(Event,Message)
	local Victim,Attacker,Index = Message[1],Message[2],NetworkGetPlayerIndexFromPed(Message[2])
	if Event == "CEventNetworkEntityDamage" and not LocalPlayer.state.Arena and not DeathUpdate and Victim == PlayerPedId() and IsEntityAPed(Victim) and GetEntityHealth(Victim) <= 100 and NetworkIsPlayerConnected(Index) then
		TriggerServerEvent("player:Death",GetPlayerServerId(Index))
		DeathUpdate = false
	end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- PLAYER:ENTERTRUNK
-----------------------------------------------------------------------------------------------------------------------------------------
AddEventHandler("player:enterTrunk",function(Entity)
	local Ped = PlayerPedId()
	if not Trunked and GetEntityHealth(Ped) > 100 then
		AttachEntityToEntity(Ped,Entity[3],-1,0.0,-2.2,0.5,0.0,0.0,0.0,true,true,false,true,2,true)
		LocalPlayer.state:set("Commands",true,true)
		SetEntityVisible(Ped,false)
		Trunked = true

		while Trunked do
			local Ped = PlayerPedId()
			local Vehicle = GetEntityAttachedTo(Ped)
			if DoesEntityExist(Vehicle) then
				local TrunkButtons = { { "E", "Sair do Porta-malas" } }
				TriggerEvent("inventory:Buttons",TrunkButtons)

				DisablePlayerFiring(Ped,true)
				DisableControlAction(0,23,true)

				if IsEntityVisible(Ped) then
					SetEntityVisible(Ped,false)
				end

				if IsControlJustPressed(1,38) then
					TriggerEvent("player:checkTrunk")

					TriggerEvent("inventory:CloseButtons")
				end
			else
				TriggerEvent("player:checkTrunk")
			end

			if GetEntityHealth(Ped) <= 100 then
				TriggerEvent("player:checkTrunk")
			end

			Wait(1)
		end
	end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- PLAYER:CHECKTRUNK
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterNetEvent("player:checkTrunk")
AddEventHandler("player:checkTrunk",function()
	if Trunked then
		local Ped = PlayerPedId()
		local Coords = GetOffsetFromEntityInWorldCoords(Ped,0.0,-1.25,-0.25)

		SetEntityVisible(Ped,true)
		DetachEntity(Ped,false,false)
		LocalPlayer.state:set("Commands",false,true)
		SetEntityCoords(Ped,Coords,false,false,false,false)

		Trunked = false
	end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- PLAYER:ENTERTRASH
-----------------------------------------------------------------------------------------------------------------------------------------
AddEventHandler("player:enterTrash",function(Entity)
	if not Trashed then
		local Ped = PlayerPedId()
		LastCameraView = GetFollowPedCamViewMode()

		LocalPlayer.state:set("Commands",true,true)
		SetEntityCoords(Ped,Entity[4],false,false,false,false)
		FreezeEntityPosition(Ped,true)
		SetEntityVisible(Ped,false)

		Trashed = GetOffsetFromEntityInWorldCoords(Entity[1],0.0,-1.5,0.0)

		while Trashed do
			local Ped = PlayerPedId()

			if GetFollowPedCamViewMode() ~= 4 then
				SetFollowPedCamViewMode(4)
			end

			DisablePlayerFiring(Ped,true)
			DisableControlAction(0,23,true)

			TriggerServerEvent("player:Infect","infection")

			local TrashButtons = { { "E", "Sair da Lixeira" } }
			TriggerEvent("inventory:Buttons",TrashButtons)

			if IsControlJustPressed(1,38) or GetEntityHealth(Ped) <= 100 then
				TriggerEvent("player:checkTrash")

				TriggerEvent("inventory:CloseButtons")
			end

			Wait(1)
		end
	end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- PLAYER:CHECKTRASH
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterNetEvent("player:checkTrash")
AddEventHandler("player:checkTrash",function()
	if Trashed then
		local Ped = PlayerPedId()

		SetEntityVisible(Ped,true)
		FreezeEntityPosition(Ped,false)
		SetFollowPedCamViewMode(LastCameraView)
		LocalPlayer.state:set("Commands",false,true)
		SetEntityCoords(Ped,Trashed,false,false,false,false)

		Trashed = false
	end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- ADDSTATEBAGCHANGEHANDLER
-----------------------------------------------------------------------------------------------------------------------------------------
for _,v in pairs({ "LSPD","SAPR","BCSO" }) do
	AddStateBagChangeHandler(v,("player:%s"):format(LocalPlayer.state.Source),function(Name,Key,Value)
		if Value then
			local Ped = PlayerPedId()
			local ArmyHash = GetHashKey("ARMY")
			local PoliceHash = GetHashKey("COP")
			local PrisonerHash = GetHashKey("PRISONER")

			SetPedRelationshipGroupHash(Ped,ArmyHash)
			SetPedRelationshipGroupHash(Ped,PoliceHash)
			SetPedRelationshipGroupHash(Ped,PrisonerHash)
		end
	end)
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- ANCHOR
-----------------------------------------------------------------------------------------------------------------------------------------
AddEventHandler("player:Anchor",function(Vehicle)
	if CanAnchorBoatHere(Vehicle) then
		SetBoatAnchor(Vehicle,false)
		TriggerEvent("Notify","Sucesso","Embarcação desancorada.","verde",5000)
	else
		SetBoatAnchor(Vehicle,true)
		TriggerEvent("Notify","Sucesso","Embarcação ancorada.","verde",5000)
	end
end)