.filenamespace redrawscreen
// Test code
.label CPTR   = $14
DoRedrawScreen:	
    // lda #$35    //Bank out kernal and basic
	// sta $01     
    
    ldx #$04			// start with row 4
	// Compute starting colour memory pointer for row 4:
	// offset = 4*40+33 = 193 = $C1, so address = $D800+$C1 = $D8C1.
	lda #$C1			
	sta CPTR			// CPTR low byte
	lda #$D8			
	sta CPTR+1			// CPTR high byte

Loop:
	ldy #$00		    // for indirect addressing using CPTR
	lda (CPTR),Y        // load colour from current row, column 33
	and #$0F		    // clear upper 4 bits (since colour memory is 4-bit)
	cmp #$05		    // compare with green ($05)
	beq Green		    // if green, branch
	cmp #$02		    // compare with red ($02)
	beq Red			    // if red, branch
	jmp skip
	// Otherwise, it is red.
Red:	
	lda #$01

	jmp NextRow

Green:	
	lda #$00

NextRow:
	sta printfailpass_main.STATUS
	lda #33
	sta printfailpass_main.XPOS
	stx printfailpass_main.YPOS
	jsr printfailpass_main.CheckAndPrint
skip:
	jsr inc_CPTR
// not17:
	cpx #19		    // when X reaches 19, we've done rows 4-18
	bne Loop
	rts
	// Continue with the rest of your code...
inc_CPTR:
	inx					// next row index
	// Add 40 ($28) to CPTR to move to the next row's column 33.
	lda CPTR
	clc
	adc #$28
	sta CPTR
	lda CPTR+1
	adc #$00
	sta CPTR+1
	rts