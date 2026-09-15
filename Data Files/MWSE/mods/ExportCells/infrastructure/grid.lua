local grid = {}

local configRef = nil

function grid.setConfig(cfg)
    configRef = cfg
end

-- Multiples and rounding helpers

-- =============================================================================
-- OFFSETS & ANCHORS
-- =============================================================================
function grid.get2x2GridOffsets(size)
    local half = math.floor(size / 2)
    local offsets = {}
    for y = -half, half do
        for x = -half, half do
            table.insert(offsets, { x = x * 2, y = y * 2 })
        end
    end
    return offsets
end

function grid.get3x3GridOffsets(size)
    local half = math.floor(size / 2)
    local offsets = {}
    for y = -half, half do
        for x = -half, half do
            table.insert(offsets, { x = x * 3, y = y * 3 })
        end
    end
    return offsets
end

function grid.get1x1GridOffsets(size)
    local half = math.floor(size / 2)
    local offsets = {}
    for y = -half, half do
        for x = -half, half do
            table.insert(offsets, { x = x, y = y })
        end
    end
    return offsets
end

-- getGridAnchors moved to grid module; uses configRef to check exportEmptyLandmassCells
function grid.getGridAnchors(gridType, minX, maxX, minY, maxY, visited)
    local anchors = {}
    local cfg = configRef or {}

    -- Absolute lattice, not player-relative. Block shape matches export2x2:
    -- 2x2 is {ax, ax+1} x {ay-1, ay}, so Y takes the odd member of the pair.
    local function anchor2x(n) return n - (n % 2) end
    local function anchor2y(n) return n - (n % 2) + 1 end
    local function anchor3(n)
        if n % 3 == 0 then return n end
        if n % 3 == 1 then return n - 1 end
        return n + 1
    end

    local toAnchorX = (gridType == "2x2") and anchor2x or anchor3
    local toAnchorY = (gridType == "2x2") and anchor2y or anchor3
    local step = (gridType == "2x2") and 2 or 3

    if cfg.exportEmptyLandmassCells then
        for x = toAnchorX(minX), toAnchorX(maxX), step do
            for y = toAnchorY(minY), toAnchorY(maxY), step do
                table.insert(anchors, { x = x, y = y })
            end
        end
    else
        local anchorSet = {}
        for key, _ in pairs(visited) do
            local x, y = key:match("(-?%d+),(-?%d+)")
            x, y = tonumber(x), tonumber(y)
            local ax, ay = toAnchorX(x), toAnchorY(y)
            local akey = ax .. "," .. ay
            if not anchorSet[akey] then
                anchorSet[akey] = { x = ax, y = ay }
            end
        end
        for _, anchor in pairs(anchorSet) do
            table.insert(anchors, anchor)
        end
    end

    return anchors
end

return grid