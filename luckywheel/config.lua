Config = {}

Config.Cooldown = 1800000 -- Cooldown on wheel spin in milliseconds (default 30 minutes)

Config.Prizes = {
    -- High value cash prizes with lower weights (rarer)
    {name = "$50,000", money = 50000, weight = 1},
    {name = "$20,000", money = 20000, weight = 2},
    {name = "$15,000", money = 15000, weight = 3},
    
    -- Mid value cash prizes with moderate weights
    {name = "$10,000", money = 10000, weight = 6},
    {name = "$7,500", money = 7500, weight = 9},
    {name = "$5,000", money = 5000, weight = 12},
    
    -- Common cash prizes with higher weights
    {name = "$3,000", money = 3000, weight = 18},
    {name = "$2,000", money = 2000, weight = 24},
    {name = "$1,000", money = 1000, weight = 30},
    
    -- Special item prizes with varying quantities and weights. If these items do not exist in your database, add some other prizes and adjust max amount
    {name = "Bagged Cocaine", money = 0, item = "coke_pooch", minQuantity = 50, maxQuantity = 500, weight = 5},
    {name = "Amfetamine Pooch", money = 0, item = "amfe_pooch", minQuantity = 50, maxQuantity = 500, weight = 8},
    {name = "Marijuana", money = 0, item = "marijuana", minQuantity = 50, maxQuantity = 500, weight = 10},
    
    -- Mystery prize with a wide range for money value
    {name = "Mystery Cash Prize", money = 0, minMoney = 100000, maxMoney = 500000, weight = 1}
}