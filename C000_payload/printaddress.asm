.filenamespace printaddress_c000
// Zero-page pointers:
//   $FA/$FB = address to display (low/high)
//   $FC/$FD = screen pointer (low/high)

//        *=$C000          // or wherever you like 

// Simple labels for ZP variables (optional clarity):
.label addrLo    = $FA
.label addrHi    = $FB
.label scrLo     = $FC
.label scrHi     = $FD


//---------------------------------------
// Test code
//        lda #$CE
//        sta addrHi
//        lda #$75
//        sta addrLo
//        lda #$34
//        sta scrLo
//        lda #$07
//        sta scrHi
//        jsr DisplayAddressHex
//        rts
//---------------------------------------



//---------------------------------------
// DisplayAddressHex
//---------------------------------------
DisplayAddressHex:

        ldy #$00               // Y = 0, will use (scrLo),Y for storing

        // 1) Write the "$" sign
        lda #$24               // Screen code for "$"
        sta (scrLo),Y
        iny

        // 2) Write high-.byte nibbles of address
        lda addrHi
        lsr
        lsr
        lsr
        lsr   // top nibble
        jsr ConvertNibbleToScreen
        sta (scrLo),Y
        iny

        lda addrHi
        and #$0F                      // bottom nibble
        jsr ConvertNibbleToScreen
        sta (scrLo),Y
        iny

        // 3) Write low-.byte nibbles of address
        lda addrLo
        lsr
        lsr
        lsr
        lsr // top nibble
        jsr ConvertNibbleToScreen
        sta (scrLo),Y
        iny

        lda addrLo
        and #$0F                      // bottom nibble
        jsr ConvertNibbleToScreen
        sta (scrLo),Y

        rts                           // done

//---------------------------------------
// ConvertNibbleToScreen
// IN  : A = 0..15
// OUT : A = screen code for "0".."9" or "a".."f"
// Destroys flags only
//---------------------------------------
ConvertNibbleToScreen:
        cmp #10
        bcc GotDigit       // if <10, it"s "0".."9"
        sbc #9            // nibble - 9 => 1..6
                          // => 1..6 => "a".."f"
        rts

GotDigit:
        clc
        adc #48           // => 48..57 => "0".."9"
        rts







