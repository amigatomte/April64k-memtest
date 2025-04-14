.filenamespace printfailpass_c000
// Define zero page addresses
.label STATUS   = $82		   // The zero page variable to check
.label XPOS     = $83          // The X position on the screen
.label YPOS     = $84          // The Y position on the screen
//.label STR_PTR  = $80		   // Low byte of the string pointer
// STR_PTR+1 (i.e., $81) holds the high byte

//-------------------------------------------------
// CheckAndPrint: Checks STATUS and prints appropriate string.
//-------------------------------------------------
CheckAndPrint:
    lda.zp XPOS
    sta.zp printstring_c000.XPOS
    lda.zp YPOS
    sta.zp printstring_c000.YPOS
	lda.zp STATUS		                // Load the value from STATUS
	beq pass_case	                // If zero, branch to pass case

fail_case:
	lda #<STRING_FAIL                   // Load low byte of STRING_FAIL address
	sta.zp printstring_c000.STR_PTR_LO	    // Store into pointer low byte
	lda #>STRING_FAIL                   // Load high byte of STRING_FAIL address
	sta.zp printstring_c000.STR_PTR_HI	    // Store into pointer high byte
    lda #$02                            // Set colour to red
    sta.zp printstring_c000.CHARCOLOUR
	jsr printstring_c000.PRINT_STRING    // Call PrintString subroutine
	rts				                    // Return from subroutine

pass_case:
	lda #<STRING_PASS                   // Load low byte of STRING_PASS address
	sta.zp printstring_c000.STR_PTR_LO	    // Store into pointer low byte
	lda #>STRING_PASS                   // Load high byte of STRING_PASS address
	sta.zp  printstring_c000.STR_PTR_HI	    // Store into pointer high byte
    lda #$05                            // Set colour to green
    sta.zp printstring_c000.CHARCOLOUR
	jsr printstring_c000.PRINT_STRING	// Call PrintString subroutine
	rts				                    // Return from subroutine

//-------------------------------------------------
// Data Strings (null-terminated)
//-------------------------------------------------
STRING_PASS:
	.text "Pass"
	.byte 0		// The string to print on success

STRING_FAIL:
	.text "Fail"
	.byte 0		// The string to print on failure
