local upgrades = {
    {
        id = "hp",
        title = "+Max HP",
        desc = "Increase base HP for all future runs.",
        baseCost = 750,
        costMultiplier = 1.5,
        maxLevel = 10,
        increment = 25,
        effect = "maxHp"
    },
    {
        id = "dmg",
        title = "+Damage",
        desc = "Increase base damage for all weapons.",
        baseCost = 900,
        costMultiplier = 1.6,
        maxLevel = 10,
        increment = 0.2,
        effect = "damage"
    },
    {
        id = "spd",
        title = "+Move Speed",
        desc = "Move faster in all runs.",
        baseCost = 675,
        costMultiplier = 1.4,
        maxLevel = 8,
        increment = 20,
        effect = "speed"
    },
    {
        id = "rng",
        title = "+Pickup Range",
        desc = "Increase pickup radius for resources.",
        baseCost = 600,
        costMultiplier = 1.3,
        maxLevel = 6,
        increment = 15,
        effect = "pickupRange"
    },
    {
        id = "cdr",
        title = "Cooldown Reduction",
        desc = "Slightly reduce ability cooldowns.",
        baseCost = 1125,
        costMultiplier = 1.7,
        maxLevel = 5,
        increment = 0.05,
        effect = "cooldownReduction"
    },
    {
        id = "luck",
        title = "Luck",
        desc = "Increase odds of rarer drops and upgrades.",
        baseCost = 1500,
        costMultiplier = 2.0,
        maxLevel = 5,
        increment = 0.1,
        effect = "luck"
    },
    {
        id = "auto_fire",
        title = "Auto-Fire",
        desc = "Fire automatically without holding input.",
        baseCost = 1875,
        costMultiplier = 1.0,
        maxLevel = 1,
        increment = 1,
        effect = "autoFire"
    },
    {
        id = "auto_aim",
        title = "Auto-Aim",
        desc = "Aim shots at nearest enemy automatically.",
        baseCost = 2250,
        costMultiplier = 1.0,
        maxLevel = 1,
        increment = 1,
        effect = "autoAim"
    },
}
return upgrades
