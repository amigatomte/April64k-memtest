.filenamespace screenbackup_c000
// ----- Zero-page pointers -----
.label BackupScreen_srcLo     = $fb
.label BackupScreen_srcHi     = $fc
.label BackupScreen_dstLo     = $fd
.label BackupScreen_dstHi     = $fe

// ----- Constants -----
.label SCREEN_START   = $0400
//SCREEN_BACKUP  = $C400     // We"ll store the backup here.

//            * = $C000      // Suppose code is placed at $C000

// ---------------------------------------------------------------
// BackupScreen
// Copies 1 KB from $0400–$07FF to $C400–$C7FF
// ---------------------------------------------------------------
BackupScreen:
        // Set up source pointer to $0400
        lda #<SCREEN_START
        sta BackupScreen_srcLo
        lda #>SCREEN_START
        sta BackupScreen_srcHi

        // Set up destination pointer to SCREEN_BACKUP
        lda #<SCREEN_BACKUP
        sta BackupScreen_dstLo
        lda #>SCREEN_BACKUP
        sta BackupScreen_dstHi

        // We have 4 pages of 256 .bytes = 1024 .bytes total
        ldx #$04          
        ldy #$00

backupLoop:
        // Copy one page (256 .bytes)
        lda (BackupScreen_srcLo),Y
        sta (BackupScreen_dstLo),Y
        iny
        bne backupLoop      // if Y != 0, keep looping this page

        // Done one page, move to the next
        inc BackupScreen_srcHi
        inc BackupScreen_dstHi
        dex
        bne backupLoop

        rts                 // return when all 4 pages copied


// ---------------------------------------------------------------
// RestoreScreen
// Copies the 1 KB from $C400–$C7FF back to $0400–$07FF
// ---------------------------------------------------------------
RestoreScreen:
        // Set up source pointer to $C400 (where we backed it up)
        lda #<SCREEN_BACKUP
        sta BackupScreen_srcLo
        lda #>SCREEN_BACKUP
        sta BackupScreen_srcHi

        // Set up destination pointer to $0400
        lda #<SCREEN_START
        sta BackupScreen_dstLo
        lda #>SCREEN_START
        sta BackupScreen_dstHi

        // Again, 4 pages of 256 .bytes
        ldx #$04
        ldy #$00

restoreLoop:
        // Copy one page (256 .bytes)
        lda (BackupScreen_srcLo),Y
        sta (BackupScreen_dstLo),Y
        iny
        bne restoreLoop     // if Y != 0, keep copying within this page

        // Done one page, move to next
        inc BackupScreen_srcHi
        inc BackupScreen_dstHi
        dex
        bne restoreLoop

        rts                 // finished restoring

// CB_COLOR_BACKUP:  //We store these at the same location as they are not backed up simultaneously.
.label SCREEN_BACKUP = $D000 - 1024
.label CB_COLOR_BACKUP = SCREEN_BACKUP
// .label COUNTER_BACKUP = $D000 - 1024 - 4             // (SCREEN_BACKUP -4) 4 bytes for backup of the counter. This is defined in counter_main.asm



// SCREEN_BACKUP:
 //               .fill 1024, 0
// END_SCREEN_BACKUP:



