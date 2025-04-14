	.filenamespace copycodetoram
    //-------------------------------------------------------------------------
	// Copy Routine Using a 16-Bit Counter
	//
	// This routine copies the data from "source" (defined by the .incbin)
	// to the destination at $C000.
	//
	// It uses:
	//  - Two zero-page pointers (src_ptr and dst_ptr) for source and destination.
	//  - A 16-bit counter (copy_count) computed as (Source_end - source).
	//
	// The routine uses the (indirect),Y addressing mode.
	//-------------------------------------------------------------------------
	
	// Zero-page storage for pointers and counter:
.label src_ptr =$F0     // 16-bit source pointer (little-endian)
.label dst_ptr=$F2      // 16-bit destination pointer
.label copy_count=$F4   // 16-bit counter = number of bytes to copy

	// Entry point of the copy routine
COPY_ROUTINE:
	// // Initialize source pointer with the address of 'source'
	// lda #<source
	// sta src_ptr
	// lda #>source
	// sta src_ptr+1

	// // Initialize destination pointer with $C000
	// lda #<$C000
	// sta dst_ptr
	// lda #>$C000
	// sta dst_ptr+1

	// // Initialize the 16-bit counter with the length of the binary.
	// // COPY_LENGTH is computed as (Source_end - source)
	// lda #<COPY_LENGTH
	// sta copy_count
	// lda #>COPY_LENGTH
	// sta copy_count+1

COPY_LOOP:
	// Check if our 16-bit counter has reached zero.
	lda copy_count+1    // Check high byte first
	cmp #0
	bne CONTINUE_COPY   // If high byte is nonzero, we have bytes left.
	lda copy_count      // If high byte is zero, check low byte.
	cmp #0
	beq COPY_DONE       // If both bytes are zero, we're done.
CONTINUE_COPY:
	//
	// Copy one byte from [src_ptr] to [dst_ptr]:
	//
	// The (indirect),Y addressing mode uses the 16-bit pointer at src_ptr.
	// (Since Y is always zero here, it simply dereferences the pointer.)
	ldy #0
	lda (src_ptr),Y
	ldy #0
	sta (dst_ptr),Y

	//
	// Increment the source pointer (16-bit add 1)
	//
	inc src_ptr         // Increment low byte
	bne SRC_INC_OK      // If no carry, skip incrementing high byte
	inc src_ptr+1       // Else increment high byte
SRC_INC_OK:
	//
	// Increment the destination pointer (16-bit add 1)
	//
	inc dst_ptr         // Increment low byte
	bne DST_INC_OK
	inc dst_ptr+1
DST_INC_OK:
	//
	// Decrement the 16-bit counter by 1.
	//
	lda copy_count
	sec
	sbc #1
	sta copy_count
	bcs SKIP_DEC_HIGH   // If no borrow, high byte is unchanged.
	dec copy_count+1    // Borrow occurred: decrement high byte.
SKIP_DEC_HIGH:
	jmp COPY_LOOP       // Repeat the copy loop.

COPY_DONE:
	rts                 // Return from subroutine.


	//-------------------------------------------------------------------------
	// Data Section: Binary inclusion and length definition.
	//-------------------------------------------------------------------------
// source:
// 	//.incbin "code.bin"
// Source_end:
// .label COPY_LENGTH = Source_end - source
.label source = c000_Code
.label COPY_LENGTH = c000_Code_Size
