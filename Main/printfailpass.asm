.filenamespace printfailpass_main
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
    lda XPOS
    sta printstring_main.XPOS
    lda YPOS
    sta printstring_main.YPOS
	lda STATUS		                // Load the value from STATUS
	beq pass_case	                // If zero, branch to pass case

fail_case:
	lda #<STRING_FAIL                   // Load low byte of STRING_FAIL address
	sta printstring_main.STR_PTR_LO	    // Store into pointer low byte
	lda #>STRING_FAIL                   // Load high byte of STRING_FAIL address
	sta printstring_main.STR_PTR_HI	    // Store into pointer high byte
    lda #$02                            // Set colour to red
    sta printstring_main.CHARCOLOUR
	jsr printstring_main.PRINT_STRING    // Call PrintString subroutine
	rts				                    // Return from subroutine

pass_case:
	lda #<STRING_PASS                   // Load low byte of STRING_PASS address
	sta printstring_main.STR_PTR_LO	    // Store into pointer low byte
	lda #>STRING_PASS                   // Load high byte of STRING_PASS address
	sta printstring_main.STR_PTR_HI	    // Store into pointer high byte
    lda #$05                            // Set colour to green
    sta printstring_main.CHARCOLOUR
	jsr printstring_main.PRINT_STRING	// Call PrintString subroutine
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
