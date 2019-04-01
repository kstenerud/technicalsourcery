---
title: "High Availability"
date: 2019-03-31T23:16:47+02:00
featuredImage: "thumbnail.jpg"
description: "How important is uptime to you? How bad would it be if your services went down for 10 seconds? 10 minutes? 10 hours? 10 days? Every system has its breaking point, where the consequences become so severe that heads start rolling."
draft: true
---

How important is uptime to you? How bad would it be if your services went down for 10 seconds? 10 minutes? 10 hours? 10 days? Every system has its breaking point, where the consequences become so severe that heads start rolling.

Once the breaking point for downtime is shorter than your worst-case time for fixing things, you need high-availability.


## What is High Availability?

High availability is a mechanism whereby multiple redundant services collaborate to minimize interruptions. When one service goes down, another, identical service picks up the slack.

IMAGE

We see redundant systems everyplace where failures can be catastrophic. Commercial airplanes have many redundant systems and sensors, as does the space shuttle. RAID arrays offer protection against data loss due to disk failures. High availability simply brings redundancy to a new level.

Redundancy increases costs but decreases risk, and so - much like with insurance - the kind of redundancy you need depends on your risk profile.


## Network Level High Availability

High availability at the network level involves switching a virtual IP address between different nodes that run the same service. When a node goes offline, the virtual IP is switched over to another node running the same service. This functionality can also be used to provide load balancing, where the virtual IP address floats between servers during normal operation.

IMAGE

This kind of setup has the advantage of being simple, but it doesn't handle the failing services themselves. The downed service remains down, and must be restarted manually. If all redundant services eventually fail without someone intervening to restart them, the service goes offline completely. As well, this kind of setup has no way to detect misbehaving nodes. If a node is accepting network connections, it must be OK, even if the service inside the node is behaving badly. It's up to the nodes themselves to monitor their own health.

Since the management layer has no knowledge of what's inside the nodes, all services in the nodes must run simultaneously, which causes problems if they need to write to shared resources such as network filesystems. Corruption is likely unless the services or the shared resources are carefully designed to avoid it.


## Service Level High Availability

High availability at the service level is more complicated. The management layer must have knowledge about how to start, stop, and monitor services on nodes. This requires a special management communication channel to the nodes (heartbeat network).

IMAGE

The service interfaces can be via virtual IP or some other mechanism. Nodes can run any number of services. Management can run separately, or via a quorum protocol on the nodes themselves.

Since the management layer knows how to monitor services inside the nodes, it can ensure that at most one copy of a service is running at any given time, which means that they can write to shared resources without fear of corruption. As well, a misbehaving node can be detected and fenced (cut off so that it can do no damage), and then killed/restarted as needed.

[Various node configurations are possible](https://en.wikipedia.org/wiki/High-availability_cluster#Node_configurations)
