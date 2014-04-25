---
layout: post
title: "An OSI layer model for the 21st century"
date: 2014-04-24 17:48:03 -0400
comments: true
categories: 
---

The Internet protocol suite is wonderful, but it was designed before the advent
of modern cryptography and without the benefit of hindsight. On the modern
Internet, cryptography is typically squeezed into a single, incredibly complex
layer, Transport Layer Security (TLS; formerly known as Secure Sockets Layer, or
SSL). Over the last few months, 3 entirely unrelated (but equally catastrophic)
bugs have been uncovered in 3 independent TLS implementations ([Apple
SSL/TLS](https://www.imperialviolet.org/2014/02/22/applebug.html),
[GnuTLS](http://arstechnica.com/security/2014/03/critical-crypto-bug-leaves-linux-hundreds-of-apps-open-to-eavesdropping/),
and most recently [OpenSSL](http://heartbleed.com), which powers most "secure"
servers on the Internet), making the TLS system difficult to trust in practice.

What if cryptographic functions were spread out into more layers? Would the
stack of layers become too tall, inefficient, and hard to debug, making the
problem worse instead of better? On the contrary, I propose that appropriate
cryptographic protocols could replace most existing layers, improving security
as well as other functions generally not thought of as cryptographic, such as
concurrency control of complex data structures, lookup or discovery of services
and data, and decentralized passwordless login.  Perhaps most importantly, the
new architecture would enable individuals to internetwork as peers rather than
as tenants of the telecommunications oligopoly, putting net neutrality directly
in the hands of citizens and potentially enabling a drastically more competitive
bandwidth market.

<style>
td, th {
text-align: center;
}
b {
font-weight: bold;
}
table tr td i {
font-style: italic;
}
thead {
border-bottom: 1px black solid;
}
td.common {
background-color: #e8f87e;
}
td.practice {
background-color: #ffda88;
}
td.phy {
background-color: #d8f0fe;
}
td.new {
background-color: #d0ee9a;
font-weight: bold;
}
td {
border-bottom: 1px solid rgba(150,150,150,0.2);
}
</style>
</style>
<table>
  <thead>
  <tr>
  <th width=40></th><th width=200>Current [OSI model](http://en.wikipedia.org/wiki/OSI_model)</th><th width=180>In
  practice</th> <th width=200>Proposed update</th>
  </tr>
  </thead>
  <tbody>
  <tr><td>8</td><td><i>(none)</i>                  </td><td class="common">Application</td><td class="common">[Application](/blog/2014/04/24/an-osi-layer-model-for-the-21st-century/#Application)</td></tr>
  <tr><td>7</td><td class="common">"[Application](http://en.wikipedia.org/wiki/Application_layer)"</td><td class="practice">[HTTP](http://en.wikipedia.org/wiki/Hypertext_Transfer_Protocol)</td><td class="new">[Transactions](/blog/2014/04/24/an-osi-layer-model-for-the-21st-century/#Transactions)</td></tr>
  <tr><td>6</td><td class="common">[Presentation](http://en.wikipedia.org/wiki/Presentation_layer)</td><td class="practice">[SSL/TLS](http://en.wikipedia.org/wiki/Transport_Layer_Security)</td><td class="new">[(Non-)Repudiation](/blog/2014/04/24/an-osi-layer-model-for-the-21st-century/#Non-Repudiation)</td></tr>
  <tr><td>5</td><td class="common">[Session](http://en.wikipedia.org/wiki/Session_layer)</td><td class="practice" rowspan="2">[TCP](http://en.wikipedia.org/wiki/Transmission_Control_Protocol)</td><td class="new">[Confidentiality](/blog/2014/04/24/an-osi-layer-model-for-the-21st-century/#Confidentiality)</td></tr>
  <tr><td>4</td><td class="common">[Transport](http://en.wikipedia.org/wiki/Transport_layer)</td>                                                                          <td class="new">[Availability](/blog/2014/04/24/an-osi-layer-model-for-the-21st-century/#Availability)</td></tr>
  <tr><td>3</td><td class="common">[Network](http://en.wikipedia.org/wiki/Network_layer)</td><td class="practice">[IP](http://en.wikipedia.org/wiki/Internet_Protocol)</td><td class="new">[Integrity](/blog/2014/04/24/an-osi-layer-model-for-the-21st-century/#Integrity)</td></tr>
  <tr><td>2</td><td class="common">[Data Link](http://en.wikipedia.org/wiki/Data_link_layer)</td>
  <td class="phy" rowspan="2"><a href="http://en.wikipedia.org/wiki/E-UTRA">e-UTRA</a> (LTE),
  <a href="http://en.wikipedia.org/wiki/IEEE_802.11">802.11</a> (WiFi),
  <a href="http://en.wikipedia.org/wiki/IEEE_802.3">802.3</a> (Ethernet), <i>etc.</i>
  </td>
  <td class="common">Data Link</td></tr>
  <tr><td>1</td><td class="common">[Physical](http://en.wikipedia.org/wiki/Physical_layer)</td><td class="common">Physical</td></tr>
  </tbody>
</table>
<br/>

 Of course, the layers I propose will doubtless introduce new problems of their
 own, but I'd like to start this conversation with some concrete ideas, even
 if I don't have a final answer. (Please feel free to <a
 href="http://mailhide.recaptcha.net/d?k=01A3Grt9OhKg2-MSZSi6YDVA==&c=YXdAjPYO-xwh0WDnMu37kmOqfzUGcLhwkXoLkHdM6NA=">email</a>
 me your comments or tweet <a href="http://twitter.com/davidad">@davidad</a>.)

 Descriptions follow for each of the five new layers I suggest, four of which
 are named after common [information security
 requirements](http://en.wikipedia.org/wiki/Security_testing), and one of which
 ([Transactions](/blog/2014/04/24/an-osi-layer-model-for-the-21st-century/#Transactions))
 is borrowed from [database requirements](http://en.wikipedia.org/wiki/ACID)
 (and also vaguely suggestive of cryptocurrency).

<!-- more -->

* * *

**General disclaimer for InfoSec articles:** <em>Reading this article does not
qualify you to design secure systems. Writing this article does not qualify
</em>me <em>to design secure systems.  In fact, </em>nobody is qualified to
design secure systems<em>. A system should not be considered secure unless it
has been reviewed by multiple security experts </em>and <em>resisted multiple
serious attempts to violate its security claims in practice. The information
contained in this article is offered "as is" and without warranties of any kind
(express, implied, and statutory), all of which the author expressly disclaims
to the fullest extent permitted by law.</em>

## Data Link and Physical layers

For our purposes today, the Data Link and Physical layers are a black box
(perhaps literally), to which we have an interface (the "network interface")
which looks like a transmit queue and a receive queue.  These queues can store
"payloads" of anywhere from 1 to 1280[^1]
[octets](http://en.wikipedia.org/wiki/Octet_(computing)) (bytes). The next layer
in the stack can push a payload onto the Data Link transmit queue (and possibly
get an error if it's full) and can pop a payload from the Data Link receive
queue (and possibly get an error if it's empty). The Data Link layer is
responsible for (eventually) flushing the transmit queue, and any payload which
leaves the transmit queue must appear on the receive queues of all <i>other</i>
devices connected to the same
[channel](http://en.wikipedia.org/wiki/Channel_(communications)) (a technical
term, which may refer to a radio channel in the case of cellular devices, or
simply to a particular length of cable in a point-to-point wired connection).

[^1]: This number is cribbed from the [IPv6 RFC](http://tools.ietf.org/html/rfc2460).

<a name="Integrity"></a>
## Integrity layer

We would like a received payload to self-evidently be the same payload which was
sent. Although the Data Link layer is supposed to provide such an assurance,
various kinds of attacks on the system might invalidate this assumption.
Integrity protocols mitigate these attacks:

<p>
<table>
<thead>
  <tr><th width=60>Paranoia Level</th><th width=240>Attacks</th><th width=180>Mitigation</th><th width=150>Common Implementation</th><th width=180>My Preferred Implemenation</th></tr>
</thead>
<tbody>
  <tr><td>1</td><td>Thermal noise, cosmic rays</td><td>checksum hash</td><td>[TCP Checksum](http://en.wikipedia.org/wiki/Transmission_Control_Protocol#Checksum_computation)</td><td>[CRC-32C](http://www.strchr.com/crc32_popcnt)</td></tr>
  <tr><td>2</td><td>Deliberate corruption</td><td>cryptographic hash</td><td>[SHA-1](http://en.wikipedia.org/wiki/SHA-1)</td><td>[BLAKE2b](https://blake2.net/)</td></tr>
  <tr><td>3</td><td>Spoofing of trusted contacts</td><td>keyed hash</td><td>[HMAC-SHA1](http://en.wikipedia.org/wiki/Hash-based_message_authentication_code)</td><td>[SipHash](https://131002.net/siphash/siphash.pdf)</td></tr>
  <tr><td>4</td><td>Spoofing of strangers</td><td>public-key signature of cryptographic hash</td><td>[SHA-1](http://en.wikipedia.org/wiki/SHA-1) + [RSA](http://en.wikipedia.org/wiki/RSA_(cryptosystem))</td><td>[BLAKE2b](https://blake2.net/) + [Ed25519](http://ed25519.cr.yp.to/index.html)</td></tr>
</tbody>
</table>
</p>

Integrity protocols are fairly simple: the appropriate verification material is
placed at the beginning of every Data Link payload. The Integrity layer exposes
the same kind of "transmit queue and receive queue" interface as the Data Link
layer, but the payload which can be passed to the Integrity layer must be
somewhat smaller, so that there is room for the verification material and the
Integrity payload together to fit into 1280 octets. Overhead ranges from 4
octets for a CRC-32C checksum to 96 octets for an Ed25519 signature.

In the keyed hash case, some state is necessary at the Integrity protocol level:
each API customer must be able to add "trusted contacts" to its "address book"
by specifying a symmetric key correpsonding to a given endpoint name (which may
have been negotiated at a higher protocol level, or simply out-of-band
entirely). Since some advanced higher-level protocols may define symmetric
authentication keys that are only good for a single use (e.g. [Axolotl
ratcheting](https://github.com/trevp/axolotl/wiki) after the handshake phase),
"address book entries" should be single-use by default, with renewal explicitly
required after each payload received from a given contact.


<a name="Availability"></a>
## Availability layer

We would like networked endpoints to be available to receive packets from other
endpoints in a way that is robust to unannounced changes in network topology.
This layer conceptually takes the place of the
[Network](http://en.wikipedia.org/wiki/Network_layer) layer in the original
model, as it will be responsible for routing packets.  <b>Significantly, in this
proposal, there are no "hosts" or "ports": only "endpoints", identified by
public keys.</b> This is simply taking the [end-to-end
principle](http://en.wikipedia.org/wiki/End-to-end_principle) one step further,
by considering the "host" merely part of the network infrastructure which
makes applications available. 

A fully implemented Availability layer should provide
[unicast](http://en.wikipedia.org/wiki/Unicast) (deliver to a unique endpoint
authenticated by a given public key, wherever it may be),
[anycast](http://en.wikipedia.org/wiki/Anycast) (deliver to nearest endpoint
authenaticated by a given public key), and
[multicast](http://en.wikipedia.org/wiki/Multicast) (<i>a.k.a.</i>
[pub/sub](http://en.wikipedia.org/wiki/Publish%E2%80%93subscribe_pattern): route
to all endpoints who have asked to subscribe to a given ID, and provide a
subscription method).

<p>
<table>
<thead>
  <tr><th width=80 rowspan="2">Routing Semantics</th><th width=170 rowspan="2">Current Reliability</th><th colspan="2" style="border-bottom: 1px solid rgba(150,150,150,0.4)">New Implemenation</th></tr>
  <tr><th width=260>Overlay on existing Internet</th><th width=280>Native Mesh</th></tr>
</thead>
<tbody>
  <tr><td>Multicast</td><td>awful</td><td>[S/Kademlia](http://www.researchgate.net/publication/4319659_SKademlia_A_practicable_approach_towards_secure_key-based_routing/file/72e7e524ad3e97d67d.pdf) message broker</td><td>Straightforward extension of unicast</td></tr>
  <tr><td>Anycast</td><td>decent</td><td>No advantage over load balancers</td><td>Possible extension of unicast</td></tr>
  <tr><td>Unicast</td><td>excellent</td><td>Special case of multicast</td><td>[Electric Routing](http://arxiv.org/pdf/0909.2859v1.pdf)</td></tr>
</tbody>
</table>
</p>

I believe the <a href="http://arxiv.org/pdf/0909.2859v1.pdf">Electric
Routing</a> algorithm[^2] is up to the challenge of replacing unicast[^3], and
that it could be extended to provide multicast and even anycast, but other
algorithms could be developed at this protocol layer as well. The first
real-world implementation of the system I'm describing will very likely be
developed as an overlay network on top of
[IP](http://en.wikipedia.org/wiki/Internet_Protocol), in which case multicast
can be implemented simply atop
[S/Kademlia](http://www.researchgate.net/publication/4319659_SKademlia_A_practicable_approach_towards_secure_key-based_routing/file/72e7e524ad3e97d67d.pdf),
with unicast as a special case, and anycast can be emulated with standard
load-balancing techniques.


[^2]: coauthored by [Petar Maymounkov](http://www.maymounkov.org/), who also
coauthored [Kademlia](http://en.wikipedia.org/wiki/Kademlia), the
[DHT](http://en.wikipedia.org/wiki/Distributed_hash_table) powering
[BitTorrent](http://en.wikipedia.org/wiki/BitTorrent_(protocol))
[^3]: Electric routing does need some extensions to mitigate various attacks, but I believe the
countermeasures from
[S/Kademlia](http://www.researchgate.net/publication/4319659_SKademlia_A_practicable_approach_towards_secure_key-based_routing/file/72e7e524ad3e97d67d.pdf)
are readily adapted to meet these needs.

The tradeoff here is that routers have a lot more work to do, since there are no
"addresses" corresponding directly to geographic location. But, it means that
every node on the network can participate as a router, so there is a lot more
capacity to do that work. In addition, the endpoints-only scheme has many
potentially desirable properties with respect to features like pseudonymity, NAT
transparency, redundancy, and decentralization of the telecommunications market
(especially in densely settled areas).

<a name="Confidentiality"></a>
## Confidentiality layer

Ideally, we would like to not transmit any information to anything other than
the destination endpoint(s). This ideal is not in general achievable on a public
network, but some types of mitigation are possible:

<p>
<table>
<thead>
  <tr><th width=60>Paranoia Level</th><th width=240>Attacks</th><th width=180>Mitigation</th><th width=150>Common Implementation</th><th width=180>My Preferred Implemenation</th></tr>
</thead>
<tbody>
  <tr><td>1</td><td>Sniffing payloads to trusted contacts</td><td>[symmetric](http://en.wikipedia.org/wiki/Symmetric-key_algorithm) encryption</td><td>[AES](http://en.wikipedia.org/wiki/Advanced_Encryption_Standard)</td><td>[ChaCha](http://cr.yp.to/chacha.html)</td></tr>
  <tr><td>2</td><td>Sniffing payloads to strangers</td><td>[public-key](http://en.wikipedia.org/wiki/Public-key_cryptography) encryption</td><td>[RSA](http://en.wikipedia.org/wiki/RSA_(algorithm))</td><td>[RSA](http://en.wikipedia.org/wiki/RSA_(algorithm))</td></tr>
  <tr><td>3</td><td>Chosen plaintext attacks</td><td>[key agreement](http://en.wikipedia.org/wiki/Key-agreement_protocol) + symmetric encryption</td><td>[ECDH](http://en.wikipedia.org/wiki/Elliptic_Curve_Diffie%E2%80%93Hellman) + [AES](http://en.wikipedia.org/wiki/Advanced_Encryption_Standard)</td><td>[Curve25519](http://cr.yp.to/ecdh.html) + [ChaCha](http://cr.yp.to/chacha.html)</td></tr>
  <tr><td>4</td><td>Key compromise</td><td>ephemeral key agreement + symmetric encryption</td><td>[ECDHE](http://vincent.bernat.im/en/blog/2011-ssl-perfect-forward-secrecy.html) + [AES](http://en.wikipedia.org/wiki/Advanced_Encryption_Standard)</td><td>[Axolotl ratchet](https://github.com/trevp/axolotl/wiki) with [Curve25519](http://cr.yp.to/ecdh.html), [SipHash](https://131002.net/siphash/siphash.pdf), [PBKDF2](http://en.wikipedia.org/wiki/PBKDF2), [ChaCha](http://cr.yp.to/chacha.html)</td></tr>
</tbody>
</table>
</p>

In cases 3 and 4, this layer has to maintain some state, holding session keys or
message keys, and the Axolotl ratchet is a little complicated; but this layer
does not have to worry about the verification of identity (which will be
provided on a higher layer) or integrity (which will be provided by a lower
layer).

<a name="Non-Repudiation"></a>
##Non-Repudiation and/or Repudiation layer

We would like for a receiver to be sure that a message they receive was sent by
a given sender, and we would like for a sender to be sure that a given message
was successfully received. Sometimes, we would also like for a receiver to be
unaware of the location a message was sent from. The result is three related but
orthogonal protocol types, which may be nested:

<p>
<table>
<thead>
  <tr><th width=180>Repudiation Property</th><th width=200>Meaning</th><th width=300>Protocol</th></tr>
</thead>
<tbody>
  <tr><td>Non-Repudiation of Sending</td><td>Recipient knows immediate sender</td><td>Sender includes a hash of their public key in the message. To understand why this is necessary given the Integrity layer, read [this excellent article](http://world.std.com/~dtd/sign_encrypt/sign_encrypt7.html)</td></tr>
  <tr><td>Non-Repudiation of Receipt</td><td>Sender knows message was received</td><td>Recipient must send a signed acknowledgement for every message. This also implements "reliable delivery"</td></tr>
  <tr><td>Repudiation of Origin</td><td>Message is difficult to trace</td><td>[Onion Routing](http://en.wikipedia.org/wiki/Onion_routing)</td></tr>
</tbody>
</table>
</p>


<a name="Transactions"></a>
## Transactions layer

We would like for sets of nodes which wish to maintain common mutable state
variables to be able to do so, even in the presence of various types of
adversaries. This is a common abstraction for the requirements of `git`,
cryptocrurencies, and distributed databases (i.e.
[ACID](http://en.wikipedia.org/wiki/ACID)
[MVCC](http://en.wikipedia.org/wiki/Multiversion_concurrency_control)). I
propose that (borrowing most directly from `git`, but also from Clojure's
concurrent data structures) changes in large or complex mutable states be
represented as changes to the root of a [Merkle
tree](http://en.wikipedia.org/wiki/Merkle_tree), thus reducing the state
subject to transactional semantics to single-packet size[^4].

To make it obvious what I'm intending to refer to, the owner of a particular
"domain name" or a particular "coin" (or, generally, any cryptographically
controlled resource) is an example of a mutable state. But so is, for instance,
the contents of any social media profile, email inbox, hypertext page, or source
code repository. These things could all be managed without reference to central
authorities or single points of failure.

<p>
<table>
<thead>
  <tr><th width=60>Paranoia Level</th><th width=340>Attacks</th><th width=380>Mitigation</th></tr>
</thead>
<tbody>
  <tr><td>1</td><td>Asynchrony; node failure/disconnection</td><td>[D1HT](http://www.cos.ufrj.br/~monnerat/papers/Monnerat_et_Amorim_D1HT_2006.pdf) tracker</td></tr>
  <tr><td>2</td><td>Sybil attacks; eclipse attacks; churn attacks</td><td>[S/Kademlia](http://www.researchgate.net/publication/4319659_SKademlia_A_practicable_approach_towards_secure_key-based_routing/file/72e7e524ad3e97d67d.pdf) tracker</td></tr>
  <tr><td>3</td><td>Malicious trackers</td><td>[Leaderless Byzantine Paxos](http://research.microsoft.com/en-us/um/people/lamport/pubs/disc-leaderless-web.pdf) or [Byzantine gossip](http://link.springer.com/article/10.1007%2Fs10796-013-9460-7#page-1)</td></tr>
  <tr><td>4</td><td>Any attack that Bitcoin can survive</td><td>[Block-chain](https://en.bitcoin.it/wiki/Block_chain) protocol</td></tr>
</tbody>
</table>
</p>

Many (including myself) have claimed that the core contribution of Bitcoin, the
block-chain protocol, is a novel solution to the [Byzantine Generals
Problem](http://research.microsoft.com/en-us/um/people/lamport/pubs/byz.pdf),
but it turns out this is somewhat misleading. Although the block-chain protocol
is Byzantine-fault-tolerant in a novel way, there has been plenty of research on
Byzantine protocols over the years, and it seems probably unnecessary to constantly
"mine," i.e. solve cryptopuzzles, to achieve Byzantine fault tolerance. The main
reason to introduce cryptopuzzles is to reduce the efficacy of [Sybil
attacks](http://en.wikipedia.org/wiki/Sybil_attack), in which one malicious
actor fabricates arbitrarily many identities in order to exceed the Byzantine
fault tolerance threshhold and control the system. However, these attacks can
also be mitigated by requiring crypto-puzzles only for joining the network (as
in
[S/Kademlia](http://www.researchgate.net/publication/4319659_SKademlia_A_practicable_approach_towards_secure_key-based_routing/file/72e7e524ad3e97d67d.pdf)),
and by blacklisting nodes which behave suspiciously (the latter being how most
attacks on Bitcoin are stopped in practice).

<a name="Application"></a>
## Application layer

In such an environment, applications (or application components!) are
essentially just maps from one mutable state to another, in [functional reactive
programming](http://elm-lang.org/learn/What-is-FRP.elm) style. In the same way
that you might encode packet filters into a kernel's TCP/IP stack today, you
might encode entire applications into a kernel's "mesh" stack in the future.
Various search functions, including full-text search, could be provided using
the [OneSwarm](http://www.michaelpiatek.com/papers/oneswarm_SIGCOMM.pdf)
approach or potentially by distributed [Bloom
filters](http://en.wikipedia.org/wiki/Bloom_filter) implemented atop this
platform (an idea due to [Andrée Monette](https://twitter.com/AndreeMonette)).
Resource control and access control can be provided by means of [cryptographic
capabilities](http://www.erights.org/elib/capability/ode/ode-protocol.html).

But, in general, this layer is completely open for all sorts of applications.
Essentially, any end-user service that runs on a network (and what doesn't,
these days?) would fit here.

# Conclusion

I've outlined some radical ideas for how to re-build the Internet protocol stack
in a way that is ultimately more coherent with Internet cultural values (freedom
of expression, pseudonymity, reduced potential for abuses of power). This
outline still needs quite a bit of work and thought before being turned into
implementations, but I feel like I've reached a turning point in making my
[ideas](http://mesh.is/confusing,ok?) about next-generation architectures
concrete, and at a timely moment with respect to conversations about TLS and net
neutrality. If you would like to see these concepts made into working code,
please <a
href="http://mailhide.recaptcha.net/d?k=01A3Grt9OhKg2-MSZSi6YDVA==&c=YXdAjPYO-xwh0WDnMu37kmOqfzUGcLhwkXoLkHdM6NA=">reach
out</a> and let me know.

[^4]: This is similar in principle to the trick used by most practical
public-key cryptosystems, which use the actual public-key algorithm only to
encrypt a key from some symmetric cryptosystem, and then encrypt arbitrarily
large content using a stream cipher. The common principle is that you can do the
hard security algorithm on a small piece of data, and use easier security
algorithms to apply those hard secrutiy properties to large chunks of data.
