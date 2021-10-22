CC  ?= xcrun -sdk iphoneos cc -arch arm64

SRC := netctl.c wifi.m cellular.m

all: netctl

%.m.o: %.m
	$(CC) $(CFLAGS) -F Frameworks -fobjc-arc $< -c -o $@

%.c.o: %.c
	$(CC) $(CFLAGS) $< -c -o $@

netctl: $(SRC:%=%.o)
	$(CC) $(CFLAGS) $(LDFLAGS) -F Frameworks -fobjc-arc $^ -o $@ -framework MobileWiFi -framework CoreTelephony
	ldid -Cadhoc -Snetctl.plist $@

clean:
	rm -rf netctl *.dSYM $(SRC:%=%.o)

.PHONY: all clean
