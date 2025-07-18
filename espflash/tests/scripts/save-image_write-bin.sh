#!/usr/bin/env bash
app="espflash/tests/data/$1"

# if $1 is esp32c2, create an variable that contains `-x 26mhz`
if [[ $1 == "esp32c2" ]]; then
    freq="-x 26mhz"
fi

result=$(espflash save-image --merge --chip $1 $freq $app app.bin 2>&1)
echo "$result"
if [[ ! $result =~ "Image successfully saved!" ]]; then
    exit 1
fi
echo "Writing binary"
result=$(timeout 90 espflash write-bin --monitor 0x0 app.bin --non-interactive 2>&1)
echo "$result"
if [[ ! $result =~ "Binary successfully written to flash!" ]]; then
    exit 1
fi

if ! echo "$result" | grep -q "Hello world!"; then
    exit 1
fi

if [[ $1 == "esp32c6" ]]; then
    # Regression test for https://github.com/esp-rs/espflash/issues/741
    app="espflash/tests/data/esp_idf_firmware_c6.elf"

    result=$(espflash save-image --merge --chip esp32c6 $app app.bin 2>&1)
    echo "$result"
    if [[ ! $result =~ "Image successfully saved!" ]]; then
        exit 1
    fi

    echo "Checking that app descriptor is first"
    # Read 4 bytes from 0x10020, it needs to be 0xABCD5432

    app_descriptor=$(xxd -p -s 0x10020 -l 4 app.bin)
    if [[ $app_descriptor != "3254cdab" ]]; then
        echo "App descriptor magic word is not correct: $app_descriptor"
        exit 1
    fi
fi
