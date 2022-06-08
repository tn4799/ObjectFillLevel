ObjectFillLevel = {
    COLLISION_MASK_HIDE = 0,
    COLLISION_MASK_SHOW = 255
}

function ObjectFillLevel.registerXMLPaths(schema, basePath)
    schema:register(XMLValueType.NODE_INDEX, basePath .. ".capacity(?).visibilityNodes#rootNode", "The root node for visibilityObjects for a specific fillType")
end

function ObjectFillLevel:load(superFunc, components, xmlFile, key, i3dMappings)
    local returnValue = superFunc(self, components, xmlFile, key, i3dMappings)

    self.visibilityNodes = {}

    xmlFile:iterate(key .. ".capacity", function (_, capacityKey)
		local fillTypeName = xmlFile:getValue(capacityKey .. "#fillType")
		local fillType = g_fillTypeManager:getFillTypeIndexByName(fillTypeName)

		if fillType ~= nil then
			self.visibilityNodes[fillType] = {}

            local visibilityRootNode = xmlFile:getValue(capacityKey .. ".visibilityNodes#rootNode", nil, components, i3dMappings)

            if visibilityRootNode ~= nil then
                for i = 1, getNumOfChildren(visibilityRootNode) do
                    table.insert(self.visibilityNodes[fillType], getChildAt(visibilityRootNode, i - 1))

                    local childNode = getChildAt(visibilityRootNode, i - 1)
                    setVisibility(childNode, false)
                    setCollisionMask(childNode, ObjectFillLevel.COLLISION_MASK_HIDE)
                end
            end
		end
	end)

    return returnValue
end

function ObjectFillLevel:updateVisualNodes(fillLevel, fillType, fillInfo)
    local capacity = self:getCapacity(fillType)

    ObjectFillLevel.hideAllNodes(self, fillType)
    local normalizedFillLevel = MathUtil.clamp(fillLevel/capacity, 0, 1)
    local nodesToShow = math.floor(#self.visibilityNodes[fillType] * normalizedFillLevel)

    for i = 1, nodesToShow do
        setVisibility(self.visibilityNodes[fillType][i], true)
        setCollisionMask(self.visibilityNodes[fillType][i], ObjectFillLevel.COLLISION_MASK_SHOW)
    end
end

function ObjectFillLevel:hideAllNodes(fillType)
    for _, node in pairs(self.visibilityNodes[fillType]) do
        setVisibility(node, false)
        setCollisionMask(node, ObjectFillLevel.COLLISION_MASK_HIDE)
    end
end

Storage.registerXMLPaths = Utils.appendedFunction(Storage.registerXMLPaths, ObjectFillLevel.registerXMLPaths)
Storage.load = Utils.overwrittenFunction(Storage.load, ObjectFillLevel.load)
Storage.setFillLevel = Utils.appendedFunction(Storage.setFillLevel, ObjectFillLevel.updateVisualNodes)