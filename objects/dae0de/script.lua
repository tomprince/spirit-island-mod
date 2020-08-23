function onLoad()
    if not Global.getVar("gameStarted") then
        self.createButton({
            click_function = "getPowerCards",
            function_owner = self,
            label = "Days That Never Were",
            position = {0,0.2,0},
            rotation = {0,180,0},
            width = 3000,
            height = 500,
            font_size = 300,
        })
    end
end

function getPowerCards(_, color)
    if not Global.getVar("gameStarted") then
        broadcastToColor("Please wait for the game to start before pressing button!", color, "Red")
        return
    end

    local zone = getObjectFromGUID(Global.getVar("elementScanZones")[color])
    local objs = zone.getObjects()
    local found = false
    for _,obj in pairs(objs) do
        if obj.guid == "013dfc" then
            found = true
            break
       end
    end
    if not found then
        broadcastToColor("You have not picked Fractured Days Split the Sky!", color, "Red")
        return
    end

    local count = 4
    if Global.getVar("numPlayers") <= 2 then
        count = 6
    end
    local minorPowerDeck = getObjectFromGUID(Global.getVar("minorPowerZone")).getObjects()[1]
    for i=1,count do
        local card = minorPowerDeck.takeObject({
            flip = true,
        })
        card.setPosition(Player[color].getHandTransform(2).position + Vector(-10,0,0))
        card.deal(1, color, 2)
    end
    local majorPowerDeck = getObjectFromGUID(Global.getVar("majorPowerZone")).getObjects()[1]
    for i=1,count do
        local card = majorPowerDeck.takeObject({
            flip = true,
        })
        card.setPosition(Player[color].getHandTransform(2).position + Vector(10,0,0))
        card.deal(1, color, 2)
    end
    self.destruct()
end