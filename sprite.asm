	org 0x100

start:
	mov	ax, 0x13
	int	0x10

setPalette:
	mov	dx, 0x03C8
	mov	al, 0
	out	dx, al
	inc	dx
	mov	cx, image-palette
	mov	si, palette

	.writeRGB:
	lodsb
	shr	al, 2
	out	dx, al
	loop	.writeRGB

    ; Setup video pointer
    mov	ax, 0xA000
	mov	es, ax
    xor dx, dx
    
main:
    call drawImage
    call calcPosition
    call drawSprite
    mov cx, 65535
    .empty:
    loop .empty
    jmp main
    
calcPosition:
    ; bl:0 == going left, bl:1 == going right
    cmp bl, 0
    jz .goingLeft
    
    .goingRight:
    cmp dx, 320-50
    je .goLeft
    inc dx
    jmp .end
    
        .goLeft:
        mov bl, 0
        dec dx
        jmp .end
    
    .goingLeft:
    cmp dx, 0
    je .goRight
    dec dx
    jmp .end
    
        .goRight:
        mov bl, 1
        inc dx
        jmp .end
    
    .end:
    ret

drawSprite:
    pusha
    ; Update image data source and destination
    mov si, image.ball
    ; dx contains the horizontal offset
    mov di, dx
    
    mov cx, 50
    .nextLine:
    push cx
    mov cx, 50
    rep movsb
    add di, 320-50
    pop cx
    loop .nextLine
    
    .end:
    popa
    ret
    
drawImage:
    pusha
	xor	di, di
	mov	cx, 32000	; (320*200)/2
	mov	si, image.image

	.unpack:
	lodsb
	mov	ah, al		; ah = high nibble, al = low nibble
	shr	ah, 4		; write high nibble...
	mov	[es:di], ah
	inc	di
	shl	al, 4		; write low nibble...
	shr	al, 4
	stosb
	loop	.unpack
    
    .end:
    popa
    ret

exit:
	xor	ax, ax
	int	0x16
	mov	ax, 0x03
	int	0x10
	ret

palette:
    .image:
        file 'image.pal'
    .ball:
        file 'ball.pal'

image:
    .image:
        file 'image.pxl'
    .ball:
        file 'ball.pxl'