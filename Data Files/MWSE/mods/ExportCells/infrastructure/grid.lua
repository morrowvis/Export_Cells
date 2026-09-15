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

    -- Anchors sit on an ABSOLUTE lattice (multiples of 2 or 3), never relative to
    -- where the player is standing, so a landmass always partitions into the same
    -- blocks no matter where the export is started from.
    --
    -- Each function must return the anchor of the block that CONTAINS n:
    --   2x2 blocks expand dx,dy = 0..1  -> {a, a+1},     so floor n to even.
    --   3x3 blocks expand dx,dy = -1..1 -> {a-1, a, a+1}, so snap n to a multiple of 3.
    -- Rounding n UP instead drops cells: a 2x2 anchor of n+1 gives {n+1, n+2}, which
    -- does not contain n at all, and whole columns and rows fall outside every block.
    local function anchor2(n) return n - (n % 2) end
    local function anchor3(n)
        if n % 3 == 0 then return n end
        if n % 3 == 1 then return n - 1 end
        return n + 1
    end

    local toAnchor = (gridType == "2x2") and anchor2 or anchor3
    local step = (gridType == "2x2") and 2 or 3

    if cfg.exportEmptyLandmassCells then
        -- Walk the bounding box along the lattice. Both ends are snapped, so the
        -- outermost column and row sit inside a block instead of just past the last
        -- anchor.
        for x = toAnchor(minX), toAnchor(maxX), step do
            for y = toAnchor(minY), toAnchor(maxY), step do
                table.insert(anchors, { x = x, y = y })
            end
        end
    else
        local anchorSet = {}
        for key, _ in pairs(visited) do
            local x, y = key:match("(-?%d+),(-?%d+)")
            x, y = tonumber(x), tonumber(y)
            local ax, ay = toAnchor(x), toAnchor(y)
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