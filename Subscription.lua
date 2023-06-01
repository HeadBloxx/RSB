local SubscriptionModule = {}
SubscriptionModule.__index = SubscriptionModule

local MessagingService = game:GetService ( "MessagingService" )

local ResponseSuffix: string = "_response"

type Listener = {

	Identifier         : string,
	DestroyedOnCallback: boolean,
	Callback           : ( any ) -> nil

}

type Payload = {
	
	Sent: number,
	Data: any
	
}

type ProcessResult = {
	
	JobId     : string,
	Result    : { Response: any, Identifier: any },
	Identifier: any,
	
}

type Subscription = {
	
	Listeners                 : {},
	Process                   : ( Payload )                                           -> any,
	Topic                     : string,
	SendRequest               : ( self: Subscription, Message: any, Identifier: any ) -> nil,
	AddListener               : ( self: Subscription, Listener: Listener )            -> nil,
	ResponseSenderConnection  : RBXScriptConnection,
	ResponseListenerConnection: RBXScriptConnection
	
}

local SameServerResponsesAllowed: boolean = script:GetAttribute ( "SameServerResponsesAllowed" )

function SubscriptionModule.New ( Topic: string, Process: ( Payload ) -> any ): Subscription
	local self: Subscription = {}
	setmetatable ( self, SubscriptionModule )
	
	self.Listeners = {}
	self.Process   = Process
	self.Topic     = Topic
	
	local function JobIdIsSame ( Payload: Payload )
		
		return game.JobId == Payload.Data.JobId and not SameServerResponsesAllowed
	end
	
	-- response sender
	self.ResponseSenderConnection = MessagingService:SubscribeAsync ( self.Topic, function ( Payload: Payload )
		
		if JobIdIsSame ( Payload ) then return end
		
		local Result = self.Process ( Payload )
		
		local ProcessResult: ProcessResult = {
			
			Result     = Result.Response,
			Identifier = Result.Identifier,
			JobId      = game.JobId,
			
		}
		
		MessagingService:PublishAsync ( self.Topic .. ResponseSuffix, ProcessResult )
	end)
	
	-- response listener
	self.ResponseListenerConnection = MessagingService:SubscribeAsync ( self.Topic .. ResponseSuffix, function ( Payload: Payload )
		
		if JobIdIsSame ( Payload ) then return end
		
		local ToRemove = {}
		
		for _, listener: Listener in pairs ( self.Listeners ) do
			
			if listener.Identifier ~= Payload.Data.Identifier then continue end
			
			listener.Callback ( Payload )
			
			if listener.DestroyedOnCallback then
				
				table.insert ( ToRemove, table.find ( ToRemove, listener ) :: number )
			end
		end
		
		for _, position: number in pairs ( ToRemove ) do
			
			table.remove ( self.Listeners, position )
		end
	end)
	
	return self
end

function SubscriptionModule:SendRequest ( Message: any, Identifier: any )
	
	MessagingService:PublishAsync ( self.Topic, { Identifier = Identifier, Message = Message, JobId = game.JobId } )
end

function SubscriptionModule:AddListener ( NewListener: Listener )
	
	table.insert ( self.Listeners, NewListener )
end

function SubscriptionModule:Unsubscribe ()
	
	self.ResponseSenderConnection  :Disconnect ()
	self.ResponseListenerConnection:Disconnect ()
	
	for i, v in pairs ( self ) do
		
		self[ i ] = nil
	end
	
	table.freeze ( self )
	self = nil
end

return SubscriptionModule
