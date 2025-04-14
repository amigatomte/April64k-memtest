	.filenamespace testzpstack
*=$C000
        .label ZP_STARTLO = $20
        .label ZP_STARTHI = $21
        .label ZP_ENDLO = $22
        .label ZP_ENDHI = $23
START:
        // sei
	// lda #$7f    //Disable CIA IRQ"s
	// sta $dc0d
	// sta $dd0d

	// lda #$35    //Bank out kernal and basic
	// sta $01     

	// ldy #$17        //Restore default VIC memory pointers, lowercase
	// sty $D018

        // We don't have access to the symbol table of the calling program.
        // Therefore the return address is passed in $10 and $11.
        // As we are going to wreak havoc on the zeropage, it will not be available when it's time to return.
        // We store it in RETURN_ADDRESS (self-modifying the code) and use it to return to the calling program. 

        lda.zp $10
        sta RETURN_ADDRESS_LO
        lda.zp $11
        sta RETURN_ADDRESS_HI

        // lda.zp ZP_STARTLO       // Load the test parameters. We need to pass these through zeropage as the testZPS_ variables are not accessible before unpacking.
                                // And as with the return address above, zeropage will soon be overwritten by the test, so we need to store them in the testZPS_ variables. Tricky stuff..
        // lda #$00
        // sta testZPS_STARTLO
        // lda.zp ZP_STARTHI
        // // lda #$02
        // sta testZPS_STARTHI
        // lda.zp ZP_ENDLO
        // // lda #$FF
        // sta testZPS_ENDLO
        // lda.zp ZP_ENDHI
        // // lda #$02
        // sta testZPS_ENDHI

        jmp Do17nMarchBTest
           //*= $C100
//-----------------------------------------------------------------------
// Test parameters and status
//-----------------------------------------------------------------------
RETURN_ADDRESS_LO: .byte 0
RETURN_ADDRESS_HI: .byte 0
testZPS_STARTLO: .byte $02
testZPS_STARTHI: .byte $00
testZPS_ENDLO: .byte $ff
testZPS_ENDHI: .byte $01
testZPS_FAILLO: .byte 0
testZPS_FAILHI: .byte 0
testZPS_STATUS: .byte 0
testZPS_FAILBITS: .byte 0
// We need a pointer for looping:
ptrLo:     .byte 0
ptrHi:     .byte 0
// Manual "return address" (since no hardware stack usage)
returnLo:  .byte 0
returnHi:  .byte 0
// The expected read value (for readCheckSub)
expectedValue: .byte 0
// The .byte to write (for writeSub)
writeValue: .byte 0
                //*=$C000

//***********************************************************************
//*  Macros                                                             *
//***********************************************************************
//-----------------------------------------------------------------------
// Simulate "CALL label" by storing the "return PC" in returnLo/returnHi
// then JMP to the subroutine. The subroutine does "JMP (returnLo)" to return.
//-----------------------------------------------------------------------
//defm CALL_ABS
//  LDA #<retHere
//  STA returnLo
//  LDA #>retHere
//  STA returnHi
//  JMP param1
//retHere
//endm
//-----------------------------------------------------------------------
//  Macro: READ_EXPECT <val>
//    1) Self‐modify the readMem operand to [ptrHi:ptrLo].
//    2) Store <val> into expectedValue.
//    3) CALL_ABS readCheckSub.
//-----------------------------------------------------------------------
.macro READ_EXPECT(param1) {
        lda ptrLo
        sta readMem+1
        lda ptrHi
        sta readMem+2
        lda #param1
        sta expectedValue
        lda #<retHere
        sta returnLo
        lda #>retHere
        sta returnHi
        jmp readCheckSub
retHere:
}
//-----------------------------------------------------------------------
//  Macro: WRITE_BYTE <val>
//    1) Self‐modify the writeMem operand to [ptrHi:ptrLo].
//    2) Store <val> into writeValue.
//    3) CALL_ABS writeSub.
//-----------------------------------------------------------------------
.macro WRITE_BYTE(param1) {
        lda ptrLo
        sta writeMem+1
        lda ptrHi
        sta writeMem+2
        lda #param1
        sta writeValue
        lda #<retHere
        sta returnLo
        lda #>retHere
        sta returnHi
        jmp writeSub
retHere:
}

//-----------------------------------------------------------------------
// Macros to increment/decrement ptrLo/ptrHi by 1 (unsigned 16‐bit)
//-----------------------------------------------------------------------
.macro INC_PTR() {
        inc ptrLo
        lda ptrLo
        bne done     // if not zero after increment, done
        inc ptrHi
done:
}

.macro DEC_PTR() {
        lda ptrLo
        beq borrow   // if Lo=0, we need to borrow from Hi
        dec ptrLo
        jmp done
borrow:
        dec ptrHi
        lda #$FF
        sta ptrLo
done:
}

//***********************************************************************
//*  Shared Subroutines                                                 *
//*  (readCheckSub and writeSub use self-mod code plus manual return)   *
//***********************************************************************
//-----------------------------------------------------------------------
// readCheckSub:
//  - Expects readMem+1, readMem+2 = address to read
//  - expectedValue = .byte we expect
//  - Mismatch => update testZPS_STATUS, FAILLO/HI (if first), FAILBITS
//  - Return => JMP (returnLo)
//-----------------------------------------------------------------------
readCheckSub:
//          JMP readMem   // jump directly to the self‐mod code
readMem:
        .byte $AD, $00, $00   // LDA $0000
//          .byte $4C, <doCheck, >doCheck   // JMP doCheck
doCheck:
                                                // now A = memory read
        eor expectedValue
        beq noFail    // if zero => match => go return
                                                // else mismatch
        tax           // difference in X
        lda testZPS_STATUS
        bne skipSetFirst// if already 1, we skip first‐fail address
                                                // set the first fail address
        lda ptrLo
        sta testZPS_FAILLO
        lda ptrHi
        sta testZPS_FAILHI
skipSetFirst:
        txa
        ora testZPS_FAILBITS
        sta testZPS_FAILBITS
        lda #$01
        sta testZPS_STATUS
noFail:
        jmp (returnLo)
//-----------------------------------------------------------------------
// writeSub:
//  - Expects writeMem+1, writeMem+2 = address
//  - writeValue = .byte to write
//  - Return => JMP (returnLo)
//-----------------------------------------------------------------------
writeSub:
        lda writeValue
//          JMP writeMem
writeMem:
        .byte $8D, $00, $00   // STA $0000
//          .byte $4C, <doneWrite, >doneWrite
doneWrite:
        jmp (returnLo)
//***********************************************************************
//*  Main Routine: Do17nMarchBTest                                      *
//*  Executes the 17n March-B sequence on [testZPS_START..testZPS_END]. *
//***********************************************************************
//***********************************************************************
//*  Main Routine: Do17nMarchBTest                                      *
//*  Executes the 17n March-B sequence:                                 *
//*    1) (w0)                                                          *
//*    2) up (r0, w1, r1, w0, r0, w1)                                   *
//*    3) up (r1, w0, w1)                                               *
//*    4) down (r1, w0, w1, w0)                                         *
//*    5) down (r0, w1, w0)                                             *
//*                                                                     *
//***********************************************************************
Do17nMarchBTest:
                                                // (Optional) Clear status/failbits if you want a fresh start

       sei
        // lda #$7f    //Disable CIA IRQ"s
        // sta $dc0d
        // sta $dd0d

        // lda #$34    //Bank out kernal, i/o and basic
        // sta $01     

        // ldy #$17        //Restore default VIC memory pointers, lowercase
        // sty $D018


        lda #$00
        sta testZPS_STATUS
        sta testZPS_FAILBITS
        sta testZPS_FAILLO
        sta testZPS_FAILHI
//=======================================================================
// PASS 1) (w0) : For all addresses from START..END => write 0x00
//=======================================================================
Pass1_Init:
        lda testZPS_STARTLO
        sta ptrLo
        lda testZPS_STARTHI
        sta ptrHi
Pass1_Loop:
                                                //WRITE_BYTE($00)
        WRITE_BYTE($00)// (w0) => write 0x00 to [ptrHi:ptrLo]
        INC_PTR()          // increment pointer
Pass1_Compare:
                                                // while ptr <= END, keep looping
                                                // i.e. (ptrHi < endHi) OR (ptrHi == endHi && ptrLo <= endLo)
        lda ptrHi
        cmp testZPS_ENDHI
        bcc Pass1_Loop// if ptrHi < endHi => keep looping
        bne Pass2_Init// if ptrHi > endHi => done (go next pass)
                                                // here ptrHi == endHi, check low
        lda ptrLo
        cmp testZPS_ENDLO
        bcc Pass1_Loop
        beq Pass1_Loop
        // if ptrLo > endLo => done
        jmp Pass2_Init


        // bcs Pass2_Init       // if ptrLo >= endLo => next pass
        // jmp Pass1_Loop       // else ptrLo < endLo => loop
//=======================================================================
// PASS 2) up (r0, w1, r1, w0, r0, w1)
//=======================================================================
Pass2_Init:
        lda testZPS_STARTLO
        sta ptrLo
        lda testZPS_STARTHI
        sta ptrHi
Pass2_Loop:
        READ_EXPECT($00)       // read expect 00
        WRITE_BYTE($FF)       // write FF
        READ_EXPECT($FF)       // read expect FF
        WRITE_BYTE($00)       // write 00
        READ_EXPECT($00)      // read expect 00
        WRITE_BYTE($FF)       // write FF
        INC_PTR()
Pass2_Compare:
        lda ptrHi
        cmp testZPS_ENDHI
        bcc Pass2_Loop_t
        bne Pass3_Init
                                                // hi == endHi
        lda ptrLo
        // cmp testZPS_ENDLO
        // bcs Pass3_Init
        cmp testZPS_ENDLO
        bcc Pass2_Loop_t   // if ptrLo < endLo => loop
        beq Pass2_Loop_t   // if ptrLo == endLo => loop
        jmp Pass4_Init   // else => exit


Pass2_Loop_t:
        jmp Pass2_Loop

//=======================================================================
// PASS 3) up (r1, w0, w1)
//=======================================================================
Pass3_Init:
        lda testZPS_STARTLO
        sta ptrLo
        lda testZPS_STARTHI
        sta ptrHi
Pass3_Loop:
        READ_EXPECT($FF)       // read expect FF
        WRITE_BYTE($00)      // write 00
        WRITE_BYTE($FF)       // write FF
        INC_PTR()
Pass3_Compare:
        lda ptrHi
        cmp testZPS_ENDHI
        bcc Pass3_Loop
        bne Pass4_Init
                                                                // hi == endHi
        lda ptrLo
        // cmp testZPS_ENDLO

        // bcs Pass4_Init
        // jmp Pass3_Loop
        cmp testZPS_ENDLO
        bcc Pass3_Loop   // if ptrLo < endLo => loop
        beq Pass3_Loop   // if ptrLo == endLo => loop
        jmp Pass4_Init   // else => exit

//=======================================================================
// PASS 4) down (r1, w0, w1, w0)
//=======================================================================
Pass4_Init:
        lda testZPS_ENDLO
        sta ptrLo
        lda testZPS_ENDHI
        sta ptrHi
Pass4_Loop:
        READ_EXPECT($FF)       // read expect FF
        WRITE_BYTE($00)        // write 00
        WRITE_BYTE($FF)        // write FF
        WRITE_BYTE($00)        // write 00
        DEC_PTR()
Pass4_Compare:
                                                // while ptr >= START
                                                // => (ptrHi > startHi) OR (ptrHi == startHi && ptrLo >= startLo)
        lda ptrHi
        cmp testZPS_STARTHI
        bcc Pass5_Init        // hi < startHi => done
        bne Pass4_Loop_t      // hi > startHi => loop
                                                                // hi == startHi
        lda ptrLo
        cmp testZPS_STARTLO
        bcc Pass5_Init
Pass4_Loop_t:
        jmp Pass4_Loop

//=======================================================================
// PASS 5) down (r0, w1, w0)
//=======================================================================
Pass5_Init:
        lda testZPS_ENDLO
        sta ptrLo
        lda testZPS_ENDHI
        sta ptrHi
Pass5_Loop:
        READ_EXPECT($00)       // read expect 00
        WRITE_BYTE($FF)       // write FF
        WRITE_BYTE($00)       // write 00
        DEC_PTR()
Pass5_Compare:
        lda ptrHi
        cmp testZPS_STARTHI
        bcc TestDone
        bne Pass5_Loop
                                                // hi == startHi
        lda ptrLo
        cmp testZPS_STARTLO
        bcc TestDone
        
        jmp Pass5_Loop
TestDone:
Done:
                                                // The test is complete. If testZPS_STATUS=0 => pass, else 1 => fail
                                                // testZPS_FAILLO/HI => first fail address
        jmp (RETURN_ADDRESS_LO)
        // jmp $2000                                        // testZPS_FAILBITS => which bits were wrong (OR of differences)
        // jmp RETURN_ADDRESS:$0000                // Return to the calling program. The return address (RETURN_ADDRESS) has been overwritten at the beginning of the routine.
        // jmp Do17nMarchBTest_RETURN      // hang here or do what you want