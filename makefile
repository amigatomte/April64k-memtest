# Directories
PAYLOAD_DIR = C000_payload
FINAL_DIR   = Final_test
MAIN_DIR	= Main
BIN_DIR		= bin
ODIR		= odir

KICKASM_DIR	= C:/src/C64/KickAssembler_v5.25
RETRODEBUG_DIR = C:/src/C64/RetroDebuggerv0.64.72
VICE_DIR	= C:/src/C64/GTK3VICE-3.9-win64/bin
MSYS_DIR	= C:/msys64/usr/bin
# Variables for tools
RETRODEBUGGER = $(RETRODEBUG_DIR)/retrodebugger-notsigned.exe
KICKASM = java -jar $(KICKASM_DIR)/KickAss.jar -debugdump -vicesymbols -odir ../odir							# Replace with your Kick Assembler executable name/path
DALI	= $(BIN_DIR)/dali035.exe			# Replace with your dali executable name/path
VICE	= $(VICE_DIR)/x64sc.exe			# Replace with your VICE executable name/path
CARTCONV= $(VICE_DIR)/cartconv.exe		# Replace with your cartconv executable name/path
DD 		= $(MSYS_DIR)/dd.exe
## STRIP	= $(BIN_DIR)/stripheader.exe		# This is the C tool we provided to strip the 2-byte header

# ----------------------------------------------------------------
# Main Payload (from C000_payload)
# ----------------------------------------------------------------
# The main payload source is payload.asm, and it may include other .asm files.
PAYLOAD_MAIN = $(PAYLOAD_DIR)/mainc000.asm
PAYLOAD_PRG     = $(ODIR)/mainc000.prg
COMPRESSED_PRG  = $(ODIR)/mainc000_compressed.prg

# ----------------------------------------------------------------
# Additional Payload: testZPstack (from C000_payload)
# ----------------------------------------------------------------
TESTZP_SRC       = $(PAYLOAD_DIR)/testZPstack.asm
TESTZP_PRG       = $(ODIR)/testZPstack.prg
TESTZP_COMPRESSED = $(ODIR)/testZPstack_compressed.prg


# ----------------------------------------------------------------
# Additional Payload: final_end (from Final_test)
# ----------------------------------------------------------------
# FINAL_END_SRC       = $(FINAL_DIR)/final_end.asm
# FINAL_END_PRG       = $(ODIR)/final_end.prg
# FINAL_END_COMPRESSED = $(ODIR)/final_end_compressed.prg

# ----------------------------------------------------------------
# Additional Payload: final_start (from Final_test)
# ----------------------------------------------------------------
FINAL_START_SRC       = $(FINAL_DIR)/final_start.asm
FINAL_START_PRG       = $(ODIR)/final_start.prg
# FINAL_START_COMPRESSED = $(ODIR)/final_start_compressed.prg

# ----------------------------------------------------------------
# Additional Payload: final_start (from Final_test)
# ----------------------------------------------------------------
RASTERIRQ_SRC       = $(MAIN_DIR)/rasterirq_main.asm
RASTERIRQ_PRG       = $(ODIR)/rasterirq_main.prg
# RASTERIRQ_COMPRESSED = $(ODIR)/rasterirq_main_compressed.prg


# ----------------------------------------------------------------
# Main project
# ----------------------------------------------------------------
# The main project sources are in the Main directory.
MAIN_PRG  = $(ODIR)/main.bin
MAIN_CRT_TEMP = $(ODIR)/main_temp.crt
MAIN_CRT  = $(ODIR)/main.crt


# ----------------------------------------------------------------
# Default target: build everything
# ----------------------------------------------------------------
all: $(MAIN_PRG) makefile
# $(COMPRESSED_BIN) $(TESTZP_BIN) $(FINAL_END_BIN) $(FINAL_START_BIN)

# ----------------------------------------------------------------
# Assemble the main payload.
# This rule says: if any file in $(PAYLOAD_ASMS) changes, reassemble payload.asm.
$(PAYLOAD_PRG): $(PAYLOAD_ASMS) makefile
	@echo "Assembling main payload from $(PAYLOAD_DIR)..."
	$(KICKASM) $(PAYLOAD_MAIN) -o $(PAYLOAD_PRG)
	@echo "Payload assembled: $(PAYLOAD_PRG)"

# Compress the main payload.
$(COMPRESSED_PRG): $(PAYLOAD_PRG) makefile
	@echo "Compressing main payload with dali..."
	$(DALI) --sfx '$$C000' --relocate-sfx '$$C000' -o $(COMPRESSED_PRG) $(PAYLOAD_PRG)
	@echo "Compressed main payload: $(COMPRESSED_PRG)"


# ----------------------------------------------------------------
# Assemble and process testZPstack payload.
$(TESTZP_PRG): $(TESTZP_SRC) makefile
	@echo "Assembling testZPstack payload..."
	$(KICKASM) $(TESTZP_SRC) -o $(TESTZP_PRG)
	@echo "TestZPstack payload assembled: $(TESTZP_PRG)"

$(TESTZP_COMPRESSED): $(TESTZP_PRG) makefile
	@echo "Compressing testZPstack payload..."
# $(DALI) --effect --sfx '$$C000' --relocate-sfx '$$C000' -o $(TESTZP_COMPRESSED) $(TESTZP_PRG)
	$(DALI) --sfx '$$C000' --relocate-sfx '$$C000' -o $(TESTZP_COMPRESSED) $(TESTZP_PRG)
	@echo "Compressed testZPstack payload: $(TESTZP_COMPRESSED)"


# ----------------------------------------------------------------
# Assemble and process final_end payload.
# $(FINAL_END_PRG): $(FINAL_END_SRC) makefile
# 	@echo "Assembling final_end payload..."
# 	$(KICKASM) $(FINAL_END_SRC) -o $(FINAL_END_PRG)
# 	@echo "Final_end payload assembled: $(FINAL_END_PRG)"

# $(FINAL_END_COMPRESSED): $(FINAL_END_PRG) makefile
# 	@echo "Compressing final_end payload..."
# 	$(DALI) --effect --sfx '$$f800' --relocate-sfx '$$f800' -o $(FINAL_END_COMPRESSED) $(FINAL_END_PRG)
# 	@echo "Compressed final_end payload: $(FINAL_END_COMPRESSED)"


# ----------------------------------------------------------------
# Assemble and process final_start payload.
$(FINAL_START_PRG): $(FINAL_START_SRC) makefile
	@echo "Assembling final_start payload..."
	$(KICKASM) $(FINAL_START_SRC) -o $(FINAL_START_PRG)
	@echo "Final_start payload assembled: $(FINAL_START_PRG)"

# $(FINAL_START_COMPRESSED): $(FINAL_START_PRG)
# 	@echo "Compressing final_start payload..."
# 	$(DALI) --effect --sfx '$$0200' --relocate-sfx '$$0200' -o $(FINAL_START_COMPRESSED) $(FINAL_START_PRG)
# 	@echo "Compressed final_start payload: $(FINAL_START_COMPRESSED)"

# ----------------------------------------------------------------
# Assemble and process rasterirq payload.
$(RASTERIRQ_PRG): $(RASTERIRQ_SRC) makefile
	@echo "Assembling rasterirq payload..."
	$(KICKASM) $(RASTERIRQ_SRC) -o $(RASTERIRQ_PRG)
	@echo "Final_end payload assembled: $(RASTERIRQ_PRG)"

# $(RASTERIRQ_COMPRESSED): $(RASTERIRQ_PRG) makefile
# 	@echo "Compressing rasterirq payload..."
# 	$(DALI) --effect --sfx '$$c000' --relocate-sfx '$$f800' -o $(FINAL_END_COMPRESSED) $(FINAL_END_PRG)
# 	@echo "Compressed final_end payload: $(FINAL_END_COMPRESSED)"
# ----------------------------------------------------------------
# Assemble main project (if needed).
$(MAIN_PRG): $(MAIN_DIR)/*.asm $(COMPRESSED_PRG) $(TESTZP_COMPRESSED)  $(FINAL_START_PRG) $(RASTERIRQ_PRG) # $(FINAL_START_COMPRESSED) makefile $(FINAL_END_COMPRESSED) 
	@echo "Assembling main program from $(MAIN_DIR)..."
	$(KICKASM) $(MAIN_DIR)/main.asm -binfile -o $(MAIN_PRG)
	@echo "Main program assembled: $(MAIN_PRG)"

# ----------------------------------------------------------------
# Convert the main program to a cartridge image.
cart: $(MAIN_PRG) makefile
	@echo "Converting main program to cartridge image..."
	$(DD) if=$(MAIN_PRG) bs=8192 count=1 conv=sync of=$(MAIN_CRT_TEMP)
	$(CARTCONV) -t normal -n April64k -i $(MAIN_CRT_TEMP) -o $(MAIN_CRT)
	@echo "Cartridge image created: $(MAIN_CRT)"


# ----------------------------------------------------------------
# Clean up all generated files.
clean:
	rm $(ODIR)/*.*

debug: $(MAIN_PRG) makefile
	$(RETRODEBUGGER) $(MAIN_PRG)

run: $(MAIN_PRG) makefile cart
# $(VICE) $(MAIN_PRG)
	$(VICE) -cartcrt $(MAIN_CRT)

.PHONY: all clean
