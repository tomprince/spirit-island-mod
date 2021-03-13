-- Spirit Panel for MJ & iakona's Spirit Island Mod --

function onLoad(saved_data)
    if saved_data ~= "" then
        local loaded_data = JSON.decode(saved_data)
        for k, v in pairs(loaded_data) do
            _G[k] = v
        end
    end
    local sourceSpirit = getObjectFromGUID("SourceSpirit")
    sourceSpirit.call("loadSpirit", self)
end
-- Source Spirit start

function loadSpirit(spirit)
    if Global.getVar("gameStarted") then return end

    spirit.createButton({
        click_function = "setupSpirit",
        function_owner = self,
        label          = "Choose Spirit",
        position       = Vector(0.7, -0.1, 0.9),
        rotation       = Vector(0,0,180),
        scale = Vector(0.2,0.2,0.2),
        width          = 1800,
        height         = 500,
        font_size      = 300,
    })
    spirit.createButton({
        click_function = "toggleProgression",
        function_owner = self,
        label          = "",
        position       = Vector(-0.7, -0.1, 0.9),
        rotation       = Vector(0,0,180),
        scale = Vector(0.2,0.2,0.2),
        width          = 0,
        height         = 0,
        font_size      = 300,
        tooltip        = "Enable/Disable Progression Deck",
    })
    spirit.createButton({
        click_function = "toggleAspect",
        function_owner = self,
        label          = "",
        position       = Vector(0.7, -0.2, 0.4),
        rotation       = Vector(0,0,180),
        scale = Vector(0.2,0.2,0.2),
        width          = 0,
        height         = 0,
        font_size      = 300,
        tooltip        = "Enable/Disable Aspect Deck",
    })
    local castObjects = upCast(spirit)
    for _, obj in pairs (castObjects) do
        if string.find(obj.getName(),"Progression") then
            spirit.setVar("progressionCard", obj)
            spirit.editButton({
                index          = 1,
                label          = "Progression: No",
                width          = 2200,
                height         = 500,
            })
        elseif string.find(obj.getName(),"Aspects") then
            spirit.editButton({
                index          = 2,
                label          = "Aspects: All",
                width          = 2300,
                height         = 500,
            })
        end
    end
    Global.call("addSpirit", {spirit=spirit})
end
function randomAspect(spirit)
    for _,obj in pairs(upCast(spirit)) do
        if obj.type == "Deck" and obj.getName() == "Aspects" then
            local objs = obj.getObjects()
            local index = math.random(0,#objs)
            if index == 0 then
                return ""
            end
            return objs[index].name
        end
    end
    return nil
end
function pickSpirit(params)
    if params.aspect then
        if params.aspect == "Random" then
            params.spirit.setVar("useAspect", 1)
        elseif params.aspect == "" then
            params.spirit.setVar("useAspect", 0)
        else
            params.spirit.setVar("useAspect", 3)
            params.spirit.setVar("aspect", params.aspect)
        end
    end
    setupSpirit(params.spirit, params.color)
end
function setupSpirit(spirit, color)
    local xPadding = 1.3
    local xOffset = 1
    local PlayerBag = getObjectFromGUID(Global.getTable("PlayerBags")[color])
    if #PlayerBag.getObjects() ~= 0 then
        local castObjects = upCast(spirit)
        local hpos = Player[color].getHandTransform().position
        spirit.setPosition(Vector(hpos.x,0,hpos.z) + Vector(0,1.05,13.9))
        spirit.setRotation(Vector(0,180,0))
        spirit.setLock(true)
        spirit.clearButtons()
        local spos = spirit.getPosition()
        local snaps = spirit.getSnapPoints()
        local placed = 0

        -- Setup Presence
        for i = 1,13 do
            local p = snaps[i]
            if i <= #snaps then
                PlayerBag.takeObject({position = spirit.positionToWorld(p.position)})
            else
                PlayerBag.takeObject({position = Vector(spos.x,0,spos.z) + Vector(-placed*xPadding+xOffset,1.1,10)})
                placed = placed + 1
            end
        end

        -- Setup Ready Token
        local ready = PlayerBag.takeObject({
            position = Vector(spos.x,0,spos.z) + Vector(7.5, 1.1, 6.5),
            rotation = Vector(0, 180, 0),
        })

        -- Setup Energy Counter
        local counter = getObjectFromGUID(Global.getVar("counterBag")).takeObject({position = Vector(spos.x,0,spos.z) + Vector(-5,1,5)})
        counter.setLock(true)

        Global.call("removeSpirit", {spirit=spirit.guid, color=color, ready=ready, counter=counter})

        -- Setup Progression Deck if enabled
        local useProgression = spirit.getVar("useProgression")
        if useProgression then
            local minorPowerDeck = getObjectFromGUID(Global.getVar("minorPowerZone")).getObjects()[1]
            local majorPowerDeck = getObjectFromGUID(Global.getVar("majorPowerZone")).getObjects()[1]
            local progressionDeck = spirit.getVar("progressionCard").getVar("progressionDeck")
            for i,card in pairs(progressionDeck) do
                if card[2] then
                    majorPowerDeck.takeObject({
                        position = Vector(spos.x,i,spos.z) + Vector(0,1.1,14),
                        rotation = Vector(0,180,180),
                        guid = card[1],
                    })
                else
                    minorPowerDeck.takeObject({
                        position = Vector(spos.x,i,spos.z) + Vector(0,1.1,14),
                        rotation = Vector(0,180,180),
                        guid = card[1],
                    })
                end
            end
        end

        -- Setup objects on top of board
        for _, obj in pairs(castObjects) do
            obj.setLock(false)
            if obj.type == "Deck" then
                if obj.getName() == "Aspects" then
                    handleAspect(spirit, obj, color)
                else
                    obj.deal(#obj.getObjects(), color)
                end
            elseif obj.type == "Card" and obj.getName() == "Progression" then
                if useProgression then
                    obj.setPositionSmooth(Vector(spos.x,8,spos.z) + Vector(0,1.1,14))
                else
                    obj.destruct()
                end
            elseif Global.getVar("gameStarted") and obj.hasTag("Spirit Setup") then
                local obj = obj  -- luacheck: ignore 423 (deliberate shadowing)
                Wait.frames(function () obj.call("doSpiritSetup", {color=color}) end, 1)
            else
                obj.setPositionSmooth(Vector(spos.x,0,spos.z) + Vector(-placed*xPadding+xOffset,1.1,10))
                placed = placed + 1
            end
        end

        local broadcast = spirit.getVar("broadcast")
        if broadcast ~= nil then
            Player[color].broadcast(broadcast, Color.SoftBlue)
        end
    else
        Player[color].broadcast("You already picked a spirit", "Red")
    end
end
function toggleProgression(spirit)
    local useProgression = spirit.getVar("useProgression")
    useProgression = not useProgression
    spirit.setVar("useProgression", useProgression)
    if useProgression then
        spirit.editButton({
            index          = 1,
            label          = "Progression: Yes",
        })
    else
        spirit.editButton({
            index          = 1,
            label          = "Progression: No",
        })
    end
end
function toggleAspect(spirit, _, alt_click)
    local useAspect = spirit.getVar("useAspect") or 2
    if alt_click then
        useAspect = (useAspect - 1) % 3
    else
        useAspect = (useAspect + 1) % 3
    end
    spirit.setVar("useAspect", useAspect)
    if useAspect == 0 then
        spirit.editButton({
            index          = 2,
            label          = "Aspects: None",
        })
    elseif useAspect == 1 then
        spirit.editButton({
            index          = 2,
            label          = "Aspects: Random",
        })
    else
        spirit.editButton({
            index          = 2,
            label          = "Aspects: All",
        })
    end
end

function handleAspect(spirit, deck, color)
    local useAspect = spirit.getVar("useAspect") or 2
    if useAspect == 0 then
        deck.destruct()
    elseif useAspect == 1 then
        local index = math.random(0,#deck.getObjects())
        if index == 0 then
            Player[color].broadcast("Your random Aspect is no Aspect", Color.SoftBlue)
            deck.destruct()
        else
            deck.takeObject({
                index = index - 1,
                position = deck.getPosition() + Vector(0,2,0),
                callback_function = function(obj) obj.deal(1, color) deck.destruct() Player[color].broadcast("Your random Aspect is "..obj.getName(), Color.SoftBlue) end,
            })
            if deck.remainder then deck = deck.remainder end
        end
    elseif useAspect == 3 then
        local found = false
        local aspect = spirit.getVar("aspect")
        for _, data in pairs(deck.getObjects()) do
            if data.name == aspect then
                found = true
                deck.takeObject({
                    index = data.index,
                    position = deck.getPosition() + Vector(0,2,0),
                    callback_function = function(obj) obj.deal(1, color) deck.destruct() end,
                })
                if deck.remainder then deck = deck.remainder end
                break
            end
        end
        if not found then
            deck.destruct()
            Player[color].broadcast("Unable to find aspect "..aspect, "Red")
        end
    else
        deck.deal(#deck.getObjects(), color)
    end
end
function upCast(obj)
    local hits = Physics.cast({
        origin       = obj.getPosition() + Vector(0,0.1,0),
        direction    = Vector(0,1,0),
        type         = 3,
        size         = obj.getBoundsNormalized().size,
        orientation  = obj.getRotation(),
        max_distance = 0,
        --debug        = true,
    })
    local hitObjects = {}
    for _, v in pairs(hits) do
        if v.hit_object ~= obj then table.insert(hitObjects,v.hit_object) end
    end
    return hitObjects
end
