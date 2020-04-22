-- blood_economy.lua
-- Uncommon tier item that makes the player drop an item on death

local item = Item("Blood Economy")

item.pickupText = "Gain 10% of damage dealt or taken as gold"

item.sprite = Sprite.load("Items/sprites/Blood_economy", 1, 12, 13)

item:setTier("uncommon")

-- TODO: make it spawn items on dio trigger?

-- Create an item on death
registercallback("onPlayerDeath", function(player)
    local count = player:countItem(item)

    if count > 0 then
        local location = math.random(-25, 25)
        local n = 0
        local xx = player.x + location
        while n < 50 and Stage.collidesPoint(xx, player.y) do
            xx = math.approach(xx, player.x, 1)
            n = n + 1
        end
        

        -- Stacking the item increases the chance of gold and medium chests by 10%
        if math.chance((10 * count) - 9) then
            chest = Object.find("Chest5")
        elseif math.chance(9 + (10 * count)) then
            chest = Object.find("Chest2")
        else
            chest = Object.find("Chest1")
        end

        local ichest = chest:create(xx, player.y)
        ichest:set("cost", 0)
        misc.shakeScreen(5)

    end

end)


registercallback("preHit", function(bullet, hit)
    local player = bullet:getParent()
        if type(player) == "PlayerInstance" then
            createGold(player, bullet)
        else 
            if type(hit) == "PlayerInstance" then
               createGold(hit, bullet)
            end
        end
end)

-- TODO: maybe clamp it so the player can't generate way more gold than the enemy has HP when dealing high damage
function createGold (player, bullet)
    local count = player:countItem(item)

    if count > 0 then
        bullet:set("gold_on_hit", math.sqrt(bullet:get("damage") * count * 0.1)) -- gold_on_hit produces the number squared amount of coins
    end

end

item:setLog{
    group = "uncommon",
    description = "Gain 10% of damage dealt or taken as gold. Dying spawns an item chest",
    story = "",
    destination = "",
    date = ""
}

