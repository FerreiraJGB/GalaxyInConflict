echoutil = {}

function echoutil.findInTable(tab, val)
	for index, value in ipairs(tab) do
        if value == val then
            return true
        end
    end

    return false
end

function echoutil.findInTablePairs(tab, val)
	for index, value in pairs(tab) do
		--sb.logInfo("index " .. sb.printJson(index))
		--sb.logInfo("value " .. sb.printJson(value))
        if value == val then
			--sb.logInfo(value .. " value")
			--sb.logInfo(val .. " end goal")
            return true
        end
    end

    return false
end

function echoutil.playerHasInTable(tab)
	for index, value in ipairs(tab) do
        if player.hasItem({name = tab[index]}) == true then
            return {tab[index],index}
		end
    end

    return false
end

function echoutil.findItemWithTag(tag,tab,itemToIndex) --itemToIndex is an object with parameters named to an item, with its value set to the index. supposed optimization, if defined beforehand.
	local itemList = player.itemsWithTag(tag)
	
	for itemListIndex, item in ipairs(itemList) do
		if not item then return false end
		local itemName = item.name
	
		if itemToIndex[itemName] then
			return {itemName,itemToIndex[itemName]}
		end
	end

    return false
end

function echoutil.addTables(tab1,tab2)
	local resultTable = {}
	resultTable[1] = tab1[1] + tab2[1]
	resultTable[2] = tab1[2] + tab2[2]
    return resultTable
end

function echoutil.subtractTables(tab1,tab2)
	local resultTable = {}
	resultTable[1] = tab1[1] - tab2[1]
	resultTable[2] = tab1[2] - tab2[2]
    return resultTable
end

function echoutil.logJson(input)
	sb.logInfo(sb.printJson(input))
end

function echoutil.round(decimalPlaces,exact)
	return tonumber(string.format("%."..(decimalPlaces or 1).."f", exact))
end