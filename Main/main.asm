*=$8000
#import "cartstartup.asm"
//--------------------------------------
.import source "../odir/mainc000.sym"
.import source "../odir/testzpstack.sym"
// .import source "../odir/rasterirq_main.sym"
// .import source "../odir/final_end.sym"
// .import source "../odir/final_start.sym"
//--------------------------------------
TESTSTART:
	sei
	lda #$7f    //Disable CIA IRQ"s
	sta $dc0d
	sta $dd0d
  // Example of installing a safe IRQ handler:
    lda #<SafeIRQHandler
    sta $0314
    lda #>SafeIRQHandler
    sta $0315

	// lda #$35    //Bank out kernal and basic
	// sta $01     

	ldy #$17        //Restore default VIC memory pointers, lowercase
	sty $D018


	jmp copyscreennoram.copyscreennoram
copyscreennoram_return:

//--------------------------------------
// Test $0002-$00ff
// Silently pre-test zeropage.
// No JSR and we need a special routine, because we have no reliable RAM or stack yet.
// This is only done once.
//--------------------------------------
	jmp testzeropage.marchBTest
testzeropage_Fail:
// Zeropage is faulty. Do a address printout, activate rasterbars, and halt.
	ldy #$00
	jmp rasterbars_main.STARTRASTER_zero
testzeropage_Return:

//--------------------------------------
// Test $0100-$01ff
// Silently pre-test stack.
// No JSR and we need a special routine, because we have no reliable RAM or stack yet.
// This is only done once.
//--------------------------------------
	jmp teststack.marchBTest
teststack_Fail:
// Stack is faulty. Do a address printout, activate rasterbars, and halt.
	ldy #$01
	jmp rasterbars_main.STARTRASTER_stack
teststack_Return:
	lda #$00						// Set the memory test loop counter to 0
	sta.zp counter_main.counter1
	sta.zp counter_main.counter2
	sta.zp counter_main.counter3
	sta.zp counter_main.counter4
	sta.zp rasterirq_main.bitpattern	// Clear the raster IRQ bitpattern.

rerun_test:
	jsr counter_main.INC4BYTE 		// Increment the memory test loop counter by 1.
	jsr counter_main.PRINT_COUNTER		// Print the counter to the screen.
//--------------------------------------
// Test $c000-$cfff
// If successful, this is where we copy the two code payloads
// that test the ZP+Stack and the rest of the memory, respectively.
//--------------------------------------
	//jsr Test_C000
	Test_c000($C0,$00,$CF,$FF)
	// lda #$BE               //failure test, TO BE REMOVED
	// sta ZP_FAILBITS
	// sta ZP_STATUS
	processmarchresult($d9,$cf)
	// jsr colourlogo

//--------------------------------------
// Copy the first testzpstack payload that will do testing of ZeroPage and stack ($0002 - $01FF)
//--------------------------------------
	copycodetoram_macro(testzpstack_Code, $C0, $00, testzpstack_Code_Size)
	
	jsr counter_main.UnrolledBackup		// We will overwrite zeropage, so make a backup of the counter and the failure bitpattern.
	lda #<Do17nMarchBTest_RETURN
	sta.zp $10
	lda #>Do17nMarchBTest_RETURN
	sta.zp $11
	TestZpStack($00,$02,$01,$ff)
	// *=$2000

Do17nMarchBTest_RETURN:
	jsr counter_main.UnrolledRestore 	// Restore the counter from backup.
	// sei
	// lda #$7f    //Disable CIA IRQ"s
	// sta $dc0d
	// sta $dd0d

	// lda #$35    //Bank out kernal and basic
	// sta $01     

	// ldy #$17        //Restore default VIC memory pointers, lowercase
	// sty $D018

	processmarchresult_zps($d8,$b7) // Print result. If fail, activate rasterbars, and halt.
	// lda testzpstack.testZPS_FAILBITS       // Print bit test status
	// pha                  	   // Push bit pattern to stack
	// sta.zp bitByte             // For the .text
	// lda #$b7
	// sta.zp colorPtr            // colour memory location low
	// lda #$d8
	// sta.zp colorPtr+1          // colour memory location high
	// jsr setColorsForBits



//--------------------------------------
// Copy the C000 payload that will do further testing of the rest of the memory.
//--------------------------------------
	copycodetoram_macro(c000_Code, $C0, $00, c000_Code_Size)
	//jmp $C000
	.break
	sei
	lda #<c000_end_RETURN
	sta.zp $10
	lda #>c000_end_RETURN
	sta.zp $11
	jmp mainC000.START
c000_end_RETURN:
	// nop
	//jmp TESTSTART
	// 	jsr copyscreennoram.copyscreennoram_jsr_end	// Redraw the initial screen.
	// jmp rerun_test


/*
//--------------------------------------
// Final test #1 $0002-$f7ff(?)
	// copycodetoram_macro(final_end_Code, $f8, $00, final_end_Code_Size)
	copycodetoram_macro(trampoline_to_test_end_code, $10, $00, trampoline_to_test_end_code_Size)
	jsr counter_main.UnrolledBackup_Final		// We will overwrite zeropage, so make a backup of the counter.
	// jsr restorechars_end.backup_chars			// Backup the characters (fail address) at $075C-$0760

//	jsr screenbackup_end.BackupScreen	// TODO: We don't need to backup the screen here. The only thing that might differ is the "Result" column and the "fail address". 
										// The "Result" can be derived from colour memory, and the "fail address" can be stored in two bytes. Or five 
										// bytes to store the screen codes. Then we can just copy them back.
	lda #<final_end_RETURN
	sta.zp $10
	lda #>final_end_RETURN
	sta.zp $11
	// TestFinalEnd($00,$02,$f7,$ff)
	// .break
	jmp $1000
	// jmp trampoline_to_test_end.start
	// jmp final_end.START // The start and end addresses are hard coded in the final_end.asm file.
final_end_RETURN:
	.break
	// jmp rerun_test
	jsr counter_main.UnrolledRestore_Final 		// Restore the counter from backup.
	// jmp TESTSTART
//	jsr screenbackup_end.RestoreScreen
	jsr restorechars_end.backup_chars			// Backup the characters (fail address) at $075C-$0760
	jsr copyscreennoram.copyscreennoram_jsr		// Just redraw the initial chars, no colour. 
	jsr redrawscreen.DoRedrawScreen 			// Reprint the start/fail-messages based on the colour information that is still present in colourmem.
	jsr restorechars_main.restore_chars			// Reprint the backed-up characters (fail address) from the backup buffer back to screen memory.
		.break
	processmarchresult_fte($da,$6f)
	jsr counter_main.PRINT_COUNTER				// Print the counter to the screen.
//--------------------------------------
*/



//--------------------------------------
// Final test (former #2) $0800(?)-$ffff
	.break
	copycodetoram_macro(final_start_Code, $02, $00, final_start_Code_Size)
	.break
	jsr restorechars_start.backup_chars			// Backup the characters (fail address) at $075C-$0760
	//jsr screenbackup_start.BackupScreen	// TODO: We don't need to backup the screen here. The only thing that might differ is the "Result" column and the "fail address". 
										// The "Result" can be derived from colour memory, and the "fail address" can be stored in two bytes. Or five 
										// bytes to store the screen codes. Then we can just copy them back.
	// TestFinalStart($08,$00,$ff,$ff)
	TestFinalStart($04,$00,$ff,$ff)
	//jsr screenbackup_start.RestoreScreen
	jsr copyscreennoram.copyscreennoram_jsr		// Just redraw the initial chars, no colour. 
	jsr redrawscreen.DoRedrawScreen 			// Reprint the start/fail-messages based on the colour information that is still present in colourmem.
	jsr restorechars_start.restore_chars		// Reprint the backed-up characters (fail address) from the backup buffer back to screen memory.
	processmarchresult_fts($da,$97)
	jsr counter_main.PRINT_COUNTER				// Print the counter to the screen.
//-------------------------------------- 
	.break
	lda.zp rasterirq_main.bitpattern		  	// Get the bit pattern
	bne TESTFAIL
	// If we get here, all tests have passed.
	jsr wait10sec_main.w10_wait10sec
	jsr copyscreennoram.copyscreennoram_jsr_end	// Redraw the initial screen.
	jmp rerun_test

TESTFAIL:
	jsr colourlogo
	copycodetoram_macro(rasterirq_Code, $C0, $00, rasterirq_Code_Size)
	jsr rasterirq_main.createrasterirq  		// If the bit pattern is not zero, start the rasterbars.
infinite:
	jmp infinite

#import "copyscreennoram.asm"
#import "teststack.asm"
#import "testzeropage.asm"
//Incasm "Printstatus.asm"
#import "rasterbars.asm"
//Incasm "Stage/marchbrom.asm"
#import "MarchB_cart.asm"
#import "printstatusnoram.asm"

//Incasm "printbits.asm"
//Incasm "printhex.asm"
#import "setColorsForBits.asm"
#import "printaddress.asm"
#import "copycodetoram.asm"
#import "printstring_main.asm"
#import "printfailpass.asm"
#import "redrawscreen.asm"
#import "counter_main.asm"
// #import "rasterirq_main.asm"
#import "restorechars_start.asm"
//Incasm "Stage/includes/initscreen.asm"
// #import "restorechars_main.asm"
#import "wait10sec.asm"

.macro TestZpStack(starthi,startlo,endhi,endlo){
	lda #startlo
	sta testzpstack.ZP_STARTLO
	lda #starthi
	sta testzpstack.ZP_STARTHI

	lda #endlo
	sta testzpstack.ZP_ENDLO
	lda #endhi
	sta testzpstack.ZP_ENDHI

	// Run the March B test
	jmp testzpstack.START
}
// .macro TestFinalEnd(starthi,startlo,endhi,endlo){
// 	lda #startlo
// 	sta final_end.testZPS_STARTLO
// 	lda #starthi
// 	sta final_end.testZPS_STARTHI

// 	lda #endlo
// 	sta final_end.testZPS_ENDLO
// 	lda #endhi
// 	sta final_end.testZPS_ENDHI

// 	// Run the March B test
// 	jmp final_end.START
// }


.macro Test_c000(starthi,startlo,endhi,endlo){
	lda #startlo
	sta.zp MarchB_main.ZP_STARTLO
	lda #starthi
	sta.zp MarchB_main.ZP_STARTHI

	lda #endlo
	sta.zp MarchB_main.ZP_ENDLO
	lda #endhi
	sta.zp MarchB_main.ZP_ENDHI

	// Run the March B test
	jsr MarchB_main.MarchBTest
}

.macro TestFinalStart(starthi,startlo,endhi,endlo){
	lda #startlo
	sta.zp final_start.ZP_STARTLO
	lda #starthi
	sta.zp final_start.ZP_STARTHI

	lda #endlo
	sta.zp final_start.ZP_ENDLO
	lda #endhi
	sta.zp final_start.ZP_ENDHI

	// Run the March B test
	jsr final_start.MarchBTest
}

// Test_C000:
// 	lda #$00
// 	sta MarchB_main.ZP_STARTLO
// 	lda #$C0
// 	sta MarchB_main.ZP_STARTHI

// 	lda #$FF
// 	sta MarchB_main.ZP_ENDLO
// 	lda #$CF
// 	sta MarchB_main.ZP_ENDHI

// 	// Clear status
// 	lda #$00
// 	sta MarchB_main.ZP_STATUS
// 	sta MarchB_main.ZP_FAILBITS

// 	// Run the March B test
// 	//JSR MarchBTestROM
// 	jsr MarchB_main.MarchBTest
// 	rts

.macro processmarchresult(param1, param2) { 
	lda.zp MarchB_main.ZP_FAILBITS         // Print bit test status
//	pha                     						// Push bit pattern to stack
	sta.zp printfailpass_main.STATUS  
	sta.zp setColorsForBits_main.bitByte            // For the text
	ora.zp rasterirq_main.bitpattern
	sta.zp rasterirq_main.bitpattern
	jsr colourlogo
//	lda #mod(((param1*$100+param2)-$d800),40)			// Compute X and Y position from colour memory location
	lda #33
	sta.zp printfailpass_main.XPOS
	lda #floor(((param1*$100+param2)-$d800)/40)		// Compute Y position from colour memory location
													/*	int offset = memoryLocation - 0xD800;
														int x = offset % 40;
														int y = offset / 40;  // Integer division */
	sta.zp printfailpass_main.YPOS
	jsr printfailpass_main.CheckAndPrint
	lda #param2
	sta.zp setColorsForBits_main.colorPtr            // colour memory location low
	lda #param1
	sta.zp setColorsForBits_main.colorPtr+1          // colour memory location high
	jsr setColorsForBits_main.setColorsForBits
	// Check result
	lda.zp MarchB_main.ZP_STATUS
	beq AllPassed
	lda.zp MarchB_main.ZP_FAILLO
	sta.zp printaddress_main.addrLo
	lda.zp MarchB_main.ZP_FAILHI
	sta.zp printaddress_main.addrHi
	lda #$5c
	sta.zp printaddress_main.scrLo
	lda #$07
	sta.zp printaddress_main.scrHi
	jsr printaddress_main.DisplayAddressHex
//	pla // Pull bit pattern from stack (for the rasterbars)
//	sta.zp rasterirq_main.bitpattern
	jmp TESTFAIL
		// jmp rasterbars_main.STARTRASTER_C000
AllPassed:
//	pla // Remove bit pattern from stack
}
.macro processmarchresult_fts(param1, param2) { 
	lda final_start.ZP_FAILBITS         // Print bit test status
//	pha                     // Push bit pattern to stack
	sta.zp printfailpass_main.STATUS  
	sta.zp setColorsForBits_main.bitByte             // For the text
	ora.zp rasterirq_main.bitpattern
	sta.zp rasterirq_main.bitpattern
	lda #33
	sta.zp printfailpass_main.XPOS
	lda #floor(((param1*$100+param2)-$d800)/40)		// Compute Y position from colour memory location
													/*	int offset = memoryLocation - 0xD800;
														int x = offset % 40;
														int y = offset / 40;  // Integer division */
	sta.zp printfailpass_main.YPOS
	jsr printfailpass_main.CheckAndPrint
	lda #param2
	sta.zp setColorsForBits_main.colorPtr            // colour memory location low
	lda #param1
	sta.zp setColorsForBits_main.colorPtr+1          // colour memory location high
	jsr setColorsForBits_main.setColorsForBits
	// Check result
	lda final_start.ZP_STATUS
	beq AllPassed
	lda final_start.ZP_FAILLO
	sta.zp printaddress_main.addrLo
	lda final_start.ZP_FAILHI
	sta.zp printaddress_main.addrHi
	lda #$5c
	sta.zp printaddress_main.scrLo
	lda #$07
	sta.zp printaddress_main.scrHi
	jsr printaddress_main.DisplayAddressHex
//	pla // Pull bit pattern from stack (for the rasterbars)
//	jmp rasterbars_main.STARTRASTER_C000
	jmp TESTFAIL
AllPassed:
//	pla // Remove bit pattern from stack
}
.macro processmarchresult_zps(param1, param2) { 
	lda testzpstack.testZPS_FAILBITS       // Print bit test status
	
	pha                  	   // Push bit pattern to stack
	sta.zp setColorsForBits_main.bitByte             // For the .text
	sta.zp printfailpass_main.STATUS  
	ora.zp rasterirq_main.bitpattern
	sta.zp rasterirq_main.bitpattern
	lda #33
	sta.zp printfailpass_main.XPOS
	lda #floor(((param1*$100+param2)-$d800)/40)		// Compute Y position from colour memory location
													/*	int offset = memoryLocation - 0xD800;
														int x = offset % 40;
														int y = offset / 40;  // Integer division */
	sta.zp printfailpass_main.YPOS
	jsr printfailpass_main.CheckAndPrint
	lda #param2
	sta.zp setColorsForBits_main.colorPtr            // colour memory location low
	lda #param1
	sta.zp setColorsForBits_main.colorPtr+1          // colour memory location high
	jsr setColorsForBits_main.setColorsForBits
	// Check result
	lda testzpstack.testZPS_STATUS         
	beq AllPassed
	lda testzpstack.testZPS_FAILLO
	sta.zp printaddress_main.addrLo
	lda testzpstack.testZPS_FAILHI
	sta.zp printaddress_main.addrHi
	lda #$5c
	sta.zp printaddress_main.scrLo
	lda #$07
	sta.zp printaddress_main.scrHi
	jsr printaddress_main.DisplayAddressHex
	pla // Pull bit pattern from stack (for the rasterbars)
	jsr colourlogo
	jmp rasterbars_main.STARTRASTER_C000
AllPassed:
	pla // Remove bit pattern from stack
	// ora.zp rasterirq_main.bitpattern
	// sta.zp rasterirq_main.bitpattern
	jsr colourlogo
}
/*
.macro processmarchresult_fte(param1, param2) { 
	lda final_end.testZPS_FAILBITS       // Print bit test status
//	pha                  	   // Push bit pattern to stack
	sta.zp setColorsForBits_main.bitByte             // For the .text
	sta.zp printfailpass_main.STATUS  
	ora.zp rasterirq_main.bitpattern
	sta.zp rasterirq_main.bitpattern
	lda #33
	sta.zp printfailpass_main.XPOS
	lda #floor(((param1*$100+param2)-$d800)/40)		// Compute Y position from colour memory location
														// int offset = memoryLocation - 0xD800;
														// int x = offset % 40;
														// int y = offset / 40;  // Integer division
	sta.zp printfailpass_main.YPOS
	jsr printfailpass_main.CheckAndPrint
	lda #param2
	sta.zp setColorsForBits_main.colorPtr            // colour memory location low
	lda #param1
	sta.zp setColorsForBits_main.colorPtr+1          // colour memory location high
	jsr setColorsForBits_main.setColorsForBits
	// Check result
	lda final_end.testZPS_STATUS         
	beq AllPassed
	lda final_end.testZPS_FAILLO
	sta.zp printaddress_main.addrLo
	lda final_end.testZPS_FAILHI
	sta.zp printaddress_main.addrHi
	lda #$5c
	sta.zp printaddress_main.scrLo
	lda #$07
	sta.zp printaddress_main.scrHi
	jsr printaddress_main.DisplayAddressHex
	jmp TESTFAIL
//	pla // Pull bit pattern from stack (for the rasterbars)
//	jmp rasterbars_main.STARTRASTER_C000 // TODO: Upon failure, we should not hang here. We should jump to the next test. How do we preserve failed bits? - Store somewhere in zeropage! ..or colour mem(!)
AllPassed:
//	pla // Remove bit pattern from stack
}*/
.macro copycodetoram_macro(src_ptr, dst_ptr_hi, dst_ptr_lo, copy_count) {
	// Initialize source pointer with the address of 'source'
	lda #<src_ptr
	sta .zp copycodetoram.src_ptr
	lda #>src_ptr
	sta.zp  copycodetoram.src_ptr+1

	// Initialize destination pointer with dst_ptr_hi, dst_ptr_lo
	lda #dst_ptr_lo
	sta.zp copycodetoram.dst_ptr
	lda #dst_ptr_hi
	sta.zp copycodetoram.dst_ptr+1

	// Initialize the 16-bit counter with the length of the binary.
	// COPY_LENGTH is computed as (Source_end - source)
	lda #<copy_count
	sta.zp copycodetoram.copy_count
	lda #>copy_count
	sta.zp copycodetoram.copy_count+1

	jsr copycodetoram.COPY_ROUTINE
} 

colourlogo:
// Set colours of the April64k logo
        lda.zp rasterirq_main.bitpattern
        sta.zp setColorsForBits_main.bitByte
        lda #$0a
        sta.zp setColorsForBits_main.colorPtr
        lda #$d8
        sta.zp setColorsForBits_main.colorPtr+1
        jsr setColorsForBits_main.setColorsForBits
		lda.zp rasterirq_main.bitpattern
        sta.zp setColorsForBits_main.bitByte
//--------------------------------------
        rts



testzpstack_Code: .segmentout [segments="testzpstack_Code"]
.label testzpstack_Code_Size = *-testzpstack_Code

c000_Code: .segmentout [segments="C000_Code"]
.label c000_Code_Size = *-c000_Code

// final_end_Code: .segmentout [segments="final_end_Code"]
// .label final_end_Code_Size = *-final_end_Code

final_start_Code: .segmentout [segments="final_start_Code"]
.label final_start_Code_Size = *-final_start_Code

rasterirq_Code: .segmentout [segments="rasterirq_Code"]
.label rasterirq_Code_Size = *-rasterirq_Code

// trampoline_to_test_end_code: .segmentout [segments="trampoline_to_test_end_code"]
// .label trampoline_to_test_end_code_Size = *-trampoline_to_test_end_code

.segment C000_Code [start=$c000]
//#import "../C000_payload/mainC000.asm"
.import c64 "../odir/mainc000_compressed.prg"
//.print "Namespace = "+getNamespace()

.segment testzpstack_Code [start=$c000]
//#import "../C000_payload/testzpstack.asm"
.import c64 "../odir/testzpstack_compressed.prg"

// .segment final_end_Code [start=$f800]
// // #import "../Final_test/final_end.asm"
// .import c64 "../odir/final_end_compressed.prg"

.segment final_start_Code [start=$0200]
#import "../Final_test/final_start.asm" // This got bigger when compressing the code, so compression is disabled for now.
//.import c64 "../odir/final_start_compressed.prg"

.segment rasterirq_Code [start=$c000]
// .import c64 "../odir/rasterirq_compressed.prg"
#import "rasterirq_main.asm"
// .segment trampoline_to_test_end_code [start=$1000]
// #import "trampoline_to_test_end.asm"

SafeIRQHandler:
    rti   // Immediately return from interrupt

//------------------------------------------------------------------------------------------------
// Pad the code to the end of the 8K cartridge
//------------------------------------------------------------------------------------------------
// *=$9fff                     // fill up to -$9fff (or $bfff if 16K)
//      .byte 0
//------------------------------------------------------------------------------------------------