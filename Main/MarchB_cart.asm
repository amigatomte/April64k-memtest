.filenamespace MarchB_main
           // *= $C000         // Put code at $C000

// ---------------------------------------------------------
// Zero-page variables
// ---------------------------------------------------------
.label ZP_STARTLO   = $F0   // Start address (low .byte)
.label ZP_STARTHI   = $F1   // Start address (high .byte)
.label ZP_ENDLO     = $F2   // End address (low .byte)
.label ZP_ENDHI     = $F3   // End address (high .byte)
.label ZP_FAILLO    = $A4   // First failing address (low .byte)
.label ZP_FAILHI    = $A5   // First failing address (high .byte)
.label ZP_STATUS    = $16   // 0 = pass, 1 = fail
.label ZP_FAILBITS  = $17   // Failed bits (difference)
.label PtrLo        = $FB   // Temporary pointer (low .byte)
.label PtrHi        = $FC   // Temporary pointer (high .byte)

// ZP_FAILLO:    .byte 0   // First failing address (low .byte)
// ZP_FAILHI:    .byte 0   // First failing address (high .byte)
// ZP_STATUS:    .byte 0   // 0 = pass, 1 = fail
// ZP_FAILBITS:  .byte 0   // Failed bits (difference)
//PRINT_COL    .byte 23
//PRINT_ROW    .byte 9


// ---------------------------------------------------------
// SUBROUTINE: MarchBTest
// ---------------------------------------------------------
// Performs the 17n March B sequence on [ZP_START..ZP_END].
// On fail: sets ZP_STATUS=1, records failing address/bits,
//          returns immediately.
// On pass: sets ZP_STATUS=0, returns.
// ---------------------------------------------------------
MarchBTest:
// ---------------------------------------------------------
        // Disable display to slightly speed up the test. 
        // //The screen would be garbled anyway due to overwriting of the screen memory.
        // .break
        // lda $D011         // Load current VIC-II control register value
        // and #%11101111    // Clear bit 4 (mask $EF) to disable display (DEN = 0)
        // sta $D011         // Store the modified value back to $D011
// ---------------------------------------------------------

// ---------------------------------------------------------
        // Start by zeroing out the zero-page status variables
        lda #$00
        sta.zp ZP_STATUS
        sta.zp ZP_FAILLO
        sta.zp ZP_FAILHI
        sta.zp ZP_FAILBITS
// ---------------------------------------------------------

        // Step 1: Write 0 to entire range
        jsr Write0Range // No reads here, so no point checking ZP_STATUS
        

        // Step 2: Up pass (R0W1, R1W0, R0W1)
        jsr UpPass_R0W1_R1W0_R0W1
        // .break
        // lda ZP_STATUS
        // bne FAIL // If ZP_STATUS is set, abort
        

// --- Memory corruption test
        // lda #$FE
        // sta $0813
        // lda #$EF
        // sta $0811
// --------------------------
        
        // Step 3: Up pass (R1W0W1)
        jsr UpPass_R1W0W1
        // .break
        // lda ZP_STATUS
        // bne FAIL // If ZP_STATUS is set, abort
        

        // Step 4: Down pass (R1W0W1W0)
        jsr DownPass_R1W0W1W0
        // .break
        // lda ZP_STATUS
        // bne FAIL // If ZP_STATUS is set, abort
        

        // Step 5: Down pass (R0W1W0)
        jsr DownPass_R0W1W0
        // .break
//         lda ZP_STATUS
//         bne FAIL // If ZP_STATUS is set, abort
        
//         // If we get here, no fails
        
//         lda #$00
//         sta ZP_STATUS
// FAIL:   
        // lda #$37                                //Bank in Cartridge ROM (+ kernal and basic)
        // sta $01
        lda #$0e                        // Set the border color to light blue
        sta $d020
// ---------------------------------------------------------
        // We are done. Re-enable display.
        // lda $D011         // Load current VIC-II control register value
        // ora #%00010000    // Set bit 4 (mask $10) to enable display (DEN = 1)
        // sta $D011         // Store the modified value back to $D011
// ---------------------------------------------------------
        rts
FLICKER:
        jsr flickerscreen
        jmp FLICKER

flickerscreen:
        lda #$37                                //Bank in Cartridge ROM (+ kernal and basic)
        sta.zp $01
        inc $D020
        inc $D020
        inc $D020
        lda #$30                               //Bank in Cartridge ROM (+ kernal and basic)
        sta.zp $01
        rts
// Step 1: Write 0 to entire range
// ---------------------------------------------------------
// Write0Range: Write 0 to [Start..End] (forward)
// ---------------------------------------------------------
Write0Range:
        // Initialize pointer = Start
        lda ZP_STARTLO
        sta PtrLo
        lda ZP_STARTHI
        sta PtrHi

        lda #$00       // A=0 to store
        ldy #$00

Write0Loop:
        jsr CheckAddrForward
        bcs Write0Done
        lda #$00
        sta (PtrLo),Y

        inc PtrLo
        bne Write0Loop
        inc PtrHi
        jmp Write0Loop

Write0Done:
        rts

// Step 2: Up pass (R0W1, R1W0, R0W1)
// ---------------------------------------------------------
// UpPass_R0W1_R1W0_R0W1
//  Forward pass:
//    (1) Read 0, check, Write 1
//    (2) Read 1, check, Write 0
//    (3) Read 0, check, Write 1
// ---------------------------------------------------------
UpPass_R0W1_R1W0_R0W1:
        // Initialize pointer
        lda ZP_STARTLO
        sta PtrLo
        lda ZP_STARTHI
        sta PtrHi

UpR0W1Loop:
        jsr CheckAddrForward
        bcs DoneUpR0W1

        ldy #$00
        // Read 0, check
        lda (PtrLo),Y
        eor #$00
        beq NOfailUpR0W1
        jsr MarkFail
NOfailUpR0W1:
        // Write 1
        lda #$FF
        sta (PtrLo),Y

        // Read 1, check
        lda (PtrLo),Y
        eor #$FF
        beq NOfailUpR0W1_2
        jsr MarkFail
NOfailUpR0W1_2:
        // Write 0
        lda #$00
        sta (PtrLo),Y

        // Read 0, check
        lda (PtrLo),Y
        eor #$00
        beq NOfailUpR0W1_3
        jsr MarkFail
NOfailUpR0W1_3:

        // Write 1
        lda #$FF
        sta (PtrLo),Y

        // Next address
        inc PtrLo
        bne UpR0W1Loop
        inc PtrHi
        jmp UpR0W1Loop

DoneUpR0W1:
        rts

// Step 3: Up pass (R1W0W1)
// ---------------------------------------------------------
// UpPass_R1W0W1
//  Forward pass:
//    (1) Read 1, check
//    (2) Write 0
//    (3) Write 1
// ---------------------------------------------------------
UpPass_R1W0W1:
        // Initialize pointer
        lda ZP_STARTLO
        sta PtrLo
        lda ZP_STARTHI
        sta PtrHi

UpR1W0W1Loop:
        jsr CheckAddrForward
        bcs DoneUpR1W0W1

        ldy #$00
        // Read 1, check
        lda (PtrLo),Y
        eor #$FF
        beq NOfailUpR1W0W1
        jsr MarkFail

NOfailUpR1W0W1:
        // Write 0
        lda #$00
        sta (PtrLo),Y

        // Write 1
        lda #$FF
        sta (PtrLo),Y

        // Next address
        inc PtrLo
        bne UpR1W0W1Loop
        inc PtrHi
        jmp UpR1W0W1Loop

DoneUpR1W0W1:
        rts

// Step 4: Down pass (R1W0W1W0)
// ---------------------------------------------------------
// DownPass_R1W0W1W0
//  Backward pass:
//    (1) Read 1, check
//    (2) Write 0
//    (3) Write 1
//    (4) Write 0
// ---------------------------------------------------------
DownPass_R1W0W1W0:
        // Initialize pointer = End
        lda ZP_ENDLO
        sta PtrLo
        lda ZP_ENDHI
        sta PtrHi

DownR1W0W1W0Loop:
        jsr CheckAddrBackward
        bcs DoneDownR1W0W1W0

        ldy #$00
        // Read 1, check
        lda (PtrLo),Y
        eor #$FF
        beq NOfailDownR1W0W1W0
        jsr MarkFail
NOfailDownR1W0W1W0:
        // Write 0
        lda #$00
        sta (PtrLo),Y

        // Write 1
        lda #$FF
        sta (PtrLo),Y

        // Write 0
        lda #$00
        sta (PtrLo),Y

        lda PtrLo
        cmp #$00
        bne dec_low4
        dec PtrHi
        lda #$FF
        sta PtrLo
        jmp DownR1W0W1W0Loop
dec_low4:
        dec PtrLo
        jmp DownR1W0W1W0Loop

DoneDownR1W0W1W0:
        rts

// Step 5: Down pass (R0W1W0)
// ---------------------------------------------------------
// DownPass_R0W1W0
//  Backward pass:
//    (1) Read 0, check
//    (2) Write 1
//    (3) Write 0
// ---------------------------------------------------------
DownPass_R0W1W0:
                
       
        // Initialize pointer = End
        lda ZP_ENDLO
        sta PtrLo
        lda ZP_ENDHI
        sta PtrHi

        // --- Memory corruption test
        // lda #$01
        // sta $F123
        // --------------------------

DownR0W1W0Loop:
        jsr CheckAddrBackward
        bcs DoneDownR0W1W0

        ldy #$00
        // Read 0, check
        lda (PtrLo),Y
        eor #$00
        beq NOfailDownR0W1W0
        jsr MarkFail
NOfailDownR0W1W0:
        // Write 1
        lda #$FF
        sta (PtrLo),Y

        // Write 0
        lda #$00
        sta (PtrLo),Y

        lda PtrLo
        cmp #$00
        bne dec_low5
        dec PtrHi
        lda #$FF
        sta PtrLo
        jmp DownR0W1W0Loop
dec_low5:
        dec PtrLo
        jmp DownR0W1W0Loop
ContinueLoop:

DoneDownR0W1W0:
        rts


// ---------------------------------------------------------
// CheckAddrForward
//  If (Ptr > End) or if Ptr equals $0000 (wrap-around),
//  sets C=1, else C=0
//
// This subroutine checks whether the current pointer (PtrHi:PtrLo)
// is within the valid test range defined by the end address in
// ZP_ENDHI:ZP_ENDLO. The test range is inclusive, meaning that
// a pointer equal to the end address is still considered valid.
// 
// In addition, the routine also checks for a wrap-around condition:
// if the pointer has wrapped to $0000 (i.e. both PtrHi and PtrLo are 0),
// then it is flagged as out-of-range.
// 
// The subroutine sets the carry flag (C=1) if the pointer is out-of-range,
// and clears it (C=0) if the pointer is in-range.
// 
// Out-of-range conditions include:
//   - The pointer is exactly $0000 (wrap-around condition)
//   - The pointer is greater than the end address (ZP_ENDHI:ZP_ENDLO)
// ---------------------------------------------------------


CheckAddrForward:
        lda PtrHi               // Load the high byte of the pointer
        ora PtrLo               // OR with the low byte: result will be 0 if both are 0
        beq OutOfRangeForward    // if both bytes are 0, pointer is wrapped (assuming test range never includes $0000 (which is won't as the 6510 cpu can't access RAM at addresses $0000-$0001))
        // Otherwise, do the normal inclusive range check:
        lda PtrHi               // Load the high byte of the pointer again
        cmp ZP_ENDHI            // Compare it with the high byte of the end address
        bcc InRangeForward      // If PtrHi is less than the end's high byte, the pointer is in range
        bne OutOfRangeForward   // If PtrHi is greater than the end's high byte, the pointer is out-of-range

        // At this point, the high bytes are equal, so compare the low bytes:
        lda PtrLo               // Load the low byte of the pointer
        cmp ZP_ENDLO            // Compare it with the low byte of the end address
        bcc InRangeForward      // If PtrLo is less than the end's low byte, pointer is in range
        beq InRangeForward      // If PtrLo equals the end's low byte, pointer is exactly at the boundary and is in range
        jmp OutOfRangeForward   // Otherwise, pointer is out-of-range (PtrLo > ZP_ENDLO)

InRangeForward:
        clc
        rts

OutOfRangeForward:
        sec
        rts

// ---------------------------------------------------------
// CheckAddrBackward
//  If (Ptr < Start), sets C=1, else C=0
// ---------------------------------------------------------

CheckAddrBackward:
        lda PtrHi
        cmp ZP_STARTHI
        beq CheckLowBackward   // If high bytes are equal, check the low byte.
        bcs InRangeBackward    // If PtrHi > ZP_STARTHI, pointer is in range.
        jmp OutOfRangeBackward // Otherwise, it’s out of range.
        
CheckLowBackward:
        lda PtrLo
        cmp ZP_STARTLO
        bcc OutOfRangeBackward // If PtrLo < ZP_STARTLO, pointer is out of range.
        jmp InRangeBackward    // Otherwise, it’s in range.
        
InRangeBackward:
        clc
        rts
        
OutOfRangeBackward:
        sec
        rts


// ---------------------------------------------------------
// MarkFail
//  Records failing address, data mismatch, sets STATUS=1
// ---------------------------------------------------------
MarkFail:


// ---------------------------------------------------------
// This code checks if we are currently checking colour memory.
// As colour memory only has 4 bits, the upper 4 bits contains random garbage
// that need to be filtered out. If the lower bits are clear, then we
// have a false alarm and do a RTS back immediately. Otherwise, clear the upper
// 4 bits and continue.
        tax               // save original A in X
        // Check if the two-byte pointer equals $D800.
        lda ZP_STARTHI    // load high .byte (or use ZP_STARTLO+1)
        cmp #$D8         // high .byte of $D800 is $D8
        bne NotD800     // if not equal, skip our test
        lda ZP_STARTLO    // load low byte of pointer
        cmp #$00         // low byte of $D800 is $00
        bne NotD800     // if not equal, skip our test

        // The pointer equals $D800.
        txa               // restore original A from X
        and #$0F        // clear bits 7–4 (keep only bits 3–0)
        beq DoRTS       // if low nibble is 0, return immediately
        jmp PointerDone // otherwise, continue with A modified
NotD800:
        txa               // pointer was not $D800, so restore original A
PointerDone:

// ---------------------------------------------------------

        // The failing data read is still in A if we EORed it,
        // but let's store something consistent. Typically we
        // store the mismatch bits, so A has (readVal ^ expected).
        ora ZP_FAILBITS // Add any failing bits
        sta ZP_FAILBITS
        lda ZP_STATUS
        bne SkipPtrSet // ZP_STATUS is already set, keep ZP_FAIL[LO|HI]

        lda PtrLo
        sta ZP_FAILLO
        lda PtrHi
        sta ZP_FAILHI


        lda #$01
        sta ZP_STATUS
DoRTS:   // return if none of bits 3–0 were set
SkipPtrSet:
        // Return immediately to caller. Once fail is flagged,
        // the rest of the test is moot. The calling routine
        // sees ZP_STATUS=1.
        rts