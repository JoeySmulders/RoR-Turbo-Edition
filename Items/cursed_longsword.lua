-- cursed_longsword.lua
-- Rare tier item that makes a sword follow you and launch itself at nearby enemies

local item = Item("Cursed Longsword")

item.pickupText = "Seek and destroy"

item.sprite = Sprite.load("Items/sprites/cursed_longsword", 1, 14, 15)

item:setTier("rare")

-- Longsword object
local objSword = Object.new("LongSword")
objSword.sprite = Sprite.load("LongSword", "Items/sprites/longsword", 1, 6, 12)
objSword.depth = 1
local rotationSpeed = -0.085
local movementSpeed = 3
local attackSpeed = 10

-- Sword creation and variables
objSword:addCallback("create", function(objSword)
	local objSwordAc = objSword:getAccessor()
	objSwordAc.life = 0
	objSwordAc.speed = 0
	objSwordAc.size = 1
	objSwordAc.damage = 1.5
    objSword.spriteSpeed = 0.25
    objSword.angle = 180
    objSword:getData().explosionTimer = 0
end)

registercallback("onStageEntry", function()
    for i, player in ipairs(misc.players) do
        local count = player:countItem(item) 
        if count > 0 then
            local sword = objSword:create(player.x, player.y - 100)
            sword:set("parent", player.id)
            sword:getData().target = player
            player:getData().sword = sword
        end
    end
end)

swordTarget = net.Packet("Sword Target Packet", function(player, netTarget)

    local target = netTarget:resolve()
    local sword = player:getData().sword

    -- Add a sword is valid too lmao
    if target and target:isValid() and sword and sword:isValid() then
        sword:getData().target = target
    elseif sword and sword:isValid() then
        sword:getData().target = player
    end

    if net.host then
        swordTarget:sendAsHost(net.EXCLUDE, player, netTarget)
    end
end)

-- If changing to player target from enemy, only then send a packet
function sendSwordTarget(objSword, player)
    if objSword:getData().target == player then

    else
        objSword:getData().target = player

        if not net.online or net.localPlayer == player then
            if net.host then
                swordTarget:sendAsHost(net.ALL, nil, player:getNetIdentity())
            else
                swordTarget:sendAsClient(player:getNetIdentity())
            end
        end

    end
end

-- Sword function called every step
objSword:addCallback("step", function(objSword)
	local objSwordAc = objSword:getAccessor()
    local player = Object.findInstance(objSwordAc.parent)

    if player then
        local count = player:countItem(item) 
        objSwordAc.damage = 0.5 + (count * 1)

        if objSword:getData().target:isValid() == false or objSword:getData().target == player then
            local enemy = enemies:findNearest(player.x, player.y)

            if enemy and enemy:get("team") ~= player:get("team") and player:get("dead") == 0 then
                local netTarget
                if distance(player.x, player.y, enemy.x, enemy.y) < 250 then
                    objSword:getData().target = enemy

                    if not net.online or net.localPlayer == player then
                        if net.host then
                            swordTarget:sendAsHost(net.ALL, nil, enemy:getNetIdentity())
                        else
                            swordTarget:sendAsClient(enemy:getNetIdentity())
                        end
                    end

                else
                    sendSwordTarget(objSword, player)
                end
            else
                sendSwordTarget(objSword, player)
            end
        end

        -- The target the sword tries to hit is the closest enemy to the player, or the player if there is no enemy
        if objSword:getData().target:isValid() then
            -- TODO: Make an idle state when following the player where it follows you similar to the sniper drone

            -- Stop following a tamed enemy
            if objSword:getData().target ~= player and objSword:getData().target:get("team") == player:get("team") then
                objSword:getData().target = player
            else
                --  Try to match rotation with the target
                if objSword:getData().target and objSword:getData().target:isValid() then

                    mathX = objSword:getData().target.x - objSword.x
                    mathY = objSword:getData().target.y	- objSword.y 

                    local goalAngle = -math.atan2(mathY, mathX)

                    goalAngle = math.deg(goalAngle)
                    goalAngle = goalAngle - 90 -- For some reason

                    local angleDiff = angleDif(objSword.angle, goalAngle) -- Neik approved migraine medicine

                    objSword.angle = objSword.angle + (angleDiff) * rotationSpeed

                    -- Move forward in the direction the sword is facing
                    local angle = math.rad(objSword.angle)
                    objSword.x = objSword.x + math.sin(angle) * -movementSpeed
                    objSword.y = objSword.y + math.cos(angle) * -movementSpeed

                    -- If colliding with an enemy, create explosions
                    if objSword:getData().explosionTimer <= 0 then

                        local closestEnemy = enemies:findNearest(objSword.x, objSword.y)
                        if closestEnemy and objSword:collidesWith(closestEnemy, objSword.x, objSword.y) and player:isValid() then
                            misc.fireExplosion(objSword.x, objSword.y, objSword.sprite.width / 19, objSword.sprite.height / 4, objSwordAc.damage * player:get("damage") , "player" ,nil, nil)
                        end
                        
                        objSword:getData().explosionTimer = attackSpeed
                    else
                        objSword:getData().explosionTimer = objSword:getData().explosionTimer - 1
                    end
                end
            end
        end
    else
        objSword:destroy()    
    end
end)

-- spawn the longsword on pickup
item:addCallback("pickup", function(player)
    local count = player:countItem(item) 
    if count == 1 then
        local sword = objSword:create(player.x, player.y - 100)
        sword:set("parent", player.id)
        sword:getData().target = player
        player:getData().sword = sword
    end
end)


item:setLog{
    group = "rare",
    description = "A longsword will follow the player, and launch it self at nearby enemies and deal 150% damage continuously",
    story = "",
    destination = "",
    date = ""
}

