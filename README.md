# April64k C64 Memory Test Cartridge

This cartridge implements a comprehensive memory test for the Commodore 64 using the March-B testing algorithm. It is designed to rigorously check memory integrity without using any untested memory, ensuring system stability during the test. The code fits into a standard 8k cartridge.

---

## Overview

The cartridge performs a two-stage memory test:

1. **Segmented Testing:**  
   Individual memory regions are tested sequentially.
2. **Comprehensive Testing:**  
   After testing individual segments, the entire memory range from **$0400 to $FFFF** is checked in one pass.

---

## Memory Test Details

### Segmented Testing

The following memory areas are tested one by one:

- **$0002 - $01FF**
- **$0200 - $03FF**
- **$0400 - $07FF** Display memory. The screen will become corrupted during test. This is normal.
- **$0800 - $09FF**
- **$1000 - $7FFF**
- **$8000 - $9FFF**
- **$A000 - $BFFF**
- **$C000 - $CFFF**
- **$D000 - $DFFF**
- **$E000 - $EFFF**
- **$F000 - $FFFF**

Additionally, the 4-bit **Colour Memory** is tested:
- **$D800 - $DBFF** The colours will flicker during test. This is normal.

### Comprehensive Testing

After the segmented tests, the cartridge tests all memory from **$0400 to $FFFF** in one continuous operation. This takes about 25 seconds and the screen will become corrupted during test.

---

## Fault Handling and Reporting

- **Immediate Halt:**  
  If any faults are detected during the tests on **$0002-$01FF** or **$C000-$CFFF**, the test halts immediately.

- **Post-Test Halt:**  
  If faults are found in other regions, the test continues and halts only after the full test sequence is complete.

- **Failure Reporting:**  
  - The failure address is displayed on the screen.
  - Detailed information is provided on which bits have failed.
  - Rasterbars in the screen border visually indicate the failing bits (useful if the display is compromised).

- **No Faults Detected:**  
  If no faults are found, the test automatically restarts after a 10-second delay.

---

## How to Use

1. **Insert Cartridge:**  
   Plug the cartridge into your C64’s standard cartridge slot.
2. **Power Up:**  
   Turn on the Commodore 64.
3. **Automatic Testing:**  
   The memory test starts automatically.
4. **Monitor Results:**  
   - Watch the screen for detailed failure information if any faults are detected.
   - Observe the rasterbars in the border that indicate failed bits.
5. **Restart on Success:**  
   If no faults are detected, the test will restart automatically after a 10-second pause.

---

## Design Considerations

- **Memory Safety:**  
  The test avoids relying on any untested memory regions, thereby ensuring that the test does not accidentally give false information or compromise system stability.

- **User Feedback:**  
  Clear on-screen messages and visual indicators (rasterbars) provide immediate feedback on memory integrity.

---

## Credits

- **Testing Algorithm:**  
  March-B testing algorithm.

- **Developer:**  
  *Christian Roth*

---

## License

GPL v3

---

## Disclaimer

This cartridge is provided "as is" without any warranty, express or implied. Use it at your own risk. It is intended for hobbyist and educational purposes only.
