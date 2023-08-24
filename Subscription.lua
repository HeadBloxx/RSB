local SubscriptionModule = {}
SubscriptionModule.__index = SubscriptionModule

local MessagingService = game:GetService ( "MessagingService" )
local MemoryStore      = game:GetService ( "MemoryStoreService" )

local ResponseSuffix: string = "_response"

-- // Config

local SameServerResponsesAllowed: boolean = false
local PollingTime               : number  = 60 -- I strongly suggest to not go under the 60 mark.

-- //

--|| DO NOT EDIT ANYTHING PAST THIS LINE UNLESS YOU KNOW WHAT YOU'RE DOING ||--

local ExpirationTime            : number  = PollingTime * 2

local ResponsesMap = MemoryStore:GetSortedMap ( "Responses" )
local RequestsMap  = MemoryStore:GetSortedMap ( "Requests"  )

local Callbacks = {}

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
	
	JobId           : string,
	Result          : { Response: any, Identifier: any },
	Identifier      : string,
	JobIDToRespondTo: string
	
}

type Subscription = {
	
	Listeners                 : {},
	Process                   : ( Payload )                                           -> any,
	Topic                     : string,
	SendRequest               : ( self: Subscription, Message: any, Identifier: any ) -> nil,
	AddListener               : ( self: Subscription, Listener: Listener )            -> nil,
	ResponseSenderConnection  : RBXScriptConnection,
	ResponseListenerConnection: RBXScriptConnection,
	IsHandlingResponse        : boolean,
	
}

task.spawn ( function ()
	-- Polling

	while task.wait ( PollingTime ) do

		for Identifier: string, Callback: ( any ) -> nil in pairs ( Callbacks ) do
			
			local ResponseData = ResponsesMap:GetAsync ( Identifier )
			
			if not ResponseData then continue end
				
			task.spawn ( Callback, ResponseData )
		end
	end
end)

function SubscriptionModule.New ( Topic: string, Process: ( Payload ) -> any ): Subscription
	local self: Subscription = {}
	setmetatable ( self, SubscriptionModule )
	
	self.Listeners = {}
	self.Process   = Process
	self.Topic     = Topic
	
	self.IsHandlingResponse = false
	
	local function JobIdIsSame ( JobID: string )
		
		return game.JobId == JobID and not SameServerResponsesAllowed
	end
	
	-- request receiver
	self.ResponseSenderConnection = MessagingService:SubscribeAsync ( self.Topic, function ( Payload: Payload )
		
		local Data = RequestsMap:GetAsync ( Payload.Data )
		
		if JobIdIsSame ( Data.JobId ) then return end
		
		task.spawn ( function ()
			
			local FakePayload = { -- Sorry but I don't want to bother changing the docs lol
				
				Sent = Payload.Sent,
				Data = Data
				
			}
			
			local Result = self.Process ( FakePayload )
			
			local ProcessResult: ProcessResult = {

				Result           = Result.Response,
				Identifier       = Result.Identifier,
				JobId            = game.JobId,
				JobIDToRespondTo = FakePayload.Data.JobId

			}

			ResponsesMap:SetAsync ( Result.Identifier, ProcessResult, ExpirationTime )

			local Success, Error = pcall(function()
				MessagingService:PublishAsync ( self.Topic .. ResponseSuffix, Result.Identifier )
			end)

			if Error then
				self.Queue[#self.Queue + 1] = ProcessResult
			end
		end)
	end)
	
	-- response listener
	self.ResponseListenerConnection = MessagingService:SubscribeAsync ( self.Topic .. ResponseSuffix, function ( Payload: Payload )
		
		local Response: ProcessResult = ResponsesMap:GetAsync ( Payload.Data )
		
		if JobIdIsSame ( Response.JobId ) then return end
		
		if game.JobId ~= Response.JobIDToRespondTo then return end -- This server did not make the request
		
		local ToRemove = {}
		
		self.IsHandlingResponse = true
		
		for _, listener: Listener in pairs ( self.Listeners ) do
			
			if listener.Identifier ~= Response.Identifier then continue end
			
			task.spawn ( listener.Callback, Response )
			
			ResponsesMap:RemoveAsync ( Response.Identifier )
			
			if listener.DestroyedOnCallback then
				
				self:RemoveListener ( Response.Identifier )
			end
		end
		
		self.IsHandlingResponse = false
	end)
	
	return self
end

function SubscriptionModule:SendQueue()
	local Coroutine = coroutine.create(function()
		while task.wait(10) do -- while loop :skull:
			for Index, Data in self.Queue do
				if Data["JobIDToRespondTo"] ~= nil then
					local Success, Error = pcall(function()
						RequestsMap:SetAsync ( Data.Identifier, Data, ExpirationTime )
						MessagingService:PublishAsync ( self.Topic .. ResponseSuffix, Data.Identifier )
					end)

					if Success then
						table.remove(self.Queue, Index)
					end
				else
					local Success, Error = pcall(function()
						RequestsMap:SetAsync ( Data.Identifier, Data, ExpirationTime )
						MessagingService:PublishAsync ( self.Topic, Data.Identifier )
					end)

					if Success then
						table.remove(self.Queue, Index)
					end
				end
			end
		end
	end)
	
	coroutine.resume(Coroutine)
end

function SubscriptionModule:SendRequest ( Message: any, Identifier: any )
	
	local Data = { Identifier = tostring ( Identifier ), Message = Message, JobId = game.JobId }
	
	RequestsMap:SetAsync ( Identifier, Data, ExpirationTime )
	
	local Success, Error = pcall(function()
		MessagingService:PublishAsync ( self.Topic, Identifier )
	end)
	
	if Error then
		self.Queue[#self.Queue + 1] = Data
	end
end

function SubscriptionModule:AddListener ( NewListener: Listener )
	
	Callbacks[ NewListener.Identifier ] = NewListener.Callback
	table.insert ( self.Listeners, NewListener )
end

function SubscriptionModule:RemoveListener ( Identifier: string )
	
	Callbacks[ Identifier ] = nil
	
	if not self.IsHandlingResponse then
		
		repeat task.wait () until self.IsHandlingResponse
	end
	
	local ToRemove: number?
	
	for i, Listener: Listener in pairs ( self.Listeners ) do
		
		if Listener.Identifier == Identifier then
			
			ToRemove = i
			break
		end
	end
	
	if ToRemove then
		
		table.remove ( self.Listeners, ToRemove )
	end
	
end

function SubscriptionModule:Unsubscribe ()
	
	self.ResponseSenderConnection  :Disconnect ()
	self.ResponseListenerConnection:Disconnect ()
	
	for i, v in pairs ( self ) do
		
		self[i] = nil
	end
	
	table.freeze ( self )
	self = nil
end

return SubscriptionModule
