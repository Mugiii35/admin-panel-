# 🛡️ Admin Panel — FiveM

Un panel d'administration complet, léger et **standalone** pour serveurs FiveM. Compatible ESX en option. Aucune base de données requise (les bans sont stockés dans un simple fichier JSON).

![version](https://img.shields.io/badge/version-1.0.0-e8a33d)
![standalone](https://img.shields.io/badge/standalone-oui-3fb950)
![esx](https://img.shields.io/badge/ESX-compatible-blue)

---

## ✨ Fonctionnalités

- 👥 **Liste des joueurs en temps réel** (ID, nom, ping) avec recherche
- 📍 Téléportation vers un joueur / faire venir un joueur
- ❤️ Heal / Revive / Kill
- 🧊 Freeze / Unfreeze
- 🕵️ Mode spectateur
- 🚗 Spawn de véhicules (liste rapide + modèle personnalisé)
- 💰 Give money (nécessite ESX)
- 📢 Annonces serveur (bannière à l'écran)
- 👢 Kick avec raison
- 🔨 Ban temporaire ou permanent (stocké en JSON, sans DB)
- 🧭 Noclip
- 📋 Logs Discord de toutes les actions (webhook configurable)
- 🔐 Système de permissions flexible : whitelist par identifiant, groupe ESX, ou ace permission

---

## 📦 Installation

1. Télécharge et dézippe le dossier `admin_panel` dans ton dossier `resources/`.
2. Ajoute dans ton `server.cfg` :

```cfg
ensure admin_panel
```

3. (Optionnel mais recommandé) Donne-toi la permission via ace, en ajoutant **avant** le `ensure` :

```cfg
add_ace group.admin admin.panel allow
add_principal identifier.license:TON_LICENSE group.admin
```

4. Lance ton serveur. C'est prêt !

---

## ⚙️ Configuration (`config.lua`)

| Option | Description |
|---|---|
| `Config.OpenKey` | Touche pour ouvrir le panel (défaut `F6`) |
| `Config.UseESX` | Passe à `true` si ton serveur tourne sous ESX |
| `Config.ESXAllowedGroups` | Groupes ESX autorisés à ouvrir le panel (si `UseESX = true`) |
| `Config.Admins` | Liste d'identifiants (license, steam...) autorisés manuellement |
| `Config.DiscordWebhook` | URL du webhook Discord pour les logs (laisser vide pour désactiver) |
| `Config.Actions` | Active/désactive chaque action individuellement |
| `Config.QuickVehicles` | Liste de véhicules proposés dans le panel |

### Donner l'accès à un admin

Tu as **3 méthodes au choix**, cumulables :

1. **Whitelist manuelle** — ajoute ton identifiant dans `Config.Admins` :
   ```lua
   Config.Admins = {
       'license:abcdef1234567890abcdef1234567890abcdef12',
   }
   ```
   Pour trouver ta license, tape `/license` en jeu (ou regarde dans la console au moment de ta connexion).

2. **Groupe ESX** — si `Config.UseESX = true`, n'importe quel joueur dans un groupe listé dans `Config.ESXAllowedGroups` aura accès automatiquement.

3. **Ace permission** — via `server.cfg`, comme montré dans l'installation ci-dessus.

---

## 🖱️ Utilisation

- **F6** (ou la touche configurée) pour ouvrir/fermer le panel.
- Clique sur un joueur dans l'onglet **Joueurs** pour ouvrir le menu d'actions (téléport, heal, kick, ban, etc.).
- L'onglet **Outils** regroupe le noclip, le spawn de véhicules et les annonces serveur.
- **Échap** ferme le panel à tout moment.

---

## 🗂️ Structure du projet

```
admin_panel/
├── fxmanifest.lua
├── config.lua
├── client/
│   └── main.lua        → logique client (NUI, noclip, actions locales)
├── server/
│   ├── main.lua         → permissions, actions, logs Discord
│   └── bans.lua         → système de ban en JSON (aucune DB requise)
└── html/
    ├── index.html
    ├── style.css
    └── script.js
```

---

## 🔨 Système de bans

Les bans sont stockés dans `bans.json`, généré automatiquement dans le dossier de la resource au premier ban. Pas besoin de MySQL/oxmysql.

Commandes console disponibles :

```
bans           → liste tous les bans actifs
unban <id>     → supprime un ban par son ID
```

---

## 💰 Give Money (ESX)

Cette fonctionnalité nécessite `Config.UseESX = true` et la resource `es_extended` démarrée **avant** `admin_panel` dans ton `server.cfg`. Si ESX n'est pas activé, le bouton renverra une erreur propre au lieu de crasher.

---

## 🧭 Noclip — Contrôles

| Touche | Action |
|---|---|
| Z / ↑ | Avancer |
| S / ↓ | Reculer |
| Q | Tourner à gauche |
| D | Tourner à droite |
| Espace | Monter |
| Ctrl | Descendre |

---

## 📋 Logs Discord

Renseigne `Config.DiscordWebhook` avec l'URL de ton webhook pour recevoir automatiquement un log de chaque action (heal, kick, ban, give money, annonce, spawn véhicule, tentative d'accès refusée...).

```lua
Config.DiscordWebhook = 'https://discord.com/api/webhooks/XXXXX/XXXXX'
```

---

## 🛠️ Personnalisation

- **Ajouter une action** : crée un event `admin_panel:action:tonAction` côté serveur (`server/main.lua`), ajoute le bouton correspondant dans `html/index.html`, et relie-le en JS (`html/script.js`) via `post('tonAction', {...})`.
- **Changer le thème visuel** : toutes les couleurs sont centralisées en variables CSS en haut de `html/style.css` (`:root { ... }`).

---

## ⚠️ Notes importantes

- Ce script est **standalone par défaut**. ESX n'est requis que pour le "Give Money".
- Pensez à retirer/adapter `Config.QuickVehicles` selon les véhicules autorisés sur votre serveur.
- Testez toujours vos permissions (`Config.Admins` / groupes ESX / ace) avant la mise en prod, pour éviter qu'un joueur lambda accède au panel.

---

## 👤 Crédits

Développé par **Soriano**.

---

## 📄 Licence

Libre d'utilisation et de modification pour vos serveurs FiveM, communautaires ou non. Un crédit est apprécié mais non obligatoire.
