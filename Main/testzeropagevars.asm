.filenamespace testzeropagevars

//        * = $C000            // Example start address (change as needed)
testzeropagevars:
	sei                 // Disable interrupts to prevent stack usage

START:  // ---------------------------------------------------------
	// STEP 1: Write 0 to all addresses $F0..$FF
	// ---------------------------------------------------------
	ldx #$00            // Initialize X to 0 (offset from $F0)
STEP1_LOOP:
	lda #$00            // Load 0 into A
	sta $F0,X           // Store 0 to address ($F0 + X)
	inx                 // Increment X
	cpx #$10            // Compare X with 16
	bne STEP1_LOOP      // Loop until all 16 .bytes are written

	jmp STEP2           // Proceed to STEP 2

// =========================================================================
// STEP 2: Up pass (R0W1, R1W0, R0W1)
// For each address going up:
//    - Read, expect 0
//    - Write 1
//    - Read, expect 1
//    - Write 0
//    - Read, expect 0
//    - Write 1
// =========================================================================
STEP2:
	ldx #$00            // Initialize X to 0
STEP2_LOOP:
	// R0: Read and expect 0
	lda $F0,X
//        LDY #$00            // Y = expected value 0
	eor #$00            // A = A ^ 0
	bne FAIL2            // If result != 0, fail

	// W1: Write 1
	lda #$FF
	sta $F0,X

	// R1: Read and expect 1
	lda $F0,X
//        LDY #$01            // Y = expected value 1
	eor #$FF            // A = A ^ 1
	bne FAIL2            // If result != 0, fail

	// W0: Write 0
	lda #$00
	sta $F0,X

	// R0: Read and expect 0
	lda $F0,X
//        LDY #$00            // Y = expected value 0
	eor #$00            // A = A ^ 0
	bne FAIL2            // If result != 0, fail

	// W1: Write 1
	lda #$FF
	sta $F0,X

	inx                 // Increment X
	cpx #$10            // Compare X with 16
	bne STEP2_LOOP      // Loop until all 16 .bytes are processed

	jmp STEP3           // Proceed to STEP 3
FAIL2:
	jmp FAILTERM
// =========================================================================
// STEP 3: Up pass (R1W0W1)
// For each address going up:
//    - Read, expect 1
//    - Write 0
//    - Write 1
// =========================================================================
STEP3:
	ldx #$00            // Initialize X to 0
STEP3_LOOP:
	// R1: Read and expect 1
	lda $F0,X
//        LDY #$01            // Y = expected value 1
	eor #$FF            // A = A ^ 1
	bne FAIL2            // If result != 0, fail

	// W0: Write 0
	lda #$00
	sta $F0,X

	// W1: Write 1
	lda #$FF
	sta $F0,X

	inx                 // Increment X
	cpx #$10            // Compare X with 16
	bne STEP3_LOOP      // Loop until all 16 .bytes are processed
//-----
// Simulated memory failure
	   // LDA #$ED
//        STA $F3
//-----
	jmp STEP4           // Proceed to STEP 4

// =========================================================================
// STEP 4: Down pass (R1W0W1W0)
// For each address going down:
//    - Read, expect 1
//    - Write 0
//    - Write 1
//    - Write 0
// =========================================================================
STEP4:
	ldx #$0F            // Initialize X to 15 (offset from $F0)
STEP4_LOOP:
	// R1: Read and expect 1
	lda $F0,X
//        LDY #$01            // Y = expected value 1
	eor #$FF            // A = A ^ 1
	bne FAILTERM            // If result != 0, fail

	// W0: Write 0
	lda #$00
	sta $F0,X

	// W1: Write 1
	lda #$FF
	sta $F0,X

	// W0: Write 0 again
	lda #$00
	sta $F0,X

	dex                 // Decrement X
	bpl STEP4_LOOP      // Loop while X >= 0

	jmp STEP5           // Proceed to STEP 5

// =========================================================================
// STEP 5: Down pass (R0W1W0)
// For each address going down:
//    - Read, expect 0
//    - Write 1
//    - Write 0
// =========================================================================
STEP5:
	ldx #$0F            // Initialize X to 15
STEP5_LOOP:
	// R0: Read and expect 0
	lda $F0,X
//        LDY #$00            // Y = expected value 0
	eor #$00            // A = A ^ 0
	bne FAIL2            // If result != 0, fail

	// W1: Write 1
	lda #$FF
	sta $F0,X

	// W0: Write 0
	lda #$00
	sta $F0,X

	dex                 // Decrement X
	bpl STEP5_LOOP      // Loop while X >= 0

	jmp tzp_SUCCESS         // All tests passed

// =========================================================================
// FAILURE HANDLER
// On a mismatch:
//    - X = failing address offset (0..15)
//    - Y = expected value
//    - A = A ^ Y (differing bits)
// =========================================================================

FAILTERM:
	// At this point:
	// X = failing address offset ($F0 + X)
	// Y = expected value [unused - REMOVED]
	// A = A ^ Y (difference bits)
//FAIL_LOOP
	tay             // A kludge to add F0 to the offset to get the failing address
	txa
	clc
	adc #$F0
	tax
	tya
	jmp testzeropagevars_Fail        // Spin forever to indicate failure

// =========================================================================
// SUCCESS HANDLER
// All tests passed successfully
// =========================================================================

tzp_SUCCESS:
	jmp testzeropagevars_Return          // Spin forever to indicate success

// How to Interpret Failure Information

// When a failure occurs and the program jumps to the FAIL loop, you can inspect the CPU registers to determine the nature of the failure:

//    Register X:
//        Value: Offset of the failing address (0 to 15).
//        Interpretation:
//            The failing address is $F0 + X. For example, if X = $07, the failing address is $F7.

//    Register Y:
//        Value: Expected value at the failing address ($00 or $01).
//        Interpretation:
//            Indicates what value was expected during the read operation.

//    Register A:
//        Value: Result of A ^ Y, representing the differing bits.
//        Interpretation:
//            Each bit set to 1 in A indicates a mismatch in that bit position.
//            To determine the actual read value:
//                Formula: read_data = A ^ Y

