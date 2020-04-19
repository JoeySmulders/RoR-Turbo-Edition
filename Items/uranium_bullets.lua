-- uranium_bullets.lua
-- Rare tier item that makes hits deal extra damage based on enemies max hp

local item = Item("Uranium Bullets")

item.pickupText = "Deal 1% of enemy max hp per 100% damage dealt as extra damage"

item.sprite = Sprite.load("Items/sprites/uranium_bullets", 1, 12, 13)

item:setTier("rare")

--TODO: see if this should be preHit or onHit (onHit calculates damage with extra damage sources like crowbar and such)

-- Just before the enemy takes damage, check their HP and the bullet damage to calculate how much extra damage to deal
registercallback("preHit", function(bullet, hit)
    local player = bullet:getParent()
    if type(player) == "PlayerInstance" then
        local count = player:countItem(item)

        if count > 0 then
            local damageMultiplier = (bullet:get("damage") / player:get("damage"))
            local enemyHealth = hit:get("maxhp")

            local extraDamage = (damageMultiplier / (110 - math.clamp(count * 10, 10, 60))) * enemyHealth

            --log(bullet:get("damage"), "original damage")

            bullet:set("damage", bullet:get("damage") + extraDamage)
            bullet:set("damage_fake", bullet:get("damage_fake") + extraDamage)

            --log(enemyHealth, "enemy max health")
            --log(bullet:get("damage"), "final damage dealt")
            --log(extraDamage, "added damage")
        end
    end
end)

item:setLog{
    group = "rare",
    description = "Deal extra damage on each attack for 1% of enemy max hp per 100% damage dealt",
    story = "",
    destination = "",
    date = ""
}

