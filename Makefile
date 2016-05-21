dfiles = $(wildcard *.d)
exefiles = $(dfiles:.d=.exe)

D = gdc

DFLAGS = 

all: $(exefiles)

%.exe: %.d
	$(D) $(DFLAGS) $< -o $@

test: test_flags $(exefiles)
	@for f in $(exefiles); do echo "Running $$f"; ./$$f; done;

test_flags:
	$(eval DFLAGS += -funittest)

.phony: all test test_flags

clean:
	rm *.o *.exe