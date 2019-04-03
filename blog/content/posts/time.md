---
title: "Time"
date: 2019-03-30T16:09:13+01:00
featuredImage: "thumbnail.jpg"
description: "Time is a tricky beast - quite possibly one of the trickiest things to get right in software engineering. Walk with me on a brief tour of computerized time, and see why we keep getting it wrong."
categories:
  - time
tags:
  - time
---

Time is a tricky beast - quite possibly one of the trickiest things to get right in software engineering. Walk with me on a tour of time, and see why we keep getting it wrong.

There are two levels of time problems: advancing time and storing time. Advancing time deals with the nuances of leap years and leap seconds, and when and how and where you resolve the lost or gained time. Storing time is about how to store time values in an unambiguous way. We've seen plenty of posts about advancing time, so I'm going to focus on storing time in this post.

### Time Zones

Time zones are deceptively simple on the surface. Every zone has a time offset from UTC in hours and minutes. Most people don't think too deeply about them - after all, they're just bands on a globe, right? Why should we care too much? But time zones are not that clean. Even picturing "bands on a globe" leads to the mistaken assumption that zones at the same longitude share the same time. But consider this:

{{< figure src="australia-timezones.png" caption="Australian Time Zones" >}}

Yeah... If anyone knows how to make you chuck a wobbly, it's the Australians. *#thereisaidit* *#johnpickedonthemfirst*


## The Politics of Time

Time zones are not simply a way to keep the sun shining at an appropriate hour; they are political and economic tools, and as such, follow arbitrary and ever-changing rules. A territory at +0100 one year may be +0000 the next year, and I'm not talking about daylight savings time (although that's also a complicated political and economic subject).

Time - at least as humans experience it - is not absolute. Time for us is meaningless without a corresponding location, and cannot even be calculated without it. At 14:00, July 1st, 1939 UTC, it was 15:20 in Amsterdam. Exactly one year later, it was 16:00. Meanwhile, in Kiev, it remained 17:00, but then switched to 16:00 in 1941, and then back to 17:00 in 1943, 17:00 and 18:00 between 1981 and 1990, and it's 16:00 and 17:00 at the moment (but re-read this post in a decade and it may not be).

How often does this happen? [Often enough to give you gray hairs!](https://www.iana.org/time-zones)


## A Time and Place for Everything

Imagine you have a daily workout schedule. Every weekday morning, you do a half hour workout from 7:30 to 8:00. If you took a week-long trip from Seattle to Berlin, that would, in absolute time, become a workout from 13:30 to 14:00. However, being human, you're not concerned with absolute time, and would rather do your workout from 7:30 to 8:00 regardless of where you are. The absolute time changes in this case, and the local time does not.

Now imagine you've got a meeting for 9:00 in Naples on the morning of August 2, 2021. Will the meeting occur at 8:00 UTC? Maybe, maybe not. Europe has voted to end daylight savings in 2021, but has left it up to each member state to decide whether to remain on daylight savings time, or go to standard time, when the changeover occurs. Depending on what Italy decides, the absolute time value of 9:00 in Naples will change. How will this affect your meeting? *When* will your meeting even be?

The issue with future events is that political changes will affect how time is interpreted. For past events, we don't have this problem, as all changes have alreay been resolved. It doesn't matter whether daylight savings time was in effect, or what time offset was in effect; that information is not necessary to determine the **when** of something in the past (although if you wanted to know what time it was locally at the time of the event, you'd of course need the location information).


## Different Times

Since time is both political and circumstantial, we must define multiple kinds of time. [RFC 5545](https://tools.ietf.org/html/rfc5545) defines three main kinds:

* **Absolute Time**: A time value fixed to UTC.
* **Fixed Time**: A time value fixed to a specific time zone.
* **Floating Time**: A time value that is interpreted according to the time zone of the observer.


## Time in a Bottle

With all of these different ways of experiencing time, how do we store it? Ideally, you'd want to store time values in a way such that you don't have to constantly update already stored data. It wouldn't make sense to store floating times as UTC values, because you'd have to update your calendar database every time you changed time zones or went to/from daylight savings time. Different kinds of time have different storage requirements:

* **Absolute time** is always in UTC, and therefore only needs a time value.
* **Floating time** is always relative to your current time zone, and therefore also only needs a time value.
* **Fixed time** is relative to a specific time zone, and must therefore be stored along with that time zone, in values relative to that time zone.

You could in theory store fixed time in UTC, but then you'd need to sweep your database to update your times every time a time zone rule changes.


## Keeping Time

Think carefully about how time affects all observers, and tailor the kind of time to whichever observer is most important to the data being captured. For example:

* *An event in the past*: Absolute time
* *Your daily schedule*: Floating time
* *An appointment*: Fixed time
* *Log entries*: Absolute time
* *Deadlines (local)*: Probably fixed time
* *Deadlines (international)*: Probably absolute time

Remember: Your goal is to store data such that it doesn't need to be updated, because database update sweeps suck, and break, and lose data.


## A Brief Rant About IS0 8601

[ISO 8601](https://www.iso.org/iso-8601-date-and-time-format.html) (and [RFC 3339](https://www.ietf.org/rfc/rfc3339.txt)) is an attempt to standardize a textual representation of time in an unambiguous manner. It mostly succeeds, except for one major problem: It only refers to time zones as numerical offsets. Why is this a problem? *Future events*!

Going back to the 2021 issue, there's a 50% chance that `2021-08-02T09:00:00+0200` will refer to different times in Naples vs Berlin, *because the location portion of the fixed time is missing!* So the "time zone" information of `+0200` doesn't gain you a thing when you're referring to future events. And even if the dev was aware enough to store `Europe/Berlin` along with the time, how confusing would it be if Germany were to choose standard time? Now you'd have a time containing `+0200` that actually refers to a time at `+0100`!

The really annoying part is that a time without a timezone offset specifier is considered by the standard to be in local (floating) time. So you must either break the spec with a special rule that no-offset time refers to a location-based time zone that you promise to accompany all time values (i.e. the time is fixed, not floating), or you must store a confusing value for future events (plus the location-based time zone info if you want any hope of it being resolvable), or even worse, store as UTC and location, and suffer the database update sweep issue.

What we really need is something like `2021-08-02T09:00:00/Europe/Berlin`


## Presenting Time

When presenting data, you're best off using an established time engine rather than writing your own, because you WILL get it wrong. A good time engine is capable of converting any kind of time to any other kind. So long as you keep the kinds straight in your head, you'll be able to present time values to your users in a sane, meaningful way.


## Time Keeps on Slipping

Dealing with time is no simple task. From Y2K to leap year failures to internationalization gaffes, time - and its storage - is a source of more bugs than possibly any other data type. So the next time someone says "Easy! Just store it as UTC!", be sure to take them quietly aside, take a firm hold, and dunk their head in a nearby toilet.
