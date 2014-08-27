#1.clover的原理
这个在zetam.org上的wiki中有描述。

clover的任务:

1.SMBIOS，模拟一个Apple电脑。

2.ACPI表。

3.OS X会从bootloader获得一些数

.....

#2.clover的安装
在mac os下，下载那个clover的安装文件，然后运行安装程序。系统要是gpt分区才行。选择装在那个Install Clover in the ESP，ESP是第一个分区。

安装出错会在根目录生成一个日志文件。

#3.clover配置
config.plist文件，wiki上有详细说明。

例如：

<key>Graphics</key>
<dict>
...
<key>ig-platform-id</key>
<string>0x01620005</string>
</dict>

##HD4000显示的fakeID配置
在:
<key>PCI</key>
<dict>
...
	<key>FakeID</key>
	<dict>
		<key>IntelGFX</key>
		<string>0x1660000</string>
...
</dict>

##ACPI
/EFI/CLOVER/ACPI/ACPI-p.aml
