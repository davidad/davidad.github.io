%include "os_dependent_stuff.asm"

  ; Initialize constants.
  mov r12, 65537                 ; Exponent to modular-exponentiate with
  mov rbx, 235                   ; Modulus to modular-exponentiate with
  mov r15, NPROCS                ; Number of processes to fork.
  mov r14, (SIZE+1)*8            ; Size of shared memory; reserving first
                                 ; 64 bits for bookkeeping

  ; Check for command-line argument.
  cmp qword [rsp], 1
  je map_anon

open_file:
  ; We have a file specified on the command line, so open() it.
  mov rax, SYSCALL_OPEN
  mov rdi, [rsp+2*8]
  mov rsi, O_RDWR|O_CREAT        ; read/write mode; create if necessary
  mov rdx, 660o                  ; `chmod`-mode of file to create (octal)
  syscall
  mov r13, rax                   ; preserve file descriptor in r13
  mov rax, SYSCALL_PWRITE        ; adjust file size by writing to "end"
  mov rdi, r13
  mov rsi, null_byte             ; write a null byte
  mov rdx, 1                     ; just one byte
  mov r10, r14                   ; at offset of our desired file size
  dec r10                        ; minus one
  syscall
  mov r8,  r13
  mov r10, MAP_SHARED
  jmp mmap

map_anon:
  mov r10, MAP_SHARED|MAP_ANON   ; MAP_ANON means not backed by a file
  mov r8,  -1                    ; thus our file descriptor is -1
mmap:
  mov r9,   0                    ; ...and there's no file offset in either case.
  ; Ask the kernel for a shared memory mapping.
  mov rax, SYSCALL_MMAP
  mov rdx, PROT_READ|PROT_WRITE  ; We'd like a read/write mapping
  mov rdi,  0                    ; at no pre-specified memory location.
  mov rsi, r14                   ; Length of the mapping in bytes.
  syscall                        ; Do mmap() system call.
  test rax, rax                  ; Return value will be in rax.
  js error                       ; If it's negative, that's trouble.
  mov rbp, rax                   ; Otherwise, we have our memory region [rbp].

  lock add [rbp], r15            ; Initialize the first machine word to NPROCS.
                                 ; We'll use it to track the # of still-running
                                 ; processes.

  ; Next, fork NPROCS processes.
fork:
  mov eax, SYSCALL_FORK
  syscall
%ifidn __OUTPUT_FORMAT__,elf64
  test rax, rax                  ; We're a child iff return value of fork()==0.
  jz child
%elifidn __OUTPUT_FORMAT__,macho64
  test rdx, rdx                  ; Apple...you're not supposed to touch rdx here
  jnz child                      ; Apple, what
%endif
  dec r15
  jnz fork

parent:
  pause
  cmp qword [rbp], 0
  jnz parent                     ; Wait for [rbp] to be zero
%ifndef NOPRINT
  mov rbx, rbp
  add rbx, r14                   ; rbx marks the end of the [rbp] region
  add rbp, 8                     ; Don't print the first 8 bytes
print_loop:
  mov rdi, unsigned_int          ; Set printf format string
  xor rax, rax                   ; Clear rax (number of non-int args to printf)
  xor rdx, rdx                   ; Clear rdx
  mov dl, [rbp]                  ; so I can load a single byte into its low byte
  mov rsi, rdx                   ; Transfer to the first-printf-arg register
  and rsp, ~(0xf)                ; 16-byte-align stack pointer
  call printf                    ; Do printf
  inc rbp                        ; Increment data pointer
  cmp rbp, rbx                   ; Make sure we haven't hit the region's end
  jne print_loop
%endif

success:
  mov eax, SYSCALL_EXIT          ; Normal exit
  mov edi, 0
  syscall

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
.next:
  cmp rdi, rsi                   ; Make sure we haven't hit the end.
  jne find_work

child_exit:                      ; If we have hit the end, we're done.
  lock dec qword [rbp]           ; Atomic-decrement the # of active processes.
  jmp success

found_work:
  mov r8, 8                      ; There are 8 tasks per piece.
do_task:                       ; This part does the actual work of mod-exp.
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
  dec r8                         ; Decrement task counter
  jnz do_task                    ; Do the next task if there is one.
  jmp find_work.next             ; Else, find the next piece of work.

error:
  mov rdi, rax                   ; In case of error, return code is -errno...
  mov rax, SYSCALL_EXIT
  neg rdi                        ; ...so negate to get actual errno
  syscall

%ifndef NOPRINT
  extern printf
  section .data
  unsigned_int:
    db `%u\n`
  null_byte:
    db 0
%else
  section .data
  null_byte:
    db 0
%endif
