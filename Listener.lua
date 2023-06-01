local ListenerModule = {}
ListenerModule.__index = ListenerModule

type Listener = {

	Identifier         : string,
	DestroyedOnCallback: boolean,
	Callback           : ( any ) -> nil

}

type Payload = {

	Sent: number,
	Data: any

}


-- The result is in Payload.Data.Result
function ListenerModule.New ( Identifier: any, DestroyedOnCallback: boolean, Callback: ( Payload ) -> nil ): Listener
	
	local self: Listener = {}
	setmetatable ( self, ListenerModule )
	
	self.Identifier          = Identifier
	self.DestroyedOnCallback = DestroyedOnCallback
	self.Callback            = Callback
	
	return self
end

return ListenerModule
