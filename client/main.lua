-- ═══════════════════════════════════════════
--  ADMIN PANEL - CLIENT MAIN
-- ═══════════════════════════════════════════

local panelOpen = false
local noclipEnabled = false
local frozenPlayers = {}
local spectating = false
local spectateCam = nil

-- ───────────────────────────────────────────
-- Ouverture / fermeture du panel
-- ───────────────────────────────────────────
RegisterKeyMapping('adminpanel', 'Ouvrir le panel admin', 'keyboard', Config.OpenKey)

RegisterCommand('adminpanel', function()
    if not panelOpen then
        TriggerServerEvent('admin_panel:requestOpen')
    else
        ClosePanel()
    end
end, false)

RegisterNetEvent('admin_panel:openPanel', function(cfg)
    panelOpen = true
    SetNuiFocus(true, true)
    SendNUIMessage({
        action = 'open',
        config = cfg
    })
    TriggerServerEvent('admin_panel:getPlayers')
end)

function ClosePanel()
    panelOpen = false
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'close' })
end

RegisterNUICallback('close', function(_, cb)
    ClosePanel()
    cb('ok')
end)

RegisterNetEvent('admin_panel:receivePlayers', function(players)
    SendNUIMessage({
        action = 'updatePlayers',
        players = players
    })
end)

RegisterNUICallback('refreshPlayers', function(_, cb)
    TriggerServerEvent('admin_panel:getPlayers')
    cb('ok')
end)

-- ───────────────────────────────────────────
-- Notifications
-- ───────────────────────────────────────────
RegisterNetEvent('admin_panel:notify', function(message, type)
    SendNUIMessage({
        action = 'notify',
        message = message,
        type = type
    })
end)

-- ───────────────────────────────────────────
-- Callbacks NUI -> Server (actions)
-- ───────────────────────────────────────────
local function forwardAction(eventName)
    RegisterNUICallback(eventName, function(data, cb)
        TriggerServerEvent('admin_panel:action:' .. eventName, data.targetId, data.value, data.extra)
        cb('ok')
    end)
end

forwardAction('heal')
forwardAction('revive')
forwardAction('kill')
forwardAction('kick')
forwardAction('ban')
forwardAction('giveMoney')
forwardAction('announcement')
forwardAction('spawnVehicle')
forwardAction('teleportToPlayer')
forwardAction('bringPlayer')
forwardAction('spectate')

RegisterNUICallback('freeze', function(data, cb)
    TriggerServerEvent('admin_panel:action:freeze', data.targetId, data.value)
    cb('ok')
end)

RegisterNUICallback('noclip', function(data, cb)
    noclipEnabled = data.value
    cb('ok')
end)

-- ───────────────────────────────────────────
-- Actions exécutées côté client (reçues du serveur)
-- ───────────────────────────────────────────
RegisterNetEvent('admin_panel:client:heal', function(targetId)
    if GetPlayerServerId(PlayerId()) ~= targetId then return end
    local ped = PlayerPedId()
    SetEntityHealth(ped, GetEntityMaxHealth(ped))
    ClearPedBloodDamage(ped)
end)

RegisterNetEvent('admin_panel:client:revive', function(targetId)
    if GetPlayerServerId(PlayerId()) ~= targetId then return end
    local ped = PlayerPedId()
    NetworkResurrectLocalPlayer(GetEntityCoords(ped), GetEntityHeading(ped), true, false)
    SetEntityHealth(ped, GetEntityMaxHealth(ped))
end)

RegisterNetEvent('admin_panel:client:kill', function(targetId)
    if GetPlayerServerId(PlayerId()) ~= targetId then return end
    SetEntityHealth(PlayerPedId(), 0)
end)

RegisterNetEvent('admin_panel:client:freeze', function(targetId, state)
    if GetPlayerServerId(PlayerId()) ~= targetId then return end
    FreezeEntityPosition(PlayerPedId(), state)
end)

RegisterNetEvent('admin_panel:client:teleportToPlayer', function(targetId)
    local targetPed = GetPlayerPed(GetPlayerFromServerId(targetId))
    if not targetPed or targetPed == 0 then
        SendNUIMessage({ action = 'notify', message = 'Joueur introuvable ou hors zone.', type = 'error' })
        return
    end
    local coords = GetEntityCoords(targetPed)
    SetEntityCoords(PlayerPedId(), coords.x, coords.y, coords.z + 1.0, false, false, false, true)
end)

RegisterNetEvent('admin_panel:client:bringPlayer', function(targetId, adminServerId)
    if GetPlayerServerId(PlayerId()) ~= targetId then return end
    local adminPed = GetPlayerPed(GetPlayerFromServerId(adminServerId))
    if not adminPed or adminPed == 0 then return end
    local coords = GetEntityCoords(adminPed)
    SetEntityCoords(PlayerPedId(), coords.x, coords.y, coords.z + 1.0, false, false, false, true)
end)

RegisterNetEvent('admin_panel:client:spawnVehicle', function(model)
    local hash = GetHashKey(model)
    RequestModel(hash)
    local timeout = 0
    while not HasModelLoaded(hash) and timeout < 5000 do
        Citizen.Wait(50)
        timeout = timeout + 50
    end
    if not HasModelLoaded(hash) then
        SendNUIMessage({ action = 'notify', message = 'Modèle de véhicule invalide.', type = 'error' })
        return
    end

    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local forward = GetEntityForwardVector(ped)
    local spawnCoords = coords + forward * 3.0

    local veh = CreateVehicle(hash, spawnCoords.x, spawnCoords.y, spawnCoords.z, GetEntityHeading(ped), true, false)
    SetPedIntoVehicle(ped, veh, -1)
    SetVehicleNumberPlateText(veh, 'ADMIN')
    SetModelAsNoLongerNeeded(hash)
end)

RegisterNetEvent('admin_panel:client:announcement', function(message, adminName)
    SendNUIMessage({
        action = 'announcement',
        message = message,
        admin = adminName
    })
end)

-- ───────────────────────────────────────────
-- Spectate simple
-- ───────────────────────────────────────────
RegisterNetEvent('admin_panel:client:spectateStart', function(targetId)
    local targetPlayer = GetPlayerFromServerId(targetId)
    if targetPlayer == -1 then return end
    local targetPed = GetPlayerPed(targetPlayer)

    if spectating then
        NetworkSetInSpectatorMode(false, PlayerPedId())
        spectating = false
        SendNUIMessage({ action = 'notify', message = 'Spectate désactivé.', type = 'info' })
    else
        NetworkSetInSpectatorMode(true, targetPed)
        spectating = true
        SendNUIMessage({ action = 'notify', message = 'Spectate activé. Réutilise le bouton pour quitter.', type = 'info' })
    end
end)

-- ───────────────────────────────────────────
-- Noclip
-- ───────────────────────────────────────────
CreateThread(function()
    while true do
        Citizen.Wait(0)
        if noclipEnabled then
            local ped = PlayerPedId()
            SetEntityCollision(ped, false, false)
            FreezeEntityPosition(ped, true)

            local coords = GetEntityCoords(ped)
            local speed = 1.0
            local heading = GetGameplayCamRelativeHeading() + GetEntityHeading(ped)
            local pitch = GetGameplayCamRelativePitch()

            local x, y, z = coords.x, coords.y, coords.z

            if IsControlPressed(0, 32) then -- Z / avancer
                x = x + speed * math.sin(-heading * math.pi / 180.0) * math.cos(pitch * math.pi / 180.0)
                y = y + speed * math.cos(-heading * math.pi / 180.0) * math.cos(pitch * math.pi / 180.0)
                z = z + speed * math.sin(pitch * math.pi / 180.0)
            end
            if IsControlPressed(0, 33) then -- S / reculer
                x = x - speed * math.sin(-heading * math.pi / 180.0) * math.cos(pitch * math.pi / 180.0)
                y = y - speed * math.cos(-heading * math.pi / 180.0) * math.cos(pitch * math.pi / 180.0)
                z = z - speed * math.sin(pitch * math.pi / 180.0)
            end
            if IsControlPressed(0, 34) then -- Q / gauche
                SetEntityHeading(ped, GetEntityHeading(ped) + 2.0)
            end
            if IsControlPressed(0, 35) then -- D / droite
                SetEntityHeading(ped, GetEntityHeading(ped) - 2.0)
            end
            if IsControlPressed(0, 44) then -- Q monter (space alt)
                z = z + speed
            end
            if IsControlPressed(0, 36) then -- Ctrl descendre
                z = z - speed
            end

            SetEntityCoordsNoOffset(ped, x, y, z, true, true, true)
        else
            Citizen.Wait(500)
        end
    end
end)

-- ───────────────────────────────────────────
-- Fermeture avec ESC (sécurité)
-- ───────────────────────────────────────────
CreateThread(function()
    while true do
        Citizen.Wait(0)
        if panelOpen then
            DisableControlAction(0, 1, true)
            DisableControlAction(0, 2, true)
            if IsDisabledControlJustPressed(0, 322) then -- ESC
                ClosePanel()
            end
        else
            Citizen.Wait(400)
        end
    end
end)
