--[[
    Apex Engine Key Generator
    PRIVATE - Never push this file to GitHub
    
    Usage: Run this in a Lua environment (not Roblox)
    Requires: lua-http or just paste the HttpService calls into a Roblox server script
]]

local GITHUB_USER  = "newdev27"
local GITHUB_REPO  = "ApexEngine"
local GITHUB_TOKEN = "YOUR_TOKEN_HERE"  -- paste your token here, never push this file
local KEYS_FILE    = "keys.json"
local SALT         = "AX_br27_$3cr3t_2k25"

-- Tier durations in seconds
local TIERS = {
    ["1min"]    = 60,
    ["1hr"]     = 3600,
    ["1day"]    = 86400,
    ["free"]    = 86400,       -- free = 1 day, instant revoke on expire
    ["weekly"]  = 604800,
    ["monthly"] = 2592000,
    ["yearly"]  = 31536000,
    ["lifetime"] = nil,        -- nil = never expires
}

-- Tier prefix codes baked into key
local TIER_CODES = {
    ["1min"]    = "MN",
    ["1hr"]     = "HR",
    ["1day"]    = "DY",
    ["free"]    = "FR",
    ["weekly"]  = "WK",
    ["monthly"] = "MO",
    ["yearly"]  = "YR",
    ["lifetime"] = "LT",
}

local CHARS = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789" -- no 0/O/1/I to avoid confusion

local function randomSegment(len)
    math.randomseed(os.time() + math.random(1, 99999))
    local s = ""
    for i = 1, len do
        local idx = math.random(1, #CHARS)
        s = s .. CHARS:sub(idx, idx)
    end
    return s
end

-- Checksum: simple hash of key body + salt, returns 2 chars
local function makeChecksum(body)
    local hash = 5381
    local str = body .. SALT
    for i = 1, #str do
        hash = ((hash * 33) + string.byte(str, i)) % 1048576
    end
    local c1 = CHARS:sub((hash % #CHARS) + 1, (hash % #CHARS) + 1)
    local c2 = CHARS:sub(((math.floor(hash / #CHARS)) % #CHARS) + 1, ((math.floor(hash / #CHARS)) % #CHARS) + 1)
    return c1 .. c2
end

local function generateKey(tier)
    assert(TIERS[tier] ~= nil or tier == "lifetime", "Invalid tier: " .. tostring(tier))
    local code = TIER_CODES[tier]
    local seg1 = code .. randomSegment(4)   -- e.g. WK3F2A
    local seg2 = randomSegment(6)           -- e.g. K9P2M1
    local body = "APEX-" .. seg1 .. "-" .. seg2
    local checksum = makeChecksum(body)
    return body .. "-" .. checksum
end

local function getExpiresAt(tier)
    local duration = TIERS[tier]
    if duration == nil then return nil end  -- lifetime
    return os.time() + duration
end

-- GitHub API: fetch current keys.json
local function fetchKeysJson()
    -- Returns content + sha (sha needed to update file)
    local url = "https://api.github.com/repos/" .. GITHUB_USER .. "/" .. GITHUB_REPO .. "/contents/" .. KEYS_FILE
    -- In Roblox server script use HttpService, here shown as pseudo:
    -- local res = HttpService:RequestAsync({ Url = url, Method = "GET", Headers = { Authorization = "token " .. GITHUB_TOKEN } })
    -- return HttpService:JSONDecode(res.Body)
    print("[Generator] Would fetch: " .. url)
    return nil, nil
end

-- GitHub API: push updated keys.json
local function pushKeysJson(content, sha)
    local url = "https://api.github.com/repos/" .. GITHUB_USER .. "/" .. GITHUB_REPO .. "/contents/" .. KEYS_FILE
    -- local encoded = base64(content)  -- GitHub API requires base64
    -- local body = HttpService:JSONEncode({
    --     message = "Add key",
    --     content = encoded,
    --     sha     = sha,
    -- })
    -- HttpService:RequestAsync({ Url = url, Method = "PUT", Headers = {
    --     Authorization = "token " .. GITHUB_TOKEN,
    --     ["Content-Type"] = "application/json",
    -- }, Body = body })
    print("[Generator] Would push to: " .. url)
end

--[[
    Main generator function
    tier   = "1min" | "1hr" | "1day" | "free" | "weekly" | "monthly" | "yearly" | "lifetime"
    note   = optional string e.g. "given to user X"
    amount = how many keys to generate (default 1)
]]
local function GenerateKeys(tier, note, amount)
    amount = amount or 1
    note   = note or ""
    local generated = {}

    for i = 1, amount do
        local key        = generateKey(tier)
        local created_at = os.time()
        local expires_at = getExpiresAt(tier)

        generated[key] = {
            hwid       = "",
            blocked    = false,
            tier       = tier,
            created_at = created_at,
            expires_at = expires_at,
            note       = note,
        }

        print(string.format("[ApexEngine] Generated [%s] key: %s | expires: %s",
            tier, key, expires_at and os.date("%Y-%m-%d %H:%M:%S", expires_at) or "Never"))
    end

    -- TODO: fetch current keys.json, merge, push back
    -- local data, sha = fetchKeysJson()
    -- for k, v in pairs(generated) do data.keys[k] = v end
    -- pushKeysJson(HttpService:JSONEncode(data), sha)

    return generated
end

-- Example usage:
-- GenerateKeys("free",     "lootlabs reward",  1)
-- GenerateKeys("1day",     "worink reward",    1)
-- GenerateKeys("weekly",   "paid user",        1)
-- GenerateKeys("lifetime", "VIP",              1)
-- GenerateKeys("1min",     "test key",         5)

return {
    GenerateKeys  = GenerateKeys,
    makeChecksum  = makeChecksum,
    TIERS         = TIERS,
    TIER_CODES    = TIER_CODES,
}
