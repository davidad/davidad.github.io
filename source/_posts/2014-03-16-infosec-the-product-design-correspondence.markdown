---
layout: post
title: "The Security/Product Design Correspondence"
date: 2014-03-16 09:55:30 -0400
comments: true
categories: InfoSec
---

**General disclaimer for InfoSec articles:** <em>Reading this article does not
qualify you to design secure systems. Writing this article does not qualify
</em>me <em>to design secure systems.  In fact, </em>nobody is qualified to
design secure systems<em>. A system should not be considered secure unless it
has been reviewed by multiple security experts </em>and <em>resisted multiple
serious attempts to violate its security claims in practice. The information
contained in this article is offered "as is" and without warranties of any kind
(express, implied, and statutory), all of which the author expressly disclaims
to the fullest extent permitted by law.</em>

* * *

> If programming is the art of adding functionality to computers, security is
> the art of removing it.

This maxim is a bit unfair to deep and wonderful world of information security
(InfoSec), but it has a point. A lot of essential concepts in InfoSec have
natural opposites in software product design.

Let's start at the top. Every professional software project begins with
specifications. In product design, the specifications are called **use cases**:
stories about an external agent who wants to perform some function, and how they
would go about performing the function using your software. In InfoSec, the
specifications are called **threats**. These are also stories about an external
agent who wants to perform some function, and how would go about performing the
function using your software. The difference is, in product design, you want to
make the agent's job _as easy as possible_, while in InfoSec, you want
to make it as _hard_  as possible. We also have these related correspondences:
<!-- more -->

* **Use case model** &#8660; **Threat model**
* **User** &#8660; **Attacker**
* **User interface** &#8660; **Attack surface**
* **Interaction** &#8660; **Protocol**
* **Affordance** &#8660; **Vulnerability**

In product design, the goal is to address all use cases with a set of
**features**. The correspondence between a use case model and a feature set is
nontrivial, and translating use cases into features is arguably the core of the
product designer's job. Meanwhile in InfoSec, the next step is to address all
threats with a set of **claims**; the correspondence between a threat model and
a set of security claims is nontrivial in the same sense. Both involve many
assumptions about what the user/attacker is willing and able to do, and guesses
about the best way to enable/prevent them from achieving their objectives,
drawing on a lot of experience and patterns observed in the field with both
well-designed and badly-designed products/security systems.

The most common features and most common security claims are also related:

* A **view/display/read** feature, enabling a user to access a record of
  information, is the opposite of a **confidentiality** claim, guaranteeing that
  an attacker cannot access information.
* A **modify/update** feature, enabling a user to edit a record of information,
  is the opposite of an **integrity** claim, guaranteeing that an attacker
  cannot modify information without detection.
* A **create** feautre, enabling a user to add a new record, is the opposite of
  an **authenticity** claim, guaranteeing that an attacker cannot create a new
  record.
* A **delete/remove** feature, enabling a user to destroy a record, is the
  opposite of a **non-repudiation** claim, guaranteeing that an attacker cannot
  credibly deny the existence of information once it is entered into the system.

This correspondence is essentially perfect for confidentiality and integrity;
autheticity and non-repudiation are a little more subtle. Just as any system
which supports both creation and deletion technically supports modification
(since a user can delete a record and then add back a modified version), any
system which provides authenticity and non-repudiation also provides integrity.

One place where InfoSec and product design overlap is **availability**. The
product design version of availability is that a user wishes to access our
system through some communications channel, and it must be able to respond. The
InfoSec version is that an attacker wishes to cause our system to stop
responding to legitimate users (usually, though not always, via [denial of
service](http://en.wikipedia.org/wiki/Denial-of-service_attack) techniques), and
the attacker must be unable to do this.

Availability is commonly listed beside confidentiality and integrity as one of
the "three core goals" of information security, but it is really a different
kind of thing. It's sometimes possible to get all four of the other security
claims listed above simply by careful application of off-the-shelf cryptographic
primitives, but there are no such cryptographic solutions for availability. The
closest thing to a magic availability solution is massive scale, with redundant
nodes all over the planet ready to take up the slack if other nodes stop
responding. (BitTorrent and Bitcoin both fall into this category.) However,
truly high availability requires a dedicated 24x7 staff equipped to respond to
emerging threats. It is probably best to let [someone
else](http://www.cloudflare.com/) handle that.

You may also come across the words **authorization** and **authentication**
connected with some of the above. These are issues without clear product design
correspondences (except insofar as products are designed to provide them in
their InfoSec senses). Like **trust** and **risk**, they also tend to be
intricately tied up in human affairs. These terms, along with the basic
categories of cryptographic primitives, will be treated in future InfoSec
articles.
