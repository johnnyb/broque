<img src="docs/images/logos/Cartoon_Woman_Without_Money_Left_In_Her_Wallet.svg?raw=true" width="30%" align="right" />

# broQue: The Poor Man's Enterprise Message Bus

broQue aims to be an enterprise message bus which is extremely simple to deploy and use, but has all of the features you need.
Most message queueing software tries to be the fastest, most high-throughput.
That's not what I'm aiming for, here.

Project Goals:
1. Simplicity of deployment
2. Simplicity of development
3. Stability/reliability/durability of messaging

The key differentiator of broQue is that ALL queues (we call them *channels*) are stored pub/sub channels.
This means that once a message is published, it is permanently available by default.
You have to configure the channel if you want it to do something else.

At present, it uses PostgreSQL as the storage engine, by default in the same Pod.
It is setup to make that easy to override in the future (should work fine for external MySQL and PostgreSQL implementations), but using PostgreSQL in the same Pod means that it can be deployed in a self-contained manner.
Everything should be SQLite-compatible for testing, however, I have not been successful running SQLite in production at-all (though this could be a limitation of my knowledge of SQLite).

## Installing in Kubernetes

To install, simply run

```
kubectl apply -f https://raw.githubusercontent.com/johnnyb/broque/main/deploy/simple.yaml
```

Other common deployment configurations are available in the `deploy` folder, or you can use them to create your own!

## API

The API is straightforward.
There are a few basic URL structures:

1. `/v1/channels/CHANNEL-NAME/messages`: POST-ing to this will create a message in the specified channel.  The channel does NOT have to have already existed (though it can be created/configured with a POST to `/v1/channels`).
2. `/v1/channels/CHANNEL-NAME/subscriptions/SUBSCRIPTION-NAME/messages`: retrieve messages from a named subscription on a channel (defaults to 100 messages at a time).  The subscription (nor the channel) does NOT have to have already existed (though it can be created/configured with a POST to `/v1/channels/CHANNEL-NAME/subscriptions`).
3. `/v1/channels/CHANNEL-NAME/cursors/CURSORID/messages`: retrieve messages from a cursor.  The cursor DOES need to be created with a POST to `/v1/channels/CHANNEL-NAME/cursors`.  
4. `/v1/channels/CHANNEL-NAME/subscriptions/SUBSCRIPTION-NAME/messages/MSGID/complete`: PUT-ing to this will mark the message as being finished.  Otherwise, in 30 seconds, the message will be available again.  If you read the message with \icode{autocomplete} set to true, you can skip this step.

An example interactive session using CURL:

```
curl -X POST http://localhost:3000/v1/channels/mychannel/messages -dmessage=HelloThere

{"id":"3","publisher_uid":"none","created_at":"2022-05-24T21:07:08.980Z","updated_at":"2022-05-24T21:07:08.980Z"}

curl http://localhost:3000/v1/channels/mychannel/subscriptions/subscription1/messages

[] # returns nothing because it starts at the end of the queue

curl -X PUT http://localhost:3000/v1/channels/mychannel/subscriptions/subscription1/reset

# Returns the subscription information
{"id":"6","name":"subscription1"}

curl http://localhost:3000/v1/channels/mychannel/subscriptions/subscription1/messages

# Returns the message
[{"id":"3","channel_id":"2","message_origination_reference":"9bbf0d31-3f29-4d1a-81bb-52d5e1287e5d","message_reference":"c7dbffc5-7280-498e-8864-99d30eca613c","publisher_uid":"none","message":"HelloThere","created_at":"2022-05-24T21:07:08.980Z","updated_at":"2022-05-24T21:07:08.980Z"}]

curl http://localhost:3000/v1/channels/mychannel/subscriptions/subscription1/messages

[] # Returns nothing because we have read everything

sleep 30

curl http://localhost:3000/v1/channels/mychannel/subscriptions/subscription1/messages

[{...}] # Returns the message again because we never marked it complete

curl -X PUT http://localhost:3000/v1/channels/mychannel/subscriptions/subscription1/messages/MSGID/complete

# returns nothing (204)

curl http://localhost:3000/v1/channels/mychannel/subscriptions/subscription1/messages?autocomplete=1

# Returns messages that you don't have to call /complete on.

```

As you can see, you can get up-and-running immediately.
All messages are permanently saved, unless otherwise specified.

## Security

Right now, I'm only doing a REST-based API.
Currently, it is unauthenticated.
I plan on adding authentication, and the first aspect of that will be Kubernetes authentication.

## Auth Configuration

The following environment variables are supported:

* `AUTH_METHOD`: `kubernetes` or `custom`.  Leaving blank makes all UIDs nil.
* `AUTH_CUSTOM_ENDPOINT`: If `AUTH_METHOD` is `custom`, this is the endpoint to check.  Performs a GET request to the endpoint with the authorization header copied.  Expects a JSON object with a `uid` field.
* `AUTH_CACHE_EXPIRATION`: How long to cache auth header results (in seconds).  Defaults to 900 seconds (15 minutes).
* `AUTH_REQUIRED`: If set to a true-ish value, requires all connections to have a non-nil authentication result
* `AUTH_MASTER_BOOSTRAP`: If an auth master bootstrap is *not* set, then any user can create/configure channels.  If an auth master *is* set, then only users with explicit permissions can create channels.  Then, the `AUTH_MASTER_BOOTSTRAP` account is the only initial account that can configure an account so that it can create channels.

The basic idea of broQue is that, if this system is behind the firewall anyway, for many systems authentication/authorization just wouldn't be required, as it would be overkill for the given system.
The next step up from that is simply requiring authentication for all connections.
Then, for a "secure by default" setup, you can set an `AUTH_MASTER_BOOTSTRAP` account, which essentially designates an account to set up the security for the cluster, and doesn't allow any other accounts unless granted permissions by the bootstrap account.

The goal is to provide simple access for those who just need a simple system, but be able to graduate to more complex and secure setups going forward, and also to keep global configuration options available as environment variables.

## Current Plans

1. Get this running in a Pod container ready for Kubernetes
2. Add the ability to have a separate "writer" process (possibly as a DaemonSet) so that you can get reliable writes even if the main server is loaded.
3. Add Kubernetes-based authentication options
4. Add options to delete historic messages, if desired.
   1. Delete "ActiveReadings" if they are all closed out
   2. If a queue is marked as non-persistent, delete messages if all cursors have moved beyond the message (or possibly also after a timeout)
   3. Have a dead-letter queue-type mechanism for repeated failed reads from a cursor

Open questions

* Authentication mechanisms
* Authorization mechanisms
* Channel configuration options
* Status API
* Kubernetes API resources and/or controller mechanisms?
* Have subscriptions which can automatically kick-off jobs, or automatically scale jobs to handle message processing
* Have docker images which publish or process messages with as little configuration as possible.  Perhaps have a script add-on to a controller mechanism.

## Motivation for the Project

This is a new enterprise message queue.
I know there's already a lot of them around.
I wrote this one for a few reasons:

1. Most message queues are a pain to install and get running.
2. Most message queues don't realize that all other queue types are just degenerate forms of a stored pub/sub queue.
3. I couldn't stop thinking about it.

This does not aim to be the fastest or handle the most messages.
Its first claim to fame will be that it is dead simple to install and very reliable for small to medium sizes workloads.
Whether or not it goes beyond that, we'll see.

The goal will be for usage in a private Kubernetes network, though it should be runnable without Kubernetes as well.

I'm labeling this as an "enterprise" message queue not because of its massive scale/bandwidth, but because it is a data-processing-oriented message queue.  
I.e., it is for permanent data stores, not speed-handling on live events.

## Thanks

Thanks to Vectortoons for providing the logos through Wikimedia Commons:

https://commons.wikimedia.org/wiki/File:Cartoon_Woman_Without_Money_Left_In_Her_Wallet.svg
