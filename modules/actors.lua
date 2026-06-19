local actors = {}

local utils = require("ExportCells.utils")
local config = nil

function actors.setConfig(cfg)
    config = cfg
end

function actors.export(ref)
    if not ref or not (ref.object.objectType == tes3.objectType.npc or ref.object.objectType == tes3.objectType.creature) then
        tes3.messageBox("No NPC or creature targeted.")
        return
    end

    if config and config.resetAnimation then
        utils.resetAnimation(ref)
    end

    local bakedNode = utils.bakeActor(ref)
    if not bakedNode then
        tes3.messageBox("Failed to bake actor.")
        return
    end

    local exportDir = config and config.exportFolder or "Data Files/Export Cells/"
    local rawName = ref.baseObject.name or ref.baseObject.id
    local safeName = rawName:gsub('[^%w %._-]', '_')
    local fileName = ("%s.nif"):format(safeName)
    local fullPath = exportDir .. "\\" .. fileName

    fullPath = fullPath:gsub("[/\\]+", "\\")

    bakedNode:saveBinary(fullPath)
    tes3.messageBox("Actor exported to %s", fileName)
end

function actors.exportActiveCells()
    local activeCells = tes3.getActiveCells()
    local exportedIds = {}
    local exportCount = 0
    local exportDir = config and config.exportFolder or "Data Files/Export Cells/"
    lfs.mkdir(exportDir)

    for _, cell in ipairs(activeCells) do
        local function processRef(ref)
            if not ref or ref == tes3.player or ref.disabled or ref.deleted then
                return
            end
            local obj = ref.object
            if not obj or (obj.objectType ~= tes3.objectType.npc and obj.objectType ~= tes3.objectType.creature) then
                return
            end

            local id = obj.id
            if exportedIds[id] then
                return
            end
            exportedIds[id] = true

            if config and config.resetAnimation then
                utils.resetAnimation(ref)
            end

            local bakedNode = utils.bakeActor(ref)
            if bakedNode then
                bakedNode.translation = tes3vector3.new(0, 0, 0)
                bakedNode.rotation = tes3matrix33.new(1, 0, 0, 0, 1, 0, 0, 0, 1)

                local rawName = ref.baseObject.name or ref.baseObject.id
                local safeName = rawName:gsub('[^%w %._-]', '_')
                local fileName = ("%s.nif"):format(safeName)
                local fullPath = exportDir .. "\\" .. fileName
                fullPath = fullPath:gsub("[/\\]+", "\\")

                bakedNode:saveBinary(fullPath)
                exportCount = exportCount + 1
            end
        end

        for ref in cell:iterateReferences(tes3.objectType.npc) do
            processRef(ref)
        end
        for ref in cell:iterateReferences(tes3.objectType.creature) do
            processRef(ref)
        end
    end

    if exportCount > 0 then
        tes3.messageBox("Exported %d actors to %s", exportCount, exportDir)
    else
        tes3.messageBox("No actors found in active cells.")
    end
end

return actors