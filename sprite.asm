format MZ
entry seg_code:start
    ;org 0x100

segment seg_code

start:
    mov ax, seg_data
    mov ds, ax
    mov es, ax
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

setSpriteColors:
    ; ball.pxl data aligns to its local palette, not the global palette
    ; so, add however many palette entries there are before it to offset it
    mov si, image.ball
    mov di, si
    mov cx, 50*50
    
    .updatePixel:
    lodsb
    add al, (palette.ball - palette.image) / 3
    stosb
    loop .updatePixel

setupPointers:
    ; Setup pointer to secondary video buffer
    mov ax, seg_buffer
    mov es, ax
    xor dx, dx
    xor bx, bx
    
main:
    ;call proc_drawImage
    call proc_calcPosition
    call proc_drawSprite
    call proc_showBuffer
    mov cx, 65535
    .empty:
    loop .empty
    jmp main
    
proc_showBuffer:
    push ax
    push cx
    push si
    push di
    push ds
    push es
    
    mov ax, seg_buffer  ; Buffer segment is now the source
    mov ds, ax
    
    mov ax, 0xA000      ; Video memory segment is now the destination
    mov es, ax
    
    xor di, di
    xor si, si
    
    mov cx, 320*200
    rep movsb
    
    pop es
    pop ds
    pop di
    pop si
    pop cx
    pop ax
    ret
    
proc_calcPosition:
    ; bl:0=0 == going left, bl:0=1 == going right
    ; bl:1=0 == going up, bl:1=1 == going down
    ;cmp bl, 0
    push ax
    
    .testVertical:
        ; If vertical direciton bit not set, sprite is going up
        mov al, bl
        and al, 00000010b
        jz .goingUp
        
        .goingDown:
        cmp bh, 200-50
        je .goUp
        inc bh
        jmp .testHorizontal
        
            .goUp:
            ; Clear direction bit: mark as going up
            sub bl, 00000010b
            dec bh
            jmp .testHorizontal
            
        .goingUp:
        cmp bh, 0
        je .goDown
        dec bh
        jmp .testHorizontal
        
            .goDown:
            ; Set direction bit: mark as going down
            add bl, 00000010b
            inc bh
            jmp .testHorizontal
    
    .testHorizontal:
        ; If horizontal direction bit not set, sprite is going left
        mov al, bl
        and al, 00000001b
        jz .goingLeft
        
        .goingRight:
        cmp dx, 320-50
        je .goLeft
        inc dx
        jmp .end
        
            .goLeft:
            ; Clear direction bit: mark as going left
            sub bl, 00000001b
            dec dx
            jmp .end
        
        .goingLeft:
        cmp dx, 0
        je .goRight
        dec dx
        jmp .end
        
            .goRight:
            ; Set direction bit: mark as going right
            add bl, 00000001b
            inc dx
            jmp .end
    
    .end:
    pop ax
    ret

proc_drawSprite:
    pusha
    ; Update image data source and destination
    mov si, image.ball
    ; bh contains the vertical offset
    ; dx contains the horizontal offset
    push dx     ; dx is destroyed when multiplier is a word
    mov al, bh
    mov cx, 320
    mul cx      ; vertical offset
    pop dx
    add ax, dx  ; horizontal offset
    mov di, ax
    
    mov cx, 50
    .nextLine:
    push cx
    mov cx, 50
    
        .putPixel:
        lodsb
        ; If the pixel is part of the white background, don't draw it
        ; First pixel of the sprite is the background color
        cmp al, byte [image.ball]
        je .skip
        stosb
        jmp .cont
        
        .skip:
        inc di
        
        .cont:
        loop .putPixel
    
    add di, 320-50
    pop cx
    loop .nextLine
    
    .end:
    popa
    ret
    
proc_drawImage:
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
	loop .unpack
    
    .end:
    popa
    ret

exit:
	xor	ax, ax
	int	0x16
	mov	ax, 0x03
	int	0x10
	ret
    
segment seg_data
    
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

segment seg_buffer
db 5,1,7,5,9,8,1,3,5,1,5,6,4,8,5,3,5,1
