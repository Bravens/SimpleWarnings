local netstrings = {"AdminMenu", "WarningAccepted", "sv_TargetWarningBegin", "TargetMenu", "SendMessage"}
local warnings = {}
local staff = {}

for k, v in pairs(netstrings) do
    util.AddNetworkString(v)
end

local function getplayerbyname(playername)
    for k, v in pairs(player.GetAll()) do
        if(string.lower(v:Nick()) == string.lower(playername)) then return v end
    end
end

local function isStaff(steamid) 
    for k, v in pairs(staff) do
        if(v == steamid) then return true end
    end
    return false 
end

local function getWarnings(steamid) 
    for k, v in pairs(warnings) do
        local _v = string.Explode("/", v)
        if(_v[1] == steamid) then
            local information = string.Explode("/", v)
            local steamid = information[1]
            local warnings = information[2]
            return tonumber(warnings)
        end
    end
end

net.Receive("WarningAccepted", function(len, ply) 
    local staffname = net.ReadString()
    local warnings = tonumber(net.ReadString())
    local staffply = getplayerbyname(staffname)
    if(IsValid(staffply) and staffply:IsPlayer()) then
        for k, v in pairs(player.GetAll()) do
            if(isStaff(v:SteamID64())) then
                net.Start("SendMessage")
                net.WriteString("[Warnings] " .. "User: " .. ply:Nick() .. " has acknowledged the warning from staff member: " .. staffply:Nick())
                net.Send(v)
                ply:Freeze(false)
                ply:GodDisable()
                if(warnings > 3) then
                    ply:Kill()
                    net.Start("sendMessage")
                    net.WriteString("You got killed because you had more than 3 warnings")
                    net.Send(ply)
                end
            end
        end
    end
end)

net.Receive("sv_TargetWarningBegin", function(len, ply) 
    local targetname = net.ReadString()
    local message = net.ReadString()
    local targetply = getplayerbyname(targetname)
    local newwarningnum
    if(IsValid(targetply) and targetply:IsPlayer()) then
        -- Search for the target player in warning list  
        local information = ""
        local warns = getWarnings(targetply:SteamID64())
        local arr
        if(warns == nil) then -- We create a new player in the warnings list
            table.insert(warnings, targetply:SteamID64() .. "/" .. "1")
            for k, v in pairs(warnings) do
                local searcharr = string.Explode("/", v)
                if(searcharr[1] == targetply:SteamID64()) then
                    information = warnings[k]
                    arr = string.Explode("/", information)
                end
            end

            net.Start("TargetMenu")
            net.WriteString(ply:Nick()) -- This is the staff member that is warning the player
            net.WriteString(arr[2])
            net.WriteString(message)
            net.Send(targetply)
            targetply:Freeze(true) -- So the player can't be moved in any way, which forces him to look at the warning
            targetply:GodEnable() -- So the player can't get killed while he is getting warned
        elseif(warns == 0) then
            table.insert(warnings, targetply:SteamID64() .. "/" .. "1")
            for k, v in pairs(warnings) do
                local searcharr = string.Explode("/", v)
                if(searcharr[1] == targetply:SteamID64()) then
                    information = warnings[k]
                    arr = string.Explode("/", information)
                end
            end

            net.Start("TargetMenu")
            net.WriteString(ply:Nick()) -- This is the staff member that is warning the player
            net.WriteString(arr[2])
            net.WriteString(message)
            net.Send(targetply)
            targetply:Freeze(true) -- So the player can't be moved in any way, which forces him to look at the warning
            targetply:GodEnable() -- So the player can't get killed while he is getting warned
        else
            for k, v in pairs(warnings) do
                information = warnings[k]
                arr = string.Explode("/", information)
                local _arr = string.Explode("/", v)
                if(_arr[1] == arr[1]) then
                    newwarningnum = tonumber(arr[2]) + 1
                    arr[2] = newwarningnum
                    warnings[k] = arr[1] .. "/" .. arr[2]
                end
            end

            net.Start("TargetMenu")
            net.WriteString(ply:Nick()) -- This is the staff member that is warning the player
            net.WriteString(newwarningnum)
            net.WriteString(message)
            net.Send(targetply)
            targetply:Freeze(true) -- So the player can't be moved in any way, which forces him to look at the warning
            targetply:GodEnable() -- So the player can't get killed while he is getting warned
        end
    end
end)

hook.Add("PlayerSay", "WarningSystemChat", function(ply, text, team)
    if(isStaff(ply:SteamID64())) then
        local text = string.Explode(" ", text)
        if(text[1] == "!warn") then
            if(text[2]) then
                table.remove(text, 1) -- Remove the command from the array
                local textinput = ""
                for k, v in pairs(text) do
                    textinput = textinput .. " " .. v
                end
                textinput = textinput:sub(2, #textinput)
                local targetplayer = getplayerbyname(textinput)
                if(IsValid(targetplayer) and targetplayer:IsPlayer()) then
                    net.Start("AdminMenu") -- Menu for the staff
                    net.WriteString(ply:Nick())
                    net.WriteString(targetplayer:Nick())
                    net.Send(ply)
                else
                    net.Start("sendMessage")
                    net.WriteString("Couldn't find user: " .. textinput)
                    net.Send(ply)
                end
            else
                net.Start("sendMessage")
                net.WriteString("You need to specify a user you want to warn!")
                net.Send(ply)
            end
        end
    end

    if(isStaff(ply:SteamID64())) then
        local text = string.Explode(" ", text)
        if(text[1] == "!resetwarn") then
            table.remove(text, 1) -- Remove the command from the array
            local textinput = ""
            for k, v in pairs(text) do
                textinput = textinput .. " " .. v
            end
            textinput = textinput:sub(2, #textinput)
            local targetplayer = getplayerbyname(textinput)
            if(IsValid(targetplayer) and targetplayer:IsPlayer()) then
                local information = ""
                for k, v in pairs(warnings) do
                    local searcharr = string.Explode("/", v)
                    if(searcharr[1] == targetplayer:SteamID64()) then
                        information = warnings[k]
                    end
                end
                local _arr = string.Explode("/", information)
                local newwarns = 0
                information = _arr[1] .. "/" .. newwarns
                for k, v in pairs(warnings) do
                    local _arr = string.Explode("/", v)
                    if(_arr[1] == targetplayer:SteamID64()) then
                        warnings[k] = information
                        net.Start("sendMessage")
                        net.WriteString("Succesfully set the warns to 0 for player: " .. targetplayer:Nick())
                        net.Send(ply)
                    end
                end
            end
        end
    end
end)
