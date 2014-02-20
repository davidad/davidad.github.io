---
layout: post
title: "Relocatable vs. Position-Independent Code (or, Virtual Memory isn't
Just For Swap)"
date: 2014-02-19 17:12:50 -0500
comments: true
categories: 
---

> **Myth**: "Virtual memory" is the mechanism that a kernel uses to make more
> memory available than is actually physically installed, by setting aside a
> disk partition for the overflow and copying pages between memory and disk as
> needed.

I acquired this belief very early in my programming career, but it turns out
that swapping pages to disk is merely one of the many things that "virtual
memory" makes possible.

> **Fact**: "Virtual memory" is a _hardware_ (CPU) mechanism, which, every
> single time memory is accessed, references a kernel-specified data structure
> called a "page table" to arbitrarily
> [frobnicate](http://www.catb.org/jargon/html/F/frobnicate.html) the high bits
> of the address, which is called "translating" from a "linear addresss" to a
> "physical address". (The page table gets cached by a [translation lookaside
> buffer](http://en.wikipedia.org/wiki/Translation_lookaside_buffer), so the
> lookup is usually quite efficient!)

This fact became very real to me this week as I made a [kernel from
scratch](/blog/2014/02/18/kernel-from-scratch/): I was moderately surprised
that I _needed_ to set up a page table, when I had always thought of virtual
memory as a mildly advanced kernel feature. Today, I learned how "relocatable"
and "PIC" -- terms I'd encountered in the past and never really understood --
suddenly make sense in this context.  <!-- more -->

Here's another fact that surprised me: in conventional operating systems,
**every process has its own page table**. The pointer `0x7fff8000` does not
necessarily translate to the same physical address in one process as it does in
another[^1].

Now, let's talk about libraries. Libraries are code, but they don't run as
processes of their own. They're going to wind up under someone else's page
table. There's two ways that can happen: static linking and dynamic linking[^2].

 * If a library is statically linked, the linker finds some place in a code
segment of the executable to situate the library. The loader will then place
this segment in virtual memory (wherever it's explicitly specified to go) when
the executable is run.
 * If a library is dynamically
linked, then when the loader sets up the executable, it will invoke the dynamic
linker to make sure that the
required library shows up some place in the process's virtual memory[^3]. 

Whether static or dynamic, a linked library is going to be situated in virtual
memory somewhere that the library can't predict[^4], which is problematic for
accessing its own memory.  Fortunately, the linker (whether static or dynamic)
can help us out by **relocating** the library's code, so that it knows where it
is.  Unfortunately, library writers have to help the linker out by specifying,
in the object file, the set of instructions or initialized data that need to be
modified to properly relocate it. As long as all that "relocation information"
is present, the object file is said to be **relocatable**.

On the other hand, **position-independent code** (**PIC**), as the name
suggests, doesn't even need to be relocated. None of its instructions or
initialized data encode any assumptions about the region of virtual memory the
program will be loaded into; it figures out where it is (usually by referencing
the instruction pointer) and makes all memory accesses based on what it finds
out.

So why do all that work when the linker can relocate for us?

Here's the kicker. The whole motivation for dynamic linking was **shared
libraries**. **Shared** doesn't just mean that multiple programs reference the
same library file on disk. It means those processes share that library **in
physical memory**[^5].  Since every process has its own page table, the exact
same library code winds up executing as if it were loaded into multiple,
inconsistent virtual memory locations.  If we relocated it for one process, it
wouldn't necessarily be valid for another. **This is why weird things sometimes
happen where the solution is "recompile `blah` with `-fPIC`"**.

* * *

Perhaps the most interesting thing about all this is that in today's 64-bit age,
position-independent code may not even be necessary. The available virtual
memory address space with 64 bits is so large that an OS may be able to afford
blocking off a region of _every_ process's virtual memory space to host _every_
shared library on the system, so that their linear locations are guaranteed to
be consistent from process to process. That means shared libraries would still
have to be relocatable, but they wouldn't have to be PIC.

On the other hand, x86_64 makes it [significantly
easier](http://eli.thegreenplace.net/2011/11/11/position-independent-code-pic-in-shared-libraries-on-x64/)
to write position-independent code, by referring addresses to the current
program counter (so no matter what virtual memory offset the code is at, it's
internally consistent). If we adopt a policy that _all_ libraries (static and
dynamic) are PIC, then libraries don't ever have to worry about being relocated
and the linker gets a lot simpler.

[^1]: This is one of the things that differentiates a "process" from a "thread": **threads** don't have their own page tables.
[^2]: Just as with static typechecking and dynamic typechecking, "static" means that it happens before the program is invoked, and "dynamic" means that happens after the program is invoked.
[^3]: The loader also needs to populate a series of "slots" at fixed addresses with instructions that jump into where the library is (since the executable won't know in advance where the library will show up, unlike with static linking). But that part of dynamic linking is a distraction for the discussion of relocatable vs. PIC.
[^4]: unlike a stand-alone executable, which can request (almost) any virtual memory address that it wants (since it has the whole page table to itself)
[^5]: In fact, in most operating systems, if multiple processes map the same file into their virtual memory, and none of them write to it, those processes' page tables will point each of their process-specific addresses at the **same pages** of physical memory.
