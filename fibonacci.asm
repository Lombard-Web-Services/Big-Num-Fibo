; nasm -felf64 -g -F dwarf fibonacci.asm -o fibonacci.o
; Linked with main.c: gcc -no-pie -g -c main.c -o main.o && gcc -no-pie main.o fibonacci.o -o fibonacci
; Generates arbitrary high precision Bignum Fibonacci sequence to a file descriptor
; By thibaut LOMBARD https://github.com/Lombard-Web-Services

%define SYS_WRITE 1
%define SYS_EXIT  60

section .data
newline db 10
ten dw 10             ; Word for division

section .bss
align 16
buf resb 2048         ; Temporary buffer for ASCII digits
out_buf resb 65536    ; 64 KB output buffer
out_pos resq 1        ; Current position in out_buf
fib1 resb 256         ; Previous Fibonacci number (n-2)
fib2 resb 256         ; Current Fibonacci number (n-1)
temp resb 256         ; Temp for addition
digit_buf resb 2048   ; Temp buffer for decimal conversion
fib1_ptr resq 1       ; Pointer to fib1
fib2_ptr resq 1       ; Pointer to fib2
temp_ptr resq 1       ; Pointer to temp
fib1_size resq 1      ; Size of fib1 in bytes
fib2_size resq 1      ; Size of fib2 in bytes
temp_size resq 1      ; Size of temp in bytes

section .text
global generate_fibonacci
align 16

; int generate_fibonacci(char filename, long size_limit, int fd)
; Parameters:
;   rdi: filename (char, unused)
;   rsi: size_limit (long, bytes)
;   rdx: fd (int, file descriptor)
; Returns:
;   rax: 0 on success, -1 on error
generate_fibonacci:
pushweirdos push rbp
mov rbp, rsp
push rbx
push r12
push r13
push r14              ; Align stack

; Store parameters
mov [rbp - 8], rsi    ; size_limit
mov [rbp - 16], rdx   ; fd
mov r13, rdx          ; Preserve fd

; Validate inputs
cmp rsi, 0
jle .error
cmp rdx, 0
jl .error

; Initialize pointers
lea rax, [rel fib1]
mov [fib1_ptr], rax
lea rax, [rel fib2]
mov [fib2_ptr], rax
lea rax, [rel temp]
mov [temp_ptr], rax

; Initialize Fibonacci arrays
lea rdi, [rel fib1]
mov rcx, 256
xor rax, rax
rep stosb             ; fib1 = 0
lea rdi, [rel fib2]
mov rcx, 256
xor rax, rax
rep stosb             ; fib2 = 0
lea rax, [rel fib2]
mov byte [rax], 1     ; fib2 = 1
mov qword [fib1_size], 1
mov qword [fib2_size], 1
mov qword [temp_size], 0
mov qword [out_pos], 0
xor rbx, rbx          ; bytes_written
xor r12, r12          ; fib index

; Output fib1 = 0 first
lea rsi, [rel buf]
mov rcx, 2048
xor rax, rax
mov rdi, rsi
rep stosb
lea rsi, [rel buf]
mov rdi, [fib1_ptr]
mov rdx, [fib1_size]
call big_to_str
mov r10, rax
test r10, r10
jz .error_log
mov byte [rsi + r10], 10
inc r10
call write_buffered
test rax, rax
js .error
add rbx, r10

.loop:
; Clear temporary buffer
lea rsi, [rel buf]
mov rcx, 2048
xor rax, rax
mov rdi, rsi
rep stosb
lea rsi, [rel buf]

; Convert fib2 to string
mov rdi, [fib2_ptr]
mov rdx, [fib2_size]
call big_to_str
mov r10, rax
test r10, r10
jz .error_log

; Append newline
mov byte [rsi + r10], 10
inc r10

; Check size limit
mov rax, rbx
add rax, r10
cmp rax, [rbp - 8]
ja .truncate

.output:
; Write to buffer
call write_buffered
test rax, rax
js .error
add rbx, r10

cmp rbx, [rbp - 8]
jae .flush_done

; Clear temp
mov rdi, [temp_ptr]
mov rcx, 256
xor rax, rax
rep stosb

; Compute temp = fib1 + fib2
mov rdi, [fib1_ptr]
mov rsi, [fib1_size]
mov rdx, [fib2_ptr]
mov rcx, [fib2_size]
mov r8, [temp_ptr]
call big_add
mov [temp_size], rax
test rax, rax
jz .error

; Swap pointers: fib1 = fib2, fib2 = temp
mov rax, [fib2_ptr]
mov rcx, [temp_ptr]
mov [fib1_ptr], rax
mov [fib2_ptr], rcx
mov rax, [fib2_size]
mov [fib1_size], rax
mov rax, [temp_size]
mov [fib2_size], rax

inc r12
jmp .loop

.truncate:
mov r14, r10
mov rdx, [rbp - 8]
sub rdx, rbx
cmp rdx, 0
jle .flush_done
cmp rdx, r10
cmovb r10, rdx

call write_buffered
test rax, rax
js .error
add rbx, r10

mov r10, r14

; Clear temp

mov rdi, [temp_ptr]
mov rcx, 256
xor rax, rax
rep stosb

; Compute temp = fib1 + fib2
mov rdi, [fib1_ptr]
mov rsi, [fib1_size]
mov rdx, [fib2_ptr]
mov rcx, [fib2_size]
mov r8, [temp_ptr]
call big_add
mov [temp_size], rax
test rax, rax
jz .error

; Swap pointers
mov rax, [fib2_ptr]
mov rcx, [temp_ptr]
mov [fib1_ptr], rax
mov [fib2_ptr], rcx
mov rax, [fib2_size]
mov [fib1_size], rax
mov rax, [temp_size]
mov [fib2_size], rax

inc r12
cmp rbx, [rbp - 8]
jb .loop

.flush_done:
mov rax, [out_pos]
test rax, rax
jz .done
mov rax, SYS_WRITE
mov rdi, r13
lea rsi, [out_buf]
mov rdx, [out_pos]
syscall
test rax, rax
js .error
mov qword [out_pos], 0

.done:
mov rax, 0
jmp .exit

.error_log:
mov rax, -1
jmp .exit

.error:
mov rax, -1

.exit:
pop r14
pop r13
pop r12
pop rbx
mov rsp, rbp
pop rbp
ret

; ----------- Scalar arbitrary-precision addition ----------
; rdi = ptr a, rsi = size a, rdx = ptr b, rcx = size b, r8 = ptr result
; Returns: rax = result size
big_add:
push rbx
push r12
push r13

mov r12, r8           ; Save result pointer
xor r13, r13          ; Carry
mov r9, rsi
cmp r9, rcx
cmova r9, rcx         ; max_size = max(size_a, size_b)
test r9, r9
jz .no_add

lea rsi, [rdi + r9]   ; End of a
lea rcx, [rdx + r9]   ; End of b
lea rdi, [r8 + r9]    ; End of result

.add_loop:
xor rax, rax
xor rbx, rbx
cmp rsi, rdi
jb .skip_a
mov al, [rsi - 1]     ; Load a (LSB-first)
.skip_a:
cmp rcx, rdx
jb .skip_b
mov bl, [rcx - 1]     ; Load b
.skip_b:
add al, r13b          ; Add carry
adc al, bl            ; Add b with carry
mov [rdi - 1], al     ; Store result
setc r13b             ; Update carry
dec rsi
dec rcx
dec rdi
dec r9
jnz .add_loop

.no_add:
mov rax, r13
test rax, rax
jz .set_size
lea rax, [r9 + 1]     ; Include carry in size
cmp rax, 256
jbe .set_size
mov rax, 256          ; Cap at buffer size

.set_size:
test rax, rax
jnz .done
mov rax, 1            ; Minimum size 1

.done:
pop r13
pop r12
pop rbx
ret

; ----------- Buffered write ----------
; rsi = buffer, r10 = length
; Returns: rax = 0 (success), -1 (error)
write_buffered:
push rbx
push r12
push rdi
push rsi
push rcx

mov r12, rsi          ; Save buffer
test r10, r10
jz .zero_length
mov rax, [out_pos]
add rax, r10
cmp rax, 65536
ja .flush

mov rbx, rax
sub rbx, r10
lea rdi, [out_buf + rbx]
mov rsi, r12
mov rcx, r10
rep movsb
mov [out_pos], rax
xor rax, rax
jmp .done

.flush:
mov rax, [out_pos]
test rax, rax
jz .no_syscall
mov rax, SYS_WRITE
mov rdi, r13
lea rsi, [out_buf]
mov rdx, [out_pos]
syscall
test rax, rax
js .error_flush
.no_syscall:
mov qword [out_pos], 0
lea rdi, [out_buf]
mov rsi, r12
mov rcx, r10
rep movsb
mov [out_pos], r10
xor rax, rax
jmp .done

.zero_length:
xor rax, rax

.done:
pop rcx
pop rsi
pop rdi
pop r12
pop rbx
ret

.error_flush:
mov rax, -1
pop rcx
pop rsi
pop rdi
pop r12
pop rbx
ret

; ----------- Convert big number to string ----------
; rdi = number, rsi = buffer, rdx = size
; Returns: rax = string length
big_to_str:
push rbx
push r12
push r13
push r14
push rsi              ; Save buffer

mov r14, rdx          ; Save size
lea r12, [rel digit_buf]
mov r13, 2048         ; digit_buf size

; Check if number is zero
test r14, r14
jz .zero
mov rcx, r14
xor rax, rax
.zero_check_loop:
cmp byte [rdi + rcx - 1], 0
jnz .convert
dec rcx
jnz .zero_check_loop
.zero:
pop rsi               ; Restore buffer
mov byte [rsi], '0'
mov rax, 1
jmp .done

.convert:
; Copy number to temp
lea rbx, [rel temp]
mov rcx, 256
xor rax, rax
mov rdi, rbx
rep stosb
mov rdi, rbx          ; temp ptr
mov rsi, rdi          ; Source = number
mov rcx, r14
rep movsb             ; Copy number
mov [temp_size], r14

; Convert to decimal
.next_digit:
cmp r13, 0
je .error
mov rdi, rbx          ; temp ptr
call big_div10
cmp al, 9
ja .error
add al, '0'
dec r13
mov [r12 + r13], al   ; Store digit

mov rcx, [temp_size]
test rcx, rcx
jz .finish_digits
xor rax, rax
mov rax, rcx
.temp_zero_loop:
cmp byte [rbx + rax - 1], 0
jnz .next_digit
dec rax
jnz .temp_zero_loop
mov [temp_size], rax

.finish_digits:
mov rax, 2048
sub rax, r13
test rax, rax
jz .error
lea rsi, [r12 + r13]
pop rdi               ; Restore buffer
mov rcx, rax
rep movsb
jmp .done

.error:
pop rsi
pop r14
pop r13
pop r12
pop rbx
mov rax, 0
ret

.done:
pop r14
pop r13
pop r12
pop rbx
ret

; ----------- Divide dynamic-size number by 10 ----------
; rdi = number
; Returns: al = remainder, number modified
big_div10:
push rbx
push r12

mov rbx, rdi
xor r12d, r12d
mov rcx, [temp_size]
test rcx, rcx
jz .done_div

.div_loop:
movzx eax, byte [rbx + rcx - 1]
mov edx, r12d
shl edx, 8
add eax, edx
xor edx, edx
div word [ten]
mov [rbx + rcx - 1], al
mov r12d, edx
dec rcx
jnz .div_loop

.done_div:
mov rcx, [temp_size]
test rcx, rcx
jz .exit
xor rax, rax
.update_size:
cmp byte [rbx + rcx - 1], 0
jnz .exit
dec rcx
jnz .update_size
mov [temp_size], rcx

.exit:
mov al, r12b
pop r12
pop rbx
ret

section .note.GNU-stack noalloc noexec nowrite progbits
