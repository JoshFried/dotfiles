# Pass pro or max to connect the corresponding paired headset via blueutil. The
# Bluetooth addresses below identify this workstation's devices.

echo "DJSKLJDSLKFJDLSKJFL"
case "$1" in
"pro")
	blueutil --connect 00-f3-9f-6a-21-47
	;;
"max")
	blueutil --connect 90-9c-4a-e5-cc-ca
	;;
*)
	echo default
	;;
esac
