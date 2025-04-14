.filenamespace wait10sec_main

// 10‑second delay subroutine for the C64 (approximately 10 seconds at 1 MHz)
//
// This routine uses three nested loops:
//   - The outer loop (in X) runs 100 times.
//   - The middle loop (in Y) runs 100 times.
//   - The inner loop (using a zero‐page counter at DELAY_COUNT)
//     runs 124 times.
//
// (Total cycle count is roughly 10,010,300 cycles.)
//
// Usage:
//     JSR wait10sec   // delays about 10 seconds, then returns with RTS

// Reserve a zero‑page .byte for the inner loop counter.
.label w10_DELAY_COUNT = $FB
w10_wait10sec:
        ldx #$64         // Outer loop counter = 100
w10_outer_loop:
        ldy #$64         // Middle loop counter = 100
w10_middle_loop:
        lda #$7C         // Inner loop counter = 124 (0x7C)
        sta w10_DELAY_COUNT  // (This zero‐page variable is used by the inner loop)
w10_inner_loop:
        dec w10_DELAY_COUNT  // 5 cycles
        bne w10_inner_loop   // (Branch taken: 3 cycles// not taken: 2 cycles)
        dey              // 2 cycles
        bne w10_middle_loop  // (3 cycles if branch taken, 2 if not)
        dex              // 2 cycles
        bne w10_outer_loop   // (3 cycles if branch taken, 2 if not)
        rts              // Return