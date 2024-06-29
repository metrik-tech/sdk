local ReplicatedStorage = game:GetService("ReplicatedStorage")

local MetrikSDK = require(ReplicatedStorage.MetrikSDK)

MetrikSDK.Server:SetContext({
    Name = "A very problematic module"
})

local function abc()
    MetrikSDK.Server:CreateBreadcrumb("Am I going to error? Who knows...")

    if math.random() > 0.95 then
        return
    end

    error("A problem")
end

return {
    abc = abc
}