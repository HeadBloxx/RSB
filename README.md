# CrossServerRemoteFunction
Documentation and API Reference for CrossServerRemoteFunction ( CSRF )

## Introduction

CSRF is a light-weight module that allows developers to send requests from a server to other servers, and to receive a response.

## Installation

There are __two__ main ways of installing this module.
1. You can get it from the Marketplace, and just insert it into ``ReplicatedStorage`` or ``ServerStorage``, or
2. You can install the ``.rbxm`` or the ``.rbxl``, and go on from there

Make sure to have ``Subscription.lua`` and ``Listener.lua`` parented to ``CrossServerRemoteFunction.lua``

## Getting Started

Let's write some code that will allow us to get the ``UserId`` of a player in another server by the player's name.

1. The first step is having the module installed, follow one of the aforementioned steps.
2. Create a ``Script`` inside of ``ServerScriptService``
3. Require the module
```lua
local CSRF = require ( PATH_TO )
``` 
4. Create your ``Listener``

- The first parameter is the ``Identifier``. An identifier is anything that can be used to identify the request you are listening for.</br>
- The second parameter determines whether or not the listener will be destroyed once it picks up the response.</br>
- The third parameter is the ``Callback``. It's the function that's called when the listener picks up on a response, with a passed parameter containing the ``Payload`` of the message from the server to which the request was sent. To view the ``UserId`` of the player we're interested in, we will print out the ``Result``.
```lua
local CSRF = require ( PATH_TO )

local Listener = CSRF.NewListener ( "GetIDForHeadBloxx", true, function ( Payload )

    print ( Payload.Data.Result )
end)
```
5. Create your ``Subscription``

- The first parameter is the ``Topic``
- The second parameter is the ``Process``. A ``Process`` is a ``function`` that will be executed when the server receives a request, with a passed parameter containing the ``Payload`` of the request. It has to return a table consisting of ``Response`` and ``Identifier``, ``Response`` being the response to the request, and ``Identifier`` being the same ``Identifier`` which is inside the Payload.

```lua
local CSRF = require ( PATH_TO )

local Listener = CSRF.NewListener ( "GetIDForHeadBloxx", true, function ( Payload )

    print ( Payload.Data.Result )
end)

local Subscription = CrossServerRemoteFunction.NewSubscription ( "Test", function ( Payload )
	
	local Name: string = Payload.Data.Message
	
	return {
		Response = game.Players:FindFirstChild ( Name ).UserId,
		Identifier = Payload.Data.Identifier
	}
end)
```
6. Add the ``Listener`` we've created to the ``Subscription``

```lua
local CSRF = require ( PATH_TO )

local Listener = CSRF.NewListener ( "GetIDForHeadBloxx", true, function ( Payload )

    print ( Payload.Data.Result )
end)

local Subscription = CrossServerRemoteFunction.NewSubscription ( "Test", function ( Payload )
	
	local Name: string = Payload.Data.Message
	
	return {
		Response = game.Players:FindFirstChild ( Name ).UserId,
		Identifier = Payload.Data.Identifier
	}
end)

Subscription:AddListener ( Listener )
```
7. Send the request

We'll be connecting the request sending line to a ``BindableEvent`` inside of ``ReplicatedStorage``
```lua
local CSRF = require ( PATH_TO )

local Listener = CSRF.NewListener ( "GetIDForHeadBloxx", true, function ( Payload )

    print ( Payload.Data.Result )
end)

local Subscription = CrossServerRemoteFunction.NewSubscription ( "Test", function ( Payload )
	
	local Name: string = Payload.Data.Message
	
	return {
		Response = game.Players:FindFirstChild ( Name ).UserId,
		Identifier = Payload.Data.Identifier
	}
end)

Subscription:AddListener ( Listener )

game.ReplicatedStorage.BindableEvent.Event:Connect ( function ()
  
  Subscription:SendRequest ( "HeadBloxx", "GetIDForHeadBloxx" )
end)
```

And there you go, you now have a script that will get HeadBloxx's ``UserId`` whilst HeadBloxx is in another server.</br>
Although ``Identifiers`` prove more valuable in complex scenarios, I've chosen this simple example to introduce the module.

## API Reference


