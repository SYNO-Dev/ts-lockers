local ESX = exports['es_extended']:getSharedObject()


if Config.DrawText and not Config.Target then
Citizen.CreateThread(function()
    local sleep = 3000
    local inZone = false
    while true do
        local nearArea = false
        local coords = GetEntityCoords(PlayerPedId())
        for k, v in pairs(Config.LockerZone) do
            local dist = #(vec3(v.x,v.y,v.z)-coords)
            if dist < 5 then
                nearArea = true
                DisableControlAction(0, 47)
                if IsDisabledControlJustPressed(0, 47) then
                    ESX.TriggerServerCallback("ts-lockers:getLockers", function(data) 
                        TriggerServerEvent('ts-lockers:LoadStashes')
                        TriggerEvent("ts-lockers:OpenMenu", {locker = k, info = data})
                    end, k)
                    
                end
                DrawText3Ds(v.x,v.y,v.z+1.0, "Press ~r~[G]~s~ To Open ~y~Locker~s~")
            end
        end
        if nearArea and not inZone then
            inZone = true
            sleep = 0
        end
        if not nearArea and inZone then           
            sleep = 3000
        end
        Citizen.Wait(sleep)
    end
end)
end

if Config.Target and not Config.DrawText then
    Citizen.CreateThread(function()
        for k, v in pairs(Config.LockerZone) do
            RegisterNetEvent('ts-lockers:qtargetevent')
            AddEventHandler('ts-lockers:qtargetevent', function()
                ESX.TriggerServerCallback("ts-lockers:getLockers", function(data) 
                    TriggerServerEvent('ts-lockers:LoadStashes')
                    TriggerEvent("ts-lockers:OpenMenu", {locker = k, info = data})
                end, k)
            end)
            exports.qtarget:AddBoxZone(k.."Target",vec3(v.x,v.y,v.z) , 0.5, 0.5, {
                name=k.."Target",
                heading=11.0,
                debugPoly=false,
                minZ= -50.77834,
                maxZ=100.87834,
                }, 
              {
                options = {
                  {
                    event = 'ts-lockers:qtargetevent' ,
                    icon = "fas fa-sign-in-alt",
                    label = "Open Locker Menu" ,
                  },
                },
              distance = 2.5
            })
            exports["nihal_peds"]:NewPed(`cs_casey`, k, {
                coords = vector3(v.x,v.y,v.z),
                radius = 50.0,
                heading = v.w,
                useZ = true,
                debug = false
            }, {
                invincible = true,
                canMove = true,
                ignorePlayer = true
            })
        end
    end)
end


RegisterNetEvent("ts-lockers:OpenMenu", function(data)
	lib.registerContext({
        id = 'locker_menu',
        title = 'TS Lockers',
        options = {
            ['Create Locker'] = {
                description = 'Create A Locker',
                arrow = true,
                event = 'ts-lockers:CreateLocker',
                args = {
                    branch = data.locker
                }
            },
			['Open Locker'] = {
                description = 'Open Existing Locker',
                arrow = true,
                event = 'ts-lockers:LockerList',
                args = {
                    arg = data.info,
                    branch = data.locker
                }
            },
			['Open Your Locker'] = {
                description = 'Open Self Locker',
                arrow = true,
                event = 'ts-lockers:OpenSelfLocker',
                args = {
                    arg = data.info,
                    branch = data.locker
                }
            },
			['Delete Locker'] = {
                description = 'Delete Existing Locker',
                arrow = true,
                event = 'ts-lockers:LockerListDelete',
                args = {
                    arg = data.info,
                    branch = data.locker
                }
            },
			['Change Locker Password'] = {
                description = 'Change Existing Locker Password',
                arrow = true,
                event = 'ts-lockers:LockerChangePass',
                args = {
                    arg = data.info,
                    branch = data.locker
                }
            }
        }
	})
    lib.showContext('locker_menu')
end)

RegisterNetEvent('ts-lockers:LockerList', function(data)
	local optionTable = {}
    local arg = data.arg
	local idt = 2
    if arg then
    for k,v in pairs(arg) do
        idt = idt + 1
		optionTable["Locker ID: "..v.dbid] = {
			description = 'Owner: '..v.playername,
                arrow = true,
                event = 'ts-lockers:client:OpenLocker',
                args = {
                    data = v
                }
		}
    end
    end
	lib.registerContext({
        id = 'locker_list',
        title = data.branch..' Locker Menu',
		menu = "locker_menu",
        options = optionTable
	})
    lib.showContext('locker_list')
end)

RegisterNetEvent('ts-lockers:LockerChangePass', function(data)
	local Ply = ESX.GetPlayerData()
    local lockers = data.arg
    for k,v in pairs(lockers) do
        if Ply.identifier == v.owner then
            TriggerEvent('ts-lockers:client:ChangePassword', {data = v})
        end
    end
end)

RegisterNetEvent('ts-lockers:LockerListDelete', function(data)
	local Ply = ESX.GetPlayerData()
    local lockers = data.arg
    for k,v in pairs(lockers) do
        if Ply.identifier == v.owner then
            TriggerEvent('ts-lockers:client:DeleteLocker', {data = v,id = v.lockerid})
        end
    end
end)

RegisterNetEvent('ts-lockers:client:ChangePassword', function(info)
    local data = info.data
    local id = data.lockerid
	local input = lib.inputDialog('TS Lockers', {
    { type = "input", label = "Locker Password", password = true, icon = 'lock' }
})
	if input and input[1] then
		TriggerServerEvent('ts-lockers:server:ChangePass', id, input[1])
	end
end)

RegisterNetEvent('ts-lockers:client:DeleteLocker', function(info)
    local data = info.data
    local id = info.id
	lib.registerContext({
        id = 'delete_locker_confirmation',
        title = 'Delete Locker',
		menu = 'locker_menu',
        options = {
            ['Confirm'] = {
                description = 'Confirm Deletion of Your Locker',
                arrow = true,
                serverEvent = 'ts-lockers:server:DeleteLocker',
                args = {
                    lockerid = id
                }
            },
			['Cancel'] = {
                description = 'Cancel Deletion of Your Locker',
                arrow = true,
                menu = 'locker_menu'
            }
			
        }
    })
    lib.showContext('delete_locker_confirmation')
end)

RegisterNetEvent('ts-lockers:OpenSelfLocker', function(info)
    local Ply = ESX.GetPlayerData()
    local lockers = info.arg
    local branch = info.branch
    for k,v in pairs(lockers) do
        if Ply.identifier == v.owner then
            exports.ox_inventory:setStashTarget(v.lockerid, nil)
            ExecuteCommand('inv2')
            exports.ox_inventory:setStashTarget(nil)
        end
    end
end)

RegisterNetEvent('ts-lockers:client:OpenLocker', function(info)
    local data = info.data
	local input = lib.inputDialog('TS Lockers', {
    { type = "input", label = "Locker Password", password = true, icon = 'lock' }
})
	if input and input[1] then
		if tostring(input[1]) == tostring(data.password) then
                exports.ox_inventory:setStashTarget(data.lockerid, nil)
                ExecuteCommand('inv2')
                exports.ox_inventory:setStashTarget(nil)
            else
                ESX.ShowNotification("Wrong Password")
            end
	end
end)

RegisterNetEvent("ts-lockers:CreateLocker", function(data)
    local area = data.branch
	local input = lib.inputDialog('TS Lockers - Create Password', {
    { type = "input", label = "Locker Password", password = true, icon = 'lock' }
})
	if input and input[1] then
		TriggerServerEvent("ts-lockers:server:CreateLocker", input[1], area)
	end
end)

function DrawText3Ds(x, y, z, text)
    local onScreen, _x, _y = World3dToScreen2d(x, y, z)
    local px, py, pz = table.unpack(GetGameplayCamCoords())

    SetTextScale(0.32, 0.32)
    SetTextFont(4)
    SetTextProportional(1)
    SetTextColour(255, 255, 255, 255)
    SetTextEntry("STRING")
    SetTextCentre(1)
    AddTextComponentString(text)
    DrawText(_x, _y)
    local factor = (string.len(text)) / 500
    DrawRect(_x, _y + 0.0125, 0.015 + factor, 0.03, 0, 0, 0, 80)
end
