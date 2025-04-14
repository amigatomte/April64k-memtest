.filenamespace testzeropage
//----------------------------------------------------------
// Configuration
//----------------------------------------------------------
// Example: Test from $0002..$00FF  => 254 addresses
.label TEST_START         = $0002
.label LAST_TEST_OFFSET   = $FD     // 0..$FD inclusive = 254 addresses

// Alternatively, for $0100..$01FF => 256 addresses:
// .label TEST_START         = $0100
// .label LAST_TEST_OFFSET   = $FF     // 0..$FF inclusive = 256 addresses

// Macro: checkMismatch(<expectedValue>)
// Compares A against <expectedValue>.

.macro checkMismatch(expected) {
    cmp #expected
    beq ok
    // Mismatch: compute "all failed bits" = A ^ <expectedValue>
    eor #expected
    jmp testzeropage_Fail
ok:
}

//----------------------------------------------------------
// The March B Routine
//----------------------------------------------------------
//* = $0801
marchBTest:
    // Initialize "no mismatch found" => Y=0
    ldy #$00

//----------------------------------------------------------
// STEP 1: Write 0 to all tested addresses
//   from offset 0..LAST_TEST_OFFSET
//----------------------------------------------------------
    ldx #$00
step1Loop:
    lda #$00
    sta TEST_START,x
    inx
    cpx #LAST_TEST_OFFSET+1
    bne step1Loop

//----------------------------------------------------------
// STEP 2: Up pass (R0 W1 R1 W0 R0 W1)
//----------------------------------------------------------
    ldx #$00
step2Loop:
    // R0
    lda TEST_START,x
    checkMismatch($00)

    // W1
    lda #$FF
    sta TEST_START,x

    // R1
    lda TEST_START,x
    checkMismatch($FF)

    // W0
    lda #$00
    sta TEST_START,x

    // R0
    lda TEST_START,x
    checkMismatch($00)

    // W1
    lda #$FF
    sta TEST_START,x

    inx
    cpx #LAST_TEST_OFFSET+1
    bne step2Loop

//----------------------------------------------------------
// STEP 3: Up pass (R1 W0 W1)
//----------------------------------------------------------
    ldx #$00
step3Loop:
    // R1
    lda TEST_START,x
    checkMismatch($FF)

    // W0
    lda #$00
    sta TEST_START,x

    // W1
    lda #$FF
    sta TEST_START,x

    inx
    cpx #LAST_TEST_OFFSET+1
    bne step3Loop

//----------------------------------------------------------
// STEP 4: Down pass (R1 W0 W1 W0)
//----------------------------------------------------------
    ldx #LAST_TEST_OFFSET
step4Loop:
    // R1
    lda TEST_START,x
    checkMismatch($FF)

    // W0
    lda #$00
    sta TEST_START,x

    // W1
    lda #$FF
    sta TEST_START,x

    // W0
    lda #$00
    sta TEST_START,x

    dex
    bpl step4Loop   // continue while X >= 0

//----------------------------------------------------------
// STEP 5: Down pass (R0 W1 W0)
//----------------------------------------------------------
    ldx #LAST_TEST_OFFSET
step5Loop:
    // R0
    lda TEST_START,x
    checkMismatch($00)

    // W1
    lda #$FF
    sta TEST_START,x

    // W0
    lda #$00
    sta TEST_START,x

    dex
    bpl step5Loop   // continue while X >= 0

//----------------------------------------------------------
// Final: Report results
//----------------------------------------------------------
doneCheck:

    lda #$00        // A=0 => "no errors"
    ldx #$00        // X=0 => "no failing offset"
    jmp testzeropage_Return
