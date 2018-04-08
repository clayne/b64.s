///////////////////////////////////////////////////////////////////////////////////////////////////
// RODATA SECTION                                                                                //
///////////////////////////////////////////////////////////////////////////////////////////////////
	
.section .rodata
	.equ F_OK, 0x0
	.equ R_OK, 0x2
	.equ bit_group_1, 0x00FC0000
	.equ bit_group_2, 0x0003F000
	.equ bit_group_3, 0x00000FC0
	.equ bit_group_4, 0x0000003F
	
in_prompt:
	.asciz "Which file do you want to encode? "
	
out_prompt:
	.asciz "What's the name of the output file? "
	
again_prompt:	
	.asciz "Do you want to encode another file? (Y/n) "

bad_again:
	.asciz "Please answer (Y)es or (N)o.\n"
	
b64_table:	
	.ascii "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"

extension:
	.asciz ".b64"

bad_input:
	.asciz "Input file does not exist or is not readable! Quitting.\n"

bad_output:
	.asciz "Output file already exists! Quitting.\n"

read_mode:
	.asciz "rb"

write_mode:
	.asciz "w"

bye:
	.asciz "Bye!\n"
	
///////////////////////////////////////////////////////////////////////////////////////////////////
// DATA SECTION                                                                                  //
///////////////////////////////////////////////////////////////////////////////////////////////////

.section .data	
curr_bits:
	.long 0

repeat_char:
	.long 0

///////////////////////////////////////////////////////////////////////////////////////////////////
// BSS SECTION                                                                                   //
///////////////////////////////////////////////////////////////////////////////////////////////////

.section .bss
	.comm aux, 4
	.comm in_file_name, 256
	.comm out_file_name, 260
	.comm in_file, 8
	.comm out_file, 8

///////////////////////////////////////////////////////////////////////////////////////////////////
// TEXT SECTION                                                                                  //
///////////////////////////////////////////////////////////////////////////////////////////////////

.section .text
.globl main
main:
	push %rbp
	movq %rsp, %rbp

do_while_input:	
	// Clean memory of file-name buffers
	leaq in_file_name(%rip), %rdi
	xorl %esi, %esi
	movq $516, %rdx
	xorl %eax, %eax
	call memset@plt

	// Print prompt, read input file name and clear terminating new-line
	leaq in_prompt(%rip), %rdi
	xorl %eax, %eax
	call printf@plt

	leaq in_file_name(%rip), %rdi
	movq $256, %rsi
	movq stdin(%rip), %rdx
	call fgets@plt

	leaq in_file_name(%rip), %rdi
	call strlen@plt
	decq %rax
	leaq in_file_name(%rip), %r8
	movb $0, (%r8, %rax, 1)
	
	// Print prompt, read output file name and clear terminating new-line
	leaq out_prompt(%rip), %rdi
	xorl %eax, %eax
	call printf@plt

	leaq out_file_name(%rip), %rdi
	movq $256, %rsi
	movq stdin(%rip), %rdx
	call fgets@plt

	leaq out_file_name(%rip), %rdi
	call strlen@plt
	decq %rax
	leaq out_file_name(%rip), %r8
	movb $0, (%r8, %rax, 1)
	
	// Append .b64 extension to output file name
	leaq out_file_name(%rip), %rdi
	leaq extension(%rip), %rsi
	call strcat@plt

	// Check if input file is readable
	leaq in_file_name(%rip), %rdi
	movq $R_OK, %rsi
	call access@plt
	cmpq $0, %rax
	je good_input
	leaq bad_input(%rip), %rdi
	xorl %eax, %eax
	call printf@plt
	// Return 1
	movq $1, %rax
	jmp main_end

good_input:
	// Check if output file doesn't exist
	leaq out_file_name(%rip), %rdi
	xorl %esi, %esi
	call access@plt
	cmpq $F_OK, %rax
	jne good_output
	leaq bad_output(%rip), %rdi
	xorl %eax, %eax
	call printf@plt
	// Return 2
	movq $2, %rax
	jmp main_end

good_output:
	// Open files for reading and writing respectively
	// Input file first
	leaq in_file_name(%rip), %rdi
	leaq read_mode(%rip), %rsi
	call fopen@plt
	movq %rax, in_file(%rip)

	// Output file second
	leaq out_file_name(%rip), %rdi
	leaq write_mode(%rip), %rsi
	call fopen@plt
	movq %rax, out_file(%rip)

	// Read first byte of the file
	movq in_file(%rip), %rdi
	call fgetc@plt
	movl %eax, aux(%rip)

	// Test end-of-file to skip empty files
	movq in_file(%rip), %rdi
	call feof@plt
	cmpl $0, %eax
	jne end_while_feof

	// Shift byte and add it to accumulator
	movl aux(%rip), %eax
	addl %eax, curr_bits(%rip)
	shll $16, curr_bits(%rip)

while_feof:	
	// Read second input byte
	movq in_file(%rip), %rdi
	call fgetc@plt
	movl %eax, aux(%rip)

	// Test end-of-file
	movq in_file(%rip), %rdi
	call feof@plt
	cmpl $0, %eax
	jne process_double_padding

	// Shift byte and add it to accumulator
	movl aux(%rip), %eax
	shll $8, %eax
	addl %eax, curr_bits(%rip)

	// Read third input byte
	movq in_file(%rip), %rdi
	call fgetc@plt
	movl %eax, aux(%rip)
	
	// Test end-of-file
	movq in_file(%rip), %rdi
	call feof@plt
	cmpl $0, %eax
	jne process_single_padding

	// Shift byte and add it to accumulator
	movl aux(%rip), %eax
	addl %eax, curr_bits(%rip)

process:
	// Process first six bits
	leaq b64_table(%rip), %r8
	movl curr_bits(%rip), %eax
	andl $bit_group_1, %eax
	shrl $18, %eax
	xorl %ebx, %ebx
	movb (%r8, %rax, 1), %bl
	movl %ebx, %edi
	movq out_file(%rip), %rsi
	call fputc@plt

	// Process second six bits
	leaq b64_table(%rip), %r8
	movl curr_bits(%rip), %eax
	andl $bit_group_2, %eax
	shrl $12, %eax
	xorl %ebx, %ebx
	movb (%r8, %rax, 1), %bl
	movl %ebx, %edi
	movq out_file(%rip), %rsi
	call fputc@plt

	// Process third six bits
	leaq b64_table(%rip), %r8
	movl curr_bits(%rip), %eax
	andl $bit_group_3, %eax
	shrl $6, %eax
	xorl %ebx, %ebx
	movb (%r8, %rax, 1), %bl
	movl %ebx, %edi
	movq out_file(%rip), %rsi
	call fputc@plt

	// Process fourth six bits
	leaq b64_table(%rip), %r8
	movl curr_bits(%rip), %eax
	andl $bit_group_4, %eax
	xorl %ebx, %ebx
	movb (%r8, %rax, 1), %bl
	movl %ebx, %edi
	movq out_file(%rip), %rsi
	call fputc@plt

	jmp end_process

process_single_padding:	
	// Process first six bits
	leaq b64_table(%rip), %r8
	movl curr_bits(%rip), %eax
	andl $bit_group_1, %eax
	shrl $18, %eax
	xorl %ebx, %ebx
	movb (%r8, %rax, 1), %bl
	movl %ebx, %edi
	movq out_file(%rip), %rsi
	call fputc@plt

	// Process second six bits
	leaq b64_table(%rip), %r8
	movl curr_bits(%rip), %eax
	andl $bit_group_2, %eax
	shrl $12, %eax
	xorl %ebx, %ebx
	movb (%r8, %rax, 1), %bl
	movl %ebx, %edi
	movq out_file(%rip), %rsi
	call fputc@plt

	// Process third six bits
	leaq b64_table(%rip), %r8
	movl curr_bits(%rip), %eax
	andl $bit_group_3, %eax
	shrl $6, %eax
	xorl %ebx, %ebx
	movb (%r8, %rax, 1), %bl
	movl %ebx, %edi
	movq out_file(%rip), %rsi
	call fputc@plt

	// Process fourth six bits
	movq $0x3D, %rdi
	movq out_file(%rip), %rsi
	call fputc@plt

	jmp end_while_feof

process_double_padding:
	// Process first six bits
	leaq b64_table(%rip), %r8
	movl curr_bits(%rip), %eax
	andl $bit_group_1, %eax
	shrl $18, %eax
	xorl %ebx, %ebx
	movb (%r8, %rax, 1), %bl
	movl %ebx, %edi
	movq out_file(%rip), %rsi
	call fputc@plt

	// Process second six bits
	leaq b64_table(%rip), %r8
	movl curr_bits(%rip), %eax
	andl $bit_group_2, %eax
	shrl $12, %eax
	xorl %ebx, %ebx
	movb (%r8, %rax, 1), %bl
	movl %ebx, %edi
	movq out_file(%rip), %rsi
	call fputc@plt

	// Process third six bits
	movq $0x3D, %rdi
	movq out_file(%rip), %rsi
	call fputc@plt

	// Process fourth six bits
	movq $0x3D, %rdi
	movq out_file(%rip), %rsi
	call fputc@plt

	jmp end_while_feof
	
end_process:
	// Clear curr_bits
	movl $0, curr_bits(%rip)
	
	// Read first byte of the file again
	movq in_file(%rip), %rdi
	call fgetc@plt
	movl %eax, aux(%rip)

	// Test end-of-file
	movq in_file(%rip), %rdi
	call feof@plt
	cmpl $0, %eax
	jne end_while_feof

	// Shift byte and add it to accumulator
	movl aux(%rip), %eax
	addl %eax, curr_bits(%rip)
	shll $16, curr_bits(%rip)

	jmp while_feof
	
end_while_feof:
	// Close input file
	movq in_file(%rip), %rdi
	call fclose@plt

	// Close output file
	movq out_file(%rip), %rdi
	call fflush@plt
	movq out_file(%rip), %rdi
	call fclose@plt
	
	// Ask for repetition
	leaq again_prompt(%rip), %rdi
	xorl %eax, %eax
	call printf@plt

	// Read answer
	movq stdin(%rip), %rdi
	call fgetc@plt
	movl %eax, repeat_char(%rip)

	// Clear new-line from stdin
	movq stdin(%rip), %rdi
	call fgetc@plt
	
	// Repeat if answer is 'Y' or 'y', quit if answer is 'N' or 'n'
	cmpl $0x59, repeat_char(%rip)
	je do_while_input
	cmpl $0x79, repeat_char(%rip)
	je do_while_input
	cmpl $0x4E, repeat_char(%rip)
	je end_repeat
	cmpl $0x6E, repeat_char(%rip)
	je end_repeat

	// Print bad repeat prompt
	leaq bad_again(%rip), %rdi
	xorl %eax, %eax
	call printf@plt
	jmp end_while_feof

end_repeat:
	// Print good bye
	leaq bye(%rip), %rdi
	xorl %eax, %eax
	call printf@plt

	// Return 0
	xorl %eax, %eax
	
main_end:
	leave
	ret
