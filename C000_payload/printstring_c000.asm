	.filenamespace printstring_c000
//-----------------------------------------------------------
// Zero page variables
// STR_PTR_LO, STR_PTR_HI       // pointer to the null-terminated string
// XPOS, YPOS                           // starting coordinates (0..39,0..24)
// CHARCOLOUR                           // foreground color
//
// We use some temporary zero page variables:
// TMP_Y, OFFS_L, OFFS_H                // for computing offset = YPOS*40+XPOS
// SCR_PTR_LO, SCR_PTR_HI       // current screen pointer
// COL_PTR_LO, COL_PTR_HI       // current color pointer
// TMP_PTR_LO, TMP_PTR_HI       // temporary copy of string pointer
//-----------------------------------------------------------

.label STR_PTR_LO       = $F0  // Low byte of pointer to the null-terminated string
.label STR_PTR_HI       = $F1  // High byte of pointer to the null-terminated string
.label SCR_PTR_LO       = $F2  // current screen pointer
.label SCR_PTR_HI       = $F3  
.label COL_PTR_LO       = $F4  // current color pointer
.label COL_PTR_HI       = $F5

.label TMP_PTR_LO       = $F6 
.label TMP_PTR_HI       = $F7  
.label TMP_Y            = $F8  // for computing offset = YPOS*40+XPOS
.label OFFS_L           = $F9  // for computing offset = YPOS*40+XPOS
.label OFFS_H           = $FA  // for computing offset = YPOS*40+XPOS

.label XPOS             = $FB	// X position (0-39)
.label YPOS             = $FC   // Y position (0-24)
.label CHARCOLOUR       = $FD 	// Color code (0-15)

PRINT_STRING:
        // Compute offset = YPOS * 40 + XPOS.
        // (40 decimal is $28 hex.)
        lda YPOS
        sta TMP_Y               // copy YPOS into TMP_Y
        lda #0
        sta OFFS_L              // clear offset low
        sta OFFS_H              // clear offset high
 
MULT_LOOP:
        lda TMP_Y
        beq MULT_DONE           // when TMP_Y==0, we are done
        clc
        lda OFFS_L
        adc #$28				// add 40
        sta OFFS_L
        lda OFFS_H
        adc #0
        sta OFFS_H
        dec TMP_Y
        jmp MULT_LOOP
MULT_DONE:
        // Now add XPOS to the low part of offset.
        clc
        lda OFFS_L
        adc XPOS
        sta OFFS_L
        lda OFFS_H
        adc #0
        sta OFFS_H
 
        // Compute screen pointer = $0400 + offset.
        lda OFFS_L
        sta SCR_PTR_LO  		// note: $0400 low byte is 0, so no addition needed
        lda OFFS_H
        clc
        adc #$04				// add high byte of $0400
        sta SCR_PTR_HI
 
        // Compute color pointer = $D800 + offset.
        lda OFFS_L
        sta COL_PTR_LO
        lda OFFS_H
        clc
        adc #$D8				// add high byte of $D800
        sta COL_PTR_HI
 
        // Copy the string pointer to a temporary pointer.
        lda STR_PTR_LO
        sta TMP_PTR_LO
        lda STR_PTR_HI
        sta TMP_PTR_HI
 
        // Use the Y register for reading the string offset.
        ldy #0
 
PRINT_LOOP:
        ldy #0
        lda (TMP_PTR_LO),Y  // load next character from the string
        beq PRINT_DONE    // if zero, end of string
        // Write character to screen memory at pointer SCR_PTR.
        ldy #0
        sta (SCR_PTR_LO),Y
        // Write CHARCOLOUR to the corresponding color memory.
        lda CHARCOLOUR
        ldy #0
        sta (COL_PTR_LO),Y
 
        // Increment the string pointer (TMP_PTR).
        inc TMP_PTR_LO
        bne SKIP_TMPHI
        inc TMP_PTR_HI
SKIP_TMPHI:
        // Increment the screen pointer.
        inc SCR_PTR_LO
        bne SKIP_SCRHI
        inc SCR_PTR_HI
SKIP_SCRHI:
        // Increment the color pointer.
        inc COL_PTR_LO
        bne SKIP_COLHI
        inc COL_PTR_HI
 SKIP_COLHI:
        // Loop back to print the next character.
        jmp PRINT_LOOP
 
PRINT_DONE:
        rts
 