OBJS = \
	obj/kernel/bio.o\
	obj/kernel/console.o\
	obj/kernel/exec.o\
	obj/kernel/file.o\
	obj/kernel/fs.o\
	obj/kernel/ide.o\
	obj/kernel/ioapic.o\
	obj/kernel/kalloc.o\
	obj/kernel/kbd.o\
	obj/kernel/lapic.o\
	obj/kernel/log.o\
	obj/kernel/main.o\
	obj/kernel/mp.o\
	obj/kernel/picirq.o\
	obj/kernel/pipe.o\
	obj/kernel/proc.o\
	obj/kernel/sleeplock.o\
	obj/kernel/spinlock.o\
	obj/kernel/string.o\
	obj/kernel/swtch.o\
	obj/kernel/syscall.o\
	obj/kernel/sysfile.o\
	obj/kernel/sysproc.o\
	obj/kernel/trapasm.o\
	obj/kernel/trap.o\
	obj/kernel/uart.o\
	obj/kernel/vectors.o\
	obj/kernel/vm.o\

# Cross-compiling (e.g., on Mac OS X)
# TOOLPREFIX = i386-jos-elf

# Using native tools (e.g., on X86 Linux)
#TOOLPREFIX =

# Try to infer the correct TOOLPREFIX if not set
ifndef TOOLPREFIX
TOOLPREFIX := $(shell if i386-jos-elf-objdump -i 2>&1 | grep '^elf32-i386$$' >/dev/null 2>&1; \
	then echo 'i386-jos-elf-'; \
	elif objdump -i 2>&1 | grep 'elf32-i386' >/dev/null 2>&1; \
	then echo ''; \
	else echo "***" 1>&2; \
	echo "*** Error: Couldn't find an i386-*-elf version of GCC/binutils." 1>&2; \
	echo "*** Is the directory with i386-jos-elf-gcc in your PATH?" 1>&2; \
	echo "*** If your i386-*-elf toolchain is installed with a command" 1>&2; \
	echo "*** prefix other than 'i386-jos-elf-', set your TOOLPREFIX" 1>&2; \
	echo "*** environment variable to that prefix and run 'make' again." 1>&2; \
	echo "*** To turn off this error, run 'gmake TOOLPREFIX= ...'." 1>&2; \
	echo "***" 1>&2; exit 1; fi)
endif

# If the makefile can't find QEMU, specify its path here
# QEMU = qemu-system-i386

# Try to infer the correct QEMU
ifndef QEMU
QEMU = $(shell if which qemu > /dev/null; \
	then echo qemu; exit; \
	elif which qemu-system-i386 > /dev/null; \
	then echo qemu-system-i386; exit; \
	elif which qemu-system-x86_64 > /dev/null; \
	then echo qemu-system-x86_64; exit; \
	else \
	qemu=/Applications/Q.app/Contents/MacOS/i386-softmmu.app/Contents/MacOS/i386-softmmu; \
	if test -x $$qemu; then echo $$qemu; exit; fi; fi; \
	echo "***" 1>&2; \
	echo "*** Error: Couldn't find a working QEMU executable." 1>&2; \
	echo "*** Is the directory containing the qemu binary in your PATH" 1>&2; \
	echo "*** or have you tried setting the QEMU variable in Makefile?" 1>&2; \
	echo "***" 1>&2; exit 1)
endif

CC = $(TOOLPREFIX)gcc
AS = $(TOOLPREFIX)gas
LD = $(TOOLPREFIX)ld
OBJCOPY = $(TOOLPREFIX)objcopy
OBJDUMP = $(TOOLPREFIX)objdump
CFLAGS = -fno-pic -static -fno-builtin -fno-strict-aliasing -O2 -Wall -MD -ggdb -m32 -Werror -fno-omit-frame-pointer
#CFLAGS = -fno-pic -static -fno-builtin -fno-strict-aliasing -fvar-tracking -fvar-tracking-assignments -O0 -g -Wall -MD -gdwarf-2 -m32 -Werror -fno-omit-frame-pointer
CFLAGS += -Iinclude
CFLAGS += $(shell $(CC) -fno-stack-protector -E -x c /dev/null >/dev/null 2>&1 && echo -fno-stack-protector)
ASFLAGS = -m32 -gdwarf-2 -Wa,-divide -Iinclude
# FreeBSD ld wants ``elf_i386_fbsd''
LDFLAGS += -m $(shell $(LD) -V | grep elf_i386 2>/dev/null | head -n 1)

all:	obj/xv6.img obj/fs.img

obj/xv6.img: obj/out/bootblock obj/out/kernel.elf
	dd if=/dev/zero of=$@ count=10000
	dd if=obj/out/bootblock of=$@ conv=notrunc
	dd if=obj/out/kernel.elf of=$@ seek=1 conv=notrunc

obj/xv6memfs.img: obj/out/bootblock obj/out/kernelmemfs.elf
	dd if=/dev/zero of=$@ count=10000
	dd if=obj/out/bootblock of=$@ conv=notrunc
	dd if=obj/out/kernelmemfs.elf of=$@ seek=1 conv=notrunc

# kernel object files
obj/kernel/%.o: kernel/%.c
	@mkdir -p obj/kernel
	$(CC) $(CFLAGS) -c -o $@ $<

obj/kernel/%.o: kernel/%.S
	@mkdir -p obj/kernel
	$(CC) $(ASFLAGS) -c -o $@ $<

# userspace object files
obj/user/%.o: user/%.c
	@mkdir -p obj/user
	$(CC) $(CFLAGS) -c -o $@ $<

obj/ulib/%.o: ulib/%.c
	@mkdir -p obj/ulib
	$(CC) $(CFLAGS) -c -o $@ $<

obj/ulib/%.o: ulib/%.S
	@mkdir -p obj/ulib
	$(CC) $(ASFLAGS) -c -o $@ $<

obj/out/bootblock: kernel/bootasm.S kernel/bootmain.c
	@mkdir -p obj/out
	$(CC) $(CFLAGS) -fno-pic -O -nostdinc -Iinclude -o obj/out/bootmain.o -c kernel/bootmain.c
	$(CC) $(CFLAGS) -fno-pic -nostdinc -Iinclude -o obj/out/bootasm.o -c kernel/bootasm.S
	$(LD) $(LDFLAGS) -N -e start -Ttext 0x7C00 -o obj/out/bootblock.o obj/out/bootasm.o obj/out/bootmain.o
	$(OBJDUMP) -S obj/out/bootblock.o > obj/out/bootblock.asm
	$(OBJCOPY) -S -O binary -j .text obj/out/bootblock.o $@
	tools/sign.pl $@

obj/out/entryother: kernel/entryother.S
	@mkdir -p obj/out
	$(CC) $(CFLAGS) -fno-pic -nostdinc -o obj/out/entryother.o -c kernel/entryother.S
	$(LD) $(LDFLAGS) -N -e start -Ttext 0x7000 -o obj/out/bootblockother.o obj/out/entryother.o
	$(OBJCOPY) -S -O binary -j .text obj/out/bootblockother.o $@
	$(OBJDUMP) -S obj/out/bootblockother.o > obj/out/entryother.asm

obj/out/initcode: kernel/initcode.S
	@mkdir -p obj/out
	$(CC) $(CFLAGS) -nostdinc -I. -c -o obj/out/initcode.o kernel/initcode.S
	$(LD) $(LDFLAGS) -N -e start -Ttext 0 -o obj/out/initcode.out obj/out/initcode.o
	$(OBJCOPY) -S -O binary obj/out/initcode.out $@
	$(OBJDUMP) -S obj/out/initcode.o > obj/out/initcode.asm

ENTRYCODE = obj/kernel/entry.o
LINKSCRIPT = kernel/kernel.ld
obj/out/kernel.elf: $(OBJS) $(ENTRYCODE) obj/out/entryother obj/out/initcode $(LINKSCRIPT)
	$(LD) $(LDFLAGS) -T $(LINKSCRIPT) -o $@ $(ENTRYCODE) $(OBJS) -b binary obj/out/initcode obj/out/entryother
	$(OBJDUMP) -S $@ > obj/out/kernel.asm
	$(OBJDUMP) -t $@ | sed '1,/SYMBOL TABLE/d; s/ .* / /; /^$$/d' > obj/out/kernel.sym

# kernelmemfs is a copy of kernel that maintains the
# disk image in memory instead of writing to a disk.
# This is not so useful for testing persistent storage or
# exploring disk buffering implementations, but it is
# great for testing the kernel on real hardware without
# needing a scratch disk.
MEMFSOBJS = $(filter-out obj/kernel/ide.o,$(OBJS)) obj/kernel/memide.o
obj/out/kernelmemfs.elf: $(MEMFSOBJS) $(ENTRYCODE) obj/out/entryother obj/out/initcode $(LINKSCRIPT) obj/fs.img
	$(LD) $(LDFLAGS) -T $(LINKSCRIPT) -o $@ $(ENTRYCODE)  $(MEMFSOBJS) -b binary obj/out/initcode obj/out/entryother obj/fs.img
	$(OBJDUMP) -S $@ > obj/out/kernelmemfs.asm
	$(OBJDUMP) -t $@ | sed '1,/SYMBOL TABLE/d; s/ .* / /; /^$$/d' > obj/out/kernelmemfs.sym

tags: $(OBJS) entryother.S fs/init
	etags *.S *.c

MKVECTORS = tools/vectors.pl
kernel/vectors.S: $(MKVECTORS)
	perl $< > $@

ULIBOBJS = \
	obj/ulib/crt0.o \
	obj/ulib/strcpy.o \
	obj/ulib/strlen.o \
	obj/ulib/memset.o \
	obj/ulib/strchr.o \
	obj/ulib/gets.o \
	obj/ulib/stat.o \
	obj/ulib/atoi.o \
	obj/ulib/memmove.o \
	obj/ulib/chdir.o \
	obj/ulib/close.o \
	obj/ulib/dup.o \
	obj/ulib/exec.o \
	obj/ulib/exit.o \
	obj/ulib/fork.o \
	obj/ulib/fstat.o \
	obj/ulib/getpid.o \
	obj/ulib/kill.o \
	obj/ulib/link.o \
	obj/ulib/mkdir.o \
	obj/ulib/mknod.o \
	obj/ulib/open.o \
	obj/ulib/pipe.o \
	obj/ulib/read.o \
	obj/ulib/sbrk.o \
	obj/ulib/sleep.o \
	obj/ulib/unlink.o \
	obj/ulib/uptime.o \
	obj/ulib/wait.o \
	obj/ulib/write.o \
	obj/ulib/printf.o obj/ulib/umalloc.o

obj/ulib/ulib.a:	$(ULIBOBJS)
	ar rcs $@ $^

obj/fs/%: obj/user/%.o obj/ulib/ulib.a
	@mkdir -p obj/fs obj/out
	$(LD) $(LDFLAGS) -N -e _start -Ttext 0 -o $@ $^
	$(OBJDUMP) -S $@ > obj/out/$*.asm
	$(OBJDUMP) -t $@ | sed '1,/SYMBOL TABLE/d; s/ .* / /; /^$$/d' > obj/out/$*.sym

obj/fs/forktest: obj/user/forktest.o obj/ulib/ulib.a
	@mkdir -p obj/fs
	# forktest has less library code linked in - needs to be small
	# in order to be able to max out the proc table.
	$(LD) $(LDFLAGS) -N -e main -Ttext 0 -o $@ obj/user/forktest.o obj/ulib/ulib.a
	$(OBJDUMP) -S $@ > obj/out/forktest.asm

obj/out/mkfs: tools/mkfs.c include/fs.h
	@mkdir -p obj/out
	gcc -Werror -Wall -o $@ tools/mkfs.c

# Prevent deletion of intermediate files, e.g. cat.o, after first build, so
# that disk image changes after first build are persistent until clean.  More
# details:
# http://www.gnu.org/software/make/manual/html_node/Chained-Rules.html
.PRECIOUS: obj/user/%.o

UPROGS=\
	obj/fs/cat\
	obj/fs/echo\
	obj/fs/forktest\
	obj/fs/grep\
	obj/fs/init\
	obj/fs/kill\
	obj/fs/ln\
	obj/fs/ls\
	obj/fs/mkdir\
	obj/fs/pwd\
	obj/fs/rm\
	obj/fs/sh\
	obj/fs/stressfs\
	obj/fs/usertests\
	obj/fs/wc\
	obj/fs/zombie\

obj/fs.img: obj/out/mkfs README $(UPROGS)
	obj/out/mkfs $@ README $(UPROGS)

-include */*.d

clean:
	rm -rf out obj
	rm -f kernel/vectors.S .gdbinit

# make a printout
FILES = $(shell grep -v '^\#' docsrc/runoff.list)
PRINT = runoff.list runoff.spec README toc.hdr toc.ftr $(FILES)

xv6.pdf: $(PRINT)
	./runoff
	ls -l $@

print: xv6.pdf

# run in emulators

bochs : obj/fs.img obj/xv6.img
	if [ ! -e .bochsrc ]; then ln -s tools/dot-bochsrc .bochsrc; fi
	bochs -q

# try to generate a unique GDB port
GDBPORT = $(shell expr `id -u` % 5000 + 25000)
# QEMU's gdb stub command line changed in 0.11
QEMUGDB = $(shell if $(QEMU) -help | grep -q '^-gdb'; \
	then echo "-gdb tcp::$(GDBPORT)"; \
	else echo "-s -p $(GDBPORT)"; fi)
ifndef CPUS
CPUS := 2
endif
QEMUOPTS = -drive file=obj/fs.img,index=1,media=disk,format=raw -drive file=obj/xv6.img,index=0,media=disk,format=raw -smp $(CPUS) -m 512 $(QEMUEXTRA)

qemu: obj/fs.img obj/xv6.img
	$(QEMU) -serial mon:stdio $(QEMUOPTS)

qemu-memfs: obj/xv6memfs.img
	$(QEMU) -drive file=obj/xv6memfs.img,index=0,media=disk,format=raw -smp $(CPUS) -m 256

qemu-nox: obj/fs.img obj/xv6.img
	$(QEMU) -nographic $(QEMUOPTS)

.gdbinit: .gdbinit.tmpl
	sed "s/localhost:1234/localhost:$(GDBPORT)/" < $^ > $@

qemu-gdb: obj/fs.img obj/xv6.img .gdbinit
	@echo "*** Now run 'gdb'." 1>&2
	$(QEMU) -serial mon:stdio $(QEMUOPTS) -S $(QEMUGDB)

qemu-nox-gdb: obj/fs.img obj/xv6.img .gdbinit
	@echo "*** Now run 'gdb'." 1>&2
	$(QEMU) -nographic $(QEMUOPTS) -S $(QEMUGDB)

# CUT HERE
# prepare dist for students
# after running make dist, probably want to
# rename it to rev0 or rev1 or so on and then
# check in that version.

EXTRA=\
	mkfs.c ulib.c user.h cat.c echo.c forktest.c grep.c kill.c\
	ln.c ls.c mkdir.c rm.c stressfs.c usertests.c wc.c zombie.c\
	printf.c umalloc.c\
	README dot-bochsrc *.pl toc.* runoff runoff1 runoff.list\
	.gdbinit.tmpl gdbutil\

dist:
	rm -rf dist
	mkdir dist
	for i in $(FILES); \
	do \
		grep -v PAGEBREAK $$i >dist/$$i; \
	done
	sed '/CUT HERE/,$$d' Makefile >dist/Makefile
	echo >dist/runoff.spec
	cp $(EXTRA) dist

dist-test:
	rm -rf dist
	make dist
	rm -rf dist-test
	mkdir dist-test
	cp dist/* dist-test
	cd dist-test; $(MAKE) print
	cd dist-test; $(MAKE) bochs || true
	cd dist-test; $(MAKE) qemu

# update this rule (change rev#) when it is time to
# make a new revision.
tar:
	rm -rf /tmp/xv6
	mkdir -p /tmp/xv6
	cp dist/* dist/.gdbinit.tmpl /tmp/xv6
	(cd /tmp; tar cf - xv6) | gzip >xv6-rev10.tar.gz  # the next one will be 10 (9/17)

.PHONY: dist-test dist
