/*
 * Android recovery uses two methods of communicating between the OS and
 * the recovery application:
 *   /cache/recovery/command file
 *   Bootloader Command Block (BCB)
 *
 * The BCB is a data structure read/written to a raw storage partition.
 * Because it is not easy for the bootloader to determine the offset of
 * a particular partition (without specialized bootloader code) and because
 * checking for a /cache/recovery/command file incurs extra time in the
 * bootloader mounting the cache partition, we use a byte in the EEPROM
 * to instruct the bootloader how it should boot.
 *
 * This library provides functions that can set/get that byte
 */
#include <stdio.h>
#include <linux/i2c-dev.h>
#include <i2cbusses.h>

#define BOOTFLAG_I2C_BUS	0
#define BOOTFLAG_I2C_EEPROM	0x51
#define BOOTFLAG_I2C_ADDR	0x80

#define BOOTFLAG_NORMAL		0
#define BOOTFLAG_RECOVERY	1	// boot recovery
#define BOOTFLAG_BOOTLOADER	2	// drop to bootloader
#define BOOTFLAG_FASTBOOT	3	// drop to fastboot

int set_device_bootmode(const char* mode)
{
	char filename[20];
	int file;
	int res = -EIO;
	int force = 1;
	int val;

	if (!mode)
		return 0;

	if (strcmp(mode, "recovery") == 0)
		val = BOOTFLAG_RECOVERY;
	else if (strcmp(mode, "bootloader") == 0)
		val = BOOTFLAG_BOOTLOADER;
	else if (strcmp(mode, "fastboot") == 0)
		val = BOOTFLAG_FASTBOOT;
	else
		val = 0;

	file = open_i2c_dev(BOOTFLAG_I2C_BUS, filename, sizeof(filename), 0);
	if (file < 0 || set_slave_addr(file, BOOTFLAG_I2C_EEPROM, force))
		goto err;

	res = i2c_smbus_write_byte_data(file, BOOTFLAG_I2C_ADDR, val);

err:
	if (file >= 0)
		close(file);

	return res;
}
