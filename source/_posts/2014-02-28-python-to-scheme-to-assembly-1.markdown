---
layout: post
title: "Python to Scheme to Assembly, <br>Part 1: Recursion and Named Let"
date: 2014-02-28 14:43:58 -0500
comments: true
categories: python-to-scheme-to-assembly
---

_In 2001, my favorite programming language was Python. In 2008, my favorite
programming language was Scheme. In 2014, my favorite programming language is
x64 assembly. For some reason, that progression tends to surprise people. Come
on a journey with me._

## Python

In this article, we're going to consider a very simple toy problem: recursively
summing up a list of numbers[^1].


```python
def sum_list(list):
  if len(list) == 0:
    return 0
  else:
    return list[0]+sum_list(list[1:])
```

>      >>> sum_list(range(101))
>      5050

[Young Carl Gauss](http://en.wikipedia.org/wiki/Carl_Friedrich_Gauss#Anecdotes)
would be proud.

>      >>> sum_list(range(1001))
>      RuntimeError: maximum recursion depth exceeded
>
> Oops.

Young programmers often learn from this type of experience that recursion
_sucks_. (Or, as a modern young programmer might say, it _doesn't scale_.) If
they Google around a bit, they might find the following "solution":
<!-- more -->

>      >>> import sys
>      >>> sys.setrecursionlimit(1500)
>      >>> sum_list(range(1001))
>      500500

If they have a good computer science teacher, though, they'll learn that the
real solution is to use something called **tail recursion**.  This
is a somewhat mysterious, seemingly arbitrary concept. If the result of your
recursive call gets returned _immediately_, without any intervening expessions,
then somehow it "doesn't count" toward the equally arbitrary recursion depth
limit. Our example above isn't tail-recusrive because we  add `list[0]` to
`sum_list(list[1:])` before returning the result. In order to make `sum_list`
tail-recursive, we have to add an **accumulator** variable, which represents the
sum of those numbers we've looked at already. We'll call this version
`sum_sublist`, and wrap it in a new `sum_list` function which calls
`sum_sublist` with the initial accumulator 0 (initially, we haven't looked at
any numbers yet, so the sum of them is 0).

```python
def sum_list(list):
  def sum_sublist(accum,sublist):
    if len(sublist) == 0:
      return accum
    else:
      return sum_sublist(accum+sublist[0],sublist[1:])
  return sum_sublist(0,list)
```

>      >>> sum_list(range(101))
>      5050

So far, so good.

>      >>> sum_list(range(1001))
>      RuntimeError: maximum recursion depth exceeded

Wait, what?

> On Wednesday, April 22, 2009, Guido van Rossum
> [wrote](http://neopythonic.blogspot.co.uk/2009/04/tail-recursion-elimination.html):
> > A side remark about not supporting tail recursion elimination (TRE)
> > immediately sparked several comments about what a pity it is that Python
> > doesn't do this, including links to recent blog entries by others trying to
> > "prove" that TRE can be added to Python easily. So let me defend my position
> > (which is that I don't want TRE in the language). If you want a short
> > answer, it's simply unpythonic. Here's the long answer:
>
> _[snipped]_
>
> > Third, I don't believe in recursion as the basis of all programming. This
> > is a fundamental belief of certain computer scientists, especially those who
> > love Scheme...
>
> _[snipped]_
>
> > Still, if someone was determined to add TRE to CPython, they could modify
> > the compiler roughly as follows...

In other words, the _only_ reason this doesn't work is that Guido van Rossum[^3]
_prefers it that way_. Guido, I respect your right to your opinion, but the
reader and I are switching to Scheme. 

## Scheme

Here's a line-by-line translation:

```scheme
(define (sum_list list)
  (define (sum_sublist accum sublist)
    (cond ((null? sublist)                 ; tests if sublist has length 0
           accum )                         ; don't need return statement in Scheme
          (else
           (sum_sublist (+ accum (car sublist)) (cdr sublist)) )))
  (sum_sublist 0 list) )
```

>      guile> (sum_list (iota 1001))
>      500500

Phew! Let's make sure that we aren't just getting lucky with a bigger
recursion limit:

>      guile> (sum_list (iota 10000001))
>      50000005000000

Well, isn't that neat? If we go much bigger, it'll take a long time, but as long
as the output fits into memory, we'll get the right answer[^4].

### Named Let

In our last two versions of `sum_list`, we defined a helper function
(`sum_sublist`), and the rest of the body of `sum_list` was just a single
invocation of that helper function. This is an inelegant pattern[^5], which
Scheme has a construct to address.

<a name="named-let-1"></a>
```scheme
(define (sum_list list)
  (let sum_sublist ((accum 0) (sublist list))  ; the named let!
    (cond ((null? sublist)
           accum )
          (else
           (sum_sublist (+ accum (car sublist)) (cdr sublist)) ))))
```

[**Named let**](http://people.csail.mit.edu/jaffer/r5rs_6.html#IDX130) creates a
function and invokes it (with the provided initial values) in one step.  It is
decidedly my favorite control structure of all time. You can have your `while`
loops and your `for` loops, and your `do`...`until` loops too[^6]. I'll take
named let any day, because it provides the abstraction barrier of recursion
without compromising the conciseness and efficiency of iteration. In case you're
not sufficiently impressed, I discuss the delightful properties of using
recursion instead of non-recursive loops [below](#recursion).

## Assembly
<a name="neatly-into-assembly"></a>
Named let style translates amazingly naturally into assembly.

```nasm
bits 64
; macros for readability
%define list rdi             ; by calling convention, argument shows up here
%define accum rax            ; accumulator (literally!)
%define sublist rdx

global sum_list
sum_list:
  mov accum, 0               ; these are the let-bindings!
  mov sublist, list
.sum_sublist:
  cmp sublist, 0             ; is it NULL?
  jnz .else                  ; if not, goto else
  ret; accum                (because return value is rax by calling convention)
.else:
  add accum, [sublist]       ; ~ accum=accum+car(sublist);
  mov sublist, [sublist+8]   ; ~ sublist=cdr(sublist);
  jmp .sum_sublist           ; tail-recurse
```

>     > sum_list(from(1,100))
>     5050
>     > sum_list(from(1,10000000))
>     50000005000000
> 
> (Sadly, my assembler doesn't come with its own REPL; we're borrowing
> the [LuaJIT](http://luajit.org) REPL instead[^12].)

In fact, if I weren't so comfortable with named let, I doubt I'd be an effective
assembly coder, because assembly doesn't really have any other iteration
constructs[^13]. But I don't miss them.  What would they look like, anyway?

## Addendum: C

In this section, we're going to look at the assembly for iteration, non-tail
recursion, and tail recursion, as emitted by `gcc`, and get to the bottom of
what the difference is anyway.

At the top of each C file here, we have the following:

```c
#include <stdint.h>
struct number_list {
  uint64_t number;
  struct number_list *next;
};
```

### Iteration

If I were solving this problem in the context of a C program, this is how I
would do it.

```c start:6
uint64_t sum_list(struct number_list* list) {
  uint64_t accum = 0;
  while(list) {
    accum+=list->number;
    list=list->next;
  }
  return accum;
}
```

Here's the generated assembly, translated to `nasm` syntax and commented.

```nasm
global sum_list
sum_list:
  xor eax, eax     ; equivalent to "mov rax, 0" but faster
                   ; in C it's fine to clobber rdi instead of copying it first
  test rdi, rdi    ; equivalent to "cmp rdi, 0", but more compact in machine code
  jz done          ; here the "if NULL" case is at the bottom, accumulation case is right here. 
.else:
  add rax, [rdi]
  mov rdi, [rdi+8]
  test rdi, rdi    ; equivalent to "cmp rdi, 0"
  jnz .else
.done:
  rep ret          ; equivalent to "ret", but faster on old AMD chips for no good reason
```

This is _almost_ identical to the assembly that I wrote, except that it clobbers
one of its inputs (which is perfectly allowed by the C calling convention[^16]),
it uses `xor` instead of `mov` to load `0` (a solid optimization), it uses
`test` in place of `cmp` (reasonable optimization), it uses `rep ret` (less
compact and no benefit on Intel chips) and it shuffles the instructions around
such that two `test`s are needed (almost certainly not helpful with modern
branch prediction and loop detection). I haven't run benchmarks on this, but my
guess is that it would come out about even. I also think the shuffling makes
this "iterative" version more opaque and difficult to reason about (not least
because of the duplicated `test`) than my "named let"-style code.

### Non-Tail Recursion

```c start:6
uint64_t sum_list(struct number_list* list) {
  if(!list) {
    return 0;
  } else {
    return list->number+sum_list(list->next);
  }
}
```

`gcc -O3` can _almost_ completely convert this version to iteration, so let's
look at the generated assembly from `gcc -O1` to get a better sense of what it
might look like in a language implementation for which the necessary
optimizations are too complex to be made automatically.

```nasm
global sum_list
sum_list:
  push rbx          ; preserve the current value of rbx on the stack
  mov rbx, rdi      ; replace rbx by the argument to the function, list
  mov eax, 0        ; set up 0 in the result register
  test rdi, rdi     ; check if rdi is NULL
  jz .else          ; if so go to else
  mov rdi, [rdi+8]  ; ~ list=list->next;
  call sum_list     ; sum_list(list) -> result register (rax)
  add rax, [rbx]    ; add list->number (preserved across function call) to rax
.else:
  pop rbx           ; restore the state of rbx
  ret               ; return rax
```

We can see immediately that some new instructions (`push`, `pop`, and `call`)
have been introduced. These are all **stack manipulation instructions**[^15]. If
we carefully pretend to be the CPU running this program, we can see that it
pushes the address of every number in the linked list, and then dereferences and
adds them up as it pops them from the stack. This is not good; if we wanted our
entire data structure to be replicated on the stack, we would have passed it by
value[^14]! It's generally the amount of memory set aside for the stack that
we've actually run out of in the case of a `recursion depth exceeded` error.

### Tail Recursion

What about translating the tail-recursive version into C? Like Scheme and
Python, `gcc` supports nested function definitions (as a GNU extension to C), so
this is no problem:

```c start:6
uint64_t sum_list(struct number_list* list) {
  uint64_t sum_sublist(uint64_t accum, struct number_list* sublist) {
    if(!sublist) {
      return accum;
    } else {
      return sum_sublist(accum+sublist->number,sublist->next);
    }
  }
  return sum_sublist(0,list);
}
```

Here's what `gcc -O1` gives us (translated and commented as before):
```nasm
sum_sublist.1867:       ; A random constant has been added to avoid polluting the namespace. Not the best solution, but okay.
  sub rsp, 8            ; Decrement the stack by one 8-byte machine word. Seems unnecessary...
  mov rax, rdi          ; Copy first argument (rdi/"accum") into result register (rax).
  test rsi, rsi         ; Test second argument (rsi/"sublist") for nullity.
  jz .else              ; If null, goto else.
  add rdi, [rsi]        ; ~ accum = accum + sublist->number;
  mov rsi, [rsi+8]      ; sublist = sublist->next;
  call sum_sublist.1867 ; recurse. result appears in rax, ready to pass along (as the return value) to the next caller in the stack.
.else:
  add rsp, 8            ; seems unnecessary
  ret                   ; return rax

sum_list:
  sub rsp, 8
  mov rsi, rdi          ; first argument (rdi/"list") of sum_list becomes 2nd argument (rsi/"sublist") of sum_sublist
  mov rdi, 0            ; first argument (rdi/"accum") of sum_sublist is 0
  call sum_sublist.1867 ; call sum_sublist!
  add rsp, 8
  ret
```

In this mode, the tail `call` is not being eliminated -- although we're no
longer `push`ing `rbx`, we're still pushing `rip` to stack with every `call`,
and eventually we'll run out of stack that way. The only way to get around this
is to replace each `call` with `jmp`: since we're just going to take the return
value of the next recursive invocation and then immediately `ret` back to the
previous caller on the stack, there's no point in even inserting our own address
on the stack (as `call` does); we can just set up the next guy to pass the
return value straight back to the previous guy, and quietly disappear.

`gcc -O3` does this. In fact, somewhat surprisingly, it generates _exactly_ the
same assembly, line for line, for this version as for the purely iterative
version above.  That's "**tail call optimization**" (TCO) or "**tail recursion
elimination**" (TRE) in its most agressive form: it literally just gets rid of
all calls and recursions and replaces them with an equivalent iteration
(complete with duplicate `test`).

The upshot of all this is that _not only does Scheme's "named let" recursion
form translate [neatly into assembly](#neatly-into-assembly), it provides --
penalty-free -- a better abstraction than either iteration_ (while-loop
imitation) _or stack-driven recursion_, the two options `gcc` appears to pick
from when dealing with various ways to code a list traversal.

Actually, the real point I'm trying to make here is that, **unlike in C, I can
naturally do named let directly in assembly, and that's one of the many reasons
working in assembly makes me happy**.

<a name="recursion"></a>
## Appendix: What's so great about recursion, anyway?

For me, the most important point in favor of a recursive representation is that
I find it easier to reason about **correctness** that way.

Any function we define ought to implement some ideal mathematical function that
maps inputs to outputs[^7]. If our code truly does implement that ideal
function, we say that the code is **correct**. Generally, we can break down the
body of a function as a
[composition](http://en.wikipedia.org/wiki/Function_composition) of smaller
functions; even in imperative languages, we can think of every statement as
pulling in a state of the world, making well-defined changes, and passing the
new state of the world into the next statement[^8]. At each step, we ask
ourselves, "are the outputs of this function going to be what I want them to
be?" For loops, though, [this gets
tricky](http://en.wikipedia.org/wiki/Loop_invariant#Informal_example).

What recursion does for us as aspiring writers of correct functions is automatic
translation of the loop verification problem into the much nicer problem of
function verification.  Intuitively, you can simply assume that all invocations
of a recursive function within its own body are going to Do The Right Thing,
ensure that the function as a whole Does The Right Thing under that assumption,
and then conclude that the function Does The Right Thing in general.  If this
sounds like circular reasoning, it does[^10]; but it turns out to be valid
anyway.

There are many ways to justify this procedure formally, all of which are truly
mind-bending[^9]. But once you've justified this procedure once, you never have
to do it again (unlike ad-hoc reasoning about loops). I've determined that the
most elegant way to explain it is by expanding our [named let
example](#named-let-1) into a non-recursive function, which just happens to
accept as a parameter a correct[^11] version of itself.

```scheme
(define (sum_list list)
  (define (sum_sublist_nonrec f_correct accum sublist)
    (cond ((null? sublist)
           accum )
          (else
           (f_correct f_correct (+ accum (car sublist)) (cdr sublist)) )))
  (sum_sublist_nonrec sum_sublist_nonrec 0 list) )
```

Now, `sum_sublist_nonrec` is an honest-to-goodness non-recursive function, and
we can check that it is correct. Given a correct function `f_correct` (which
takes as inputs a correct version of itself, a number, and a list, and correctly
returns the sum of all the elements in the list plus the number), a number, and
a list, does `sum_sublist_nonrec` correctly return the sum of all elements in
the list plus the number? Why yes, it does. (Constructing a formal proof tree
for this claim is left as an exercise for the self-punishing reader.) Note that
since `f_correct` is assumed to already be correct, the correct version of it is
still just `f_correct`, so we can safely pass it to itself without violating our
assumptions or introducing new ones. So, `sum_sublist_nonrec` is correct.

Now let's consider the correctness of `sum_list`. It's supposed to add up all
the numbers in `list`. What it actually does is to apply the (correct) function
`sum_sublist_nonrec`, passing in a correct version of itself (check! it's
already correct), a number to add the sum of the list to (check! adding zero to
the sum of the list won't change it), and the list (check! that's what we're
supposed to sum up).

We've just proved our program correct! The magic of named let is that it
generates this clumsy form with a bunch of `f_correct`s from a compact and
elegant form. In so doing, it lets us get away with much less formal reasoning
while still having the confidence that it can be converted into something like
what we just slogged through. Rest assured that no matter what you do with named
let, no matter how complicated the construct you create, this "assume it does
the right thing" technique still applies!

With one _tiny_ caveat. We haven't proved that the program _terminates_. If this
technique proved termination, then we could just write

```scheme
(define (do-the-right-thing x)
  (let does-the-right-thing ((x x))
    (does-the-right-thing x)))
```

and it would be totally correct, no matter what thing we want it to do.

Technically, everywhere I've said "correct", what I mean is **partially
correct**: _if_ it terminates, _then_ the output is correct. (Equivalently, it
definitely _won't_ return something incorrect.) `do-the-right-thing` is, in
fact, partially correct: it never returns at all, so it won't give you any
incorrect outputs!

Termination proofs of recursive functions can usually be handled by [structural
induction](http://en.wikipedia.org/wiki/Structural_induction) on possible
inputs: you establish that it terminates for minimal elements (e.g. the empty
list) and that termination for any non-minimal element is dependent only on
termination for some set of smaller elements (e.g. the tail of the list). The
structure that you need in order to think about termination this way is also
much clearer with recursion than with iteration constructs.

* * *

In the next installment of **Python to Scheme to Assembly**, we will look at
`call-with-current-continuation`.

[^1]: If you doubt my ability to productively use assembly for more complicated toy problems, I direct you to my [previous blog post](/blog/2014/02/25/overkilling-the-8-queens-problem/).
[^2]: If we left it out, the final result would always be `0`. Proving this invariant is left as an exercise for the reader.
[^3]: [Guido van Rossum](http://en.wikipedia.org/wiki/Guido_van_Rossum) is the author of Python, and the "Benevolent Dictator for Life" of its development process.
[^4]: Unlike most language implementations, `guile` natively supports [arbitrarily large integers](http://www.gnu.org/software/guile/manual/html_node/Integers.html#Integers).
[^5]: Although at least it's not as inelegant as defining the helper function _outside_ the body of the actual function, thereby polluting the global namespace. Take advantage of nested functions!
[^6]: You can even keep your `for-each` loops, which are no substitute for [`map` and `filter`](https://www.gnu.org/software/guile/manual/html_node/SRFI_002d1-Fold-and-Map.html#SRFI_002d1-Fold-and-Map).
[^7]: If your function cannot be fully specified by an abstract mapping from inputs to outputs, then it is **nondeterministic**, which is a fancy word for "unpredictable": there must exist some circumstances under which you cannot predict the behavior of the function, even knowing every input. Intuitively, I'm sure you can see how unpredictable software is a nightmare to debug. Controlling nondeterminism is an active field of computer science research, which is not the subject of this article. However, I hope you are at least convinced that nondeterminism is something you should avoid if possible, and that therefore you should try to design every function in your program as a proper mathematical function.<p>Note that I'm not talking about "purity" here -- it's fine for "outputs" to include side effects as of function exit, and for "inputs" to include states of the external world as of function entry. What's important is that the state at function exit of anything the function modifies be uniquely determined by the state at function entry of anything that can affect its execution.
[^8]: Unless we're dealing with hairy scope issues like hoisting, in which case you should get rid of those first.
[^9]: Trying to explain it for the purposes of this blog post -- while making sure that I'm not missing something -- took me over four hours.
[^10]: Pun intended. The sentence within which this footnote is referenced _isn't_ circular reasoning; it's a tautology. Therefore, it's an example of something that sounds like circular reasoning but is valid anyway. Of course, you shouldn't take the existence of this cute example as evidence that the circular-sounding reasoning preceding it is not, in fact, circular. (That would be a fallacy of [inappropriate generalization](http://en.wikipedia.org/wiki/Inappropriate_generalization), which neither is nor sounds like circular reasoning.)
[^11]: Technically, I mean "partially correct". This will be addressed in due time. Be patient, pedantic reader. This argument is hard enough to understand already.
[^12]: If you're curious how this works, click [here](https://gist.github.com/davidad/9288924). But I haven't settled on an ASM REPL solution I'm happy with -- this is just a one-off hack. A more legitimate ASM REPL may be the subject of a future blog post.
[^13]: Except for `rep` prefixes, which can iterate certain single instructions. I think it's fair to say those don't really count.
[^14]: You may point out here that C doesn't actually let you pass entire linked lists by value. Maybe that's because it's a _bad idea_.
[^15]: "The stack" is not merely a region of memory managed by the OS (like "the heap", its common counterpart). The stack is a hardware-accelerated mechanism deeply embedded in the CPU. There is a hardware register `rsp` (a.k.a. the stack pointer). A `push` instruction decrements `rsp` (usually by 8 at a time, in 64-bit mode, since pointers are expressed as numbers of 8-bit bytes, and 64/8=8) and then stores a value to `[rsp]`. A `pop` instruction retrieves a value from `[rsp]` and then increments `rsp`. A `call` instruction `push`es the current value of `rip` (a.k.a. the instruction pointer, or the program counter), and then executes an unconditional jump (`jmp`). Finally, a `ret` instruction `pop`s from the stack into `rip`, returning to wherever the matching `call` left off.
[^16]: I find calling conventions distasteful in general. The calling convention is like a shadow API (in fact, it's often referred to as the ABI, for application binary interface) that nobody has any control over (except the people at AMD, Intel, and Microsoft who are in a position to decide on such things) and that applies to every function, every component on every computer everywhere. What if we let people define their ABI as part of their API? Would the world come crashing down? I doubt it. You can already cause quite a bit of trouble by misusing A<em>P</em>Is; really, both API and ABI usage ought to be formally verified, and as such ought to have much more room for flexibility than they do now. &lt;/soapbox>
