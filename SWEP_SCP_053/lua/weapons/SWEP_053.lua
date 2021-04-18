SWEP.PrintName = "SWEP SCP-053"

SWEP.Author = "Tenebrosful"
SWEP.Instructions =
    "Posséder ce SWEP tuera tout joueur vous infligeant des dégâts tout en vous soignant 0,5s après. Immunise à la mort. Clique Droit permet d'activer / désactiver son effet."
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
SWEP.UseHands = false

SWEP.HoldType = "normal"

function SWEP:Initialize()
    self:SetHoldType(self.HoldType)
end

if SERVER then

    -- Liste des joueurs proteges par le SWEP
    swep_053_owners = {}

    -- Permet d'ajouter un joueur a la liste des joueurs proteges par le SWEP
    function addOwner(ply)
        if table.HasValue(swep_053_owners, ply) then return end

        table.insert(swep_053_owners, ply)
    end

    -- Permet de retirer un joueur de la liste des joueurs proteges par le SWEP
    function removeOwner(ply)
        table.RemoveByValue(swep_053_owners, ply)
    end

    function switchOwner(ply)
        if not table.HasValue(swep_053_owners, ply) then
            table.insert(swep_053_owners, ply)
            ply:PrintMessage(3, "Effets de SCP-053 actifs")
        else
            table.RemoveByValue(swep_053_owners, ply)
            ply:PrintMessage(3, "Effets de SCP-053 inactifs")
        end
    end

    -- Hook verifiant pour chaque entite qui prend des degats si elle est protegee par les effets du SWEP
    hook.Add("PlayerHurt", "SWEP_SCP_053", function(victim, attacker, healthRemaining, damageTaken)
        if not table.HasValue(swep_053_owners, victim) then return end -- Verification que la victime est protegee par le SWEP
        if damageTaken <= 0 then return end

        ---[[ Gestion des degats pris
            if (healthRemaining < 1) then victim:SetHealth(1) end-- Immunite a la mort en cas de degats mortels

            local nbrDamage = math.ceil(damageTaken) -- Arrondi au superieur des degats recus afin d'eviter de mourrir des degats decimaux comme le feu

            timer.Simple(0.5, function() -- Decalage de la regeneration de la vie de 0,5s afin de correspondre au "presque instantannement" de la fiche du SCP

                if (victim:Health() + nbrDamage <= victim:GetMaxHealth()) then -- Ajustement du soin fournis pour ne pas depasser la valeur de vie maximum

                    victim:SetHealth(victim:Health() + nbrDamage)

                else

                    victim:SetHealth(victim:GetMaxHealth())

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

    -- Retrait des joueurs deconnectes afin d'empecher des valeurs nulles dans la liste
    hook.Add('PlayerDisconnected', "SWEP_SCP_053", function(ply)
        if not table.HasValue(swep_053_owners, ply) then return end
           
        removeOwner(ply)
    end)

    function SWEP:SecondaryAttack() -- Permet d'activer ou desactiver l'effet du SWEP
        
        local ply = self:GetOwner()
        switchOwner(ply)

    end

    function SWEP:Equip() -- Active le SWEP au ramassage

        addOwner(self:GetOwner())

    end

    function SWEP:OnRemove() -- Desactive le SWEP une fois supprime (Lacher l'arme au sol ne retire pas l'effet)
        
        removeOwner(self:GetOwner())

    end

    ---[[ Commande console pour verifier la liste des joueurs proteges (Server-side)
        concommand.Add("scp_053_list",
            
        function()
            print(table.ToString(swep_053_owners, "Joueurs affectés par le SWEP de SCP-053", true))
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

    ---[[ Commande console pour verifier la liste des joueurs proteges (Client-side)
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

    -- Gestion de la reponse du serveur concernant la commande console scp_053_list
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