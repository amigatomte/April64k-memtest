.filenamespace colourbackup_c000
// ======================================================
// Zero-page pointers
// ------------------------------------------------------
.label Colour_srcLo     = $fb
.label Colour_srcHi     = $fc
.label Colour_dstLo     = $fd
.label Colour_dstHi     = $fe

// ======================================================
// Constants
// ------------------------------------------------------
.label CB_COLOR_START   = $D800     // Start of color RAM
//CB_COLOR_BACKUP  = $C800     // 1 KB buffer in normal RAM

// ======================================================
// Code starts (example at $C000)
// ------------------------------------------------------
//            * = $C000

// ------------------------------------------------------
// BackupColor
// Copies color memory ($D800-$DBFF) to a backup buffer
// at COLOR_BACKUP ($C800-$CBFF).
// ------------------------------------------------------
BackupColor:
        // Setup source pointer -> $D800
        lda #<CB_COLOR_START
        sta Colour_srcLo
        lda #>CB_COLOR_START
        sta Colour_srcHi

        // Setup destination pointer -> $C800
        lda #<screenbackup_c000.CB_COLOR_BACKUP
        sta Colour_dstLo
        lda #>screenbackup_c000.CB_COLOR_BACKUP
        sta Colour_dstHi

        // 4 pages of 256 .bytes = 1024 total
        ldx #$04
        ldy #$00

backupColorLoop:
        // Copy one page (256 .bytes)
        lda (Colour_srcLo),Y
        sta (Colour_dstLo),Y
        iny
        bne backupColorLoop     // continue until Y wraps to 0

        // Next 256-.byte page
        inc Colour_srcHi
        inc Colour_dstHi
        dex
        bne backupColorLoop

        rts

// ------------------------------------------------------
// RestoreColor
// Copies the 1 KB from COLOR_BACKUP ($C800-$CBFF) back
// to color RAM ($D800-$DBFF).
// ------------------------------------------------------
RestoreColor:
        // Setup source pointer -> $C800 (backup)
        lda #<screenbackup_c000.CB_COLOR_BACKUP
        sta Colour_srcLo
        lda #>screenbackup_c000.CB_COLOR_BACKUP
        sta Colour_srcHi

        // Setup destination pointer -> $D800 (color RAM)
        lda #<CB_COLOR_START
        sta Colour_dstLo
        lda #>CB_COLOR_START
        sta Colour_dstHi

        // 4 pages of 256 .bytes
        ldx #$04
        ldy #$00

restoreColorLoop:
        // Copy one page (256 .bytes)
        lda (Colour_srcLo),Y
        sta (Colour_dstLo),Y
        iny
        bne restoreColorLoop

        // Next 256-.byte page
        inc Colour_srcHi
        inc Colour_dstHi
        dex
        bne restoreColorLoop

        rts






