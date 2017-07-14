sleep_in_us	equ	1000000 * 3

bad_character	equ	100h


	org	100h

section	.text

start:
	call	enable_flat_mode

	xor	ax, ax
	mov	es, ax


	call	highlight_on_off

	mov	ebx, 0fffffff0h
	mov	cx, 16
.l1:
	mov	al, [es:ebx]
	call	print_byte
	inc	ebx
	loop	.l1

	call	highlight_on_off

	mov	dx, crlf
	mov	ah, 9
	int	21h


	mov	dx, pattern
	mov	ebx, 0f0000h
;	call	brutal_pattern_matching
	call	horspool_pattern_matching

	mov	eax, ebx
	call	print_double_word


	mov	ax, 2400h		; disable a20
	int	15h

	mov	ah, 4ch
	int	21h


; ebx, dx / ebx
horspool_pattern_matching:
	push	ax
	push	ecx
	push	si
	push	di


	mov	si, dx
	lodsb

	mov	di, bad_character_shift
	mov	cx, bad_character
.l1:
	mov	[ds:di], al
	inc	di
	loop	.l1


	movzx	cx, al
	dec	cx
.l2:
	movzx	di, [si]
	mov	[ds:bad_character_shift + di], cl
	inc	si
	loop	.l2


.l3:
	movzx	ecx, al
.l4:
	mov	ah, [es:ebx + ecx - 1]
	cmp	ah, [si]
	jne	.l5
	dec	si
	loop	.l4
	jmp	.l6

.l5:
	movzx	ecx, al
	movzx	di, [es:ebx + ecx - 1]

	movzx	ecx, byte [ds:bad_character_shift + di]
	add	ebx, ecx

	movzx	si, al
	add	si, dx

	jmp	.l3

.l6:
	pop	di
	pop	si
	pop	ecx
	pop	ax
	ret

; al
print_byte:
	push	ax
	push	bx
	push	cx
	push	dx

	mov	ah, 2
	mov	bx, hexadecimal_digits
	mov	cx, 2
.l1:
	rol	al, 4
	mov	dh, al
	and	al, 0fh
	xlat
	mov	dl, al
	int	21h
	mov	al, dh
	loop	.l1

	pop	dx
	pop	cx
	pop	bx
	pop	ax
	ret

; al
print_byte2:
	push	ax
	push	cx
	push	dx

	mov	ah, 2
	mov	cx, 2
.l1:
	rol	al, 4
	mov	dh, al
	and	al, 0fh
	or	al, 30h
	cmp	al, 39h
	jna	.l2
	add	al, 7
.l2:
	mov	dl, al
	int	21h
	mov	al, dh
	loop	.l1

	pop	dx
	pop	cx
	pop	ax
	ret

; ax
print_word:
	push	cx

	mov	cx, 2
.l1:
	rol	ax, 8
	call	print_byte
	loop	.l1

	pop	cx
	ret

; eax
print_double_word:
	push	cx

	mov	cx, 2
.l1:
	rol	eax, 16
	call	print_word
	loop	.l1

	pop	cx
	ret

; al
print_byte_as_decimal:
	push	ax
	push	bx
	push	cx
	push	dx

	xor	cx, cx
	mov	bl, 10
.l1:
	xor	ah, ah
	div	bl
	push	ax
	inc	cl
	or	al, al
	jnz	.l1

	mov	bx, hexadecimal_digits
.l2:
	pop	ax
	mov	al, ah
	xlat
	mov	dl, al
	mov	ah, 2
	int	21h
	loop	.l2

	pop	dx
	pop	cx
	pop	bx
	pop	ax
	ret

; ax
print_word_as_decimal:
	push	bx
	push	cx
	push	dx

	xor	cx, cx
	mov	bx, 10
.l1:
	xor	dx, dx
	div	bx
	push	dx
	inc	cl
	or	ax, ax
	jnz	.l1

	mov	bx, hexadecimal_digits
.l2:
	pop	ax
	xlat
	mov	dl, al
	mov	ah, 2
	int	21h
	loop	.l2

	pop	dx
	pop	cx
	pop	bx
	ret

; eax
print_double_word_as_decimal:
	push	ebx
	push	cx
	push	edx

	xor	cx, cx
	mov	ebx, 10
.l1:
	xor	edx, edx
	div	ebx
	push	edx
	inc	cl
	or	eax, eax
	jnz	.l1

	mov	bx, hexadecimal_digits
.l2:
	pop	eax
	xlat
	mov	dl, al
	mov	ah, 2
	int	21h
	loop	.l2

	pop	edx
	pop	cx
	pop	ebx
	ret

enable_flat_mode:
	push	eax
	push	es

	mov	ax, 2401h	; enable a20
	int	15h

	xor	eax, eax	; load gdt
	mov	ax, ds
	shl	eax, 4
	add	[gdt_segment_selector + 2], eax
	lgdt	[gdt_segment_selector]

	mov	eax, cr0	; enable protected mode
	or	al, 1
	mov	cr0, eax

	mov	ax, 8
	mov	es, ax

	mov	eax, cr0	; disable protected mode
	and	al, 0feh
	mov	cr0, eax

	pop	es
	pop	eax
	ret

; ebx, dx / ebx
brutal_pattern_matching:
	push	ax
	push	cx
	push	si
	push	edi

.l1:
	xor	edi, edi
	mov	si, dx

	lodsb
	movzx	cx, al
.l2:
	lodsb				; needle
	cmp	al, [es:ebx + edi]
	jne	.l3
	inc	edi
	loop	.l2
	jmp	.l4

.l3:
	inc	ebx
	jmp	.l1

.l4:
	pop	edi
	pop	si
	pop	cx
	pop	ax
	ret

; sleep_in_us
us_sleep:
	push	ax
	push	cx
	push	dx
	mov	cx, (sleep_in_us & 0ffff0000h) >> 16
	mov	dx, sleep_in_us & 0ffffh
	mov	ah, 86h
	int	15h
	pop	dx
	pop	cx
	pop	ax
	ret

highlight_on_off:
	push	ax
	push	bx
	push	cx

	xor	bh, bh
	mov	ah, 8
	int	10h

	mov	bl, ah
	and	bl, 88h
	and	ah, 77h
	ror	ah, 4
	or	bl, ah
	mov	cx, 80 * 25
	mov	ah, 9
	int	10h

	pop	cx
	pop	bx
	pop	ax
	ret


section .data

hexadecimal_digits	\
	db	'0123456789ABCDEF'

crlf	db	0dh, 0ah, '$'


gdt_segment_descriptor	\
	dw	0, 0, 0, 0	; null descriptor
	dw	0ffffh		; data descriptor
	dw	0
	db	0
	db	10010010b	; 92h
	db	11001111b	; 0cfh (110?1111b)
	db	0

gdt_segment_selector	\
	dw	$ - gdt_segment_descriptor - 1
	dd	gdt_segment_descriptor


pattern	\
	db	4, '_SM_'


section	.bss

bad_character_shift	\
	resb	bad_character
