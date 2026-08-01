-- ═══════════════════════════════════════════
--  ADMIN PANEL - SERVER MAIN
-- ═══════════════════════════════════════════

local ESX = nil
if Config.UseESX then
    ESX = exports['es_extended']:getSharedObject()
end

-- ───────────────────────────────────────────
-- Vérification des permissions
-- ───────────────────────────────────────────
local function IsPlayerAdmin(src)
    if src == 0 then return true end -- console

    -- Check whitelist manuelle par identifiant
    for _, id in ipairs(GetPlayerIdentifiers(src)) do
        for _, adminId in ipairs(Config.Admins) do
            if id == adminId then
                return true
            end
        end
    end

    -- Check groupe ESX
    if Config.UseESX and ESX then
        local xPlayer = ESX.GetPlayerFromId(src)
        if xPlayer and Config.ESXAllowedGroups[xPlayer.getGroup()] then
            return true
        end
    end

    -- Check ace permission (fallback universel, ajoute add_ace dans server.cfg)
    if IsPlayerAceAllowed(src, 'admin.panel') then
        return true
    end

    return false
end

exports('IsPlayerAdmin', IsPlayerAdmin)

-- ───────────────────────────────────────────
-- Logs Discord
-- ───────────────────────────────────────────
local function SendDiscordLog(title, description, color)
    if Config.DiscordWebhook == '' then return end

    PerformHttpRequest(Config.DiscordWebhook, function() end, 'POST', json.encode({
        username = Config.DiscordWebhookName,
        avatar_url = Config.DiscordWebhookAvatar,
        embeds = {
            {
                title = title,
                description = description,
                color = color or 3447003,
                footer = { text = os.date('%d/%m/%Y %H:%M:%S') }
            }
        }
    }), { ['Content-Type'] = 'application/json' })
end

-- ───────────────────────────────────────────
-- Ouverture du panel
-- ───────────────────────────────────────────
RegisterNetEvent('admin_panel:requestOpen', function()
    local src = source
    if IsPlayerAdmin(src) then
        TriggerClientEvent('admin_panel:openPanel', src, Config)
    else
        TriggerClientEvent('admin_panel:notify', src, 'Tu n\'as pas la permission d\'utiliser ce panel.', 'error')
        SendDiscordLog('⛔ Tentative d\'accès refusée', ('%s (%s) a tenté d\'ouvrir le panel admin sans permission.'):format(GetPlayerName(src), src), 15158332)
    end
end)

-- ───────────────────────────────────────────
-- Récupération de la liste des joueurs
-- ───────────────────────────────────────────
RegisterNetEvent('admin_panel:getPlayers', function()
    local src = source
    if not IsPlayerAdmin(src) then return end

    local players = {}
    for _, playerId in ipairs(GetPlayers()) do
        local ped = GetPlayerPed(playerId)
        table.insert(players, {
            id = playerId,
            name = GetPlayerName(playerId),
            ping = GetPlayerPing(playerId),
            identifiers = GetPlayerIdentifiers(playerId)
        })
    end

    TriggerClientEvent('admin_panel:receivePlayers', src, players)
end)

-- ───────────────────────────────────────────
-- Actions génériques (protégées serveur-side)
-- ───────────────────────────────────────────
local function ActionGuard(src)
    if not IsPlayerAdmin(src) then
        TriggerClientEvent('admin_panel:notify', src, 'Action refusée : permissions insuffisantes.', 'error')
        return false
    end
    return true
end

RegisterNetEvent('admin_panel:action:heal', function(targetId)
    local src = source
    if not ActionGuard(src) or not Config.Actions.heal then return end
    TriggerClientEvent('admin_panel:client:heal', tonumber(targetId))
    SendDiscordLog('💚 Heal', ('%s a soigné %s'):format(GetPlayerName(src), GetPlayerName(targetId)), 3066993)
end)

RegisterNetEvent('admin_panel:action:revive', function(targetId)
    local src = source
    if not ActionGuard(src) or not Config.Actions.revive then return end
    TriggerClientEvent('admin_panel:client:revive', tonumber(targetId))
    SendDiscordLog('❤️‍🩹 Revive', ('%s a ressuscité %s'):format(GetPlayerName(src), GetPlayerName(targetId)), 3066993)
end)

RegisterNetEvent('admin_panel:action:kill', function(targetId)
    local src = source
    if not ActionGuard(src) or not Config.Actions.kill then return end
    TriggerClientEvent('admin_panel:client:kill', tonumber(targetId))
    SendDiscordLog('☠️ Kill', ('%s a tué %s'):format(GetPlayerName(src), GetPlayerName(targetId)), 15158332)
end)

RegisterNetEvent('admin_panel:action:freeze', function(targetId, state)
    local src = source
    if not ActionGuard(src) or not Config.Actions.freeze then return end
    TriggerClientEvent('admin_panel:client:freeze', tonumber(targetId), state)
    SendDiscordLog('🧊 Freeze', ('%s a %s %s'):format(GetPlayerName(src), state and 'freeze' or 'unfreeze', GetPlayerName(targetId)), 3447003)
end)

RegisterNetEvent('admin_panel:action:teleportToPlayer', function(targetId)
    local src = source
    if not ActionGuard(src) or not Config.Actions.teleportToPlayer then return end
    TriggerClientEvent('admin_panel:client:teleportToPlayer', src, tonumber(targetId))
end)

RegisterNetEvent('admin_panel:action:bringPlayer', function(targetId)
    local src = source
    if not ActionGuard(src) or not Config.Actions.bringPlayer then return end
    TriggerClientEvent('admin_panel:client:bringPlayer', tonumber(targetId), src)
end)

RegisterNetEvent('admin_panel:action:spectate', function(targetId)
    local src = source
    if not ActionGuard(src) or not Config.Actions.spectate then return end
    TriggerClientEvent('admin_panel:client:spectateStart', src, tonumber(targetId))
end)

RegisterNetEvent('admin_panel:action:spawnVehicle', function(targetId, model)
    local src = source
    if not ActionGuard(src) or not Config.Actions.spawnVehicle then return end
    local dest = targetId and tonumber(targetId) or src
    TriggerClientEvent('admin_panel:client:spawnVehicle', dest, model)
    SendDiscordLog('🚗 Spawn véhicule', ('%s a spawn un(e) %s pour %s'):format(GetPlayerName(src), model, GetPlayerName(dest)), 3447003)
end)

RegisterNetEvent('admin_panel:action:giveMoney', function(targetId, amount, moneyType)
    local src = source
    if not ActionGuard(src) or not Config.Actions.giveMoney then return end
    if not Config.UseESX or not ESX then
        TriggerClientEvent('admin_panel:notify', src, 'ESX désactivé dans la config, action impossible.', 'error')
        return
    end

    amount = tonumber(amount)
    if not amount or amount <= 0 then return end

    local xTarget = ESX.GetPlayerFromId(tonumber(targetId))
    if not xTarget then return end

    moneyType = moneyType or 'money'
    xTarget.addAccountMoney(moneyType, amount)

    TriggerClientEvent('admin_panel:notify', src, ('%s a reçu %s $%s'):format(GetPlayerName(targetId), amount, moneyType), 'success')
    SendDiscordLog('💰 Give Money', ('%s a donné %s$ (%s) à %s'):format(GetPlayerName(src), amount, moneyType, GetPlayerName(targetId)), 15844367)
end)

RegisterNetEvent('admin_panel:action:announcement', function(message)
    local src = source
    if not ActionGuard(src) or not Config.Actions.announcement then return end
    TriggerClientEvent('admin_panel:client:announcement', -1, message, GetPlayerName(src))
    SendDiscordLog('📢 Annonce', ('%s a envoyé : %s'):format(GetPlayerName(src), message), 15844367)
end)

RegisterNetEvent('admin_panel:action:kick', function(targetId, reason)
    local src = source
    if not ActionGuard(src) or not Config.Actions.kick then return end
    reason = reason ~= '' and reason or 'Aucune raison spécifiée'

    local targetName = GetPlayerName(targetId)
    DropPlayer(tostring(targetId), ('Tu as été expulsé par un admin.\nRaison : %s'):format(reason))

    SendDiscordLog('👢 Kick', ('%s a kick %s\nRaison : %s'):format(GetPlayerName(src), targetName, reason), 15158332)
end)

-- ───────────────────────────────────────────
-- Vérification au spawn : ban check
-- ───────────────────────────────────────────
AddEventHandler('playerConnecting', function(name, setKickReason, deferrals)
    local src = source
    deferrals.defer()

    Citizen.Wait(0)

    local identifiers = GetPlayerIdentifiers(src)
    local banEntry = CheckIfBanned(identifiers)

    if banEntry then
        if banEntry.expires ~= 0 and banEntry.expires < os.time() then
            RemoveBan(banEntry.id)
        else
            deferrals.done(('Tu es banni de ce serveur.\nRaison : %s\nExpire : %s'):format(
                banEntry.reason,
                banEntry.expires == 0 and 'Jamais (permanent)' or os.date('%d/%m/%Y %H:%M', banEntry.expires)
            ))
            return
        end
    end

    deferrals.done()
end)
