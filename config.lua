Config = {}

-- ═══════════════════════════════════════════
--  CONFIGURATION GÉNÉRALE
-- ═══════════════════════════════════════════

-- Touche pour ouvrir/fermer le panel (par défaut F6)
Config.OpenKey = 'F6'

-- Utilises-tu ESX ? (true/false)
-- Si true, le script vérifiera le groupe ESX du joueur en plus des identifiants ci-dessous
Config.UseESX = false

-- Groupes ESX autorisés (si Config.UseESX = true)
Config.ESXAllowedGroups = {
    ['admin'] = true,
    ['superadmin'] = true
}

-- Identifiants autorisés à ouvrir le panel (license, steam, discord...)
-- Utilisé dans TOUS les cas, même sans ESX (whitelist manuelle)
-- Exemple : 'license:abcdef1234567890'
Config.Admins = {
    -- 'license:xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx',
}

-- Webhook Discord pour les logs d'actions admin (laisser vide '' pour désactiver)
Config.DiscordWebhook = ''
Config.DiscordWebhookName = 'Admin Panel'
Config.DiscordWebhookAvatar = 'https://i.imgur.com/6yYVczU.png'

-- ═══════════════════════════════════════════
--  ACTIONS DISPONIBLES (tu peux désactiver ce que tu ne veux pas)
-- ═══════════════════════════════════════════

Config.Actions = {
    teleportToPlayer = true,
    bringPlayer = true,
    heal = true,
    revive = true,
    kill = true,
    freeze = true,
    noclip = true,
    kick = true,
    ban = true,
    giveMoney = true, -- nécessite Config.UseESX = true
    spawnVehicle = true,
    announcement = true,
    spectate = true
}

-- Liste de véhicules rapides proposés dans le panel (spawn véhicule)
Config.QuickVehicles = {
    'adder', 'zentorno', 'police', 'ambulance', 'firetruk', 'sultan'
}

-- Durée par défaut d'un ban temporaire en heures (0 = permanent par défaut dans l'UI)
Config.DefaultBanDuration = 0
