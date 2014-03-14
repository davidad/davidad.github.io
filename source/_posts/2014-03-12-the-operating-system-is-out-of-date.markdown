---
layout: post
title: "Systems Past: the only 8 software innovations we actually use"
date: 2014-03-12 19:21:49 -0400
comments: true
categories: 
---
_Note: This is a position piece, not a technical article. Hat tip to [Jake
Skelcy](https://twitter.com/_JacobJacob) for requesting such a piece._

Computers didn't always have operating systems. The earliest machines, like the
[Harvard Mark I](http://en.wikipedia.org/wiki/Harvard_Mark_I) and the
[EDVAC](http://en.wikipedia.org/wiki/EDVAC), performed one "computation" at a
time. Whenever a computation finished, with its output printed by a
teletypewriter or recorded on a magnetic tape, the machine would shut down. A
person would then have to notice the machine stopped, unload the output, set up
a new computation by manually loading the input and program instructions, and
finally, press the **start button** to get the machine cranking again. On the
Harvard Mark I, for instance, restarting would involve separately turning on
multiple electric motors and then pressing a button marked MAIN SEQUENCE.

[![The control panel of the Harvard Mark
I.](http://upload.wikimedia.org/wikipedia/commons/0/07/Harvard_Mark_I_Computer_-_Input-Output_Details.jpg)](http://commons.wikimedia.org/wiki/File:Harvard_Mark_I_Computer_-_Input-Output_Details.jpg) 


**This is the context in which the programming language (PL) and the operating
system (OS) were invented. The year was 1955. Almost everything since then has
been window dressing** (so to speak). In this essay, I'm going to tell you my
perspective on the PL and the OS, and the six other things since then which I
consider significant improvements, which have made it into software practice,
and which are neither algorithms nor data structures (but rather system
concepts). Despite those and other incremental changes, to this day[^1], we work
exclusively[^2] within software environments which can definitely be considered
programming languages and operating systems, in exactly the same sense as those
phrases were used almost 60 years ago. My position is:

* Frankly, this is backward, and we ought to admit it.
* Most of this stuff was invented by people who had a lot less knowledge and
  experience with computing than we have accumulated today. **All** of it was
  **invented by people**: mortal, fallible humans like you and me who were
  just trying to make something work. With a solid historical perspective we can
  dare to do better.
<!-- more -->

<a name="The-Programming-Language"></a>
## 1. The Programming Language <a href="#The-Programming-Language">#</a>

**Year**: 1955

### Archetype
Every programming language used today is descended from
[FORTRAN](http://en.wikipedia.org/wiki/Fortran#History)[^3]. FORTRAN is an
abbreviation of FORmula TRANslator, and its mission was to translate typewritten
algebraic formulae into executable code.

### Motivation

Most uses of computers involved numerical calculations, which would be
translated from equation form into machine code by hand (naturally, a
time-consuming process). Multiple people (including [Grace
Hopper](http://en.wikipedia.org/wiki/Grace_Hopper), [John
Backus](http://en.wikipedia.org/wiki/John_Backus), and [Alick
Glennie](http://en.wikipedia.org/wiki/Alick_Glennie)) realized that the computer
could be used to automate such translations, and the result was the programming
language. 

### Concept
**A programming language is a piece of software that automatically translates a
specially formatted block of linear text into executable code.**

It is bizarre that we're still expressing programs entirely with text 59 years
later when the first interactive graphical display appeared _4_ years later[^5].

### Benefits
The existence of programming languages enabled the use of concise notation for
complex ideas, also known as **abstraction**. This not only saves time, but
also makes programs easier to understand and maintain.

### Exemplars

* [Lisp](http://en.wikipedia.org/wiki/Lisp_(programming_language\))
* [Forth](http://en.wikipedia.org/wiki/Forth_(programming_language\))
* [C](http://en.wikipedia.org/wiki/C_(programming_language\))

### Drawbacks
* FORTRAN's conflation of functions (an algebraic concept) and subroutines (a
  programming construct) persists to this day in nearly every piece of
  software, and causes no end of problems.
  [Tracing
  compilers](http://en.wikipedia.org/wiki/Tracing_just-in-time_compilation)
  scratch the surface of reversing this mistake, but so far I know of no
  programming languages that are specifically designed around such a mechanism.
* The fact that inputs had to be loaded into computers as stacks of punched
  cards limited the possible means of expressing computations -- lines of text.

<a name="The-Operating-System"></a>
## 2. The Operating System <a href="#The-Operating-System">#</a>

**Year**: 1955

### Archetype

The [General Motors/North American Aviation
Monitor](http://www.rand.org/content/dam/rand/pubs/papers/2008/P7316.pdf) was
arguably the "original" OS. 

### Motivation

> The typical mode of operation was programmer present and at the operating
> console. When a programmer got ready for a test, he or she signed up on a
> first-in, first-out list, much like the list at a crowded restaurant. The
> programmer then checked progress frequently to estimate when he would reach
> the top. When his time got close, he stood by with card deck in hand. When the
> previous person finished or ran out of allotted time or abruptly crashed, the
> next programmer rushed in, checked the proper board was installed in the card
> reader, checked that the proper board was installed in the printer, checked
> that the proper board was installed on the punch, hung a magnetic tape,
> punched in on a mechanical time clock, addressed the console, set the
> appropriate switches, loaded his punched card deck in the card reader, prayed
> the first card would not jam, and pressed the LOAD button to invoke the
> bootstrap sequence.
> 
> If all went well, you could load a typical deck of about 300 cards and begin
> the execution of your first instruction about 5 minutes after entering
> the room. If only one person did all this set up and got going in 5 minutes,
> he bustled around the machine like a whirling dervish [sic]. Not always did
> things go so smoothly. If a programmer was fumble-fingered, cards jammed,
> magnetic tapes would not read due to defective splices, printer boards or
> switches were incorrectly set up, and it took 10 minutes to get going; or
> worse -- you lost your opportunity and the next guy took the machine when your
> time ran out. Usually the machine spent more time idle than computing. We
> programmers weren't paid very much and although the machine was fairly costly,
> its capacity was even a more precious commodity since there were only 17 in
> the whole world.

### Concept

**An operating system is a piece of software that facilitates the execution of
multiple independent programs on one computer, using standard input and output
routines.**

There's a deep connection between the OS concept and the PL concept: the OS
facilitates the execution of independent programs, while the PL facilitates the
execution of independent modules or subroutines. In fact, GM/NAA OS was
[literally](http://millosh.wordpress.com/2007/09/07/the-worlds-first-computer-operating-system-implemented-at-general-motors-research-labs-in-warren-michigan-in-1955/)
a modification of the octal code of the FORTRAN compiler tape.

The bizzareness about operating systems is that we still accept unquestioningly
that it's a good idea to run multiple programs on a single computer with the
conceit that they're totally independent. Well-specified interfaces are great
_semantically_ for maintainability. But when it comes to what the machine is
_actually doing_, why not just run one ordinary program and teach it new
functions over time? Why persist for 50 years the fiction that every distinct
function performed by a computer executes independently in its own little barren
environment?

### Benefits

* Multiple programs could be run in a "batch," thus keeping the machine from
  ever being idle (except in case of hardware failure or an empty job queue).
* Programmers could now use standard input and output routines. (Depending on
  the formatting requirements and particular peripherals in use, properly
  handling input and output could previously have consumed most of the
  programming effort for simple jobs.)
* Bare-hands reconfiguration of hardware (e.g. plugboards) finally disappeared
  from the work of programming.

### Exemplars

* [CP/M](http://en.wikipedia.org/wiki/CP/M)
* [ProDOS](http://en.wikipedia.org/wiki/ProDOS)

### Drawbacks

* Programs expect to use the entire machine, because that's how
  programs were run previously and that's what the programmers were used to. The
  operating system must therefore isolate programs from each other (in the
  simplest/earliest cases, by running each job to completion or termination
  before loading the next).

<a name="Interactivity"></a>
## 3. Interactivity <a href="#Interactivity">#</a>

**Year**: 1958

### Archetype

The [TX-0](http://en.wikipedia.org/wiki/TX-0) machine, one of the first
transistorized computers, was installed at MIT in summer of 1958. The TX-0 had a
monitor (a 512x512 CRT display), a keyboard, and a pointing device (a [light
pen](http://en.wikipedia.org/wiki/Light_pen)), making it probably the first
computer with [a physical interface that we might recognize
today](http://youtu.be/ieuV0A01--c?t=2m41s). It also happens to be the machine
which spawned [hacker
culture](http://en.wikipedia.org/wiki/Hackers:_Heroes_of_the_Computer_Revolution#Part_One:_True_Hackers).

### Motivation

The TX-0 was a scaled-down (transistorized) offshoot of an Air Force project
called [SAGE](http://en.wikipedia.org/wiki/Semi-Automatic_Ground_Environment),
with the ambitious goal of an electronic, automated, networked missile defense
and early warning radar system.  The development of interactive display
computing had three main causes in this context:

* it was a natural successor to the analog [radar display](http://en.wikipedia.org/wiki/Radar_display)
* the on-line nature of the task demanded real-time human interaction
* the importance of the task meant that funding was no object, so an entire
  computer (in fact, the largest and most expensive computer system ever made)
  could be "wasted" on providing such interactivity

Because of its transistorized circuitry, the TX-0 needed very little
maintenance or oversight, and for years was left unattended at MIT for pretty
much anybody to use at any time, resulting in a great flourishing of interactive
programs (many of whose names began with the word "Expensive," in an
acknowledgment of the absurdity of a $3M machine being available for such
experimentation).

### Concept

**An interactive program is one which consumes input after producing output.**
Prior to SAGE, once a program produced its output, it was done, and the machine
would halt or move on to the next job. What distinguishes an interactive system
is that it will produce some output and then _wait_ until more input is
available.

### Benefits

* It became possible to do creative work at a computer.

### Exemplars

* [Sketchpad](http://en.wikipedia.org/wiki/Sketchpad)
* [VisiCalc](http://en.wikipedia.org/wiki/VisiCalc)
* [Emacs](http://en.wikipedia.org/wiki/GNU_Emacs)

### Drawbacks

* "Waiting" is poorly specified. If a program is waiting for one kind of
  input, what if a different kind of input arrives instead? It will fail to
  respond until the kind of input it was expecting appears. This problem
  continues to crop up in graphics programming, network programming, and other
  areas. 

<a name="Transactions"></a>
## 4. Transactions <a href="#Transactions">#</a>

**Year**: 1959

### Archetype

Before computerization, American Airlines' booking process was labor-intensive
and slow.  IBM realized that the basic idea behind SAGE could be applied to
solve the airline reservation problem, resulting in
[SABRE](http://en.wikipedia.org/wiki/Sabre_(computer_system\)#History). The core
of the SABRE operating system later became known as TPF (Transaction Processing
Facility).

### Motivation

American wanted a system with 1,500 booking terminals across the US and Canada
all linked by modem to a central reservations computer. But what if two
terminals try to book the last seat on a flight at the same moment? A system
like this needs strong guarantees on consistency.

### Concept

**Transactions are operations each guaranteed either to fail without any effect,
or to run in a definite, strict order.** Lots of terminals may attempt to input
transactions, but every terminal must observe the same consistent state of the
system, including a global [transaction
log](http://en.wikipedia.org/wiki/Transaction_log) listing each transaction in
the precise order in which it was applied.

### Benefits

* This one core idea enabled the development of systems called **databases**,
  which can reliably maintain the state of complex data structures across
  incessant read and write operations as well as some level of hardware
  failures.
* Modern **filesystems** are "journaled", which means that they implement
  transactions.
* Transactions are also the key idea behind **version control systems**, which are
  increasingly adopted in all corners of the software world. In that context,
  they are called "commits".
* Most recently, the core of crypto-currencies is a crude but clever solution to
  a distributed transaction processing problem. (In this context, transactions
  are in fact called transactions.)

### Exemplars

* [Ingres](http://en.wikipedia.org/wiki/Ingres_(database\))
* [ZFS](http://en.wikipedia.org/wiki/ZFS)
* [git](http://en.wikipedia.org/wiki/Git_(software\))
* [ethereum](https://github.com/ethereum/wiki/wiki/%5BEnglish%5D-White-Paper#wiki-basic-building-blocks)

### Drawbacks

None.

<a name="Garbage-Collection"></a>
## 5. Garbage Collection <a href="#Garbage-Collection">#</a>

**Year**: 1960

### Archetype

All garbage-collected environments owe a debt [to
Lisp](http://www-formal.stanford.edu/jmc/recursive/node4.html), the first to
provide such a facility.

### Motivation

Previously, programs required the manual management of the memory resource; the
programmer had to anticipate when the program would need access to more memory,
and ensure that the program wouldn't consume all the memory on the machine by
not re-using memory locations that hold no-longer-needed data.

### Concept

**A garbage collector (GC) is a piece of software which maintains a data
structure representing available memory, and marks a given memory location as
available whenever it is no longer being referred to.**

### Benefits

* The programmer doesn't have to think about allocating and deallocating memory
  in order to make a working program.

### Exemplars

* [Genera](http://en.wikipedia.org/wiki/Genera_(operating_system\))
* [LuaJIT](http://wiki.luajit.org/New-Garbage-Collector)

### Drawbacks

* Performance becomes unpredictable due to variable GC pause times.
* Memory usage becomes unpredictable due to variable GC effectiveness and
  potential reference leaks.

<a name="Virtualization"></a>
## 6. Virtualization <a href="#Virtualization">#</a>

**Year**: 1961

### Archetype

The [Atlas
Supervisor](http://www.computer.org/csdl/proceedings/afips/1961/5059/00/50590279.pdf),
developed at the University of Manchester in 1961, has been called "the first
recognizable modern operating system" and "the most significant breakthrough in
the history of operating systems"[^4].

### Motivation

System builders wanted the capability to run multiple programs at once, mostly
for the following reason:

> Whilst one program is halted, awaiting completion of a magnetic tape
> transfer for instance, the coordinator routine switches control to the next
> program in the object program list which is free to proceed.

However, as mentioned earlier, programs were (and still are!) written in such a
way as to assume they have a machine all to themselves. Thus, to bridge the gap,
we need to provide such programs with a "virtual" environment which they _do_ have
all to themselves.

### Concept

**Virtualization is a general term for software facilities (possibly supported
by hardware acceleration) to run programs as if they each have a computer all
to themselves.** Common forms include:

* **Virtual memory** is a mechanism to translate "virtual" addresses into fetch
  commands against physical data stores, in such a way that each program has a
  whole "virtual" computer to itself, despite sharing physical memory.
* A **virtual machine (VM)** is a relatively fast bytecode interpreter which does not
  enable programs to directly execute instructions on the physical machine.
* In **full virtualization**, a virtual machine exposes the entire host
  machine instruction set, thus enabling native programs to run within a VM.

### Benefits

* Virtual memory makes it possible to only copy data from slow tiers of storage
  into fast tiers of storage if and when that "page" of data is needed.
* Virtual memory makes it possible to persist data directly from volatile
  storage into nonvolatile storage "in the background," without special
  handling.
* Virtual memory makes it possible for processes to "share" memory without
  out-of-band communication.
* VMs have relatively strong security guarantees; because all programs become
  paths through an interpreter, one need only show that the interpreter is safe
  to confirm that running arbitrary code within the VM is safe.

### Exemplars

* [Multics](http://en.wikipedia.org/wiki/Multics)
* [Plan 9](http://www.slideshare.net/jserv/plan-9-not-only-a-better-unix)
  (unparalleled uniformity between volatile, nonvolatile, and network storage)
* [Xen](http://en.wikipedia.org/wiki/Xen) (full virtualization)

### Drawbacks

* Virtual memory tries so hard to stay out of the programmer's way that most
  programmers don't even have a clear idea of what it is. As a result, its
  capabilities tend to be underused. 
* Virtual memory should have been extended to network resources, but this has
  not really happened.
* As usually implemented, virtual memory subtly encourages the development of
  programs that do not talk to each other, because they are all pretending to
  exist in an isolated virtual memory space.


<a name="Hypermedia"></a>
## 7. Hypermedia <a href="#Hypermedia">#</a>

**Year**: 1968

### Archetype

Doug Engelbart's [NLS](http://en.wikipedia.org/wiki/NLS_(computer_system\))
introduced implementations of:

* hypertext links
* markup language
* document version control
* videoconferencing
* email with hypermedia
* hypermedia publishing
* flexible windowing modes

### Motivation

> **[Augmenting Human
> Intellect](http://www.dougengelbart.org/pubs/augment-3906.html)**
> 
> By "augmenting human intellect" we mean increasing the capability of a man to
> approach a complex problem situation, to gain comprehension to suit his
> particular needs, and to derive solutions to problems. Increased capability in
> this respect is taken to mean a mixture of the following: more-rapid
> comprehension, better comprehension, the possibility of gaining a useful
> degree of comprehension in a situation that previously was too complex,
> speedier solutions, better solutions, and the possibility of finding solutions
> to problems that before seemed insoluble. And by "complex situations" we
> include the professional problems of diplomats, executives, social scientists,
> life scientists, physical scientists, attorneys, designers--whether the
> problem situation exists for twenty minutes or twenty years. We do not speak
> of isolated clever tricks that help in particular situations. We refer to a
> way of life in an integrated domain where hunches, cut-and-try, intangibles,
> and the human "feel for a situation" usefully co-exist with powerful concepts,
> streamlined terminology and notation, sophisticated methods, and high-powered
> electronic aids.
> 
> Existing, or near-future, technology could certainly provide our professional
> problem-solvers with the artifacts they need to have for duplicating and
> rearranging text before their eyes, quickly and with a minimum of human
> effort. Even so apparently minor an advance could yield total changes in an
> individual's repertoire hierarchy that would represent a great increase in
> over-all effectiveness. Normally the necessary equipment would enter the
> market slowly; changes from the expected would be small, people would change
> their ways of doing things a little at a time, and only gradually would their
> accumulated changes create markets for more radical versions of the equipment.
> Such an evolutionary process has been typical of the way our repertoire
> hierarchies have grown and formed.
>
> But an active research effort, aimed at exploring and evaluating possible
> integrated changes throughout the repertoire hierarchy, could greatly
> accelerate this evolutionary process.

### Concept

**Hypermedia refers to any communications medium which comprises interactive
systems.** The most popular forms of hypermedia are those employing
**hyperlinks**: certain elements of a viewed object which can be activated
through interaction and whose activation triggers the display of a different
object, which is determined by the hyperlink and possibly also by the
interaction. For example, the World Wide Web is a form of hypermedia
(hypertext), though even HTML5 is not nearly as capable as hypermedia pioneers
like Ted Nelson and Doug Engelbart had probably hoped. 

### Benefits

* Makes nonlinear communication/expression much easier
* A continuum between hypermedia authoring and program authoring eases more
  people into being able to craft programs to solve their own problems, which is
  good for freedom
* Could enable people to organize their own thoughts and lives more elegantly
  and smoothly

### Exemplars

* [HyperCard](http://en.wikipedia.org/wiki/HyperCard)
* [Twine](http://twinery.org/)
* [Wikipedia](http://en.wikipedia.org/wiki/Wikipedia)

### Drawbacks

* It's easy to implement bad hypermedia, like HTML.
* If a software company makes good enough hypermedia, like
  [HyperCard](http://en.wikipedia.org/wiki/HyperCard), it will be quickly
  discontinued since it will threaten the rest of the company's product line.

<a name="Internetworking"></a>
## 8. Internetworking <a href="#Internetworking">#</a>

**Year**: 1969

### Archetype

[ARPAnet](http://en.wikipedia.org/wiki/Arpanet) is the quintessential computer
network.  It was originally called "the Intergalactic Computer
Network" and ultimately became known as simply "the Internet".

### Motivation

> We had in my office three terminals to three different programs that ARPA was
> supporting. One was to the Systems Development Corporation in Santa Monica.
> There was another terminal to the Genie Project at U.C. Berkeley. The third
> terminal was to the C.T.S.S. project that later became the Multics project at
> M.I.T.
>
> The thing that really struck me about this evolution was how these three
> systems caused communities to get built. People who didn't know one another
> previously would now find themselves using the same system. Because the
> systems allowed you to share files, you could find that so-and-so was
> interested in such-and-such and he had some data about it. You could contact
> him by e-mail and, lo and behold, you would have a whole new relationship.
>
> It wasn't a static medium. It was a dynamic medium. And that gave it a lot of
> power.
>
> There was one other trigger that turned me to the ARPAnet. For each of these
> three terminals, I had three different sets of user commands. So if I was
> talking online with someone at S.D.C. and I wanted to talk to someone I knew
> at Berkeley or M.I.T. about this, I had to get up from the S.D.C. terminal, go
> over and log into the other terminal and get in touch with them.
> 
> I said, oh, man, it's obvious what to do: If you have these three terminals,
> there ought to be one terminal that goes anywhere you want to go where you
> have interactive computing. That idea is the ARPAnet.
>
>--[Bob Taylor](http://en.wikipedia.org/wiki/Robert_Taylor_(computer_scientist\)) ([source](http://partners.nytimes.com/library/tech/99/12/biztech/articles/122099outlook-bobb.html)), ARPA IPTO director

### Concept

**An internetwork is a set of communications channels between computers, where
each computer is running a service that routes incoming messages to some other
communications channel, so that each message eventually reaches its addressee.**
"Messages," in this context, are generally termed "packets" (and they generally
reach their destination within less than a hundred "hops"). 

### Benefits

* Global instant email
* Global instant hypertext
* Global database-backed applications
* Global file sharing

### Exemplars

* [Internet Protocol](http://en.wikipedia.org/wiki/Internet_protocol)

### Drawbacks

* Classical internetworking has no built-in
  economic component; arrangements between large networks must be negotiated
  "out of band" and encoded in a rather nasty form called
  [BGP](http://en.wikipedia.org/wiki/Border_Gateway_Protocol). As a result of
  this, individual people or even moderately large corporations usually cannot
  internetwork, but must instead purchase access to the Internet. As a result of
  _this_, most communications systems around the world are controlled by unjust oligopolies,
  with high barriers to competition and low barriers to various abuses of power.


## Conclusion

I find that all the significant concepts in software systems
were invented/discovered in the 15 years between 1955 and 1970. What have we
been doing since then? Mostly making things faster, cheaper, more
memory-consuming, smaller, cheaper, dramatically less efficient, more secure[^6],
and worryingly glitchy. And we've been rehashing the same ideas over and over
again.  Interactivity is now "event-driven programming".  Transactions are now
"concurrency". Internetworking is now "mesh networking". Also, we have tabbed
browsing now, because overlapping windows were a bad skeuomorphism from the
start, and desktop notifications, because whatever is all the way in the corner
of your screen is probably not very important. "Flexible view control" is
relegated to the few and the proud who run something like `xmonad` or
`herbstluftwm` on their custom-compiled GNU/Linux.

Many good programs have been written. Lots of really important algorithms and
data structures have been invented (though usually not implemented in practice).
Hardware has made _so_ much progress. In the 1960s, a lot of good ideas were
tossed out because they ran too slow, but here in 2014 everything is written in
Python anyway, so let's bring back the good old days, but now with Retina screens
and multi-core gigahertz processors and tens of gigabytes of core memory. Let's
take that 20% performance hit over hand-coded assembler that was unacceptable in
the 1960s, because it's a 10x improvement over what we're doing now.

Most of all, let's rethink the received wisdom that you should teach your
computer to do things in a programming language and run the resulting program on
an operating system. A righteous operating system should be a programming
language. And for goodness' sake, let's not use the entire network stack just to
talk to another process on the same machine which is responsible for managing a
database using the filesystem stack. At least let's use shared memory (that's
what it's _for_!). But if we believe in the future -- if we believe in ourselves
-- let's dare to ask why, anyway, does the operating system give you this
"filesystem" thing that's no good as a database and expect you to just accept
that "stuff on computers goes in folders, lah"? Any decent software environment
ought to have a fully featured database, built in, and no need for a
"filesystem".

Reject the notion that one program talking to another should have to invoke
some "input/output" API. You're the human, and you _own_ this machine.  You get
to say who talks to what when, why, and how if you please. All this software
stuff we're expected to deal with -- files, sockets, function calls -- was just
invented by other mortal people, like you and I, without using any tools we
don't have the equivalent of fifty thousand of. Let's do some old-school hacking
on our new-school hardware -- like the original TX-0 hackers, in assembly,
from the ground up -- and work towards a harmonious world where there is
something new in software systems for the first time since 1969.

***

_To be continued..._

[^1]: Since then, Smalltalk, Forth, and Lisp have all flirted with becoming operating systems, but none achieved economic success, for the simple reason that none of the projects involved attempted to provide value to people. They solved technical problems to validate that their concepts can work in the real world, but did not pursue the delivery of better solutions to real-world problems than would otherwise be possible.
[^2]: Serious embedded systems people who write machine code from scratch, this is your time to gloat. You truly deserve the title of engineer. In fact, chances are good that you hold the title "electrical engineer". Chances are also good that whatever you engineer isn't computers, so hear me out. On the off-chance that you are an embedded systems person who writes machine code from scratch and you **do** make computers or computer parts, chances are good that you are (a) the bane of some free software driver author's existence, and/or (b) providing an incredibly hard-to-detect hideout for really clever malware. **Please compel your employers to publish technical documentation freely and to use ROMs in place of FLASH so that malware can't take over your lovingly crafted code.** Now, back to our regularly scheduled tirade.
[^3]: Yes, there are exceptions, but they're not the ones you think. The exceptions are those derived from the work of [Cliff Shaw](http://en.wikipedia.org/wiki/Cliff_Shaw) (e.g.  [PLANNER](http://en.wikipedia.org/wiki/PLANNER), [Prolog](http://en.wikipedia.org/wiki/Prolog), [M](http://en.wikipedia.org/wiki/MUMPS)), those derived from [APL](http://c2.com/cgi/wiki?AplLanguage) (e.g.  [J](http://c2.com/cgi/wiki?JayLanguage), [K](http://c2.com/cgi/wiki?KayLanguage), and [arguably](https://www.princeton.edu/~hos/mike/transcripts/mcilroy.htm) the UNIX shell/pipeline environment), the [COMIT](http://www.mt-archive.info/MT-1958-Yngve.pdf) family (e.g.  [SNOBOL](http://c2.com/cgi/wiki?SnobolLanguage)), and the curious corner case of [Inform 7](https://gist.github.com/koo5/4129213). Lisp was inspired by FORTRAN ([source](http://www-formal.stanford.edu/jmc/history/lisp/node2.html)). ISWIM (which some programming language histories identify as the "root" of the ML family) is based on ALGOL 60 ([source](http://www.cs.cmu.edu/~crary/819-f09/Landin66.pdf)), which of course is based on FORTRAN. The [Forth](http://www.forth.com/resources/evolution/evolve_0.html) family (e.g.  [PostScript](http://en.wikipedia.org/wiki/PostScript), [Factor](http://c2.com/cgi/wiki?FactorLanguage), [Tcl](http://www.stanford.edu/~ouster/cgi-bin/papers/tcl-usenix.pdf) via [NeWS](http://c2.com/cgi/wiki?NetworkExtensibleWindowSystem)) was rooted in Lisp ([source](http://www.colorforth.com/HOPL.html)).  Even COMIT was loosely inspired by FORTRAN ([source](http://books.google.com/books?id=-GW8lOYl3AAC&lpg=PA53&ots=OzMYwEw0kz&dq=COMIT+FORTRAN&pg=PA53)).  Machine code could simply be disqualified on the basis that it is not software (the subject of this article), but even all current machine languages feature stack operators, which derive from ALGOL via [Burroughs Large Systems](http://research.microsoft.com/en-us/um/people/gbell/computer_structures_principles_and_examples/csp0260.htm).
[^4]: ([source](http://books.google.com/books?id=-PDPBvIPYBkC&lpg=PA1&ots=LgbTZ3Z1IO&dq=Classic%20Operating%20Systems%3A%20From%20Batch%20Processing%20to%20Distributed%20Systems&pg=PA7#v=onepage&q=atlas&f=false))
[^5]: Yes, I'm aware of [all this $#!*](http://en.wikipedia.org/wiki/Graphical_programming). If you want to point out that graphical programming languages exist, and they aren't based on FORTRAN, well, they fall outside my definition of "programming language", so there. Riddle me this: why does nobody who knows how to program in text ever want to use them? Why do they break down for anything that isn't basically a signal processing task? Why don't they have lambdas, zooming, or style? You know, style. Like Edward Tufte has. Style. Nobody wants to use an ugly visual programming language.
[^6]: I considered including cryptography as another major bullet point, but if I selected a particular algorithm (e.g.  [Diffie-Hellman-Merkle key exchange](http://en.wikipedia.org/wiki/Diffie-Hellman_key_exchange) or the [Merkle–Damgård hash function construction](http://en.wikipedia.org/wiki/Merkle%E2%80%93Damg%C3%A5rd_construction)), then I'd have to include other important algorithms (I've left algorithms out of my list here; they're not "software innovations" in the sense I mean), and if I selected "encrypted communications", well, that surely predates computers. The fact that people started writing programs which encrypt communications is great, but it doesn't change the software environment on the level I'm talking about.  That said, I do consider the invention of the practical cryptographic hash a contender for most important innovation in _computer science_ in the last 25 years; asymmetric cryptography is about equally important.  Ralph Merkle really deserves more credit for having essentially conceived of both pillars of modern cryptography.
