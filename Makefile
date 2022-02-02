CC  ?= xcrun -sdk iphoneos cc -arch arm64

NO_CELLULAR ?= 0
NO_WIFI     ?= 0
NO_AIRDROP  ?= 0

CFLAGS += -DNO_CELLULAR=$(NO_CELLULAR) -DNO_WIFI=$(NO_WIFI) -DNO_AIRDROP=$(NO_AIRDROP)

SRC := netctl.c
SRC += utils/output.m
ifneq ($(NO_CELLULAR),1)
SRC += cellular/cellular.m
LIBS += -framework CoreTelephony
endif
ifneq ($(NO_WIFI),1)
SRC += wifi/wifi.m wifi/wifi-connect.m wifi/wifi-scan.m wifi/wifi-power.m wifi/wifi-info.m wifi/wifi-forget.m
LIBS += -framework MobileWiFi
endif
ifneq ($(NO_AIRDROP),1)
SRC += airdrop/airdrop.c airdrop/airdrop-scan.m airdrop/airdrop-send.m
LIBS += -framework Sharing
endif

all: netctl

%.m.o: %.m
	$(CC) $(CFLAGS) -Iinclude -F Frameworks -fobjc-arc $< -c -o $@

%.c.o: %.c
	$(CC) $(CFLAGS) $< -c -o $@

netctl: $(SRC:%=%.o)
	$(CC) $(CFLAGS) $(LDFLAGS) -F Frameworks -fobjc-arc $^ -o $@ $(LIBS)
	ldid -Cadhoc -Sentitlements.plist $@

clean:
	rm -rf netctl *.dSYM $(SRC:%=%.o)

format:
	clang-format -i $(SRC)

.PHONY: all clean format
