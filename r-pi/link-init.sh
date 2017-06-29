# fresh os:
sudo apt-get update
sudo apt-get -s dist-upgrade | grep "^Inst" | grep -i securi | awk -F " " {'print $2'} | xargs sudo apt-get install
sudo apt-get install -y raspi-config unzip rsync python-smbus i2c-tools

## append to /boot/config.txt :
#sudo bash -c 'cat << EOF >> /boot/config.txt
#dtparam=i2c_arm=on
#dtoverlay=i2c-rtc,ds3231
#EOF'

sudo modprobe rtc-ds1307
 	
## append to /etc/modules :: 
sudo bash -c 'cat << EOF >> /etc/modules
rtc-ds1307
EOF'

# comment-out lines that would return early from hwclock-set
sudo sed -i -e '/\/run\/systemd\/system/,+2 s/^/#/' /lib/udev/hwclock-set

# stop, remove fake hw clock service
sudo systemctl stop fake-hwclock.service
sudo systemctl disable fake-hwclock.service

# Create the script with
sudo mkdir /usr/lib/systemd/scripts
sudo bash -c 'cat << EOF > /usr/lib/systemd/scripts/rtc
#!/bin/bash
echo ds3231 0x68 > /sys/bus/i2c/devices/i2c-1/new_device
hwclock -s -f /dev/rtc
EOF'

# this will recreate the I2C RTC and synchronize the system clock to it.
# make the script executable 
sudo chmod 755 /usr/lib/systemd/scripts/rtc

# Now to make it run at boot.
sudo bash -c 'cat << EOF > /etc/systemd/system/rtc.service
[Unit]
Description=RTC clock
Before=netctl-auto@wlan0.service

[Service]
ExecStart=/usr/lib/systemd/scripts/rtc
 
[Install]
WantedBy=multi-user.target
EOF'

# Test it out by issuing
sudo systemctl start rtc
# If you receive no errors, you can enable this to run at boot with
sudo systemctl enable rtc

# write system time to hw clock
sudo hwclock -w


sudo reboot