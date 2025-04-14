.filenamespace printstatusnoram
		// ----------------------------------------------
		// print_hex
		// 
		// Input:   A = .byte to be printed in hex
		// Output:  Two hex digits at screen $0400/$0401
		// Destroys: A, Y
		// ----------------------------------------------
//*=$C000
.label CHAR1=$0734
.label CHAR2=CHAR1+1
.label CHAR3=CHAR2+1
.label CHAR4=CHAR3+1
.label CHAR5=CHAR4+1

.label COLOUR1=$DB34
.label COLOUR2=COLOUR1+1
.label COLOUR3=COLOUR2+1
.label COLOUR4=COLOUR3+1
.label COLOUR5=COLOUR4+1

//         LDX #$CF
printstatusnoram:
 


	ldy #$17        //Restore default VIC memory pointers, lowercase
	sty $D018
	ldy #02
	sty COLOUR1
	sty COLOUR2
	sty COLOUR3
	sty COLOUR4
	sty COLOUR5

	tay              // Save original A in Y

	// ---- High nibble ----
	txa              // Get X into A
	lsr            // Shift right 4 times to isolate the high nibble
	lsr
	lsr
	lsr
	cmp #$0A         // Is nibble >= 10?
	bcc skip_hi
	clc
	adc #$07         // Convert 10..15 -> "A".."F"
skip_hi:
	clc
	adc #$30         // Add ASCII code for "0"
	sta CHAR4

	// ---- Low nibble ----
	txa              // Reload X into A for the low nibble
	and #$0F         // Mask out the low nibble
	cmp #$0A         // Is nibble >= 10?
	bcc skip_lo
	clc
	adc #$07
skip_lo:
	clc
	adc #$30
	sta CHAR5

	tya              // Restore the original A
	// (Carry on, A is unchanged)

	jmp rasterbars_main.printstatusnoram_return
	//RTS