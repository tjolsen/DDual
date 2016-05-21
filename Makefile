dfiles = $(wildcard *.d)
exefiles = $(dfiles:.d=.exe)

D = dmd

DFLAGS = 

all: $(exefiles)

%.exe: %.d
	$(D) $(DFLAGS) $< -of$@

test: test_flags $(exefiles)
	@for f in $(exefiles); do echo "Running $$f"; ./$$f; done;

test_flags:
	$(eval DFLAGS += -unittest -main)

.phony: all test test_flags

clean:
	rm *.o *.exe