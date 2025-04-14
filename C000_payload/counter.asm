.filenamespace counter_c000
//*=$C000
//-----------------------------------------------------------------------
// Temporary code for testing
//-----------------------------------------------------------------------
//        LDA #$C0
//        STA $05
//        LDA #$00
//        STA $04
//        STA $06
//        STA $07
//        JSR INC4BYTE
//        JSR INC4BYTE

//        JSR DEC_COUNTER
//        JSR PrintString
//        RTS
////HEXBUF
////        .byte "HELLO WORLD", $00
//XPOS
//        .byte 10          // X position (0-39)
//YPOS
//        .byte 5           // Y position (0-24)
//CHARCOLOUR
//        .byte 2           // Color code (0-15)
//Incasm "Stage/includes/printstring.asm"
//-----------------------------------------------------------------------

// -------------------------------
// Zero–page variables (addresses are examples)
// The 4–.byte counter is at $04–$07.
// We use the following zero–page locations for temporary storage:
.label counter1 = $04
.label counter2 = $05
.label counter3 = $06
.label counter4 = $07

.label TEMP0    = $08   // working copy (low .byte)
.label TEMP1    = $09
.label TEMP2    = $0A
.label TEMP3    = $0B   // working copy (high .byte)

.label DC0      = $0C   // our 32–bit constant: low .byte
.label DC1      = $0D
.label DC2      = $0E
.label DC3      = $0F   // high .byte

.label DIGIT    = $10   // 1 .byte scratch for current digit
.label LEADING  = $11   // flag: 1 = still skipping leading zeros
.label DEC_OUT  = $12   // output buffer for decimal string (12 bytes)

// We use the output buffer DEC_OUT for the resulting string.
// (This buffer must be allocated in memory.)
// Here we reserve 12 .bytes (max 10 digits + null).
                                // (You can put this anywhere in RAM.)
//HEXBUF
// DEC_OUT:   .bytes 12

// -------------------------------
// INC4BYTE
// Increments the 4–.byte counter stored at $04–$07.
//
INC4BYTE:
        lda counter1
        clc
        adc #1
        sta counter1
        bne INC_RET

        lda counter2
        adc #0
        sta counter2
        bne INC_RET

        lda counter3
        adc #0
        sta counter3
        bne INC_RET

        lda counter4
        adc #0
        sta counter4
INC_RET:
        rts

// -------------------------------
// DEC_COUNTER
// Converts the current counter ($04–$07) into a decimal screen–code string
// stored in DEC_OUT (null–terminated).
//
DEC_COUNTER:
        // Make a working copy of the counter (so as not to alter $04–$07)
        lda counter1         // LSB
        sta TEMP0
        lda counter2
        sta TEMP1
        lda counter3
        sta TEMP2
        lda counter4         // MSB
        sta TEMP3

        // Set our output index (using register X as offset into DEC_OUT)
        ldx #0

        // Set flag so we don’t output any leading zero
        lda #$01
        sta LEADING

        // --- Now “peel off” each digit using a table of 10^n constants.
        // We process 10^9, 10^8, ... , 10^1, and finally 10^0.
        //
        // Process 10^9 = 1,000,000,000 (0x3B9ACA00 in hex, little–endian: 00, CA, 9A, 3B)
        lda #$00
                sta DC0
        lda #$CA
                sta DC1
        lda #$9A
                sta DC2
        lda #$3B
                sta DC3
        jsr PROCESS_POWER

        // Process 10^8 = 100,000,000 (0x05F5E100 → 00, E1, F5, 05)
        lda #$00
                sta DC0
        lda #$E1
                sta DC1
        lda #$F5
                sta DC2
        lda #$05
                sta DC3
        jsr PROCESS_POWER

        // Process 10^7 = 10,000,000 (0x00989680 → 80, 96, 98, 00)
        lda #$80
                sta DC0
        lda #$96
                sta DC1
        lda #$98
                sta DC2
        lda #$00
                sta DC3
        jsr PROCESS_POWER

        // Process 10^6 = 1,000,000 (0x000F4240 → 40, 42, 0F, 00)
        lda #$40
                sta DC0
        lda #$42
                sta DC1
        lda #$0F
                sta DC2
        lda #$00
                sta DC3
        jsr PROCESS_POWER

        // Process 10^5 = 100,000 (0x000186A0 → A0, 86, 01, 00)
        lda #$A0
                sta DC0
        lda #$86
                sta DC1
        lda #$01
                sta DC2
        lda #$00
                sta DC3
        jsr PROCESS_POWER

        // Process 10^4 = 10,000 (0x00002710 → 10, 27, 00, 00)
        lda #$10
                sta DC0
        lda #$27
                sta DC1
        lda #$00
                sta DC2
        lda #$00
                sta DC3
        jsr PROCESS_POWER

        // Process 10^3 = 1,000 (0x000003E8 → E8, 03, 00, 00)
        lda #$E8
                sta DC0
        lda #$03
                sta DC1
        lda #$00
                sta DC2
        lda #$00
                sta DC3
        jsr PROCESS_POWER

        // Process 10^2 = 100 (0x00000064 → 64, 00, 00, 00)
        lda #$64
                sta DC0
        lda #$00
                sta DC1
        lda #$00
                sta DC2
        lda #$00
                sta DC3
        jsr PROCESS_POWER

        // Process 10^1 = 10 (0x0000000A → 0A, 00, 00, 00)
        lda #$0A
                sta DC0
        lda #$00
                sta DC1
        lda #$00
                sta DC2
        lda #$00
                sta DC3
        jsr PROCESS_POWER

        // Process 10^0 = 1 (0x00000001 → 01, 00, 00, 00)
        lda #$01
                sta DC0
        lda #$00
                sta DC1
        lda #$00
                sta DC2
        lda #$00
                sta DC3
        jsr PROCESS_POWER

        // If no digit was output (i.e. the counter was 0) then output a single "0"
        lda LEADING
        cmp #0
        beq SKIP_ZERO
        lda #$30
        sta DEC_OUT,X   // store the "0"
        inx
SKIP_ZERO:
        // Terminate the string with a null
        lda #0
        sta DEC_OUT,X
        rts

// -------------------------------
// PROCESS_POWER
// For the current 10^n (constant stored in DC0–DC3), subtract it as many times
// as possible from our working copy (TEMP0–TEMP3). The count (0–9) is kept in DIGIT.
//
PROCESS_POWER:
        lda #0
        sta DIGIT
PPC_LOOP:
        jsr COMPARE_TEMP_DC  // sets carry if TEMP >= constant
        bcc PPC_DONE       // if TEMP < constant, we’re done here
        jsr SUBTRACT_DC    // TEMP = TEMP – constant
        inc DIGIT
        jmp PPC_LOOP
PPC_DONE:
        //
        // We output a digit if we’ve already output a non–zero digit,
        // or if this is the ones place (i.e. the constant equals 1).
        lda DC0
        cmp #$01
        bne PPC_OUTCHK
        lda DC1
        cmp #0
        bne PPC_OUTCHK
        lda DC2
        cmp #0
        bne PPC_OUTCHK
        lda DC3
        cmp #0
        bne PPC_OUTCHK
        // It is the ones place: fall through.
PPC_OUTCHK:
        lda LEADING
        beq PPC_OUTPUT   // already output a digit => output this one too
        lda DIGIT
        beq PPC_SKIP     // still leading zero – don’t output a 0 here
PPC_OUTPUT:
        // Convert the binary digit (0–9) into its screen code by adding $30.
        lda DIGIT
        clc
        adc #$30
        sta DEC_OUT,X
        inx
        // Clear the leading–zero flag.
        lda #0
        sta LEADING
PPC_SKIP:
        rts

// -------------------------------
// COMPARE_TEMP_DC
// Compare the 32–bit number in TEMP (TEMP3..TEMP0, high to low)
// with the 32–bit constant in DC (DC3..DC0).
// If TEMP >= constant then set the carry flag.
//
COMPARE_TEMP_DC:
        lda TEMP3
        cmp DC3
        bcc COMP_FAIL
        bne COMP_OK
        lda TEMP2
        cmp DC2
        bcc COMP_FAIL
        bne COMP_OK
        lda TEMP1
        cmp DC1
        bcc COMP_FAIL
        bne COMP_OK
        lda TEMP0
        cmp DC0
        bcc COMP_FAIL
COMP_OK:
        sec
        rts
COMP_FAIL:
        clc
        rts

// -------------------------------
// SUBTRACT_DC
// Subtract the 32–bit constant in DC (DC3..DC0) from TEMP (TEMP3..TEMP0).
//
SUBTRACT_DC:
        sec
        lda TEMP0
        sbc DC0
        sta TEMP0
        lda TEMP1
        sbc DC1
        sta TEMP1
        lda TEMP2
        sbc DC2
        sta TEMP2
        lda TEMP3
        sbc DC3
        sta TEMP3
        rts
