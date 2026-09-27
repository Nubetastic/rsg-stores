local function rotationToDirection(rotation)
    local rotationZ = math.rad(rotation.z)
    local rotationX = math.rad(rotation.x)
    local horizontal = math.abs(math.cos(rotationX))

    return vector3(
        -math.sin(rotationZ) * horizontal,
        math.cos(rotationZ) * horizontal,
        math.sin(rotationX)
    )
end

RegisterCommand('getDoorInfo', function()
    local cameraCoords = GetGameplayCamCoord()
    local direction = rotationToDirection(GetGameplayCamRot(2))
    local targetCoords = cameraCoords + (direction * 10.0)
    local shapeTest = StartExpensiveSynchronousShapeTestLosProbe(
        cameraCoords.x,
        cameraCoords.y,
        cameraCoords.z,
        targetCoords.x,
        targetCoords.y,
        targetCoords.z,
        16,
        PlayerPedId(),
        7
    )
    local _, hit, _, _, entity = GetShapeTestResult(shapeTest)

    if not hit or entity == 0 or GetEntityType(entity) ~= 3 then
        print('[rsg-stores] No door object found. Aim directly at the closed door and try /getDoorInfo again.')
        return
    end

    local coords = GetEntityCoords(entity)
    local model = GetEntityModel(entity)

    print(('{ coords = vector3(%.6f, %.6f, %.6f), model = %d, heading = %.2f },'):format(
        coords.x,
        coords.y,
        coords.z,
        model,
        GetEntityHeading(entity)
    ))
end, false)
