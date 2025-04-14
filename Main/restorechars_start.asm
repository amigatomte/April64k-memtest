.filenamespace restorechars_start

.label start_pos=$075C
//------------------------------------------------------------
// backup_chars: Back up five characters from screen memory 
// starting at $075C into a backup buffer.
//------------------------------------------------------------
backup_chars:
    ldx #$00           // initialize index to 0
backup_loop:
    lda start_pos,x        // load character from screen memory
    sta.zp backup_location,x        // store it into backup buffer
    inx                // increment index
    cpx #5            // have we done 5 characters?
    bne backup_loop   // if not, repeat loop
    rts               // return from subroutine

//------------------------------------------------------------
// restore_chars: Restore the backed-up five characters from
// backup buffer back to screen memory at $075C,
// and set their colour in colour memory (starting at $D800)
// to white ($01).
//------------------------------------------------------------
restore_chars:
    ldx #$00           // initialize index to 0
restore_loop:
    lda.zp backup_location,x        // get backed-up character
    sta start_pos,x        // restore it into screen memory
    inx               // next character
    cpx #5           // done with all 5?
    bne restore_loop  // if not, loop again
    rts               // return from subroutine
// backup_location:
    // .byte 0,0,0,0,0
    .label backup_location = $D0          // 5 bytes for backup of the fail address.