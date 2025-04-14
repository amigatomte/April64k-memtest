.filenamespace setColorsForBits_colour
//*=$C000



//-------------------------------------------------------------------------
// Zero Page Parameter Layout (example)
//-------------------------------------------------------------------------
.label Colour_bitByte       = $20   // The .byte whose bits we want to display
//paramX        = $F1   // The starting X column
//paramY        = $F2   // The row
.label Colour_colorPtr      = $25   // 2 .bytes used as a pointer to Color RAM

//-------------------------------------------------------------------------
// Constants
//-------------------------------------------------------------------------
.label Colour_COLOR_RAM     = $D800
.label Colour_COLOR_RED     = $02
.label Colour_COLOR_GREEN   = $05
.label Colour_NUM_COLS      = 40

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
 //       *= $C000           // Example of where to put code (adjust as needed)
Colour_setColorsForBits:




                //----------------------------------------------------------
                // 2) Write 8 colors for the 8 bits of bitByte
                //    High bit (bit7) goes first ⇒ leftmost color
                //----------------------------------------------------------
        lda Colour_bitByte
        asl       //Shift out the 4 top .bytes as the colour ram is 4-bit. 
        asl
        asl
        asl
        ldx #4
Colour_bitLoop:
        // Shift bitByte left by 1// the high bit goes into carry.
        lda Colour_bitByte
        asl
        sta Colour_bitByte

        // If carry=1 ⇒ color = RED, else GREEN
        bcs Colour_storeRed
        lda #Colour_COLOR_GREEN
        bne Colour_storeColor  // Always junp as Z=0. Save one .byte and a cycle. Yay.
Colour_storeRed:
        lda #Colour_COLOR_RED

Colour_storeColor:
        ldy #0
        sta (Colour_colorPtr),Y  // Store color

        // Advance pointer by 1
        inc Colour_colorPtr
        bne Colour_skipHighByte
        inc Colour_colorPtr+1
Colour_skipHighByte:

        dex
        bne Colour_bitLoop

        rts










