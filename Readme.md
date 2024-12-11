# glinet-tac-fix
This warehouse is used to correct the TAC  error. You can choose any of the following methods to repair TAC according to the actual deployment situation.
In the following two ways, if the TAC code of the current device is **35851102**, it will be replaced with **35996594**, otherwise it will remain unchanged.

## Method 1, by running the script on the router to fix(This way is for GL.iNet standard firmware)
Log in to the backend of the router via ssh and execute the following command to fix it.
```
wget https://raw.githubusercontent.com/gl-inet/glinet-tac-fix/main/files/imei_handle.sh -O imei_handle.sh
wget https://raw.githubusercontent.com/gl-inet/glinet-tac-fix/main/files/special_imei.txt -O /usr/share/special_imei.txt
chmod +x ./imei_handle.sh
./imei_handle.sh x750_fixtac
rm /tmp/modem.1-1.2/modem-imei 2>/dev/null
```

## Method 2, compile the corrected code to the firmware(This way is for the firmware developed by the customer)

If you do not use glinet firmware, you can choose to compile glinet-tac-fix into your firmware, and then fix it by upgrading the firmware.
First, clone the project to the package directory of your openwrt source code (in the following example, please replace your source code directory according to the actual situation)

```
cd openwrt/package
git clone git@github.com:gl-inet/glinet-tac-fix.git
```
Then, we need to select glinet-tac-fix under the gl-inet menu of menuconfig, and then compile the firmware.
```
make V=s
```
Or just compile the glinet-tac-fix and install it into your firmware.
```
make V=s ./package/glinet-tac-fix/compile
```
Upload the compiled executable program **sendat** to the device /usr/bin directory
```
chmod +x /usr/bin/sendat
```
Execute imei_handle.sh scripts
```
wget https://raw.githubusercontent.com/gl-inet/glinet-tac-fix/main/files/imei_handle.sh -O imei_handle.sh
wget https://raw.githubusercontent.com/gl-inet/glinet-tac-fix/main/files/special_imei.txt -O /usr/share/special_imei.txt
./imei_handle.sh x750_fixtac
rm /tmp/modem.1-1.2/modem-imei 2>/dev/null
```
