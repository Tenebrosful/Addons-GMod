SWEP.PrintName = "SWEP SCP-053"

SWEP.Author = "Tenebrosful"
SWEP.Instructions =
    "Posséder ce SWEP tuera tout joueur vous infligeant des dégâts tout en vous soignant 0,5s après.\nImmunise à la mort.\nClique Droit permet d'activer / désactiver son effet."
SWEP.Category = "SCP"

SWEP.Spawnable = true
SWEP.AdminOnly = false

SWEP.Primary.ClipSize = -1
SWEP.Primary.DefaultClip = -1
SWEP.Primary.Automatic = false
SWEP.Primary.Ammo = "none"

SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Automatic = false
SWEP.Secondary.Ammo = "none"
SWEP.Secondary.Cooldown = 2

SWEP.Slot = 1
SWEP.SlotPos = 1
SWEP.DrawCrosshair = true
SWEP.DrawAmmo = false
SWEP.weight = 0
SWEP.AutoSwitchTo = false
SWEP.AutoSwitchFrom = false

SWEP.ViewModelFlip = false
SWEP.ViewModelFOV = 60
SWEP.ViewModel = ""
SWEP.WorldModel = ""
SWEP.UseHands = true

SWEP.HoldType = "normal"

function SWEP:Initialize()
    self:SetHoldType(self.HoldType)
end

if SERVER then

    -- Liste des états des joueurs possédant le SWEP (Effet activé ou non)
    local swep_053_owners = {}

    local function isEffectEnabled(ply)
        local res = swep_053_owners[ply:SteamID64()];

        if res == nil then return false end

        return res
    end

    -- Permet d'ajouter et/ou activer l'effet du SWEP sur un joueur
    local function addOwner(ply)
        swep_053_owners[ply:SteamID64()] = true
    end

    -- Permet de désactiver l'effet du SWEP sur un joueur
    local function removeOwner(ply)
        swep_053_owners[ply:SteamID64()] = false
    end

    -- Permet de retirer un joueur de la liste (En cas de perte du SWEP)
    local function removeKeyOwner(ply)
        swep_053_owners[ply:SteamID64()] = nil
    end

    local function switchOwner(ply)
        if not isEffectEnabled(ply)
            then addOwner(ply)
            else removeOwner(ply)
        end

        return isEffectEnabled(ply)
    end

    -- Hook vérifiant pour chaque joueur qui prend des dégâts si elle est protégé par les effets du SWEP
    hook.Add("PlayerHurt", "SWEP_SCP_053", function(victim, attacker, healthRemaining, damageTaken)
        if not isEffectEnabled(victim) then return end -- Vérification que la victime est protégée par le SWEP
        if damageTaken <= 0 then return end

        ---[[ Gestion des dégâts pris
            if (healthRemaining < 1) then victim:SetHealth(1) end-- Immunise à la mort en cas de dégâts mortels

            local nbrDamage = math.ceil(damageTaken) -- Arrondi au supérieur des dégâts reçus afin d'éviter de mourrir des dégâts decimaux comme le feu

            timer.Simple(0.5, function() -- Décalage de la régénération de la vie de 0,5s afin de correspondre au "presque instantannement" de la fiche du SCP

                if IsValid(victim) then
                    victim:SetHealth(math.min(victim:Health() + nbrDamage, victim:GetMaxHealth()))
                end

            end)
        --]]

        ---[[ Gestion du slay potentiel de l'attaquant
            if (attacker:IsPlayer() and attacker:Alive() and attacker ~= victim and not attacker:HasGodMode()) then -- Ne tue pas l'attaquant s'il est la victime ou s'il est en God

                attacker:Kill()
                attacker:PrintMessage(3, "Vous êtes mort d'une crise cardique.")

            end
        --]]
    end)

    -- Retrait des joueurs déconnectés afin d'empêcher des valeurs nulles dans la liste
    hook.Add('PlayerDisconnected', "SWEP_SCP_053", function(ply)
        if not isEffectEnabled(ply) then return end

        removeKeyOwner(ply)
    end)

    function SWEP:SecondaryAttack() -- Permet d'activer ou désactiver l'effet du SWEP
        
        local newState = switchOwner(self:GetOwner())

        if(newState)
            then self:GetOwner():PrintMessage(3, "Effets de SCP-053 actifs")
            else self:GetOwner():PrintMessage(3, "Effets de SCP-053 inactifs")
        end

        self:SetNextSecondaryFire(CurTime() + self.Secondary.Cooldown)

    end

    function SWEP:Equip() -- Active le SWEP au ramassage

        addOwner(self:GetOwner())

    end

    function SWEP:OnRemove() -- Desactive le SWEP une fois supprime (Lacher l'arme au sol ne retire pas l'effet)
        if not self:GetOwner():IsValid() then return end

        removeKeyOwner(self:GetOwner())

    end

    ---[[ Commande console pour vérifier la liste des joueurs protégés (Server-side)
        concommand.Add("scp_053_list",
            
        function()
            for steamID64 in pairs(swep_053_owners) do
                local ply = player.GetBySteamID64(steamID64)
                print(steamID64, ply:Nick(), ply:GetName())
            end
        end,

        function(cmd, stringargs)
            print(cmd, stringargs)
        end,

        nil, 0)
    --]]

    ---[[ Gestion de la commande console scp_053_list demandée côté client
        util.AddNetworkString("Ask_SCP-053_SWEP_Owners")
        util.AddNetworkString("Answer_SCP-053_SWEP_Owners")
        net.Receive("Ask_SCP-053_SWEP_Owners", function(len, ply)
            if not ply:IsAdmin() then return end
            
            net.Start("Answer_SCP-053_SWEP_Owners")
                net.WriteUInt(table.Count(swep_053_owners), 7)

                for i, owner in ipairs(swep_053_owners) do
                    net.WriteEntity(owner) 
                end

            net.Broadcast()
            
        end)
    --]]
end

if CLIENT then

    function SWEP:SecondaryAttack() end

    ---[[ Commande console pour verifier la liste des joueurs protégés (Client-side)
        concommand.Add("scp_053_list",
            
        function()
            net.Start("Ask_SCP-053_SWEP_Owners")
            net.SendToServer()
        end,

        function(cmd, stringargs)
            print(cmd, stringargs)
        end,

        nil, 0)
    --]]

    -- Gestion de la réponse du serveur concernant la commande console scp_053_list
    net.Receive("Answer_SCP-053_SWEP_Owners", function()
        
        local nbrOwners = net.ReadUInt(7)
        local owners = {}

        for i=0, nbrOwners - 1 do table.insert(owners, net.ReadEntity()) end

        print(table.ToString(owners, "Joueurs affectés par le SWEP de SCP-053", true))

    end)

end

function SWEP:PrimaryAttack() end
function SWEP:OnDrop() end
function SWEP:Reload() end