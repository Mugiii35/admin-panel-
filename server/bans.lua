-- ═══════════════════════════════════════════
--  ADMIN PANEL - SYSTÈME DE BANS (fichier JSON, aucune DB requise)
-- ═══════════════════════════════════════════

local BansFile = 'bans.json'
local Bans = {}

-- ───────────────────────────────────────────
-- Chargement / Sauvegarde
-- ───────────────────────────────────────────
local function LoadBans()
    local data = LoadResourceFile(GetCurrentResourceName(), BansFile)
    if data then
        Bans = json.decode(data) or {}
    else
        Bans = {}
    end
end

local function SaveBans()
    SaveResourceFile(GetCurrentResourceName(), BansFile, json.encode(Bans, { indent = true }), -1)
end

CreateThread(function()
    LoadBans()
end)

-- ───────────────────────────────────────────
-- API
-- ───────────────────────────────────────────
function CheckIfBanned(identifiers)
    for _, ban in ipairs(Bans) do
        for _, id in ipairs(identifiers) do
            if ban.identifier == id then
                return ban
            end
        end
    end
    return nil
end

function RemoveBan(banId)
    for i, ban in ipairs(Bans) do
        if ban.id == banId then
            table.remove(Bans, i)
            SaveBans()
            return true
        end
    end
    return false
end

local function AddBan(identifier, reason, admin, durationHours)
    local expires = 0
    if durationHours and durationHours > 0 then
        expires = os.time() + (durationHours * 3600)
    end

    local ban = {
        id = #Bans + 1 + math.random(1000, 9999),
        identifier = identifier,
        reason = reason,
        admin = admin,
        date = os.date('%d/%m/%Y %H:%M'),
        expires = expires
    }

    table.insert(Bans, ban)
    SaveBans()
    return ban
end

-- ───────────────────────────────────────────
-- Event : bannir un joueur depuis le panel
-- ───────────────────────────────────────────
RegisterNetEvent('admin_panel:action:ban', function(targetId, reason, durationHours)
    local src = source
    if not exports['admin_panel']:IsPlayerAdmin(src) then return end
    if not Config.Actions.ban then return end

    targetId = tonumber(targetId)
    local targetName = GetPlayerName(targetId)
    if not targetName then return end

    local identifiers = GetPlayerIdentifiers(targetId)
    -- On utilise la license comme identifiant principal si dispo
    local mainId = identifiers[1]
    for _, id in ipairs(identifiers) do
        if string.find(id, 'license:') then
            mainId = id
            break
        end
    end

    reason = reason ~= '' and reason or 'Aucune raison spécifiée'
    durationHours = tonumber(durationHours) or 0

    AddBan(mainId, reason, GetPlayerName(src), durationHours)

    DropPlayer(tostring(targetId), ('Tu as été banni de ce serveur.\nRaison : %s\nDurée : %s'):format(
        reason,
        durationHours == 0 and 'Permanent' or (durationHours .. ' heure(s)')
    ))
end)

-- ───────────────────────────────────────────
-- Commande console pour unban manuel (optionnel)
-- ───────────────────────────────────────────
RegisterCommand('unban', function(source, args)
    if source ~= 0 then return end -- console uniquement
    local banId = tonumber(args[1])
    if not banId then
        print('Usage: unban <id>')
        return
    end
    if RemoveBan(banId) then
        print(('Ban #%s supprimé.'):format(banId))
    else
        print('Ban introuvable.')
    end
end, true)

RegisterCommand('bans', function(source, args)
    if source ~= 0 then return end
    for _, ban in ipairs(Bans) do
        print(('#%s | %s | %s | Raison: %s | Par: %s'):format(ban.id, ban.identifier, ban.date, ban.reason, ban.admin))
    end
end, true)
