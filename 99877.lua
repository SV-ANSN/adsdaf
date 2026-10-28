local CFG = {
    Host     = "http://127.0.0.1:8787/api",
    Token    = "9372103bef5e63e4421dfbe6a74f0befa453ebab673a18a0f9f14c5eae0a807f",
    Interval = 2,
    Version  = "1.6",
    KickNotice = false,
    KickWait = 60,
}

local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local LocalPlayer = Players.LocalPlayer

local G = {}
G.Enabled = true
G.Cid = nil
G.Count = 0
G.LastErr = nil
G.Thread = nil

local function jenc(v)
    local ok, r = pcall(function() return HttpService:JSONEncode(v) end)
    return ok and r or "{}"
end

local function jdec(s)
    local ok, r = pcall(function() return HttpService:JSONDecode(s) end)
    if ok and type(r) == "table" then return r end
    return nil
end

local function fetchGameName()
    local ok, info = pcall(function()
        return game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId)
    end)
    if ok and type(info) == "table" and info.Name and tostring(info.Name) ~= "" then
        return tostring(info.Name)
    end

    local ok2, body = pcall(function()
        return game:HttpGet("https://games.roblox.com/v1/games?universeIds=" .. tostring(game.GameId))
    end)
    if ok2 and type(body) == "string" and #body > 10 then
        local d = jdec(body)
        if d and type(d.data) == "table" and d.data[1] and d.data[1].name then
            return tostring(d.data[1].name)
        end
    end
    return ""
end

local function makeCid()
    return "u" .. tostring(LocalPlayer.UserId)
end

local function pickRequest()
    if type(request) == "function" then
        return function(o)
            local ok, res = pcall(request, { Url = o.Url, Method = o.Method or "GET", Headers = o.Headers or {}, Body = o.Body })
            if not ok or type(res) ~= "table" then return false, tostring(res), 0 end
            return (res.StatusCode >= 200 and res.StatusCode < 300), res.Body or "", res.StatusCode or 0
        end
    end
    if type(syn) == "table" and type(syn.request) == "function" then
        return function(o)
            local ok, res = pcall(syn.request, { Url = o.Url, Method = o.Method or "GET", Headers = o.Headers or {}, Body = o.Body })
            if not ok or type(res) ~= "table" then return false, tostring(res), 0 end
            return (res.StatusCode >= 200 and res.StatusCode < 300), res.Body or "", res.StatusCode or 0
        end
    end
    if type(http_request) == "function" then
        return function(o)
            local ok, res = pcall(http_request, { Url = o.Url, Method = o.Method or "GET", Headers = o.Headers or {}, Body = o.Body })
            if not ok or type(res) ~= "table" then return false, tostring(res), 0 end
            return (res.StatusCode >= 200 and res.StatusCode < 300), res.Body or "", res.StatusCode or 0
        end
    end
    return function(o)
        if (o.Method or "GET") == "GET" then
            local ok, body = pcall(function() return game:HttpGet(o.Url, true) end)
            return ok, body or "", ok and 200 or 0
        end
        local ok, body = pcall(function() return game:HttpPost(o.Url, o.Body or "") end)
        return ok, body or "", ok and 200 or 0
    end
end

G.Req = pickRequest()

local function post(action, tbl)
    return G.Req({
        Url = CFG.Host .. "?action=" .. action,
        Method = "POST",
        Headers = { ["X-Token"] = CFG.Token, ["Content-Type"] = "application/json" },
        Body = jenc(tbl),
    })
end

local function get(action, query)
    return G.Req({
        Url = CFG.Host .. "?action=" .. action .. "&token=" .. CFG.Token .. (query or ""),
        Method = "GET",
        Headers = { ["X-Token"] = CFG.Token },
    })
end

local function showKickDialog(text)
    local gui = Instance.new("ScreenGui")
    gui.Name = "KickNotice"
    gui.IgnoreGuiInset = true
    gui.ResetOnSpawn = false
    gui.DisplayOrder = 2147483647
    pcall(function() gui.Parent = game:GetService("CoreGui") end)
    if not gui.Parent then
        local pg = LocalPlayer:FindFirstChildOfClass("PlayerGui")
        if pg then gui.Parent = pg end
    end

    local bg = Instance.new("Frame")
    bg.Size = UDim2.fromScale(1, 1)
    bg.BackgroundColor3 = Color3.fromRGB(26, 28, 30)
    bg.BorderSizePixel = 0
    bg.Parent = gui

    local title = Instance.new("TextLabel")
    title.AnchorPoint = Vector2.new(0.5, 0.5)
    title.Position = UDim2.fromScale(0.5, 0.40)
    title.Size = UDim2.new(0, 700, 0, 44)
    title.BackgroundTransparency = 1
    title.Text = "Disconnected"
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.Font = Enum.Font.GothamBlack
    title.TextSize = 30
    title.Parent = bg

    local body = Instance.new("TextLabel")
    body.AnchorPoint = Vector2.new(0.5, 0)
    body.Position = UDim2.fromScale(0.5, 0.455)
    body.Size = UDim2.new(0, 720, 0, 80)
    body.BackgroundTransparency = 1
    body.Text = tostring(text)
    body.TextColor3 = Color3.fromRGB(206, 210, 216)
    body.Font = Enum.Font.Gotham
    body.TextSize = 18
    body.TextWrapped = true
    body.Parent = bg

    local btn = Instance.new("TextButton")
    btn.AnchorPoint = Vector2.new(0.5, 0)
    btn.Position = UDim2.fromScale(0.5, 0.575)
    btn.Size = UDim2.fromOffset(170, 42)
    btn.BackgroundColor3 = Color3.fromRGB(48, 52, 56)
    btn.BorderSizePixel = 0
    btn.Text = "Leave"
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 17
    btn.AutoButtonColor = true
    btn.Parent = bg

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = btn

    local clicked = false
    btn.MouseButton1Click:Connect(function() clicked = true end)

    return function(timeout)
        local waited = 0
        local limit = tonumber(timeout) or 60
        while not clicked and (limit <= 0 or waited < limit) do
            task.wait(0.15)
            waited = waited + 0.15
        end
        pcall(function() gui:Destroy() end)
        return clicked
    end
end

local function doKick(reason)
    reason = tostring(reason or "你已被踢出")
    local me = LocalPlayer
    local TS = game:GetService("TeleportService")
    local log = {}

    if CFG.KickNotice then
        local ok, waitClick = pcall(showKickDialog, reason)
        if ok and type(waitClick) == "function" then
            waitClick(CFG.KickWait)
        end
        task.wait(0.15)
    end

    if not me then return false, "no player" end

    local ok = pcall(function() me:Kick(reason) end)
    log[#log + 1] = "Kick=" .. tostring(ok)

    task.wait(4)

    pcall(function()
        if me and me.Parent then
            TS:Teleport(game.PlaceId, me)
            log[#log + 1] = "Rejoin"
        end
    end)

    return true, table.concat(log, " | ")
end

local handlers = {}

handlers.kick_self = function(arg)
    local reason
    if type(arg) == "table" then reason = arg.reason
    elseif type(arg) == "string" then reason = arg end
    return doKick(reason)
end

handlers.ping = function(arg)
    return true, "pong " .. tostring(arg or "")
end

handlers.stop = function()
    task.spawn(function() G.Stop() end)
    return true, "stopping"
end

local function sendAck(item, ok, res)
    post("ack", {
        id = item.id or "",
        cid = G.Cid,
        cmd = item.cmd or "",
        ok = ok and true or false,
        result = tostring(res),
    })
end

local function runOne(item)
    if type(item) ~= "table" then return end
    local cmd = item.cmd
    if type(cmd) ~= "string" then return end
    if item.cid and item.cid ~= "" and item.cid ~= "*" and item.cid ~= G.Cid then return end

    local h = handlers[cmd]
    local ok, res
    if h then
        ok, res = pcall(h, item.arg)
    else
        ok, res = false, "unknown: " .. cmd
    end

    G.Count = G.Count + 1
    sendAck(item, ok, res)
end

function G.Register()
    local ok, body = post("register", {
        cid = G.Cid,
        name = LocalPlayer and LocalPlayer.Name or "?",
        displayName = LocalPlayer and tostring(LocalPlayer.DisplayName) or "",
        userId = LocalPlayer and tostring(LocalPlayer.UserId) or "0",
        jobId = tostring(game.JobId or ""),
        placeId = tostring(game.PlaceId or ""),
        gameId = tostring(game.GameId or ""),
        gameName = G.GameName or "",
        ver = CFG.Version,
    })
    if not ok then
        G.LastErr = "register failed"
        return
    end
    local d = jdec(body)
    if d and d.banned then
        G.LastErr = "banned"
    end
end

function G.PollOnce()
    local ok, body, code = get("get", "&cid=" .. G.Cid)
    if not ok then
        G.LastErr = "get failed (" .. tostring(code) .. ")"
        return 0
    end
    local data = jdec(body)
    if not data or type(data.items) ~= "table" then
        G.LastErr = "bad reply"
        return 0
    end
    local n = 0
    for _, it in ipairs(data.items) do
        task.spawn(function() pcall(runOne, it) end)
        n = n + 1
    end
    G.LastErr = nil
    return n
end

function G.Start()
    if G.Thread then return end
    G.Enabled = true
    pcall(G.Register)
    G.Thread = task.spawn(function()
        while G.Enabled do
            pcall(G.Register)
            pcall(G.PollOnce)
            task.wait(tonumber(CFG.Interval) or 2)
        end
        G.Thread = nil
    end)
end

function G.Stop()
    G.Enabled = false
    if G.Thread then
        pcall(function() task.cancel(G.Thread) end)
        G.Thread = nil
    end
    print("[GUARD] stopped")
end

function G.Status()
    return string.format("enabled=%s cid=%s count=%d interval=%s err=%s",
        tostring(G.Enabled), tostring(G.Cid), G.Count,
        tostring(CFG.Interval), tostring(G.LastErr or "none"))
end

G.Cid = makeCid()
G.GameName = fetchGameName()
getgenv().REMOTE_GUARD = G
_G.REMOTE_GUARD = G

local function sayBye()
    pcall(function()
        G.Req({
            Url = CFG.Host .. "?action=bye",
            Method = "POST",
            Headers = { ["X-Token"] = CFG.Token, ["Content-Type"] = "application/json" },
            Body = jenc({ cid = G.Cid }),
        })
    end)
end

pcall(function() game:BindToClose(sayBye) end)
pcall(function()
    Players.PlayerRemoving:Connect(function(pl)
        if pl == LocalPlayer then sayBye() end
    end)
end)

G.Start()
print("[GUARD] " .. G.Status())
