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
    -- The block shape must match export2x2 / export3x3 exactly, because the engine
    -- builds a cell's edge decals only on its BOTTOM and RIGHT borders. A 2x2 block
    -- is therefore anchored at its TOP-LEFT cell and expands +1X / -1Y:
    --   block(ax, ay) = {ax, ax+1} x {ay-1, ay}
    -- Expanding +Y instead leaves the strip that stitches the block's bottom and
    -- right edge outside the block, and the seam shows as a line every 2 cells.
    --
    -- So each function returns the anchor of the block CONTAINING n:
    --   2x2 X -> floor to even          ({ax, ax+1} contains n)
    --   2x2 Y -> the ODD member of the pair ({ay-1, ay} contains n)
    --   3x3   -> nearest multiple of 3  ({a-1, a, a+1} contains n)
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
        -- Walk the bounding box along the lattice. Both ends are snapped, so the
        -- outermost column and row sit inside a block instead of just past the last
        -- anchor.
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