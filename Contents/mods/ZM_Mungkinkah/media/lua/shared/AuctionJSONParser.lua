--***********************************************************
--**              AUCTION JSON PARSER                    **
--**     Simple JSON parser for auction files            **
--***********************************************************

local AuctionJSONParser = {}

-- Simple JSON parser for auction files
function AuctionJSONParser.parseJSON(jsonString)
    if not jsonString or jsonString == "" then
        return nil, "Empty JSON string"
    end

    -- Remove whitespace and newlines
    jsonString = jsonString:gsub("%s+", " "):gsub("^ ", ""):gsub(" $", "")

    -- Basic JSON parsing - handles the specific structure of auction files
    local function parseValue(str, pos)
        pos = pos or 1

        -- Skip whitespace
        while pos <= #str and str:sub(pos, pos):match("%s") do
            pos = pos + 1
        end

        if pos > #str then return nil, pos end

        local char = str:sub(pos, pos)

        -- String
        if char == '"' then
            local endPos = pos + 1
            while endPos <= #str and str:sub(endPos, endPos) ~= '"' do
                if str:sub(endPos, endPos) == '\\' then
                    endPos = endPos + 2 -- Skip escaped character
                else
                    endPos = endPos + 1
                end
            end
            if endPos > #str then return nil, pos end
            local value = str:sub(pos + 1, endPos - 1)
            -- Unescape basic characters
            value = value:gsub('\\"', '"'):gsub('\\n', '\n'):gsub('\\r', '\r'):gsub('\\t', '\t')
            return value, endPos + 1
        end

        -- Number
        if char:match("[%d%-]") then
            local numStr = ""
            while pos <= #str and str:sub(pos, pos):match("[%d%.%-eE+]") do
                numStr = numStr .. str:sub(pos, pos)
                pos = pos + 1
            end
            return tonumber(numStr), pos
        end

        -- Boolean true
        if str:sub(pos, pos + 3) == "true" then
            return true, pos + 4
        end

        -- Boolean false
        if str:sub(pos, pos + 4) == "false" then
            return false, pos + 5
        end

        -- Null
        if str:sub(pos, pos + 3) == "null" then
            return nil, pos + 4
        end

        -- Object
        if char == '{' then
            local obj = {}
            pos = pos + 1

            -- Skip whitespace
            while pos <= #str and str:sub(pos, pos):match("%s") do
                pos = pos + 1
            end

            -- Empty object
            if pos <= #str and str:sub(pos, pos) == '}' then
                return obj, pos + 1
            end

            while pos <= #str do
                -- Parse key
                local key, newPos = parseValue(str, pos)
                if not key then return nil, pos end
                pos = newPos

                -- Skip whitespace and find colon
                while pos <= #str and (str:sub(pos, pos):match("%s") or str:sub(pos, pos) == ':') do
                    pos = pos + 1
                end

                -- Parse value
                local value, newPos2 = parseValue(str, pos)
                pos = newPos2

                obj[key] = value

                -- Skip whitespace
                while pos <= #str and str:sub(pos, pos):match("%s") do
                    pos = pos + 1
                end

                -- Check for comma or end
                if pos <= #str then
                    if str:sub(pos, pos) == ',' then
                        pos = pos + 1
                    elseif str:sub(pos, pos) == '}' then
                        return obj, pos + 1
                    end
                end
            end
            return obj, pos
        end

        -- Array
        if char == '[' then
            local arr = {}
            pos = pos + 1
            local index = 1

            -- Skip whitespace
            while pos <= #str and str:sub(pos, pos):match("%s") do
                pos = pos + 1
            end

            -- Empty array
            if pos <= #str and str:sub(pos, pos) == ']' then
                return arr, pos + 1
            end

            while pos <= #str do
                local value, newPos = parseValue(str, pos)
                if value ~= nil then
                    arr[index] = value
                    index = index + 1
                end
                pos = newPos

                -- Skip whitespace
                while pos <= #str and str:sub(pos, pos):match("%s") do
                    pos = pos + 1
                end

                -- Check for comma or end
                if pos <= #str then
                    if str:sub(pos, pos) == ',' then
                        pos = pos + 1
                    elseif str:sub(pos, pos) == ']' then
                        return arr, pos + 1
                    end
                end
            end
            return arr, pos
        end

        return nil, pos
    end

    local result, _ = parseValue(jsonString)
    return result
end

return AuctionJSONParser