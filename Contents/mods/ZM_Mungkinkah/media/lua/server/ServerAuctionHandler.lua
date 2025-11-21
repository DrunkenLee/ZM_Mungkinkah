--***********************************************************
--**               AUCTION HANDLER SERVER                 **
--**     Server-side auction HTTP request handling        **
--***********************************************************

if isClient() then return end -- Only run on server

local ServerAuctionHandler = {}

-- Configuration
local NODEJS_API_URL = "http://localhost:3000/player-auctions"
local TIMEOUT = 10 -- HTTP timeout in seconds
local AUCTION_LOG_FILE = "auction_data.jsonl" -- New Line Delimited JSON format for easier parsing
local AUCTION_WIN_DIR = "AuctionLog/" -- Directory for queued auction result files (JSON)

-- JSON parser for auction files (simple, already included in mod)
local AuctionJSONParser
pcall(function() AuctionJSONParser = require("AuctionJSONParser") end)

------------------------------------------------------------
-- SIMPLE HOURLY PROCESSOR FOR AUCTION RESULT FILE QUEUE  --
------------------------------------------------------------

-- Read whole file into a single string
local function readAllText(path)
    local reader = getFileReader(path, false)
    if not reader then return nil end
    local buf = {}
    while true do
        local line = reader:readLine()
        if not line then break end
        table.insert(buf, line)
    end
    reader:close()
    return table.concat(buf, "\n")
end

-- Create a processed copy and delete the original file
local function markProcessed(path)
    -- First, read the original file content
    local originalContent = readAllText(path)
    if not originalContent then
        print("[ServerAuctionHandler][DEBUG] Failed to read original file for backup: " .. path)
        return false
    end

    -- Create processed copy with .processed extension
    local processedPath = path .. ".processed"
    local writer = getFileWriter(processedPath, true, false)
    if not writer then
        print("[ServerAuctionHandler][DEBUG] Failed to create processed copy: " .. processedPath)
        return false
    end

    -- Write original content to processed copy
    writer:write(originalContent)
    writer:close()

    -- Now "delete" the original file by overwriting it with a deletion marker
    -- This effectively removes the original content and marks it as deleted
    local deleteWriter = getFileWriter(path, true, false) -- Overwrite the original file
    if deleteWriter then
        deleteWriter:write("DELETED - Original processed and moved to " .. processedPath .. " on " .. os.date("%Y-%m-%d %H:%M:%S") .. "\n")
        deleteWriter:close()
        print("[ServerAuctionHandler][DEBUG] ✓ Original file deleted: " .. path)
    else
        print("[ServerAuctionHandler][DEBUG] ✗ Failed to delete original file: " .. path)
    end

    -- Also create a .deleted marker for extra safety
    local deletedPath = path .. ".deleted"
    local markerWriter = getFileWriter(deletedPath, true, false)
    if markerWriter then
        markerWriter:write("DELETED - Original processed on " .. os.date("%Y-%m-%d %H:%M:%S") .. "\n")
        markerWriter:close()
    end

    print("[ServerAuctionHandler][DEBUG] ✓ File processed and deleted: " .. path .. " -> " .. processedPath)
    return true
end

local function writeAuctionDepositToFile(username, amount)
    local filePath = "AuctionDeposits/" .. username .. "_auctiondeposits.ini"

    local timeStamp = os.date("%Y-%m-%d %H:%M:%S")

    local fileWriter = getFileWriter(filePath, true, true)
    if fileWriter then
        fileWriter:write("[AuctionDeposit]\n")
        fileWriter:write("Time=" .. timeStamp .. "\n")
        fileWriter:write("Amount=" .. tostring(amount) .. "\n")
        fileWriter:close()
        return true
    end

    print("ERROR: Failed to write to auction deposit file: " .. filePath)
    return false
end

-- Extract numeric timestamp from filename pattern: <user>.auctionWin#12345.json
local function extractTs(name)
    local ts = tostring(name):match("#(%d+)%.json$")
    return tonumber(ts or 0) or 0
end

-- Try to list files in AUCTION_WIN_DIR (simple, straightforward)
local function listAuctionFiles()
    local function filterAndSort(list)
        local out = {}
        for i = 1, #list do
            local name = list[i]
            if type(name) == "string" then
                local isJSON = name:match("%.json$") ~= nil
                local containsProcessedInName = name:find("%.processed") ~= nil
                local containsDeletedInName = name:find("%.deleted") ~= nil
                if isJSON and not containsProcessedInName and not containsDeletedInName then
                    -- Check if file has been processed (either .processed copy exists OR original file contains DELETED marker)
                    local processed = getFileReader(AUCTION_WIN_DIR .. name .. ".processed", false)
                    if processed then
                        processed:close()
                        -- File has been processed, skip it
                    else
                        -- Check if original file contains deletion marker
                        local originalFile = getFileReader(AUCTION_WIN_DIR .. name, false)
                        if originalFile then
                            local firstLine = originalFile:readLine()
                            originalFile:close()

                            -- If first line contains DELETED, skip this file
                            if firstLine and firstLine:find("DELETED") then
                                -- File has been deleted/processed, skip it
                            else
                                -- File is valid and unprocessed
                                table.insert(out, name)
                            end
                        end
                    end
                end
            end
        end
        table.sort(out, function(a, b)
            local ta, tb = extractTs(a), extractTs(b)
            if ta ~= tb then return ta < tb end
            return tostring(a) < tostring(b)
        end)
        return out
    end

    -- Primary: directory listing
    if getFileList then
        local files = getFileList(AUCTION_WIN_DIR) or {}
        if #files > 0 then
            return filterAndSort(files)
        end
    end

    -- Enhanced Primary: Simple file existence check for ALL .json files (like fallback B but multiple files)
    local function simpleJsonFileCheck()
        local foundFiles = {}
        local seenFiles = {} -- Track files we've already found to prevent duplicates

        -- Try common naming patterns that external systems might use
        local commonPatterns = {}

        -- Generate auction patterns dynamically - check auction1.json through auction9999.json
        for i = 1, 9999 do
            table.insert(commonPatterns, "auction" .. tostring(i) .. ".json")
        end

        for i = 1, #commonPatterns do
            local fileName = commonPatterns[i]

            -- Skip if we've already found this file
            if not seenFiles[fileName] then
                local fullPath = AUCTION_WIN_DIR .. fileName
                local r = getFileReader(fullPath, false)
                if r then
                    -- Check if file contains deletion marker
                    local firstLine = r:readLine()
                    r:close()

                    if firstLine and firstLine:find("DELETED") then
                        -- Skip deleted files
                    else
                        -- Check if already processed
                        local processed = getFileReader(fullPath .. ".processed", false)
                        if processed then
                            processed:close()
                            -- Skip processed files
                        else
                            seenFiles[fileName] = true -- Mark as seen
                            table.insert(foundFiles, fileName)
                        end
                    end
                end
            end
        end

        if #foundFiles > 0 then
            return foundFiles
        end
        return nil
    end

    local simpleFiles = simpleJsonFileCheck()
    if simpleFiles then
        return filterAndSort(simpleFiles)
    end

    -- Fallback A: read from manifest-style text files created by the external writer
    local function readManifestList(path)
        local content = readAllText(path)
        if not content or content == "" then return nil end
        local list = {}
        for line in string.gmatch(content, "[^\r\n]+") do
            local name = tostring(line):gsub("^%s+", ""):gsub("%s+$", "")
            if name ~= "" then table.insert(list, name) end
        end
        return list
    end

    local manifests = { "queue.txt", "manifest.txt", "queue.list" }
    for i = 1, #manifests do
        local manifestPath = AUCTION_WIN_DIR .. manifests[i]
        local names = readManifestList(manifestPath)
        if names and #names > 0 then
            return filterAndSort(names)
        end
    end

    -- Fallback B: legacy single-file pointer (least capable)
    local nextName = "next.json"
    local fullNext = AUCTION_WIN_DIR .. nextName
    local r = getFileReader(fullNext, false)
    if r then
        r:close()
        local processed = getFileReader(fullNext .. ".processed", false)
        if processed then
            processed:close()
            return {}
        end
        return { nextName }
    end

    return {}
end

-- Find online player by exact username
local function findOnlinePlayerByUsername(username)
    if not username or username == "" then return nil end
    local players = getOnlinePlayers()
    if not players then return nil end
    for i = 0, players:size() - 1 do
        local p = players:get(i)
        if p and p:getUsername() == username then
            return p
        end
    end
    return nil
end

-- Safe wrapper to validate and call the local deposit handler
local function safeCallAuctionDeposit(targetUsername, soldPrice, playerObj)
    local module = "ServerAuctionPoints"
    local command = "deposit"

    -- Resolve the handler from the real global environment to avoid scope issues
    local handler = rawget(_G, "ZMMungkinkahonClientAuctionDepositRequest") or ZMMungkinkahonClientAuctionDepositRequest
    if type(handler) ~= "function" then
        return
    end

    local uname = tostring(targetUsername or "")
    local amount = tonumber(soldPrice) or 0
    if uname == "" or not playerObj or not amount or amount <= 0 then
        return
    end

    local args = { uname, amount }
    handler(module, command, playerObj, args)
end

-- Forward declaration so wrappers above can capture the local upvalue
-- Expose as global so wrappers and other modules can access at runtime
function ZMMungkinkahonClientAuctionDepositRequest(module, command, player, args)
    if module ~= "ServerAuctionPoints" or command ~= "deposit" then return end
    print("DEBUG: ZMMungkinkahonClientAuctionDepositRequest (AuctionPoints) called")

    local username = args[1]
    local amount = tonumber(args[2])
    local result = { success = false }

    if not username or not amount or amount <= 0 then
        result.message = "Invalid auction deposit request"
        sendServerCommand(player, "ServerAuctionPoints", "depositResult", result)
        return
    end

    if username ~= player:getUsername() then
        result.message = "You can only deposit your own auction points"
        sendServerCommand(player, "ServerAuctionPoints", "depositResult", result)
        return
    end

    if writeAuctionDepositToFile(username, amount) then
        result.success = true
        result.amount = amount
    else
        result.message = "Failed to write auction deposit to file"
    end

    sendServerCommand(player, "ServerAuctionPoints", "depositResult", result)
end
_G.ZMMungkinkahonClientAuctionDepositRequest = ZMMungkinkahonClientAuctionDepositRequest

-- Deliver one file (oldest) per hour
-- Process a single auction result file, return status flags
local function processAuctionFile(fileName)
    local fullPath = AUCTION_WIN_DIR .. fileName

    -- Read file
    local raw = readAllText(fullPath)
    if not raw or raw == "" then
        -- mark as processed to avoid infinite loop on bad file
        markProcessed(fullPath)
        return { processed = true, deferred = false }
    end

    -- Parse JSON
    local parsed
    if AuctionJSONParser and AuctionJSONParser.parseJSON then
        parsed = AuctionJSONParser.parseJSON(raw)
    end
    if not parsed then
        markProcessed(fullPath)
        return { processed = true, deferred = false }
    end

    -- Decide recipient and reason
    local status = parsed.auctionInfo and parsed.auctionInfo.status or "completed"
    local reason = (status == "expired" or status == "cancelled") and "expired" or "win"
    local targetUsername
    if reason == "win" then
        targetUsername = parsed.winnerInfo and (parsed.winnerInfo.buyerUsername or parsed.winnerInfo.buyerName)
    else
        targetUsername = parsed.sellerInfo and parsed.sellerInfo.sellerName
    end

    if not targetUsername or targetUsername == "" then
        markProcessed(fullPath)
        return { processed = true, deferred = false }
    end

    local playerObj = findOnlinePlayerByUsername(tostring(targetUsername))
    if not playerObj then
        -- Player offline; keep file for later (do not mark processed)
        return { processed = false, deferred = true }
    end

    -- Build payload
    local itemBlob = parsed.itemData or {}
    local itemData = itemBlob.itemData or {}
    local modData = itemBlob.modData or {}
    local itemType = parsed.auctionInfo and parsed.auctionInfo.itemType or itemData.itemType
    local ai = parsed.auctionInfo or {}
    local soldPrice = tonumber(ai.finalBid)
        or tonumber(ai.buyoutPrice)
        or tonumber(ai.lastbid)
        or tonumber(ai.buyoutprice)
        or tonumber(ai.currentBid)
        or tonumber(ai.startingPrice)
        or 0
    if not itemType then
        markProcessed(fullPath)
        return { processed = true, deferred = false }
    end

    local payload = {
        price = soldPrice,
        reason = reason,
        sourceFile = fileName,
        itemType = itemType,
        itemData = {
            condition = itemData.condition,
            customName = itemData.customName,
            category = itemData.category,
            weight = itemData.weight,
            enchantmentLevel = itemData.enchantmentLevel,
            enchantMinDamage = itemData.enchantMinDamage,
            enchantMaxDamage = itemData.enchantMaxDamage,
            originalMinDamage = itemData.originalMinDamage,
            originalMaxDamage = itemData.originalMaxDamage,
        },
        modData = modData,
    }

    -- Send only to that specific player
    sendServerCommand(playerObj, "PlayerAuction", "deliverItem", payload)
    -- Validate and call deposit handler with debug
    safeCallAuctionDeposit(targetUsername, soldPrice or 0, playerObj)

    -- Mark as processed
    markProcessed(fullPath)
    return { processed = true, deferred = false }
end

-- Process all available auction files this tick, respecting order and skipping offline winners
local function processAuctionResultQueue()
    local pending = listAuctionFiles()
    if not pending or #pending == 0 then
        return
    end

    local pass = 0
    while true do
        pass = pass + 1
        local nextRound = {}
        local progressed = 0
        for i = 1, #pending do
            local fileName = pending[i]
            local res = processAuctionFile(fileName)
            if res and res.processed then
                progressed = progressed + 1
            elseif res and res.deferred then
                table.insert(nextRound, fileName)
            else
                -- Unknown case, avoid infinite loop by marking as processed
                markProcessed(AUCTION_WIN_DIR .. fileName)
                progressed = progressed + 1
            end
        end

        if #nextRound == 0 then
            break
        end

        if progressed == 0 then
            break
        end

        -- Prepare for next pass: try deferred ones again (maybe others came online mid-pass)
        pending = nextRound
    end
end-- Enhanced JSON serialization helper with better nested table support
local function serializeToJSON(data)
    if not data then return "{}" end

    local function serialize(obj, depth)
        depth = depth or 0
        if depth > 5 then return '"[MAX_DEPTH]"' end -- Prevent infinite recursion

        if type(obj) == "string" then
            return '"' .. tostring(obj):gsub('"', '\\"'):gsub('\n', '\\n'):gsub('\r', '\\r'):gsub('\t', '\\t') .. '"'
        elseif type(obj) == "number" then
            return tostring(obj)
        elseif type(obj) == "boolean" then
            return obj and "true" or "false"
        elseif type(obj) == "nil" then
            return "null"
        elseif type(obj) == "table" then
            local parts = {}
            local isArray = true
            local count = 0

            -- Check if it's an array
            for k, v in pairs(obj) do
                count = count + 1
                if type(k) ~= "number" or k ~= count then
                    isArray = false
                    break
                end
            end

            if isArray and count > 0 then
                -- Array format
                for i = 1, count do
                    table.insert(parts, serialize(obj[i], depth + 1))
                end
                return "[" .. table.concat(parts, ",") .. "]"
            else
                -- Object format
                for key, value in pairs(obj) do
                    local keyStr = '"' .. tostring(key):gsub('"', '\\"') .. '"'
                    local valueStr = serialize(value, depth + 1)
                    table.insert(parts, keyStr .. ":" .. valueStr)
                end
                return "{" .. table.concat(parts, ",") .. "}"
            end
        else
            return '"' .. tostring(obj):gsub('"', '\\"') .. '"'
        end
    end

    return serialize(data)
end

-- Pretty-print table function for better debugging output
local function printTable(t, indent)
    indent = indent or 0
    if type(t) ~= "table" then
        print(string.rep("  ", indent) .. tostring(t))
        return
    end
    for k, v in pairs(t) do
        if type(v) == "table" then
            print(string.rep("  ", indent) .. tostring(k) .. ":")
            printTable(v, indent + 1)
        else
            print(string.rep("  ", indent) .. tostring(k) .. ": " .. tostring(v))
        end
    end
end

-- Get current timestamp in ISO format
local function getISOTimestamp()
    local time = os.time()
    return os.date("!%Y-%m-%dT%H:%M:%SZ", time)
end

-- Dedicated auction logging function with clean, simple format
local function writeAuctionLog(action, auctionData, additionalData)
    if not auctionData then return false end

    -- Create clean, simple log entry
    local logEntry = {
        timestamp = getISOTimestamp(),
        unixTime = os.time(),
        action = action or "CREATE_AUCTION",
        data = auctionData
    }

    -- Add additional data if provided
    if additionalData then
        logEntry.additional = additionalData
    end

    local jsonLine = serializeToJSON(logEntry)

    -- Write to dedicated log file (JSONL format - one JSON object per line)
    -- Use unique timestamped filename to prevent race conditions
    local timestamp = os.time()
    local uniqueLogFile = "auction_data_" .. timestamp .. "_" .. (action or "unknown") .. ".jsonl"

    local success = pcall(function()
        -- Try main log file first (with create flag)
        local writer = getFileWriter(AUCTION_LOG_FILE, true, true) -- append mode, create if missing
        if writer then
            writer:write(jsonLine .. "\n")
            writer:close()
            print("[ServerAuctionHandler] ✓ Auction logged to main file: " .. action)
            return true
        else
            -- Fallback: write to unique timestamped file to prevent conflicts
            print("[ServerAuctionHandler] Main log busy, using unique file: " .. uniqueLogFile)
            local fallbackWriter = getFileWriter(uniqueLogFile, true, true) -- append mode, create if missing
            if fallbackWriter then
                fallbackWriter:write(jsonLine .. "\n")
                fallbackWriter:close()
                print("[ServerAuctionHandler] ✓ Auction logged to fallback file: " .. action)
                return true
            else
                print("[ServerAuctionHandler] ✗ Failed to open both main and fallback log files")
                return false
            end
        end
    end)

    if not success then
        print("[ServerAuctionHandler] ✗ Error writing to auction log file")
        return false
    end

    return true
end

-- HTTP request function - now focused on logging
local function makeHTTPRequest(url, method, data, callback)
    method = method or "GET"

    print("[ServerAuctionHandler] Processing " .. method .. " request for: " .. url)

    if method == "POST" and data then
        -- Write to dedicated auction log file
        local logSuccess = writeAuctionLog("CREATE_AUCTION", data)

        if logSuccess then
            print("[ServerAuctionHandler] ✓ Auction data written to: " .. AUCTION_LOG_FILE)
        else
            print("[ServerAuctionHandler] ✗ Failed to write to auction log file")
        end

        -- Simulate successful response
        if callback then callback(true, "Logged successfully") end
        return true, "Logged successfully"
    else
        print("[ServerAuctionHandler] GET request would be made to: " .. url)

        -- Log GET request
        writeAuctionLog("GET_AUCTIONS", { url = url, method = method })

        if callback then callback(true, "GET request logged") end
        return true, "GET request logged"
    end
end

-- Create auction listing on Node.js API
function ServerAuctionHandler.createAuctionListing(player, auctionData)
    if not player or not auctionData then
        print("[ServerAuctionHandler] ERROR: Invalid player or auction data")
        return
    end

    print("[ServerAuctionHandler] Creating auction listing for player: " .. player:getUsername())

    -- Prepare data for API
    local enchantMinDamage = 0
    local enchantMaxDamage = 0
    local originalMinDamage = 0
    local originalMaxDamage = 0
    local hasDamageBoost = false
    -- print("--------------------------------------- AUCTION DATA ---------------------------------------")
    -- printTable(auctionData)

    -- Fix: Access modData from the correct path
    if auctionData.itemData and auctionData.itemData.modData then
        local modData = auctionData.itemData.modData

        if modData.savedDamageValues then
            enchantMinDamage = tonumber(modData.savedDamageValues.minDamage) or 0
            enchantMaxDamage = tonumber(modData.savedDamageValues.maxDamage) or 0
        end

        -- Check for original damage values (might be in origMinDamage/origMaxDamage)
        if modData.origMinDamage and modData.origMaxDamage then
            originalMinDamage = tonumber(modData.origMinDamage) or 0
            originalMaxDamage = tonumber(modData.origMaxDamage) or 0
        end

        if modData.hasDamageBoost then
            hasDamageBoost = modData.hasDamageBoost
        end
    end

    local apiData = {
        sellerUsername = auctionData.sellerUsername,
        sellerSteamID = auctionData.sellerSteamID,
        itemType = auctionData.itemData and auctionData.itemData.itemType or nil,
        itemName = auctionData.itemData and auctionData.itemData.itemName or nil,
        itemID = auctionData.itemData and auctionData.itemData.itemID or nil,
        condition = auctionData.itemData and auctionData.itemData.condition or nil,
        weight = auctionData.itemData and auctionData.itemData.weight or nil,
        category = auctionData.itemData and auctionData.itemData.category or nil,
        customName = auctionData.itemData and auctionData.itemData.customName or nil,
        tooltip = auctionData.itemData and auctionData.itemData.tooltip or nil,
        startingPrice = auctionData.startingPrice,
        buyoutPrice = auctionData.buyoutPrice,
        currentBid = auctionData.currentBid,
        duration = auctionData.duration,
        timestamp = auctionData.timestamp,
        description = auctionData.description or nil,
        isActive = auctionData.isActive,
        serverName = getServerName() or "Unknown Server",
    }

    -- Add all modData if it exists
    if auctionData.itemData and auctionData.itemData.modData then
        local modData = auctionData.itemData.modData
        apiData.modData = {}

        -- Copy all modData fields with null handling
        for key, value in pairs(modData) do
            if type(value) == "table" then
                -- Handle nested tables (like savedDamageValues, enchantmentStats)
                apiData.modData[key] = {}
                for subKey, subValue in pairs(value) do
                    apiData.modData[key][subKey] = subValue
                end
            else
                apiData.modData[key] = value
            end
        end

        -- Also add specific weapon stats at root level for easier API access
        if apiData.category == "Weapon" or string.find(tostring(apiData.itemType or ""), "Weapon") then
            apiData.enchantMinDamage = enchantMinDamage
            apiData.enchantMaxDamage = enchantMaxDamage
            apiData.originalMinDamage = originalMinDamage
            apiData.originalMaxDamage = originalMaxDamage
            apiData.hasDamageBoost = hasDamageBoost

            -- Add enchantment level if available
            if modData.enchantmentStats and modData.enchantmentStats.enchantCounter then
                apiData.enchantmentLevel = tonumber(modData.enchantmentStats.enchantCounter) or 0
            end
        end
    end
    -- print("--------------------------------------- API DATA ---------------------------------------")
    -- printTable(apiData)
    -- Make HTTP request to create auction
    makeHTTPRequest(NODEJS_API_URL, "POST", apiData, function(success, response)
        if success then
            print("[ServerAuctionHandler] Auction created successfully")

            -- Send success response back to client
            sendServerCommand(player, "PlayerAuction", "listingResult", {
                success = true,
                auctionID = "generated_by_api", -- You'd parse this from the API response
                message = "Auction listing created successfully",
                removeItemID = auctionData.itemData.itemID
            })

            -- Log the auction creation
            print("[ServerAuctionHandler] AUCTION CREATED - Player: " .. auctionData.sellerUsername ..
                  ", Item: " .. auctionData.itemData.itemName ..
                  ", Starting Price: " .. auctionData.startingPrice)
        else
            print("[ServerAuctionHandler] Failed to create auction: " .. tostring(response))

            -- Send failure response back to client
            sendServerCommand(player, "PlayerAuction", "listingResult", {
                success = false,
                message = "Failed to create auction: " .. tostring(response)
            })
        end
    end)
end

-- Get active auctions from API
function ServerAuctionHandler.getActiveAuctions(player, filters)
    local url = NODEJS_API_URL

    -- Add query parameters if filters provided
    if filters then
        local queryParams = {}
        for key, value in pairs(filters) do
            table.insert(queryParams, key .. "=" .. tostring(value))
        end
        if #queryParams > 0 then
            url = url .. "?" .. table.concat(queryParams, "&")
        end
    end

    makeHTTPRequest(url, "GET", nil, function(success, response)
        if success then
            print("[ServerAuctionHandler] Retrieved auctions successfully")

            -- Send auction data back to client
            sendServerCommand(player, "PlayerAuction", "auctionList", {
                success = true,
                auctions = response -- You'd parse JSON response here
            })
        else
            print("[ServerAuctionHandler] Failed to retrieve auctions: " .. tostring(response))

            sendServerCommand(player, "PlayerAuction", "auctionList", {
                success = false,
                message = "Failed to retrieve auctions"
            })
        end
    end)
end

-- Handle client commands
local function onClientCommand(module, command, player, args)
    if module ~= "PlayerAuction" then return end

    if command == "createListing" then
        ServerAuctionHandler.createAuctionListing(player, args)
    elseif command == "getAuctions" then
        ServerAuctionHandler.getActiveAuctions(player, args.filters)
    elseif command == "placeBid" then
        -- Handle bid placement
        print("[ServerAuctionHandler] Received bid placement request")

        -- Log bid placement
        local bidData = {
            auctionID = args.auctionID,
            bidderUsername = player:getUsername(),
            bidderSteamID = player:getSteamID(),
            bidAmount = args.bidAmount
        }

        writeAuctionLog("PLACE_BID", bidData)

    elseif command == "buyout" then
        -- Handle immediate buyout
        print("[ServerAuctionHandler] Received buyout request")

        -- Log buyout
        local buyoutData = {
            auctionID = args.auctionID,
            buyerUsername = player:getUsername(),
            buyerSteamID = player:getSteamID(),
            buyoutPrice = args.buyoutPrice
        }

        writeAuctionLog("BUYOUT", buyoutData)
    elseif command == "processAuction" then
        -- Manually trigger auction result processing
        print("[ServerAuctionHandler] Manually triggering auction result processing")
        processAuctionResultQueue()
    end
end

-- Test auction logging system on server startup
local function testHTTPConnection()
    print("[ServerAuctionHandler] Initializing auction logging system...")
    print("[ServerAuctionHandler] Auction data will be logged to: " .. AUCTION_LOG_FILE)
    print("[ServerAuctionHandler] API URL configured: " .. NODEJS_API_URL)

    -- Test the auction logging system
    local testData = {
        test = true,
        message = "Auction logging system test",
        server = getServerName() or "Project_Zomboid_Server"
    }

    -- Test write to auction log
    print("[ServerAuctionHandler] Testing auction log file...")
    local logSuccess = writeAuctionLog("SYSTEM_TEST", testData)

    if logSuccess then
        print("[ServerAuctionHandler] ✓ Auction logging system ready")
        print("[ServerAuctionHandler] ✓ Log file: " .. AUCTION_LOG_FILE)
        print("[ServerAuctionHandler] ✓ Your Node.js app can read this file for auction data")
    else
        print("[ServerAuctionHandler] ✗ Auction logging system failed to initialize")
    end
end

-- Register event handlers
Events.OnClientCommand.Add(onClientCommand)

-- Test connection when server starts
Events.OnServerStarted.Add(testHTTPConnection)

print("[ServerAuctionHandler] Server auction handler loaded successfully")
print("[ServerAuctionHandler] API URL: " .. NODEJS_API_URL)

-- Register hourly processor (runs once per in-game hour)
Events.EveryTenMinutes.Add(processAuctionResultQueue)
