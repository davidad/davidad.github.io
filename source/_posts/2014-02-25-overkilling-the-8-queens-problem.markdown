---
layout: post
title: "Overkilling the 8-queens problem"
date: 2014-02-25 10:52:57 -0500
comments: true
categories: 
---

Last night, a fellow [Hacker School](http://www.hackerschool.com)er challenged
me to a running-time contest on the classic [eight queens
puzzle](http://en.wikipedia.org/wiki/Eight_queens_puzzle). Naturally, I pulled
up my trusty
[Intel® 64 manual](http://www.intel.com/content/dam/www/public/us/en/documents/manuals/64-ia-32-architectures-software-developer-manual-325462.pdf)
and got to work. It turned out to be even faster than I expected, churning out
pretty-printed output in 15ms, which is totally dominated by the time it takes
the terminal to display it (it takes only 2ms if redirected to a file).

![pretty-printed output](http://i.imgur.com/5dOH49e.png)

<!-- more -->
([Click here to see the full output.](http://i.imgur.com/qjckCeo.png))

## The Approach

My solution method is heavily inspired by [this
paper](http://www.cl.cam.ac.uk/~mr10/backtrk.pdf) (which, appropriately enough,
concerns a beautifully insane programming language called MCPL, combining
features from ML, C, and Prolog). This paper contributes two key insights about
solving the 8-queens problem:

* Conceptually, we can model the solution space as the leaves of a tree, where
  each internal node of the tree corresponds to a partial board (with the number
  of queens equal to the tree depth), and each parent-child link represents
  adding another queen at the row number corresponding to the depth of the
  child. Since there can only be one queen per row in a correct solution, this
  tree is a superset of the actual solution set.

* Instead of actually constructing the tree, we can simply keep track of the
  current traversal state. In particular, this means we keep track of the
  currently occupied columns, the occupied leftward going diagonals, and the
  occupied rightward going diagonals, as they intersect the current row. (Each
  of these three state variables is eight bits of information.) In addition, we
  can keep track of the past traversal history of each level using ~~a~~ the
  stack.

If any of this is unclear, [check out the
paper](http://www.cl.cam.ac.uk/~mr10/backtrk.pdf), which has a beautiful diagram
that there is no need for me to attempt replicating.

## The Code

I'm going to go through the first[^1] version of the code, which doesn't
produce the pretty boards but has most of the clever tricks. (Ironically,
adding "pretty printing" made my code uglier. Maybe it's just
that I was up too late working on it.)

The heart of this algorithm is the sequence that updates the state variables as
we move from one layer into the next. This whole program is small enough that
it's still practical to just set aside registers to represent most variables;
in particular, `rdx` represents where it's okay to place a queen at the current
layer (e.g. it starts out as `0b11111111`), and `xmm1` (one of those fancy
128-bit registers that supports fancy new operations) stores the "occupied left
diagonals", "occupied right diagonals", and "occupied columns" states, in that
order (with "occupied columns" being the least significant word[^2]). `xmm2`,
`xmm3`, and `xmm4` are just being used as scratch space. Finally, `xmm7` is a
constant `0xff`.

### Instruction Dictionary

To spare you the effort of searching through the Intel® 64 manual yourself, here
are brief descriptions of all the fancy instructions I'm about to use.

* `vpsllw`: **Vector/Packed Shift Left (Logical) Words**. _Separately_ shifts
  left every word of the second argument by the number of bits represented as
  the third argument, and store the result to the first argument.
* `vpsrlw`: **Vector/Packed Shift Right (Logical) Words**. _Separately_ shifts
  right every word of the second argument by the number of bits represented as
  the third argument, and store the result to the first argument.
* `pblendw`: **Packed Blend Words**. Using the third argument as a mask,
  selectively copy words from the second argument to the first argument.
* `vpsrldq`: **Vector/Packed Shift Right (Logical) Double Quadword**. Shifts the
  entire second argument by the number of bytes specified in the third argument,
  and stores the result to the first argument.
* `por`: **Parallel OR**. Bitwise ORs the first and second argument and assigns
  the result to the first argument.
* `vpandn`: **Vector/Parallel AND NOT**. Inverts the second argument, ANDs the
  result with the third argument, and assigns the result of _that_ to the first
  argument.
* `movq`: **Move Quadword**. The standard way to move data between `xmm` registers and normal
   registers.

Now, let's take this a few lines at a time.
```nasm 8queens.asm https://github.com/davidad/8queens/blob/1989666c45baa639f152dfc89c70635f7007d20b/8queens.asm#L25 link_text:github start:25
  vpsllw xmm2, xmm1, 1      ; shift entire state to left, place in xmm2
  vpsrlw xmm3, xmm1, 1      ; shift entire state to right, place in xmm3
  pblendw xmm1, xmm2, 0b100 ; only copy "left-attacking" word back from xmm2
  pblendw xmm1, xmm3, 0b010 ; only copy "right-attacking" word back from xmm3
```

If you're accustomed to C, you might think of this as functionally equivalent to
something like `xmm1[2] <<= 1; xmm1[1] >>=1`[^3]. We want the word in position 1 to
shift right and the word in position 2 to shift left, while the word in position
0 (occupied columns) stays put.

```nasm 8queens.asm https://github.com/davidad/8queens/blob/1989666c45baa639f152dfc89c70635f7007d20b/8queens.asm#L29 link_text:github start:29
  vpsrldq xmm2, xmm1, 4     ; shift state right 4 *bytes*, place in xmm2
  vpsrldq xmm3, xmm1, 2     ; shift state right 2 bytes, place in xmm3
  por xmm2, xmm3            ; collect bitwise ors in xmm2
  por xmm2, xmm1            
```

Now, we want to combine the information about which squares in the next layer
are under attack. It doesn't matter from which direction -- we want to make sure
not to put a queen there. So, we shift right 2 words (= 4 bytes) and right 1 word
(= 2 bytes) and OR them all together (accumulating into a scratch register so we
don't clobber our state).

```nasm 8queens.asm https://github.com/davidad/8queens/blob/1989666c45baa639f152dfc89c70635f7007d20b/8queens.asm#L33 link_text:github start:33
  vpandn xmm4, xmm2, xmm7   ; invert and select low byte
  movq rdx, xmm4            ; place in rdx
  jmp next_state           ; now we're set up to iterate
```

But that still contains some stuff in the upper bytes. We only want the lower
byte. And we also want `1` bits where queens _should_ be allowed, rather than
where they're under attack. We can solve both problems with one `vpandn`
instruction, which will flip all the bits, but mask out everything except the
first byte (since `xmm7`=`0xff`).

So, now that we're iterating, what happens _next_?
### Instruction Dictionary

* `bsf`: **Bit Scan Forward**. Finds the least significant `1` bit in the second
  argument and stores the index of that bit into the first argument. If there is
  no `1` bit the second argument, the value of the first argument is undefined,
  and the zero flag (`ZF`) is set.
* `btc`: **Bit Clear**. Clears the bit in the first argument with index given by
  the second argument.
* `je`: **Jump If Equal**. Pretty self-explanatory, when used in conjunction
  with `cmp` (**Compare**).
* `jz`: **Jump If Zero**. Jumps to the specified address/label if the zero flag
  (ZF) is set.
* `push`: **Push To Stack**. Stores its single argument to the memory location
  pointed by `rsp`, and decrements `rsp` (usually by eight at a time, i.e., `rsp <- rsp-8`).
* `shl`: **Logical Shift Left** for non-`xmm` registers.

```nasm 8queens.asm https://github.com/davidad/8queens/blob/1989666c45baa639f152dfc89c70635f7007d20b/8queens.asm#L12 link_text:github start:12
next_state:
  bsf rcx, rdx             ; find next available position in current level
  jz backtrack             ; if there is no available position, we must go back
  btc rdx, rcx             ; mark position as unavailable
  cmp rsp, r14             ; check if we've done 7 levels already
  je win                   ; if so, we have a win state. otherwise continue
  movq r10, xmm1           ; save current state ...
  push rdx
  push r10                 ;   ... to stack
  mov rax, r15             ; set up attack mask
  shl rax, cl              ; shift into position
  movq xmm2, rax
  por xmm1, xmm2           ; mark as attacking in all directions
```

First we try scanning for an available position on this row -- one that isn't
under attack from already-placed queens, and that also hasn't already been
visited. If there is none, then we have no choice but to `backtrack` (a little
piece of code which is coming up soon). Assuming we find an available position,
we first mark it as visited/unavailable. We then check if this is the last
level that needs to be taken care of, by looking at the stack pointer. Since
the stack gets deeper by 16 bytes with every level, this test[^4] is easily set
up at program initialization. If the test is true, then we've discovered a
solution, or "win state" -- so we go ahead to the "win" code.

If we've neither succeeded nor failed, it means we just have to go another
level down in the tree. In order to have an efficient backtracking capability,
we store our state variables on the stack, so they can be restored when
everything fails deeper down in the tree. Finally, we update our model of which
squares are in danger by adding the queen we're currently placing as a
column-occupier and diagonal-occupier (modifying all three state variables at
once with the magic of `por`). Note here that `cl` is just a name for the least
significant byte of the `rcx` register, which houses the horizontal position of
the new queen.

What if we have to backtrack?
```nasm 8queens.asm https://github.com/davidad/8queens/blob/1989666c45baa639f152dfc89c70635f7007d20b/8queens.asm#L37 link_text:github start:37
backtrack:
  cmp rsp, r13             ; are we done?
  je done
  pop r10                  ; restore last state
  pop rdx
  movq xmm1, r10
  jmp next_state           ; try again
```

First, we have another stack-pointer test - if we've tried to backtrack past
the start of the program, then we know we've exhausted all possibilities and
just go to `done`. Assuming that's not at issue, we simply restore the `rdx`
and `xmm1` variables (using `r10` as scratch storage since one can't directly
pop `xmm` registers). Then we just jump back into our loop, with a new state
ready to go!

Now we're ready to look at the whole solution in context:
```nasm 8queens.asm https://github.com/davidad/8queens/blob/1989666c45baa639f152dfc89c70635f7007d20b/8queens.asm link_text:github
%include "os_dependent_stuff.asm"
  mov rdx, 0b11111111      ; all eight possibilities available
  mov r8, 0x000000000000   ; no squares under attack from anywhere
  movq xmm1, r8            ; maintain this state in xmm1
  mov r15, 0x000100010001  ; attack mask for one queen (left, right, and center)
  mov r14, 0xff            ; mask for low byte
  movq xmm7, r14           ; stored in xmm register
  mov r13, rsp             ; current stack pointer (if we backtrack here, then
  mov r14, rsp             ;   the entire solution space has been explored)
  sub r14, 2*8*7           ; this is where the stack pointer would be when we've
                           ;   completed a winning state
next_state:
  bsf rcx, rdx             ; find next available position in current level
  jz backtrack             ; if there is no available position, we must go back
  btc rdx, rcx             ; mark position as unavailable
  cmp rsp, r14             ; check if we've done 7 levels already
  je win                   ; if so, we have a win state. otherwise continue
  movq r10, xmm1           ; save current state ...
  push rdx
  push r10                 ;   ... to stack
  mov rax, r15             ; set up attack mask
  shl rax, cl              ; shift into position
  movq xmm2, rax
  por xmm1, xmm2           ; mark as attacking in all directions
  vpsllw xmm2, xmm1, 1      ; shift entire state to left, place in xmm2
  vpsrlw xmm3, xmm1, 1      ; shift entire state to right, place in xmm3
  pblendw xmm1, xmm2, 0b100 ; only copy "left-attacking" word back from xmm2
  pblendw xmm1, xmm3, 0b010 ; only copy "right-attacking" word back from xmm3
  vpsrldq xmm2, xmm1, 4     ; shift state right 4 *bytes*, place in xmm2
  vpsrldq xmm3, xmm1, 2     ; shift state right 2 bytes, place in xmm3
  por xmm2, xmm3            ; collect bitwise ors in xmm2
  por xmm2, xmm1            
  vpandn xmm4, xmm2, xmm7   ; invert and select low byte
  movq rdx, xmm4            ; place in rdx
  jmp next_state           ; now we're set up to iterate

backtrack:
  cmp rsp, r13             ; are we done?
  je done
  pop r10                  ; restore last state
  pop rdx
  movq xmm1, r10
  jmp next_state           ; try again

win:
  inc r8                   ; increment solution counter
  jmp next_state           ; keep going

done:
  mov rdi, r8              ; set system call argument to solution count
  mov rax, SYSCALL_EXIT    ; set system call to exit
  syscall                  ; this will exit with our solution count as status
```

If you're curious to investigate further, [run the code
yourself](https://github.com/davidad/8queens)[^5] and/or check out the [more
complicated, pretty-printing
version](https://github.com/davidad/8queens/blob/master/8queens.asm).

[^1]: Somewhat surprisingly, the first version actually _worked_.
[^2]: A word is two bytes. Why did I use words and not just bytes? The answer is that some of the fancy instructions we want to use don't allow us to work with data elements any smaller than words.
[^3]: But it's all taking place in the register file -- no memory accesses here!
[^4]: That is to say, the value of `r14`.
[^5]: Requires a recent (Sandy Bridge or later) Intel CPU.
