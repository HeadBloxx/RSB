local CrossServerRemoteFunction = {}

local Subscription = require ( script.Subscription )
local Listener     = require ( script.Listener )

CrossServerRemoteFunction.NewSubscription = Subscription.New
CrossServerRemoteFunction.NewListener     = Listener.New

return CrossServerRemoteFunction
