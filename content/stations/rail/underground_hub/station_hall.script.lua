-- The construction supplies the hall geometry; keep railway tunnel edges.
function data()
    return {updateFn = function(captureParams, params)
        local result = {pillarModels = {}, railingModels = {}}
        for i = 1, #params.railingIntervals do result.railingModels[i] = {{}} end
        return result
    end}
end
