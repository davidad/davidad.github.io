---
layout: post
title: "Concurrency Primitives in Intel 64 Assembly"
date: 2014-03-23 20:36:47 -0400
comments: true
categories: 
---

Now that nearly every computer has some form of multi-processing (that is,
multiple CPUs sharing a single address space), some high-level languages are
starting to get attention for their concurrency features. Many languages refer
to such features as "concurrency primitives." But since these are high-level
languages, we know that these "primitives" must ultimately be implemented with
hardware operations. Older high-level languages, like C, don't have baked-in
support for such operations -- not because such languages are lower-level, but
simply because the operations in question _weren't a thing_ when C was invented.
Assembly language, being up to date with the latest CPU capabilities by
definition[^5], should provide the best window into the true nature of today's
concurrency operations.

In this post I'm going to walk you through a (relatively) simple concurrent
assembly program which runs on OSX or Linux. Here's the demo
([github](https://github.com/davidad/asm_concurrency)):

    bash-3.2$ time ./concurrency-noprint-x1 foo    # single-worker version

    real  0m1.458s
    user  0m1.445s
    sys   0m0.010s
    bash-3.2$ # now run two at once
    bash-3.2$ time ./concurrency-noprint-x1 foo-2 & ./concurrency-noprint-x1 foo-2
    [1] 71366

    real  0m0.785s
    user  0m0.780s
    sys   0m0.001s
    [1]+  Done                    time ./concurrency-noprint-x1 foo-2
    bash-3.2$ time ./concurrency-noprint-x4 foo-3  # four-worker version

    real  0m0.417s
    user  0m0.413s
    sys   0m0.003s
    bash-3.2$ time ./concurrency-noprint-x7 foo-4  # seven-worker version

    real  0m0.295s
    user  0m0.283s
    sys   0m0.001s
    bash-3.2$ diff -s --from-file=foo foo-*
    Files foo and foo-2 are identical
    Files foo and foo-3 are identical
    Files foo and foo-4 are identical

<!-- more -->

What the program actually does is a pretty useless but computationally
nontrivial and easily parallelizable task: taking the offset of each byte from
the start of the buffer to the 65537th power mod 235, and storing that value
back to each byte. Since it's mod-235, the output should repeat itself every 235
bytes:

    bash-3.2$ hexdump -e '235/1 "%4u" "\n"' -s8 foo
       1  37 158 194  35 206  32 128  54 120 146 102 233   9 125  36 122 118 184 210 121 232  33  14  50 161  72  98 164 160  11 157  38  49 180 136 162 228 154  15  76  12  88 124  10  46  47  48  84 205   6  82  18  79 175 101 167 193 149  45  56 172  83 169 165 231  22 168  44  80  61  97 208 119 145 211 207  58 204  85  96 227 183 209  40 201  62 123  59 135 171  57  93  94  95 131  17  53 129  65 126 222 148 214   5 196  92 103 219 130 216 212  43  69 215  91 127 108 144  20 166 192  23  19 105  16 132 143  39 230  21  87  13 109 170 106 182 218 104 140 141 142 178  64 100 176 112 173  34 195  26  52   8 139 150  31 177  28  24  90 116  27 138 174 155 191  67 213   4  70  66 152  63 179 190  86  42  68 134  60 156 217 153 229  30 151 187 188 189 225 111 147 223 159 220  81   7  73  99  55 186 197  78 224  75  71 137 163  74 185 221 202   3 114  25  51 117 113 199 110 226   2 133  89 115 181 107 203  29 200  41  77 198 234   0
    *

Here, I'm asking `hexdump` to display this binary file in lines of 235 bytes
each, one byte at a time, giving each byte 4 characters field-width and printing
it as an unsigned integer (in decimal), with a newline at the end of the line,
starting from offset 8 (as the first 8 bytes of the file are used by the
concurrency mechanism for bookkeeping purposes[^2]). The `*` on the second line
of `hexdump`'s output means "every line after this matches it," so the file must
repeat itself every 235 bytes until the end. We can suppress the `*` with `-v`
and examine the last 4 lines, just to be sure we understand it correctly:

    bash-3.2$ hexdump -e '235/1 "%4u" "\n"' -s8 -v foo | tail -n4
       1  37 158 194  35 206  32 128  54 120 146 102 233   9 125  36 122 118 184 210 121 232  33  14  50 161  72  98 164 160  11 157  38  49 180 136 162 228 154  15  76  12  88 124  10  46  47  48  84 205   6  82  18  79 175 101 167 193 149  45  56 172  83 169 165 231  22 168  44  80  61  97 208 119 145 211 207  58 204  85  96 227 183 209  40 201  62 123  59 135 171  57  93  94  95 131  17  53 129  65 126 222 148 214   5 196  92 103 219 130 216 212  43  69 215  91 127 108 144  20 166 192  23  19 105  16 132 143  39 230  21  87  13 109 170 106 182 218 104 140 141 142 178  64 100 176 112 173  34 195  26  52   8 139 150  31 177  28  24  90 116  27 138 174 155 191  67 213   4  70  66 152  63 179 190  86  42  68 134  60 156 217 153 229  30 151 187 188 189 225 111 147 223 159 220  81   7  73  99  55 186 197  78 224  75  71 137 163  74 185 221 202   3 114  25  51 117 113 199 110 226   2 133  89 115 181 107 203  29 200  41  77 198 234   0
       1  37 158 194  35 206  32 128  54 120 146 102 233   9 125  36 122 118 184 210 121 232  33  14  50 161  72  98 164 160  11 157  38  49 180 136 162 228 154  15  76  12  88 124  10  46  47  48  84 205   6  82  18  79 175 101 167 193 149  45  56 172  83 169 165 231  22 168  44  80  61  97 208 119 145 211 207  58 204  85  96 227 183 209  40 201  62 123  59 135 171  57  93  94  95 131  17  53 129  65 126 222 148 214   5 196  92 103 219 130 216 212  43  69 215  91 127 108 144  20 166 192  23  19 105  16 132 143  39 230  21  87  13 109 170 106 182 218 104 140 141 142 178  64 100 176 112 173  34 195  26  52   8 139 150  31 177  28  24  90 116  27 138 174 155 191  67 213   4  70  66 152  63 179 190  86  42  68 134  60 156 217 153 229  30 151 187 188 189 225 111 147 223 159 220  81   7  73  99  55 186 197  78 224  75  71 137 163  74 185 221 202   3 114  25  51 117 113 199 110 226   2 133  89 115 181 107 203  29 200  41  77 198 234   0
       1  37 158 194  35 206  32 128  54 120 146 102 233   9 125  36 122 118 184 210 121 232  33  14  50 161  72  98 164 160  11 157  38  49 180 136 162 228 154  15  76  12  88 124  10  46  47  48  84 205   6  82  18  79 175 101 167 193 149  45  56 172  83 169 165 231  22 168  44  80  61  97 208 119 145 211 207  58 204  85  96 227 183 209  40 201  62 123  59 135 171  57  93  94  95 131  17  53 129  65 126 222 148 214   5 196  92 103 219 130 216 212  43  69 215  91 127 108 144  20 166 192  23  19 105  16 132 143  39 230  21  87  13 109 170 106 182 218 104 140 141 142 178  64 100 176 112 173  34 195  26  52   8 139 150  31 177  28  24  90 116  27 138 174 155 191  67 213   4  70  66 152  63 179 190  86  42  68 134  60 156 217 153 229  30 151 187 188 189 225 111 147 223 159 220  81   7  73  99  55 186 197  78 224  75  71 137 163  74 185 221 202   3 114  25  51 117 113 199 110 226   2 133  89 115 181 107 203  29 200  41  77 198 234   0
       1  37 158 194  35 206  32 128  54 120 146 102 233   9 125  36 122 118 184 210 121 232  33  14  50 161  72  98 164 160  11 157  38  49 180 136 162 228 154  15  76  12  88 124  10  46  47  48  84 205   6  82  18  79 175 101 167 193 149  45  56 172  83 169 165 231  22 168  44  80  61  97 208 119 145 211 207  58 204  85  96 227 183 209  40 201  62 123  59 135 171  57  93  94  95 131  17  53 129  65 126 222 148 214   5 196  92 103 219 130 216 212  43  69 215  91 127 108 144  20 166 192  23  19 105  16 132 143  39 230

Notice that it doesn't have an even multiple of 235 bytes -- if you scroll all
the way over, you'll see that the very last line ends in the middle. That's
because this file isn't generated by printing a particular 235-byte sequence in
a loop. Rather, every <a name="task-size"></a>8-byte machine word is computed
separately; the 235-byte repeating structure is built into the nature of the
problem the program solves (which I chose, in part, so that it's easy to check
whether the results are sensible).

<a name="critical-sections"></a>
## Critical Sections [#](#critical-sections)

Let's begin with a conceptual overview of the problem concurrency primitives are
supposed to address[^1]. When we have a single process operating in an address
space (that it, a non-concurrent process), we can reason about the state of the
entire address space at a particular point during the execution of the process.
We can make statements like "this variable must be positive because we checked
that it was positive four lines of code ago and we haven't changed it since
then." In a concurrent process, a lot of this reasoning goes out the window,
because our process's sibling might have set the variable to `-1` between here
and there. We just have no way of knowing -- the possible state transitions are
too various to justify strong claims about. Claims like "the program produces
correct output" tend to be very strong indeed in this context, and we often want
to make such claims (at least to ourselves).

So, much like [security is, in a sense, all about limiting
features](/blog/2014/03/16/infosec-the-product-design-correspondence/),
concurrency primitives are means to restrict the possible state transitions of
memory shared by multiple processors. The most common bugaboo is that a
shared-memory state could have been changed by a sibling between the time that
we measure it and the time that we take action based upon that measurement. So,
as a general rule, the most basic concurrency operations **measure a shared
state** and then use the data to **change that shared state**, while **excluding
siblings** from accessing it throughout the whole operation. A region of code
like this -- where siblings are not allowed, during its execution, to access a
particular memory location -- is called a **critical section**.

On all Intel CPUs prior to Haswell (which started shipping last year; I don't
have one yet), "actual" critical sections are limited to **single machine
instructions** with **a `lock` prefix**; larger critical sections can be
emulated based on these single-instruction primitives. We'll be doing a
variation of this today.

<a name="tasks-and-workers"></a>

## Tasks and Workers [#](#tasks-and-workers)

I don't know of any particular argument to justify the tasks-and-workers
perspective on parallel computing, but in practice, it's the one I've found most
useful for organizing my code, and it seems to be fairly common. The idea is
this: we divide our program's workload into **tasks** of some granularity, and
each task is picked up and operated on by exactly one of some number of
interchangeable **workers**, which each run concurrently. The tasks should not
be too small, so that the amount of work involved in choosing a task is not too
great[^3], but they should also not be too large, so that if any worker finishes
a task earlier than the others, there will likely be another task ready for it
to do.

In this context, **a task is a type of critical section**, because once a task
has been picked up by any single worker, the other workers are supposed to leave
it alone. But critical sections carry the connotation of being very small, so
they can execute and get out of the way quickly. I suppose I've been fortunate
enough to work in domains where I've had the luxury to split things up into
independent tasks most of the time. (These domains are sometimes referred to as
[_embarrassingly
parallel_](http://en.wikipedia.org/wiki/Embarrassingly_parallel).) But in the
code below, we'll also see one example of a state variable which is operated on
by short critical sections instead of tasks.

<a name="show-me-the-code"></a>
# Show me the code already! [#](#show-me-the-code)

```nasm concurrency.asm https://github.com/davidad/asm_concurrency/blob/TJ-1/concurrency.asm#L1-8 link_text:context
%include "os_dependent_stuff.asm"

  ; Initialize constants.
  mov r12, 65537                 ; Exponent to modular-exponentiate with
  mov rbx, 235                   ; Modulus to modular-exponentiate with
  mov r15, NPROCS                ; Number of worker processes to fork.
  mov r14, (SIZE+1)*8            ; Size of shared memory; reserving first
                                 ; 64 bits for bookkeeping
```

The first two constants are pretty straightforward -- just the parameters of the
task to compute. `NPROCS` and `SIZE` need a bit of explanation. These are
constants which are actually defined in the `Makefile` and passed in to `nasm`
using the `-D` option (as in `-DNPROCS=7`)[^4]. `SIZE` is actually measured in
8-byte machine words; it's the number of **tasks** we want to perform. (As I
briefly mentioned [earlier](#task-size), each task in this program is an
8-byte machine word of the output file to be computed.)

```nasm concurrency.asm https://github.com/davidad/asm_concurrency/blob/TJ-1/concurrency.asm#L10-12 link_text:context start:10
  ; Check for command-line argument.
  cmp qword [rsp], 1
  je map_anon
```

When our program is entered by the OS, the command-line is on the stack; `[rsp]`
is the number of command-line tokens (including the name of the program itself),
`[rsp+8]` will be a pointer to the name of the program, `[rsp+2*8]` a pointer to
the first command-line argument (if there is one), and so on. If we don't have
any command-line arguments, then the number of tokens will be 1 (just the name
of the program). In this case, we're going to a request an anonymous region of
memory; otherwise, we're going to open the file specified on the command line
and map that. _Note:_ if you haven't seen `mmap` before, check out [its man
page](http://man7.org/linux/man-pages/man2/mmap.2.html). In my opinion, it's the
"right" way to do either memory allocation ("anonymous" mappings) or file I/O.

<a name="open-ftruncate=mmap"></a>
## `open()`, `ftruncate()`, and `mmap()` [#](#open-ftruncate-mmap)

```nasm concurrency.asm https://github.com/davidad/asm_concurrency/blob/TJ-1/concurrency.asm#L14-43 link_text:context start:14
open_file:
  ; We have a file specified on the command line, so open() it.
  mov rax, SYSCALL_OPEN          ; set up open()
  mov rdi, [rsp+2*8]               ; filename from command line
  mov rsi, O_RDWR|O_CREAT          ; read/write mode; create if necessary
  mov rdx, 660o                    ; `chmod`-mode of file to create (octal)
  syscall                        ; do open() system call
  mov r13, rax                   ; preserve file descriptor in r13
  mov rax, SYSCALL_FTRUNCATE     ; set up ftruncate() to adjust file size
  mov rdi, r13                     ; file descriptor
  mov rsi, r14                     ; desired file size
  syscall                        ; do ftruncate() system call
  mov r8,  r13
  mov r10, MAP_SHARED
  jmp mmap

  ; Ask the kernel for a shared memory mapping.
map_anon:
  mov r10, MAP_SHARED|MAP_ANON     ; MAP_ANON means not backed by a file
  mov r8,  -1                      ; thus our file descriptor is -1
mmap:
  mov r9,   0                      ; and there's no file offset in either case.
  mov rax, SYSCALL_MMAP          ; set up mmap()
  mov rdx, PROT_READ|PROT_WRITE    ; We'd like a read/write mapping
  mov rdi,  0                      ; at no pre-specified memory location.
  mov rsi, r14                     ; Length of the mapping in bytes.
  syscall                        ; do mmap() system call.
  test rax, rax                  ; Return value will be in rax.
  js error                       ; If it's negative, that's trouble.
  mov rbp, rax                   ; Otherwise, we have our memory region [rbp].
```

```nasm concurrency.asm https://github.com/davidad/asm_concurrency/blob/TJ-1/concurrency.asm#L141-145 link_text:context start:141
error:
  mov rdi, rax                   ; In case of error, return code is -errno...
  mov rax, SYSCALL_EXIT
  neg rdi                        ; ...so negate to get actual errno
  syscall
```

We actually have to make three system calls to get this set up: one to open the
file (`SYSCALL_OPEN`), one to extend it to the appropriate size
(`SYSCALL_FTRUNCATE`), and finally one to make the memory mapping
(`SYSCALL_MMAP`).

<a name="lock-add"></a>
## `lock add` [#](#lock-add)

```nasm concurrency.asm https://github.com/davidad/asm_concurrency/blob/TJ-1/concurrency.asm#L45-47 link_text:context start:45
  lock add [rbp], r15            ; Add NPROCS to the file's first machine word.
                                 ; We'll use it to track the # of still-running
                                 ; worker processes.
```

Here's our first concurrency primitive! We're going to add `NPROCS` to the first
machine word of this file. We're counting on the fact that when the file is
first created, all bytes will appear to be zero (a fact which [is actually true
on most Unix implementations](http://unixhelp.ed.ac.uk/CGI/man-cgi?truncate+2)).
Why aren't we just _setting_ the word to zero? Well, a neat feature of this
program is that we can run multiple copies of it on the same file, and they'll
share the work as if by magic. So, if we're running as the second copy of the
program, we don't want to clobber this piece of bookkeeping state -- we just
want to contribute `NPROCS` workers to the worker pool.

<a name="fork"></a>
## `fork()` [#](#fork)

```nasm concurrency.asm https://github.com/davidad/asm_concurrency/blob/TJ-1/concurrency.asm#L49-61 link_text:context start:49
  ; Next, fork NPROCS processes.
fork:
  mov eax, SYSCALL_FORK
  syscall
%ifidn __OUTPUT_FORMAT__,elf64     ; (This means we're running on Linux)
  test rax, rax                  ; We're a child iff return value of fork()==0.
  jz child
%elifidn __OUTPUT_FORMAT__,macho64 ; (This means we're running on OSX)
  test rdx, rdx                  ; Apple...you're not supposed to touch rdx here
  jnz child                      ; Apple, what
%endif
  dec r15
  jnz fork
```

Apple's implementation of `fork()` is a little messed up, so unfortunately we're
forced to put some OS-dependent logic in here. But the basic idea is, we're
going to keep calling `fork()` only if (a) we're the parent process, and not a
newly `fork()`ed worked process, and (b) the number of processes we were
supposed to spawn hasn't decremented to zero yet.

<a name="the-parent"></a>
## The parent process [#](#the-parent)

```nasm concurrency.asm https://github.com/davidad/asm_concurrency/blob/TJ-1/concurrency.asm#L63-66 link_text:context start:63
parent:
  pause
  cmp qword [rbp], 0
  jnz parent                     ; Wait for [rbp], the worker count, to be zero
```

Now, the parent process simply waits until there aren't any active workers/child
processes (they'll gracefully disappear once there's no more work for them to
do). The `pause` instruction is a hint to the system that it shouldn't actually
spend a lot of energy spinning in this loop. 

```nasm concurrency.asm https://github.com/davidad/asm_concurrency/blob/TJ-1/concurrency.asm#L84-87 link_text:context start:84
exit_success:
  mov eax, SYSCALL_EXIT          ; Normal exit
  mov edi, 0
  syscall
```

Once the number of active workers is zero, the parent bails out, returning the
sucess code, `0`.

<a name="the-worker"></a>
## Dividing up work [#](#the-worker)

Here's where our workers divide up their tasks -- the most important
concurrency-related operation in the program:

```nasm concurrency.asm https://github.com/davidad/asm_concurrency/blob/TJ-1/concurrency.asm#L89-104 link_text:context start:89
child:
  mov rsi, r14                   ; Restore rsi from r14 (saved earlier)
  mov cl, 0xff                   ; Set rcx to be nonzero
  mov rdi, 8                     ; Start from index 8 (past the bookkeeping)
find_work:                       ; and try to find a piece of work to claim
  xor rax, rax
  cmp qword [rbp+rdi], 0         ; Check if qword [rbp+rdi] is unclaimed.
  jnz .moveon                    ; If not, move on - no use trying to lock.
  lock cmpxchg [rbp+rdi], rcx    ; Try to "claim" qword [rbp+rdi] if it is still
                                 ; unclaimed.
  jz found_work                  ; If successful, zero flag is set
.moveon:
  add rdi, 8                     ; Otherwise, try a different piece.
find_work.next:
  cmp rdi, rsi                   ; Make sure we haven't hit the end.
  jne find_work
```

The worker is linearly scanning each 8-byte word, starting with the second one
in the `[rbp]` region (since the word right at `[rbp]` just represents how many
workers there are), looking for one that is zero. As we covered earlier, the
file is going to start out being all zeroes. The way I imagine this setup in my
head, the file starts out as a barren desert of zeroes, like the old American
West, and the workers are searching for a plot of land to homestead on. The
first empty plot of land they find, they put up a sign that says "RESERVED" and
they start building their homestead (that's the task). In this case, the
RESERVED sign is `0xff`. Now, other workers will keep on movin' until they find
their own plot of land. The key here is to prevent two workers from putting up a
RESERVED sign at the same location. That's where **`lock cmpxchg`** comes in. 

<a name="lock-cmpxchg"></a>
### `lock cmpxchg` (compare-and-swap) [#](#lock-cmpxchg)

This is a slightly complex but beautiful operation. It takes three parameters:

* a _memory location_ (`[rbp+rdi]` in this case), which has operand size
  dependent on the operand size of the next parameter (in this case, it's an
  8-byte machine word, because the next parameter is an 8-byte register)[^6],
* an _update value_ to store (`rcx` in this case, holding the value `0xff`, our
  sentinel for RESERVED), and
* an _expected value_ to compare against (always `rax`, an implicit parameter,
  and in this case zeroed out by `xor rax, rax`; zero is the value of unreserved
  words because it is the value freshly allocated files are filled with).

The first thing `lock cmpxchg` will do is lock the memory location and compare
it to the expected value. Then, depending on the result, one of two things will
happen:

* If the comparison fails, that means the state of memory isn't what we
  expected---it must have changed since we last looked. This is bad news; the
  update is aborted. To inform us exactly what went wrong, `cmpxchg` will
  overwrite `rax` with whatever is actually in memory _now_ (instead of what we
  expected). The zero-flag `ZF` will be cleared to signal non-equality, and the
  memory location will be unlocked.
* If the value in memory _does_ match what we expected, then our update
  value replaces it in that memory location before any other CPU/core has a
  chance to either read or write there. That's a "successful" compare-and-swap.
  The zero-flag `ZF` will be set to signal success, and the memory location will
  be unlocked as soon as it is updated.

The upshot in our application is that it's impossible for more than one worker
to reserve the same task, because reservation always happens in an _atomic_
(`lock`ed) operation, which:

* will be aborted if another reservation happened before it, and
* will prevent any other atomic operation from starting until this one is done.

<a name="tatas"></a>
### "test-and-test-and-set" [#](#tatas)

You may notice that we do an ordinary `cmp` in advance of the `lock cmpxchg`.
That's not strictly necessary, but it speeds up this part of the program quite
bit; if a location was already claimed some time ago, we may as well notice that
before putting a `lock` on it (which is a moderately expensive operation) and
simply move on until we find something that _looks_ empty (then `lock cmpxchg`
to be _sure_ it's empty).

<a name="doing-the-task"></a>
## Doing the task [#](#doing-the-task)

```nasm concurrency.asm https://github.com/davidad/asm_concurrency/blob/TJ-1/concurrency.asm#L110-139 link_text:context start:110
found_work:
  mov r8, 8                      ; There are 8 pieces per task.
do_piece:                       ; This part does the actual work of mod-exp.
  mov r13, r12                   ; Copy exponent to r13.
  mov rax, rdi                   ; The actual value to mod-exp should start
  sub eax, 0x7                   ; at 1 for the first byte after the bookkeeping
  xor rdx, rdx                   ; word. This value is now in rax.
  div rbx                        ; Do modulo with modulus.
  mov r11, rdx                   ; Save remainder -- "modded" base -- to r11.
  mov rax, 1                     ; Initialize "result" to 1.
.modexploop:
  test r13, 1                    ; Check low bit of exponent
  jz .shift
  mul r11                        ; If set, multiply result by base
  div rbx                        ; Modulo by modulus
  mov rax, rdx                   ; result <- remainder
.shift:
  mov r14, rax                   ; Save result to r14
  mov rax, r11                   ; and work with the base instead.
  mul rax                        ; Square the base.
  div rbx                        ; Modulo by modulus
  mov r11, rdx                   ; base <- remainder
  mov rax, r14                   ; Restore result from r14
  shr r13, 1                     ; Shift exponent right by one bit
  jnz .modexploop                ; If the exponent isn't zero, keep working
  mov byte [rbp+rdi], al         ; Else, store result byte.
  inc rdi                        ; Move forward
  dec r8                         ; Decrement piece counter
  jnz do_piece                   ; Do the next piece if there is one.
  jmp find_work.next             ; Else, find the next task.
```

This article is long enough without a detailed prose explanation of [binary
exponentiation](http://en.wikipedia.org/wiki/Modular_exponentiation#Right-to-left_binary_method)
(which isn't what it's about, anyway). Suffice it to say that given an offset
into the `[rbp]` region `rdi`, this chunk of code will replace each byte from
`[rbp+rdi]` to `[rbp+rdi+7]` with the appropriate mod-exps of the values `rdi`
through `rdi+7`. The code is somewhat deliberately inefficient (lots of `div`s,
which consume dozens of clock cycles each) for realism's sake---we want tasks
to take a nontrivial length of time.

<a name="being-done"></a>
## Being done [#](#being-done)

_Note:_ the block of code below is out-of-order and overlaps both of the
previous two.

```nasm concurrency.asm https://github.com/davidad/asm_concurrency/blob/TJ-1/concurrency.asm#L102-110 link_text:context start:102
find_work.next:
  cmp rdi, rsi                   ; Make sure we haven't hit the end.
  jne find_work

child_exit:                      ; If we have hit the end, we're done.
  lock dec qword [rbp]           ; Atomic-decrement the # of active processes.
  jmp exit_success

found_work:
```
Once there are no more unclaimed tasks to claim, we're going to successfully
terminate the worker. But first, we need to decrement the number of active
workers.

<a name="lock dec"></a>
### `lock dec` [#](#lock-dec)

By now you can probably guess that `lock dec` is a version of the `dec`
(decrement) operation which will ensure that no other worker can decrement the
number-of-active-workers variable at the same time (e.g. the last two workers
reading the value `2`, decrementing it, and both writing back `1` and exiting,
with nobody left to decrease it to `0`).

<a name="badness"></a>
## What should have been done differently<br/>(if this weren't just an example) [#](#badness)

It's worth pointing out that for this particular problem, I did a lot of things
here that don't actually make so much sense.

* There's no particular reason to allow multiple simultaneous invocations of the
  whole program on the same file. If that requirement is relaxed, then it makes
  a lot more sense to divide up the work by starting each worker at a different
  offset and having them all skip $n$ tasks ahead when they finish (e.g. with
  $n=7$ workers, the seventh worker would take the $(7k+6)$th task for every
  integer $k$).
* Even with the requirement in question, there would be more efficient ways to
  divide up tasks---for instance, instead of trying to claim every task in
  order, workers could maintain a second bookkeeping word which would track the
  address of the current next-unclaimed-task.
* Tasks should have been rather larger than single 8-byte machine words; the
  coordination overhead for tasks at this fine granularity is unlikely to pay
  off.
* The modular exponentiation could have been implemented more efficiently.
* In fact, since the result is just a single 235-byte pattern that repeats over
  and over, I could have just computed it once and repeatedly written it into
  the file.  (Since this would be a primarily storage-bound operation, there
  wouldn't even be much sense in parallelizing it.)

But hey, now we know how to write concurrent x64 programs using
memory-mapped files.


<a name="conclusion"></a>
## Conclusion [#](#conclusion)

In whichever abstraction we're working, if we're doing concurrent processing on
an Intel platform, it may be worth considering how the abstraction resolves down
to concepts like these. See if your platform exposes a thing like `mmap()`, for
instance, and consider how your "concurrency primitives" might translate into
individual `lock`ed operations. This will assist in reasoning about performance
issues, as well as providing a deeper understanding of your concurrency
primitives' guarantees.

And, of course, make sure that you've given assembly a big check-mark under "Has
Concurrency Primitives?" on your personal programming-environment scorecard.

[^1]: Pun not intended.
[^2]: If I had been doing serious work, instead of using a flat binary file, I would be using [Cap'n Proto](http://kentonv.github.io/capnproto/), so the bookkeeping field(s) would be well-delineated. Perhaps in a future article, I'll show how to do that from assembly. Then, instead of `hexdump`, I'd be using `capnp` to explore the data. But `hexdump` is a quite versatile tool and nice to know anyway.
[^3]: The code displayed here violates this rule pretty badly, which is probably why the speedup from running in parallel is noticeably worse than ideal, but I think to do better would overcomplicate the presentation.
[^4]: I could (should?) have used command-line arguments for these values, but let's face it, parsing command-line arguments is annoying in _any_ language, let alone assembly.
[^5]: This may be counterintuitive if you think of assembly as a conspicuously old-school way to program. I won't deny that it is, but `nasm`, DynASM, `r2`, and the other tools I use for assembly hacking are relentlessly kept in sync with Intel's assembly-language specification, which is updated in advance of every new CPU release. Other tools take much longer to adapt because, well, Intel doesn't _specify_ exactly how they should make use of new features.  So, in fact, the latest hardware is supported in assembly before it's supported anywhere else.
[^6]: There are some applicatons for which you might wish to compare-and-swap _two_ machine words (often, two pointers) in a single atomic operation. This can be done using the `lock cmpxchg16b` instruction (note: the 16 bytes still have to be contiguous in memory, and in fact must be 16-byte-aligned).
