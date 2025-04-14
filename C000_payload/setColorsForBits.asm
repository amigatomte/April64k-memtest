.filenamespace setColorsForBits_c000
//*=$C000


//-------------------------------------------------------------------------
// Zero Page Parameter Layout (example)
//-------------------------------------------------------------------------
.label bitByte       = $24   // The .byte whose bits we want to display
//paramX        = $F1   // The starting X column
//paramY        = $F2   // The row
.label colorPtr      = $25   // 2 .bytes used as a pointer to Color RAM

//-------------------------------------------------------------------------
// Constants
//-------------------------------------------------------------------------
//COLOR_RAM     = $D800
.label COLOR_RED     = $02
.label COLOR_GREEN   = $05
//NUM_COLS      = 40

//-------------------------------------------------------------------------
// Test code
//-------------------------------------------------------------------------

//        LDA #%01100111
//        STA bitByte
//        LDA #$3B
//        STA colorPtr
//        LDA #$D8
//        STA colorPtr+1
//        JSR setColorsForBits
//        RTS


//-------------------------------------------------------------------------
// Routine: setColorsForBits
//
// Action:
//   1) Compute the start address in Color RAM = $D800 + 40*paramY + paramX.
//   2) For each of the 8 bits from bit7..bit0 of bitByte:
//        - If bit = 1, poke COLOR_RED.
//        - If bit = 0, poke COLOR_GREEN.
//-------------------------------------------------------------------------
setColorsForBits:
                //----------------------------------------------------------
                // 2) Write 8 colors for the 8 bits of bitByte
                //    High bit (bit7) goes first ⇒ leftmost color
                //----------------------------------------------------------
        ldx #8
bitLoop:
        // Shift bitByte left by 1// the high bit goes into carry.
        lda bitByte
        asl
        sta bitByte

        // If carry=1 ⇒ color = RED, else GREEN
        bcs storeRed
        lda #COLOR_GREEN
        bne storeColor  // Always junp as Z=0. Save one .byte and a cycle. Yay.
storeRed:
        lda #COLOR_RED

storeColor:
        ldy #0
        sta (colorPtr),Y  // Store color

        // Advance pointer by 1
        inc colorPtr
        bne skipHighByte
        inc colorPtr+1
skipHighByte:

        dex
        bne bitLoop

        rts