///////////////////////////////////////////////////////////////////////////////////////////////////
// RODATA SECTION                                                                                //
///////////////////////////////////////////////////////////////////////////////////////////////////
	
.section .rodata
	.equ F_OK, 0x0
	.equ R_OK, 0x2
	.equ first_byte, 0x00FF0000
	.equ secnd_byte, 0x0000FF00
	.equ lastt_byte, 0x000000FF
	
in_prompt:
	.asciz "Which file do you want to decode? "
	
out_prompt:
	.asciz "What's the name of the output file? "
	
again_prompt:	
	.asciz "Do you want to decode another file? (Y/n) "

bad_again:
	.asciz "Please answer (Y)es or (N)o.\n"

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

decode_tbl:
	// Characters from ASCII 0 (NULL) to ASCII 42 (*)
	.byte 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF
	.byte 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF
	// ASCII 43 (+)
	.byte 0x3E
	// ASCII 44 (,) to ASCII 46 (.)
	.byte 0xFF, 0xFF, 0xFF
	// ASCII 47 (/) to ASCII 57 (9)
	.byte 0x3F, 0x34, 0x35, 0x36, 0x37, 0x38, 0x39, 0x3A, 0x3B, 0x3C, 0x3D
	// ASCII 58 (:) to ASCII 64 (@)
	.byte 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF
	// ASCII 65 (A) to ASCII 90 (Z)
	.byte 0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09, 0x0A, 0x0B, 0x0C, 0x0D, 0x0E, 0x0F, 0x10, 0x11, 0x12, 0x13, 0x14, 0x15, 0x16, 0x17, 0x18, 0x19
	// ASCII 91 ([) to ASCII 96 (`)
	.byte 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF
	// ASCII 97 (a) to ASCII 122 (z)
	.byte 0x1A, 0x1B, 0x1C, 0x1D, 0x1E, 0x1F, 0x20, 0x21, 0x22, 0x23, 0x24, 0x25, 0x26, 0x27, 0x28, 0x29, 0x2A, 0x2B, 0x2C, 0x2D, 0x2E, 0x2F, 0x30, 0x31, 0x32, 0x33
	// ASCII 123 ({) to ASCII 127 (DEL)
	.byte 0xFF, 0xFF, 0xFF, 0xFF, 0xFF
	

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
	.comm out_file_name, 256
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
	movq $512, %rdx
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

	// Read first char of the file
	movq in_file(%rip), %rdi
	call fgetc@plt
	movl $0, aux(%rip)
	leaq aux(%rip), %r8
	movb %al, (, %r8, 1)

	// Test end-of-file to skip empty files
	movq in_file(%rip), %rdi
	call feof@plt
	cmpl $0, %eax
	jne end_while_feof

while_feof:
	movl $0, curr_bits(%rip)
	
	// Read second char
	movq in_file(%rip), %rdi
	call fgetc@plt
	leaq aux(%rip), %r8
	movb %al, 1(, %r8, 1)

	// Read third char of the file
	movq in_file(%rip), %rdi
	call fgetc@plt
	leaq aux(%rip), %r8
	movb %al, 2(, %r8, 1)

	// Read fourth char of the file
	movq in_file(%rip), %rdi
	call fgetc@plt
	leaq aux(%rip), %r8
	movb %al, 3(, %r8, 1)

	// Decode first byte
	xorl %eax, %eax
	movb (, %r8, 1), %al
	leaq decode_tbl(%rip), %r8
	movb (%r8, %rax, 1), %bl
	cmpb $0xFF, %bl
	je second_byte
	shll $18, %ebx
	addl %ebx, curr_bits(%rip)
	
second_byte:
	// Decode second byte
	leaq aux(%rip), %r8
	xorl %eax, %eax
	movb 1(, %r8, 1), %al
	leaq decode_tbl(%rip), %r8
	movb (%r8, %rax, 1), %bl
	cmpb $0xFF, %bl
	je third_byte
	shll $12, %ebx
	addl %ebx, curr_bits(%rip)

third_byte:
	// Decode third byte
	leaq aux(%rip), %r8
	xorl %eax, %eax
	movb 2(, %r8, 1), %al
	leaq decode_tbl(%rip), %r8
	movb (%r8, %rax, 1), %bl
	cmpb $0xFF, %bl
	je fourth_byte
	shll $6, %ebx
	addl %ebx, curr_bits(%rip)

fourth_byte:
	// Decode fourth byte
	leaq aux(%rip), %r8
	xorl %eax, %eax
	movb 3(, %r8, 1), %al
	leaq decode_tbl(%rip), %r8
	movb (%r8, %rax, 1), %bl
	cmpb $0xFF, %bl
	je end_process
	addl %ebx, curr_bits(%rip)
	
end_process:
	// Print three bytes to file
	// First byte
	xorl %edi, %edi
	movl curr_bits(%rip), %edi
	xorl $first_byte, %edi
	shrl $16, %edi
	movq out_file(%rip), %rsi
	call fputc@plt

	// Second byte
	xorl %edi, %edi
	movl curr_bits(%rip), %edi
	xorl $secnd_byte, %edi
	shrl $8, %edi
	movq out_file(%rip), %rsi
	call fputc@plt

	// Third byte
	xorl %edi, %edi
	movl curr_bits(%rip), %edi
	xorl $lastt_byte, %edi
	movq out_file(%rip), %rsi
	call fputc@plt

	// Read first char of the file again
	movq in_file(%rip), %rdi
	call fgetc@plt
	movl $0, aux(%rip)
	leaq aux(%rip), %r8
	movb %al, (, %r8, 1)

	// Test end-of-file
	movq in_file(%rip), %rdi
	call feof@plt
	cmpl $0, %eax
	jne end_while_feof
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
