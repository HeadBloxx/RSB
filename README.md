# Roblox Server Bridge
Documentation and API Reference for Roblox Server Bridge ( RSB )

[Devforum](https://devforum.roblox.com/t/roblox-server-bridge/2401142)

If you have any questions or concerns -> HeadBloxx#8939

## Introduction

RSB (Roblox Server Bridge) is a versatile and powerful module designed to seamlessly connect and exchange data between different Roblox servers. Acting as a robust bridge, RSB enables efficient communication and information retrieval across server boundaries, unlocking a whole new level of flexibility and functionality within your Roblox experiences.

With RSB, developers can effortlessly tap into the wealth of data scattered across various Roblox servers, streamlining access to critical information. Whether you need to retrieve player statistics, synchronize game progress, or facilitate cross-server interactions, RSB serves as the reliable conduit to bridge the gaps between servers.

This dynamic module empowers developers to create immersive and interconnected experiences by leveraging the power of multiple servers. By integrating RSB into your Roblox projects, you can harness the full potential of distributed server architecture, enabling seamless collaboration, data sharing, and real-time updates.

RSB simplifies the process of data retrieval and exchange, abstracting the complexities of server communication behind an intuitive and developer-friendly interface. It handles the intricate tasks of data synchronization, caching, and security, allowing you to focus on crafting engaging gameplay experiences without worrying about the underlying server infrastructure.

Whether you're building massive multiplayer games, collaborative projects, or intricate interconnected worlds, RSB is the essential tool that empowers your Roblox creations to transcend the limitations of individual servers. Experience the power of seamless data transfer and unleash the true potential of your Roblox projects with RSB - the ultimate Roblox Server Bridge.

___Before proceeding you should familiarize yourself with:___</br></br>
[MessagingService](https://create.roblox.com/docs/reference/engine/classes/MessagingService)

## Installation

Download the ``RobloxServerBridge.rbxm`` or ``RobloxServerBridge.rbxl``, or get it from the [Marketplace](https://www.roblox.com/library/13618859786/RobloxServerBridge) and insert it in your game. You should preferrably place them inside ``ReplicatedStorage`` or ``ServerStorage``
__Note:__ Make sure to have ``Subscription.lua`` and ``Listener.lua`` parented to ``RobloxServerBridge.lua``

## Getting Started

Let's write some code that will allow us to get the ``UserId`` of a player in another server by the player's name.

1. The first step is having the module installed, follow one of the aforementioned steps.
2. Create a ``Script`` inside of ``ServerScriptService``
3. Require the module
```lua
local RSB = require ( PATH_TO )
``` 
4. Create your ``Listener``

- The first parameter is the ``Identifier``. An identifier is anything that can be used to identify the request you are listening for.</br>
- The second parameter determines whether or not the listener will be destroyed once it picks up the response.</br>
- The third parameter is the ``Callback``. It's the function that's called when the listener picks up on a response, with a passed parameter containing the ``Payload`` of the message from the server to which the request was sent. To view the ``UserId`` of the player we're interested in, we will print out the ``Result``.
```lua
local RSB = require ( PATH_TO )

local Listener = CSRF.NewListener ( "GetIDForHeadBloxx", true, function ( Payload )

    print ( Payload.Data.Result )
end)
```
5. Create your ``Subscription``

- The first parameter is the ``Topic``
- The second parameter is the ``Process``. A ``Process`` is a ``function`` that will be executed when the server receives a request, with a passed parameter containing the ``Payload`` of the request. It has to return a table consisting of ``Response`` and ``Identifier``, ``Response`` being the response to the request, and ``Identifier`` being the same ``Identifier`` which is inside the Payload.

```lua
local RSB = require ( PATH_TO )

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
local RSB = require ( PATH_TO )

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
local RSB = require ( PATH_TO )

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

Here's a rough diagram demonstrating the architecture:

![RSB Diagram_2](https://github.com/HeadBloxx/RSB/assets/85369300/34a798ac-8d95-490e-87d6-41b2305e429c)

### Listener Class

```lua
ListenerModule.New ( Identifier: any, DestroyedOnCallback: boolean, Callback: ( Payload ) -> nil ): Listener
```

This creates and returns a new ``Listener`` instance.

Listeners listen for request **responses** from servers.

| Parameter    | Type   | Description                  | Default |
|--------------|--------|------------------------------|---------|
| Identifier        | any   | The ``Identifier`` that identifies the response it's listening for          | nil    |
| DestroyedOnCallback   | boolean | Determines whether or not the listener will be destroyed when it picks up a response| nil   |
| Callback   | function | The function that will handle the ``result``         | nil   |

Response body ( ``Result`` being the return value of the ``Process`` function. ) :
```lua
{
			
	Result     = Result.Response,
	Identifier = Result.Identifier,
	JobId      = game.JobId,
			
}
```

**Returns**: ``Listener``

### Subscription Class

```lua
SubscriptionModule.New ( Topic: string, Process: ( Payload ) -> any ): Subscription
```

This creates and returns a new ``Subscription`` instance. 

| Parameter    | Type   | Description                  | Default |
|--------------|--------|------------------------------|---------|
| Topic        | string   | The ``topic`` that will be used for ``MessagingService``          | nil    |
| Process   | function | The function that will handle the ``response``         | nil   |

**Returns**: ``Subscription``

__Note:__ This function creates *two* subscriptions to ``MessagingService``

```lua
Subscription:SendRequest ( Message: any, Identifier: any )
```

This sends a request to all servers with it's ``Topic``. 

| Parameter    | Type   | Description                  | Default |
|--------------|--------|------------------------------|---------|
| Message        | any   | The ``message`` that will be sent for with the request          | nil   |
| Identifier   | any | The ``Identifier`` used to identify this particular request         | nil   |

Request body:
```lua
{
	Identifier = Identifier,
	Message    = Message,
	JobId      = game.JobId
}
```

**Returns**: ``nil``

```lua
Subscription:AddListener ( NewListener: Listener )
```

This creates and returns a new ``Subscription`` instance. 

| Parameter    | Type   | Description                  | Default |
|--------------|--------|------------------------------|---------|
| NewListener        | Listener   | The ``Listener`` to be appointed to the ``subscription``          | nil    |

**Returns**: ``nil``

```lua
Subscription:Unsubscribe ()
```

Deletes the ``Subscription`` instance, disconnecting from both subscriptions to ``MessagingService``

**Returns**: ``nil``

## Configuration

The ``SameServerResponsesAllowed`` variable inside ``Subscription.lua`` determines whether or not one server can send a request or response to itself.


## FAQ:

#### How do I test this?
The way I tested it was a bit unorthodox.
1. You want to publish your game
2. Make the maximum server size 1
3. Use Multiple Roblox to run two instances of the roblox client
4. Test your code!

#### How do I report a bug or request a new feature?
I'm the most active on discord -> HeadBloxx#8939
