
MSP430-GCC-TI Toolchain
=======================

The TI GCC (aka "msp430-gcc-opensource", aka "Somnium GCC for msp430") is newer 
than the GCC included with various mspgcc versions. Having the uC manufacturer
actively support the compiler and toolchain is usually a good thing. Presumably, 
it should also provide better support for TI's `driverlib` and hopefully for TI's 
`USP-API`. For these reasons, using the TI msp430-gcc-opensource toolchain is the 
preferred route for MSP430 development.

Installing the MSP430-GCC-TI toolchain
--------------------------------------

* Download TI GCC installer including support packages from the TI website
  <http://www.ti.com/tool/msp430-gcc-opensource>

* Make the file executable and run the installer. Run as root to be able to 
  install to system folders (installing to /opt)
    
    ~~~
    $ chmod a+x msp430-gcc-full-linux-x64-installer-5.1.1.0.run
    $ sudo ./msp430-gcc-full-linux-x64-installer-5.1.1.0.run
    ~~~
    
* Install the toolchain. Recommended location is `/opt/ti/msp430/gcc` unless you 
  have a good reason to install it elsewhere.

* `mspdebug` isn't installed with the toolchain, and should be installed 
  separately. Beware that mismatched versions of `mspdebug` and `libmsp430.so`
  can result in silent failure. While there will be no loud errors, you might
  see an inability to program the device. Make sure that whatever version of 
  `mspdebug` and `libmsp430.so` you're using work as expected. The versions 
  described presently work with the latest mspdebug release (v0.25) from 
  <https://github.com/dlbeer/mspdebug>, while they don't with the version that
  currently ships with Ubuntu (v0.22).

* Use the `toolchain-msp430-gcc-ti.cmake` toolchain file for cmake. The system
  specific changes that may need to be made are : 
    - `MSP430_TI_COMPILER_FOLDER` : Path of TI GCC installation
    - `mspdebug` location etc. should be crosschecked, since TI gcc installation
      does not install `mspdebug`.
    - Set the correct `CMAKE_MODULE_PATH` (to your toolchains folder) so that 
      cmake can find toolchains/Platforms.

* Add the toolchain to your PATH by appending the following to `~/.bashrc`:

    ~~~
    export PATH="/opt/ti/msp430/gcc/bin:${PATH}"
    ~~~

Debugging using the LP5529 on-board device:
-------------------------------------------

* Program the device as usual by `make install` or `make firmware-<device>-load`.

* Use `mspdebug` to connect to the device and provide a gdb remote stub. 

    ~~~
    $ mspdebug tilib
    ...
    Chip ID data:                                                                                          
    ver_id:         2955
    ver_sub_id:     0000
    revision:       18
    fab:            55
    self:           5555
    config:         12
    fuses:          55
    Device: MSP430F5529
    ...
    (mspdebug) gdb
    Bound to port 2000. Now waiting for connection...
    ~~~

* Earlier versions (Upto 4.0.1 or so) of the toolchain used `gdb_agent_console` 
  instead of `mspdebug`. While this approach seems to not work anymore (as of 5.1.1),
  if you have trouble using `mspdebug`, you can perhaps try the `gdb_agent_console` 
  approach. This command should find the debugger and prepare for the connection. 
  If you happen to have more than one `gdb_agent_console` in your `PATH`, make 
  sure to use the correct one (located in `/opt/ti/gcc/bin`). You may need to 
  `chmod +x gdb_agent_console` if you get a permission denied error.

    ~~~
    $ gdb_agent_console /opt/ti/msp430/gcc/msp430.dat
    ~~~

* Run `msp430-elf-gdb`. You should give it the `elf` file as well so that it knows
  the symbols. 

    ~~~
    $ cd <build_folder>
    $ msp430-elf-gdb application/firmware-msp430f5529.elf 
    ... [GDB initialization output]
    (gdb) target remote :2000
    Remote debugging using :2000
    0x000044e4 in __crt0_start ()
    (gdb) 
    ~~~


* Ideally, `insight` should be able to run as well. Some obscure TI doc suggests the `GUI`, presumably `insight`, is supported on windows only.

* Some sample commands run on firmware that's built with TI's `driverlib`:

    ~~~
    (gdb) info address mclk_val
      Symbol "mclk_val" is static storage at address 0x2420.
    (gdb) info sym 0x2420
      mclk_val in section .noinit
    (gdb) info address UCS_getMCLK
      Symbol "UCS_getMCLK" is a function at address 0x4f50.
    (gdb) info sym 0x4f50
      UCS_getMCLK in section .text
    (gdb) c 
      Continuing.
    # Give it time to run the init code, then break with Ctrl+C
      ^C
      Program received signal SIGTRAP, Trace/breakpoint trap.
      0x000046b4 in USCI_A_UART_transmitData (baseAddress=1536, transmitData=97 'a')
	at <some path>/driverlib/MSP430F5xx_6xx/usci_a_uart.c:146
      146             while(!(HWREG8(baseAddress + OFS_UCAxIFG) & UCTXIFG))
    (gdb) call UCS_getMCLK()
    $4 = 24000000
    (gdb) print mclk_val
    $6 = 13824
    # This is likely the result of an overflow
    (gdb) print aclk_val
    $6 = 32768
    ~~~

* Loading a program into device RAM from msp430-elf-gdb is possible.

    ~~~
    (gdb) load
    Loading section .rodata, size 0x8e lma 0x4400
    Loading section .rodata2, size 0x50 lma 0x4490
    Loading section .data, size 0x4 lma 0x44e0
    Loading section .lowtext, size 0x66 lma 0x44e4
    Loading section .text, size 0x111c lma 0x454a
    Loading section __interrupt_vector_47, size 0x2 lma 0xffdc
    Loading section __interrupt_vector_57, size 0x2 lma 0xfff0
    Loading section __reset_vector, size 0x2 lma 0xfffe
    Start address 0x44e4, load size 4714
    Transfer rate: 4 KB/sec, 392 bytes/write.
    
    # load <filename> may also work
    # Reset the device by reconnecting to the target.
    # Note that this isn't equivalent to a power on reset. General RAM is not 
    # cleared. .bss may or may not be cleared (haven't checked).
    
    (gdb) target remote :55000
    A program is being debugged already.  Kill it? (y or n) y
    Remote debugging using :55000
    0x000044e4 in __crt0_start ()
    (gdb) 
    (gdb)
    ~~~
    
* `make` can, in principle, be run from within `gdb`. There are probably various other 
  constraints to run make within gdb, and the usual make from the correct build folder 
  (root) is probably a safer bet.
    
    ~~~
    (gdb) make
    ~~~

* For the sake of convenience, the various map files and symbol tables are 
  automatically generated by the `ebs CMAKE Platform` file, and can be found alongside
  the primary build outputs in their respective build folder.


Installing 64-bit libmsp430.so v3.13
------------------------------------

WARNING : Compiling libmsp430.so against recent boost versions is a nightmare. You might find it easier to go with a precompiled libmsp430.so or a binary distribution, or get an earlier version of boost. I suspect it works fine against upto atleast boost 1.62, and the official build is against boost 1.56. These instructions get the binary built against 1.66 and it seems to work, but YMMV.

* Get slac460y.zip from TI, containing MSP430.DLL v3.13.000.001 Open Source version, 
  Released 15/05/2018

    <http://www.ti.com/tool/MSPDS>

* According to the install docs, boost with BOOST_THREAD_PATCH is needed. Install
  libboost-thread-dev and hope for the best. Building boost itself is a pain. Version
  3.08 also requires libboost-filesystem. (Running apt-get update and upgrade first 
  is probably a good idea).

    ~~~
    $ sudo apt install libboost-thread-dev
    $ sudo apt install libboost-filesystem-dev
    $ sudo apt install libusb-1.0-0-dev libudev-dev
    ~~~

* The v3.11 version has the following additional dependencies, which don't seem to be 
  listed in the install docs but does cause failure during compile time. Maybe install
  them later on once compile fails if you have concerns about installing unnecessary 
  stuff.

    ~~~
    $ sudo apt install libboost-date-time-dev
    $ sudo apt install libboost-chrono-dev
    $ sudo apt install libboost-thread-dev
    ~~~

* For hidapi, required version is 0.8.0-rc1. Though Ubuntu 16.04 version is 
  also 0.8.0-rc, the makefile needs the .h and .o to be put into the source 
  tree. So obtain and build the sources instead of mucking around system hidapi.

    ~~~
    $ wget https://github.com/signal11/hidapi/archive/hidapi-0.8.0-rc1.zip
    $ unzip hidapi-0.8.0-rc1.ziz
    $ cd hidapi-0.8.0-rc1
    ~~~

* Compile with -fPIC for creating a 64-bit shared object. 

    ~~~
    $ ./bootstrap
    $ ./configure CFLAGS='-g -O2 -fPIC'
    $ make
    ~~~
    
* Get libmsp430 sources and extract

    ~~~
    $ unzip slac460y.zip -d MSPDebugStack
    $ cd MSPDebugStack
    ~~~
    
* Copy the necessary hidapi files to the MSPDebug ThirdParty folder. 
    - `hidapi/hidapi.h` to `ThirdPary/include` 
    - `libusb/hid.o` to `ThirdParty/lib64`

* Edit the Makefile to point to the correct hidapi object. 
    - Replace `HIDOBJ := $(LIBTHIRD)/hid-libusb.o` with `HIDOBJ := $(LIBTHIRD)/hid.o`

* The v3.11 version (and later) as shipped does not compile. This has to do with a 
  licensing issue that was very poorly handled by TI. The fastest way to make the 
  compile work is to ignore the licensing issue and link against the GPLv3 srecord 
  project. This can be done by editing `DLL430_v3/src/TI/DLL430/UpdateManagerFet.cpp`, 
  and uncomment the line 

  	~~~
  	//#define FPGA_UPDATE
  	~~~

* There are a number of namespace conflicts that arise from using a recent boost 
  version with a recent C++ stdlib. See <https://bugs.freebsd.org/bugzilla/show_bug.cgi?id=224094> for a discussion. Using the approaches described there, a patch for 
  slac460y.zip from TI, v3.13.000.001 Open Source, has been put together and can be 
  found alongside, see resources/patches/slac460y.fixes.patch`. You should be able to 
  apply this patch to a pristine extraction of slac460y.zip.  
    
* Run `make` as usual to generate a shared object file, and install the .so. The 
  STATIC=1 build fails with a problem linking against `boost-filesystems`, so remember 
  that the generated binary is linked against system boost and will need to be 
  recompiled if the boost version changes.

    ~~~
    $ make
    $ sudo make install
    ~~~

* `mspdebug` and `tilib` seem to have trouble locating the `libmsp430.so` binary. 
  One workaround is to add `export LD_PRELOAD="/usr/local/lib/libmsp430.so" to 
  `~/.bashrc` to make this work.

Installing python-msp430-tools and using the MSP430 USB BSL
-----------------------------------------------------------

MSP430s have built-in bootloaders on their ROM which can be used to write to 
their flash. The USB MSP430s, such as the MSP430F5529, around which a launchpad
is also available, make this bootloader available over a HID endpoint using the 
USB peripheral. 

The included Python firmware downloader in the USB Developers Pack doesn't 
seem to work, and doesn't actually seem to add much value even if it does. 
The firmware downloader tool is based on the open-source `python-msp430-tools`, 
which can be used directly.

The tools are available on PyPI at v0.8. 

    $ pip install python-msp430-tools

You can use the version from the repository if the version on pip doesn't work for you.

    $ sudo pip install -e bzr+lp:python-msp430-tools#egg=python-msp430-tools

Once installed, the tools can be used from the command line. Note that prior 
steps are needed to put the MSP430 into the BSL mode. The simplest way to do this
for the USB MSP430s is applying PUR during a reset. Refer to TI documentation for
other options and more detail. Writing to the device looks like :
    
    sudo python -m msp430.bsl5.hid -i elf -eErw application/firmware-msp430f5529.elf -PVv

   
Further details and command line options are available at 
<https://pythonhosted.org/python-msp430-tools/commandline_tools.html#msp430-bsl5>

Root access (`sudo`) is required on Ubuntu/Linux for the application to obtain
`hidraw` access to the USB device. There are probably some `udev` rules that can 
be installed to avoid the need for privilege escalation every time you want to 
write to the device.

^[To convert this file to `pdf`, use `pandoc README.md -o README.pdf`. See 
<http://johnmacfarlane.net/pandoc/README.html> for further information]
