CC  ?= xcrun -sdk iphoneos cc -arch arm64

SRC := netctl.c
SRC += utils/output.m
SRC += cellular/cellular.m
SRC += wifi/wifi.m wifi/wifi-connect.m wifi/wifi-scan.m wifi/wifi-power.m wifi/wifi-info.m wifi/wifi-forget.m
SRC += airdrop/airdrop.m

all: netctl

%.m.o: %.m
	$(CC) $(CFLAGS) -Iinclude -F Frameworks -fobjc-arc $< -c -o $@

%.c.o: %.c
	$(CC) $(CFLAGS) $< -c -o $@

netctl: $(SRC:%=%.o)
	$(CC) $(CFLAGS) $(LDFLAGS) -F Frameworks -fobjc-arc $^ -o $@ -framework MobileWiFi -framework CoreTelephony -framework Sharing
	ldid -Cadhoc -Sentitlements.plist $@

clean:
	rm -rf netctl *.dSYM $(SRC:%=%.o)

format:
	clang-format -i $(SRC)

.PHONY: all clean format
