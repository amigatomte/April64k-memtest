.filenamespace rasterbars_main
	// =========================================================
	// C64 Raster Bars in Border without RAM usage
	// =========================================================
//        * = $C000 // To be removed.
.label RED = 2
.label GREEN = 5
.label BACKGROUND = 14
//BARSTART1 = 84
.label BARSTART1 = 188
.label BARSTART2 = BARSTART1+8
.label BARSTART3 = BARSTART2+8
.label BARSTART4 = BARSTART3+8
.label BARSTART5 = BARSTART4+8
.label BARSTART6 = BARSTART5+8
.label BARSTART7 = BARSTART6+8
.label BARSTART8 = BARSTART7+8

.label BARSTOP1 = BARSTART1+5
.label BARSTOP2 = BARSTART2+5
.label BARSTOP3 = BARSTART3+5
.label BARSTOP4 = BARSTART4+5
.label BARSTOP5 = BARSTART5+5
.label BARSTOP6 = BARSTART6+5
.label BARSTOP7 = BARSTART7+5
.label BARSTOP8 = BARSTART8+5

STARTRASTER_zero:
	ldy #$30                // Print "0"
	jmp psnrPRINTPREFIX
STARTRASTER_stack:
	ldy #$31                // Print "1"
psnrPRINTPREFIX:
	sty printstatusnoram.CHAR3
	ldy #$30                // Print "0"
	sty printstatusnoram.CHAR2
	ldy #$24                // Print "$"
	sty printstatusnoram.CHAR1

	sei             // 1) Disable further IRQs at the CPU level

// --------------------------------------------------------
// Print failing address
	jmp printstatusnoram.printstatusnoram
printstatusnoram_return:


// --------------------------------------------------------
STARTRASTER_C000:

	tax             // Backup the bit pattern to the Stack Pointer(!) via X.
	txs             // We can"t use RAM and the stack will not be used anyway.
			// The backup is needed because the C flag gets polluted 
			// by other instructions between the ROL:s, so we can"t
			// rotate back to where we started.


	// 2) Disable CIA #1 interrupts
	ldx #$7F
	stx $DC0D       // Write $7F to clear any pending bits
	ldx $DC0D       // Read back to fully acknowledge

	// 3) Disable CIA #2 interrupts
	ldx #$7F
	stx $DD0D
	ldx $DD0D

	// 4) Disable VIC-II interrupts
	ldx #$00
	stx $D01A       // Disable all VIC interrupt sources
	ldx $D019
	stx $D019       // Clear any pending VIC-II interrupts
	





	//LDA #%01001110  // Example bit pattern. To be removed.
   // -------------------------------------------
// Wait for the start of raster lines >= 128
// That is: bit 7 of $D011 must be set (BMI test or checking bit7)
// -------------------------------------------     
WaitBit7Unset:
	lda $D011
	bmi WaitBit7Unset   // BPL branches if bit7 = 0, so loop until it becomes 1
WaitBit7Set:
	lda $D011
	bpl WaitBit7Set   // BPL branches if bit7 = 0, so loop until it becomes 1

// -------------------------------------------
// Main checking loop
// -------------------------------------------
CheckLineLoop:
	// Check if we are at line 311 (high bit set + $D012 = $37)
	lda $D012
	cmp #$34          // Decreased from $37 to get a little more time to do stuff.
	bne CheckBit7     // If $D012 != $37, go check if we"ve wrapped

	lda $D011
	bmi FoundLine311  // BMI branches if bit7 = 1

CheckBit7:
	// If bit7 of $D011 becomes 0 before we found line 311,
	// we"ve wrapped to a new frame -> jump to CONTINUE
	lda $D011
	bpl NTSC      // BPL = Branch if bit7 = 0
	jmp MAIN_LOOP

// -------------------------------------------
// If we found line 311
// -------------------------------------------
FoundLine311:
	// If we are at this line, we are on a PAL machine
	//BIT $44 // Extra timing delays for PAL to get the raster stable.
		// The horizontal pos where the colour change takes place is still floating
		// but at least it"s not flickering and I guess that is as good 
		// as it gets without being able to use RAM and get the cpu in sync with the VIC.
		// Anyway, this is not a graphical demo and I"ve already spent a little
		// too much energy on this, I feel.. :-)
	//NOP
	//NOP
	//NOP


// -------------------------------------------
// If raster bit7 is clear before line 311 -> never reached 311
// -------------------------------------------

// TODO: Create NTSC bar routine
NTSC:    //JMP NTSC_RASTER

MAIN_LOOP:

// --------------------------------------------------------
//PAL/NTSC Half Variance Stable Raster
// --------------------------------------------------------
		ldx #$38
		cpx $d012
		bne *-3

		ldy #$09
		dey
		bne *-1
fix1:
		cmp #$ea                //ntsc with nop nop
		nop
		nop
		inx
		cpx $d012
		beq branch1
		nop
		nop
branch1:
		ldy #$09
		dey
		bne *-1
fix2:
		cmp #$ea                //ntsc with nop nop
		nop
		nop
		inx
		cpx $d012
		beq branch2
		bit $ea
branch2:
		ldy #$0a
		dey
		bne *-1
fix3:
		cmp #$ea                //ntsc with nop nop
		inx
		cpx $d012
		bne branch3
branch3:
// --------------------------------------------------------
// Now the raster should be stable
// --------------------------------------------------------

	tsx             // Transfer the bit pattern back from the SP via X.
	txa

	nop
	nop
// =========================================================
// Bit #7
// =========================================================
	rol           // Get the MSB
	bcs RED1        // If bit is set, jump to red colour
	ldx #GREEN         // Set Green colour. Bit is 0.
	jmp BAR1
RED1:    
	ldx #RED         // Set Red colour. Bit is 1.
BAR1:    
	ldy #BARSTART1          // Set new row y where bar will start.
	cpy $d012        // Wait until row y.
	bne *-3          // is the value of Y not equal to current rasterposition? Then check again.
	stx $D020        // Set bar colour (Red or Green)
	ldx #BACKGROUND         // Set background colour.
	ldy #BARSTOP1          // Set new row y where bar will end.
	cpy $d012        // Wait until row y 
	bne *-3          // is the value of Y not equal to current rasterposition? Then check again.
	stx $D020        // Set background colour


	nop
	nop
	nop

// =========================================================
// Bit #6
// =========================================================

	rol
	bcs RED2
	ldx #GREEN
	jmp BAR2
RED2:     
	ldx #RED

BAR2:
	ldy #BARSTART2
	cpy $d012        //ComPare current value in Y with the current rasterposition.
	bne *-3          //is the value of Y not equal to current rasterposition? then 
	stx $D020
	ldx #BACKGROUND
	ldy #BARSTOP2
	cpy $d012        //ComPare current value in Y with the current rasterposition.
	bne *-3
	stx $D020
	
	nop
	nop
	nop

	nop
	nop
	bit $44
// =========================================================
// Bit #5
// =========================================================

	rol
	bcs RED3
	ldx #GREEN
	jmp BAR3
RED3:     
	ldx #RED
BAR3:
	ldy #BARSTART3
	cpy $d012        //ComPare current value in Y with the current rasterposition.
	bne *-3          //is the value of Y not equal to current rasterposition? then 
	stx $D020
	ldx #BACKGROUND
	ldy #BARSTOP3
	cpy $d012        //ComPare current value in Y with the current rasterposition.
	bne *-3
	stx $D020


	nop
	nop
	nop
// =========================================================
// Bit #4
// =========================================================


	rol
	bcs RED4
	ldx #GREEN
	jmp BAR4
RED4:     
	ldx #RED
BAR4:
	ldy #BARSTART4
	cpy $d012        //ComPare current value in Y with the current rasterposition.
	bne *-3          //is the value of Y not equal to current rasterposition? then 
	stx $D020
	ldx #BACKGROUND
	ldy #BARSTOP4
	cpy $d012        //ComPare current value in Y with the current rasterposition.
	bne *-3
	stx $D020


	nop
	nop
	nop
// =========================================================
// Bit #3
// =========================================================



	rol
	bcs RED5
	ldx #GREEN
	jmp BAR5
RED5:     
	ldx #RED

BAR5:
	ldy #BARSTART5
	cpy $d012        //ComPare current value in Y with the current rasterposition.
	bne *-3          //is the value of Y not equal to current rasterposition? then 
	stx $D020
	ldx #BACKGROUND
	ldy #BARSTOP5
	cpy $d012        //ComPare current value in Y with the current rasterposition.
	bne *-3
	stx $D020


	nop
	nop
	nop
// =========================================================
// Bit #2
// =========================================================
	
	rol
	bcs RED6
	ldx #GREEN
	jmp BAR6
RED6:     
	ldx #RED

BAR6:
	ldy #BARSTART6
	cpy $d012        //ComPare current value in Y with the current rasterposition.
	bne *-3          //is the value of Y not equal to current rasterposition? then 
	stx $D020
	ldx #BACKGROUND
	ldy #BARSTOP6
	cpy $d012        //ComPare current value in Y with the current rasterposition.
	bne *-3
	stx $D020


	nop
	nop
	nop
// =========================================================
// Bit #1
// =========================================================

	rol
	bcs RED7
	ldx #GREEN
	jmp BAR7
RED7:     
	ldx #RED

BAR7:
	ldy #BARSTART7
	cpy $d012        //ComPare current value in Y with the current rasterposition.
	bne *-3          //is the value of Y not equal to current rasterposition? then 
	stx $D020
	ldx #BACKGROUND
	ldy #BARSTOP7
	cpy $d012        //ComPare current value in Y with the current rasterposition.
	bne *-3
	stx $D020
// ---
	  //  NOP // Delays moved here to move the above bne from a page break 
	  //  NOP
	  //  NOP
	  //  NOP
// ---


	nop
	nop
	nop
// =========================================================
// Bit #0 (LSB)
// =========================================================
	rol
	bcs RED8
	ldx #GREEN
	jmp BAR8
RED8:     
	ldx #RED

BAR8:
	ldy #BARSTART8
	cpy $d012        //ComPare current value in Y with the current rasterposition.
	bne *-3          //is the value of Y not equal to current rasterposition? then 
	stx $D020
	ldx #BACKGROUND
	ldy #BARSTOP8
	cpy $d012        //ComPare current value in Y with the current rasterposition.
	bne *-3
	stx $D020

	jmp MAIN_LOOP

