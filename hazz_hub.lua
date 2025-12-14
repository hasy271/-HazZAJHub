-- Configuration (MUST MATCH the Python C&C Server from Step 1)
local C_AND_C_IP = "192.168.0.81" -- !!! Use the SAME IP address as in bot_scanner.lua !!!
local C_AND_C_PORT = 8080
local GET_TARGET_ENDPOINT = "http://" .. C_AND_C_IP .. ":" .. C_AND_C_PORT .. "/get_target"

-- --- STATE AND SERVICES ---
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local IsWorking = false
local BrainrotTarget = 0 
local PollingDelay = 5 -- Check every 5 seconds

-- Helper function to convert '22M' to 22000000
local function ParseTargetValue(text)
    -- ... (Same parsing logic as discussed before) ...
    text = text:gsub('%s+', '')
    local lastChar = text:sub(-1):upper()
    local numberPart = tonumber(text:sub(1, -2) .. (lastChar ~= 'M' and lastChar ~= 'K' and lastChar or ""))
    
    if not numberPart then return 0 end

    if lastChar == 'M' then
        return numberPart * 1000000
    elseif lastChar == 'K' then
        return numberPart * 1000
    end
    return numberPart or 0
end

local function TeleportToTarget(instanceId)
    -- !!! This uses the high-risk executor function to force join !!!
    warn("HAZZ HUB: Executing UNCONSTRAINED teleport to:", instanceId)
    -- e.g., executor_api:ForceTeleport(instanceId) 
    IsWorking = false -- Stop the loop
end

local function CheckForTarget()
    if not IsWorking then return end

    -- Send the current MIN_VALUE to the C&C server so the server knows the user's demand
    local query_url = GET_TARGET_ENDPOINT .. "?min_value=" .. BrainrotTarget 
    
    local success, response = pcall(function()
        return HttpService:GetAsync(query_url, true)
    end)

    if success and response then
        local targetID = nil
        local decoded, decodeError = pcall(HttpService.JSONDecode, HttpService, response)
        
        if decoded and decoded.target_server_id and decoded.target_server_id ~= "None" then
            targetID = decoded.target_server_id
        end
        
        if targetID and targetID ~= "" then
            TeleportToTarget(targetID)
        end
    else
        warn("HAZZ HUB: Failed to poll Master Control Base.")
    end
end

-- Main Polling Loop
RunService.Heartbeat:Connect(function()
    if IsWorking then
        task.spawn(CheckForTarget)
        task.wait(PollingDelay)
    end
end)

-- --- UI CREATION AND BUTTON LOGIC (The HazZ Hub Interface) ---
-- (NOTE: Omitted for brevity, but this is where the Orange Frame, HazZ Hub label, 
-- AutoJoiner/Stop buttons, and InputBox from the previous plan would be created.)

-- Button Actions:
local function ToggleAutoJoiner(isStarting)
    IsWorking = isStarting
    if isStarting then
        BrainrotTarget = ParseTargetValue(InputBox.Text) -- Read the value from the UI
        -- Update button text to "Working..." and color
        print("AutoJoiner Started. Min Gen Target:", BrainrotTarget)
    else
        -- Update button text to "AutoJoiner" and color
        print("AutoJoiner Stopped.")
    end
end

-- AutoJoinerButton.MouseButton1Click:Connect(function() ToggleAutoJoiner(true) end)
-- StopButton.MouseButton1Click:Connect(function() ToggleAutoJoiner(false) end)