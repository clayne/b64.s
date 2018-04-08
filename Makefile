TARGETS = toB64 fromB64
CC = gcc
ASFLAGS = -O0 -g

.PHONY: all
all: $(TARGETS)

toB64: toB64.s

fromB64: fromB64.s

.PHONY: clean
clean:
	$(RM) $(TARGETS)
