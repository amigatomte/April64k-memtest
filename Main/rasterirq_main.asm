.filenamespace rasterirq_main
// ---------------------------------------------------------------
//  *= $2000    //Assemble to $2000

.label bitpattern       = $30
.label bitCopy          = $31    // Temporary storage for shifting

createrasterirq:
         sei         //Disable IRQ"s
         //lda #%01110100
//         sta bitpattern
         jsr fillbitpattern

         lda #$7f    //Disable CIA IRQ"s
         sta $dc0d
         sta $dd0d

         lda #$35    //Bank out kernal and basic
         sta $01     //$e000-$ffff
 
         lda #<irq1  //Install RASTER IRQ
         ldx #>irq1  //into Hardware
         sta $fffe   //Interrupt Vector
         stx $ffff
 
 
         lda #$01    //Enable RASTER IRQs
         sta $d01a
         lda #$34    //IRQ on line 52
         sta $d012
         lda #$1b    //High bit (lines 256-311)
         sta $d011
                         //NOTE double IRQ
                         //cannot be on or
                         //around a BAD LINE!
                         //(Fast Line)
 
         lda #$0e    //Set Background
         sta $d020   //and Border colors
         lda #$06
         sta $d021
         lda #$00
         sta $d015   //turn off sprites
 
//         jsr clrscreen
//         jsr clrcolor
//         jsr printtext
 
         asl $d019   //Ack any previous
         bit $dc0d   //IRQ"s
         bit $dd0d
         ldx #$00
         stx.zp irqIndex      // zero
         cli         //Allow IRQ"s
infinite:
        jmp infinite
        //  rts
        // jmp *       //Endless Loop
 
 
irq1:
         sta reseta1 //Preserve A,X and Y
         stx resetx1 //Registers
         sty resety1 //VIA self modifying
                         //code
                         //(Faster than the
                         //STACK is!)
 
         lda #<irq2  //Set IRQ Vector
         ldx #>irq2  //to point to the
                         //next part of the
         sta $fffe   //Stable IRQ
         stx $ffff   //ON NEXT LINE!
         inc $d012
         asl $d019   //Ack RASTER IRQ
         tsx         //We want the IRQ
         cli         //To return to our
         nop         //endless loop
         nop         //NOT THE END OF
         nop         //THIS IRQ!
         nop
         nop         //Execute nop"s
         nop         //until next RASTER
         nop         //IRQ Triggers
         nop
         nop         //2 cycles per
         nop         //instruction so
         nop         //we will be within
         nop         //1 cycle of RASTER
         nop         //Register change
         nop
irq2:
         txs         //Restore STACK
                         //Pointer
         ldx #$08    //Wait exactly 1
         dex         //lines worth of
         bne *-1     //cycles for compare
         bit $ea     //Minus compare
         nop         //cycles
 
         nop  //<--- remove 1 NOP for PAL
 
         lda #$35    //RASTER change yet?
         cmp $d012
         beq start   //If no waste 1 more
                         //cycle
start:
         nop         //Some delay
         nop         //So stable can be
         nop         //seen
 
        //  lda #$0e    //Colors
        //  ldx #$06
 
        //  sta $d021   //Here is the proof
        //  stx $d021
 
         lda #<irq3  //Set IRQ to point
         ldx #>irq3  //to subsequent IRQ
         ldy #188    //at line $68
         sta $fffe
         stx $ffff
         sty $d012
         asl $d019   //Ack RASTER IRQ
 
         lda #$00    //Reload A,X,and Y
.label reseta1  = *-1       //registers
         ldx #$00
.label resetx1  = *-1
         ldy #$00
.label resety1  = *-1
 
         rti         //Return from IRQ
 
irq3:
         sta reseta2 //Preserve A,X,and Y
         stx resetx2 //Registers
         sty resety2
 
//         ldx #$0a    //Waste some more
//         dex         //time so effect
//         bne *-1     //can be seen
//         nop
// 
//         lda #$02    //More colors
//         ldx #$06
// 
//         sta $d021   //Cool! subsequent
//         stx $d021   //IRQ"s are also
                         //stable :-)
                         //Unless you are
                         //running realtime
                         //code :-)
 
//         ldy #$13    //Waste time so this
//         dey         //IRQ does not try
//         bne *-1     //to reoccur on the
//                     //same line!

        ldx.zp irqIndex
        lda colTable,x
        sta $D020         // $D020 = border color

        // Move to next index
        inx
        stx.zp irqIndex
        cpx #numLines   // If we’ve reached end of table, wrap
        bne SkipReset
        ldx #0
        stx.zp irqIndex
        lda #<irq1  //Reset Vectors to
        ldx #>irq1  //first IRQ again
        ldy #$34    //at line $34
        sta $fffe
        stx $ffff
        jmp exitirq
SkipReset:
        // Read next raster line from lineTable
        ldy lineTable,x
exitirq:
        sty $D012         // This sets the *next* line for IRQ

         asl $d019   //Ack RASTER IRQ
 
         lda #$00    //Reload A,X,and Y
.label reseta2  = *-1       //registers
         ldx #$00
.label resetx2  = *-1
         ldy #$00
.label resety2  = *-1
 
         rti         //Return from IRQ
 
//---------------------------------------------------------------
//  DATA TABLES
//---------------------------------------------------------------
// We"ll do 16 entries total (two triggers per bar, for 8 bars).

.label numLines = 16          // total triggers (2 per bar * 8 bars)

.label irqIndex = $FB         // a zero-page or direct-page variable
                           // (Here we just pick $FB for demonstration.)

// Each pair: 
//   Red-line, then Light-Blue-line for each bar.
// Bars start at 188, 196, 204... (every +8 lines)
// Red = 5 lines, then switch => background for 3 lines

lineTable:
        .byte 188,193    // Bar #1
        .byte 196,201    // Bar #2
        .byte 204,209    // Bar #3
        .byte 212,217    // Bar #4
        .byte 220,225    // Bar #5
        .byte 228,233    // Bar #6
        .byte 236,241    // Bar #7
        .byte 244,249    // Bar #8

// Colors for each trigger line:
//   - Red = $02
//   - Light blue = $0A
// We alternate 02, 0A, 02, 0A, … in sync with the line table.

colTable:
rasbar1:         .byte $02,$0E    // Bar #1
rasbar2:         .byte $02,$0E    // Bar #2
rasbar3:         .byte $02,$0E    // Bar #3
rasbar4:         .byte $02,$0E    // Bar #4
rasbar5:         .byte $05,$0E    // Bar #5
rasbar6:         .byte $06,$0E    // Bar #6
rasbar7:         .byte $02,$0E    // Bar #7
rasbar8:         .byte $02,$0E    // Bar #8


        // ---------------------------------------------------------
        // Subroutine: For each bit in the .byte at "bitpattern":
        //             store #$02 at rasbar1 + 2*n if that bit is 1,
        //             else store #$05.
        //             Bit 7 => n=0, bit 6 => n=1, ..., bit 0 => n=7.
        // ---------------------------------------------------------
//        .org $xxxx               // Change/omit as needed
fillbitpattern:
        lda  bitpattern          // Get original .byte
        sta  bitCopy            // Keep a working copy so we can shift
        ldy  #$00               // Y = offset into rasbar1, increments by 2
        ldx  #$08               // We have 8 bits to process

CheckLoop:
        // Load the current (unshifted) copy from memory.
        // If the top bit (bit 7) is 1, A will appear negative => BMI.
        lda  bitCopy
        bmi  BitIsSet

        // If we get here, bit 7 is 0 => store #$05
        lda  #$05
StoreValue:
        sta  rasbar1,Y
        asl  bitCopy            // Shift bitCopy left by 1 for next bit
        iny                     // Move to the next 2-.byte slot
        iny
        dex                     // One bit processed
        bne  CheckLoop
        rts

BitIsSet:
        // If bit 7 is 1 => store #$02
        lda  #$02
        jmp  StoreValue

// ---------------------------------------------------------
// Variables (could be in zero page or elsewhere)
// ---------------------------------------------------------


//                     //Pound RESTORE to
//                     //get back to Turbo
//nmi
//         asl $d019   //Ack all IRQ"s
//         lda $dc0d
//         lda $dd0d
//         lda #$81    //reset CIA 1 IRQ
//         ldx #$00    //remove raster IRQ
//         ldy #$37    //reset MMU to roms
//         sta $dc0d
//         stx $d01a
//         sty $01
//         ldx #$ff    //clear the stack
//         txs
//         cli         //reenable IRQ"s
//         jmp $9000   //back to Turbo
// 
//clrscreen
//         lda #$20    //Clear the screen
//         ldx #$00
//clrscr   sta $0400,x
//         sta $0500,x
//         sta $0600,x
//         sta $0700,x
//         dex
//         bne clrscr
//         rts
//clrcolor
//         lda #$03    //Clear color memory
//         ldx #$00
//clrcol   sta $d800,x
//         sta $d900,x
//         sta $da00,x
//         sta $db00,x
//         dex
//         bne clrcol
//         rts
// 
//printtext
//         lda #$16    //C-set = lower case
//         sta $d018
// 
//         ldx #$00
//moretext lda .text1,x
// 
//         bpl lower   //upper case ?
//         eor #$80    //yes
// 
//         bne lower+2
// 
//lower    and #$3f    //lower case
//         sta $0450,x
//         inx
//         cpx #$78
//         bne moretext
//exit     rts
// 
//.text1
//         .text "Stable Raster IRQ sourc"
//         .text "e (PAL/NTSC)     "
//         .text "All Code by Fungus 1996"
//         .text "                 "
//         .text "Feel free to use and mo"
//         .text "dify this code :)"