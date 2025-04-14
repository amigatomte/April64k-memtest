.filenamespace mainC000
*=$C000 // To be changed to $C000
START:
        lda.zp $10
        sta RETURN_ADDRESS_LO
        lda.zp $11
        sta RETURN_ADDRESS_HI
        
        sei
        lda #$0e
        sta $D020         // $D020 = border color
        lda #$7f    //Disable CIA IRQ"s
        sta $dc0d
        sta $dd0d

        lda #$35    //Bank out kernal and basic
        sta $01     

        ldy #$17        //Restore default VIC memory pointers, lowercase
        sty $D018

//        // Clear status
//        lda #$00
//        sta ZP_STATUS
//        sta ZP_FAILBITS
//        jsr StartCopyScreen

//        jmp copyscreennoram
//copyscreennoram_return
.label param1Val = $D0  // Zero page address for parameter 1
.label param2Val = $D1  // Zero page address for parameter 2




// Below doesn't fit. Needs to be in separate payload. Or does fit without screencopy?
// Should be run from cartridge and define vars in $C000 area before copying
// this payload.
////--------------------------------------
//// Test $0002-$01FF
//        jmp Do17nMarchBTest
//Do17nMarchBTest_RETURN:
//        lda testZPS_FAILBITS
//        sta.zp bitByte
//        sta bitpattern
//        lda #$b7
//        sta.zp colorPtr            // colour memory location low
//        lda #$d8
//        sta.zp colorPtr+1          // colour memory location high
//        jsr setColorsForBits
//        lda testZPS_STATUS
//        beq ZPS_AllPassed
//        lda testZPS_FAILLO
//        sta.zp addrLo
//        lda testZPS_FAILHI
//        sta.zp addrHi
//        lda #$34
//        sta.zp scrLo
//        lda #$07
//        sta.zp scrHi
//        jsr DisplayAddressHex
//ZPS_AllPassed:
////--------------------------------------

//--------------------------------------
// Test $0200-$03ff
        marchb($02,$00,$03,$ff)
        callProcessMarchResult($d8,$df)        
//--------------------------------------

//--------------------------------------
// Test $0400-$07ff (Screen memory)
        jsr screenbackup_c000.BackupScreen        // Backup screen data
marchb($04,$00,$07,$ff)
        jsr screenbackup_c000.RestoreScreen       // Restore screen data
        callProcessMarchResult($d9,$07)
//--------------------------------------

//--------------------------------------
// Test $0800-$09ff
        marchb($08,$00,$09,$FF)
        callProcessMarchResult($d9,$2f)
//--------------------------------------
//--------------------------------------
// Test $1000-$7fff
        marchb($10,$00,$7f,$FF)
        callProcessMarchResult($D9,$57)
//--------------------------------------
//--------------------------------------
// Test $8000-$9fff
        // lda #$34    //Bank in I/O
        // sta $01     //$e000-$ffff
        marchb($80,$00,$9f,$FF)
        callProcessMarchResult($D9,$7F)
        // lda #$35    //Bank in I/O
        // sta $01     //$e000-$ffff
//--------------------------------------




//--------------------------------------
// Test $a000-$bfff
        marchb($a0,$00,$bf,$FF)
        callProcessMarchResult($D9,$A7)
//--------------------------------------

//--------------------------------------
// Test $d000-$dfff
         lda #$34    //Bank out kernal, basic and I/O
         sta $01
         marchb($d0,$00,$df,$FF)        
         lda #$35    //Bank in I/O
         sta $01     //$e000-$ffff
         callProcessMarchResult($d9,$F7)
//--------------------------------------

//--------------------------------------
// Test $e000-$efff
        marchb($e0,$00,$ef,$FF)
        callProcessMarchResult($DA,$1F)
//--------------------------------------

//--------------------------------------
// Test $f000-$ffff
        //SEI
        marchb($F0,$00,$ff,$FF)
        callProcessMarchResult($DA,$47)
//--------------------------------------

//--------------------------------------
// Test $d800-$dbff (Colour memory)
        jsr colourbackup_c000.BackupColor        // Backup colour data
        marchb($d8,$00,$db,$FF)
        jsr colourbackup_c000.RestoreColor       // Restore colour data
        processmarchresult_colour($DA,$eb)
//--------------------------------------
        lda rasterirq_c000.bitpattern           // Perhaps rasterirq_c000 is not needed, as we don't use rasterbars until the end of the test, where we are back in the ROM again.
                                                // If we remove rasterirq_c000, we need to create another storage for the accumulated bitpattern and modify the above code to use that storage instead.
        sta.zp $30                              // Transfer bitpattern to $30 for rasterbars. This location is the one used by the rasterbars code in the ROM. ("rasterirq_main.asm")
        lda #$37                                //Bank in Cartridge ROM (+ kernal and basic)
        sta $01     
        jmp (RETURN_ADDRESS_LO)
//         jsr rasterirq_c000.createrasterirq
// temploop:
//         jmp temploop

//        //backup screen
//        marchb 04 00 07 FF
//        //restore screen
//        marchb 08 00 09 FF
//        marchb A0 00 BF FF
//        marchb D0 00 DF FF
//        marchb E0 00 EF FF
//        marchb F0 00 FF FF


#import "rasterirq.asm"
#import "MarchB.asm"
#import "setColorsForBits.asm"
#import "setColorsForBits_ColourMem.asm"
#import "printaddress.asm"
#import "screenbackup.asm"
#import "colourbackup.asm"
#import "printfailpass_c000.asm"
#import "printstring_c000.asm"
RETURN_ADDRESS_LO: .byte 0
RETURN_ADDRESS_HI: .byte 0
//#import "copyscreen4.asm"
// Below doesn't fit. Needs to be in separate payload. Or does fit without screencopy?
//#import "testZPStack.asm"
//Incasm "Stage/includes/copyscreennoram.asm" // To be removed (run earlier from ROM)

.macro marchb(param1, param2, param3, param4) {
        lda #param2
        sta.zp MarchB_c000.ZP_STARTLO
        lda #param1
        sta.zp MarchB_c000.ZP_STARTHI

        lda #param4
        sta.zp MarchB_c000.ZP_ENDLO
        lda #param3
        sta.zp MarchB_c000.ZP_ENDHI
        // Run the March B test
        jsr MarchB_c000.MarchBTest
}
/*
.macro processmarchresult(param1, param2) { 
        lda ZP_FAILBITS         // Print bit test status
        sta.zp bitByte             // For the .text
        ora bitpattern
        sta bitpattern          // For the rasterbars
        lda #$00
        sta ZP_FAILBITS
        lda #param2
        sta.zp colorPtr            // colour memory location low
        lda #param1
        sta.zp colorPtr+1          // colour memory location high
        jsr setColorsForBits
          //  jsr createrasterirq
        // Check result
        lda ZP_STATUS
        beq AllPassed
        lda ZP_FAILLO
        sta.zp addrLo
        lda ZP_FAILHI
        sta.zp addrHi
        lda #$34
        sta.zp scrLo
        lda #$07
        sta.zp scrHi
        jsr DisplayAddressHex
AllPassed:
}
*/
.macro processmarchresult_colour(param1, param2) {
        lda MarchB_c000.ZP_FAILBITS         // Print bit test status
        sta.zp setColorsForBits_colour.Colour_bitByte             // For the .text
        sta.zp printfailpass_c000.STATUS  
	
        ora rasterirq_c000.bitpattern
        sta rasterirq_c000.bitpattern          // For the rasterbars
        lda #33
	sta.zp printfailpass_c000.XPOS
	lda #floor(((param1*$100+param2)-$d800)/40)		// Compute Y position from colour memory location
								/*	int offset = memoryLocation - 0xD800;
									int x = offset % 40;
									int y = offset / 40;  // Integer division */
	sta.zp printfailpass_c000.YPOS
	jsr printfailpass_c000.CheckAndPrint
        lda #$00
        sta MarchB_c000.ZP_FAILBITS
        lda #param2
        sta.zp setColorsForBits_colour.Colour_colorPtr            // colour memory location low
        lda #param1
        sta.zp setColorsForBits_colour.Colour_colorPtr+1          // colour memory location high
        jsr setColorsForBits_colour.Colour_setColorsForBits


          //  jsr createrasterirq
        // Check result
        jsr colour_entry

//        lda ZP_STATUS
//        beq AllPassed
//        lda ZP_FAILLO
//        sta.zp addrLo
//        lda ZP_FAILHI
//        sta.zp addrHi
//        lda #$34
//        sta.zp scrLo
//        lda #$07
//        sta.zp scrHi
//        jsr DisplayAddressHex
AllPassed:
}



.macro callProcessMarchResult(param1, param2){
        lda #param1
        sta param1Val
        lda #param2
        sta param2Val
        lda #floor(((param1*$100+param2)-$d800)/40)		// Compute Y position from colour memory location
							        /*      int offset = memoryLocation - 0xD800;
									int x = offset % 40;
									int y = offset / 40;  // Integer division */
	sta.zp printfailpass_c000.YPOS
        jsr sub_processmarchresult
}

colourlogo:
// Set colours of the April64k logo
        lda rasterirq_c000.bitpattern
        sta.zp setColorsForBits_c000.bitByte
        lda #$0a
        sta.zp setColorsForBits_c000.colorPtr
        lda #$d8
        sta.zp setColorsForBits_c000.colorPtr+1
        jsr setColorsForBits_c000.setColorsForBits
//--------------------------------------
        rts

sub_processmarchresult:
        lda MarchB_c000.ZP_FAILBITS         // Print bit test status
        sta.zp setColorsForBits_c000.bitByte             // For the .text
        sta.zp printfailpass_c000.STATUS  
	
        ora rasterirq_c000.bitpattern
        sta rasterirq_c000.bitpattern          // For the rasterbars

        lda #33
	sta printfailpass_c000.XPOS
	jsr printfailpass_c000.CheckAndPrint

        lda #$00
        sta MarchB_c000.ZP_FAILBITS
        lda param2Val
        sta.zp setColorsForBits_c000.colorPtr            // colour memory location low
        lda param1Val
        sta.zp setColorsForBits_c000.colorPtr+1          // colour memory location high
        jsr setColorsForBits_c000.setColorsForBits

          //  jsr createrasterirq
        // Check result
colour_entry:
        jsr colourlogo
        lda MarchB_c000.ZP_STATUS
        beq AllPassed
        lda MarchB_c000.ZP_FAILLO
        sta.zp printaddress_c000.addrLo
        lda MarchB_c000.ZP_FAILHI
        sta.zp printaddress_c000.addrHi
        lda #$5c
        sta.zp printaddress_c000.scrLo
        lda #$07
        sta.zp printaddress_c000.scrHi
        jsr printaddress_c000.DisplayAddressHex
        lda #$00
        sta MarchB_c000.ZP_STATUS
AllPassed:
        rts