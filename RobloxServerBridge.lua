local RobloxServerBridg = {}

local Subscription = require ( script.Subscription )
local Listener     = require ( script.Listener )

RobloxServerBridg.NewSubscription = Subscription.New
RobloxServerBridg.NewListener     = Listener.New

return RobloxServerBridg
