program=out/a
out_dir = ./out

# Emulator options
BUILD=hunk
MODEL=A500
FASTMEM=0
CHIPMEM=512
SLOWMEM=512

BIN_DIR = ~/amiga/bin
VASM = $(BIN_DIR)/vasmm68k_mot
FSUAE = /Applications/FS-UAE.app/Contents/MacOS/fs-uae

VASMFLAGS = -m68000 -nowarn=62 -x -opt-size -showopt
FSUAEFLAGS = --floppy_drive_0_sounds=off --automatic_input_grab=0  --chip_memory=$(CHIPMEM) --fast_memory=$(FASTMEM) --slow_memory=$(SLOWMEM) --amiga_model=$(MODEL)

# generic exe path used in startup-sequence - current build is copied here to run
prog_exe = $(program).exe

hunk_exe = $(program).hunk.exe
hunk_debug = $(program).hunk-debug.exe
dist_exe = $(program).dist.exe

dist: $(dist_exe)

run: $(hunk_exe)
	cp $< $(prog_exe)
	$(FSUAE) $(FSUAEFLAGS) --hard_drive_0=$(out_dir)

run-dist: $(dist_exe)
	cp $< $(prog_exe)
	$(FSUAE) $(FSUAEFLAGS) --hard_drive_0=$(out_dir)

# Final exe trims fake BSS data at and of code hunk
$(dist_exe): $(hunk_exe)
	node ../scripts/truncateCode.js $< $@

$(hunk_exe): main.asm $(data) $(hunk_debug)
	$(VASM) $(VASMFLAGS) -kick1hunks -Fhunkexe -linedebug -nosym -o $@ $<
	cp $@ $(prog_exe)

# Build a separate exe with symbols, just used by the debugger and not actually loaded on amiga
$(hunk_debug): main.asm $(data)
	$(VASM) $(VASMFLAGS) -kick1hunks -Fhunkexe -linedebug -o $@ $<

clean:
	$(RM) $(out_dir)/*.*

.PHONY: clean dist run run-dist
