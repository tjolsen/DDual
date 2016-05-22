dfiles = $(wildcard *.d)
ofiles = $(dfiles:.d=.o)
exefiles = $(dfiles:.d=.exe)

D = dmd

DFLAGS = -O -c

LDFLAGS = 

all: $(exefiles)

%.exe: %.o
	$(D) $(LDFLAGS) $< -of$@

%.o: %.d
	$(D) $(DFLAGS) $<

test: test_flags $(ofiles) $(exefiles)
	@for f in $(exefiles); do echo "Running $$f"; ./$$f; done;

test_flags:
	$(eval DFLAGS += -unittest)

.phony: all test test_flags

clean:
	rm *.o *.exe