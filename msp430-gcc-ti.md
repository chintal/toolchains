
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
    $ chmod a+x msp430-gcc-full-linux-installer-4.1.0.0.run
    $ sudo ./msp430-gcc-full-linux-installer-4.1.0.0.run
    ~~~
    
* Install the toolchain. Recommended location is `/opt/ti/msp430/gcc` unless you 
  have a good reason to install it elsewhere.

* Use the `toolchain-msp430-gcc-ti.cmake` toolchain file for cmake. The system
  specific changes that may need to be made are : 
    - `MSP430_TI_COMPILER_FOLDER` : Path of TI GCC installation
    - `mspdebug` location etc. should be crosschecked, since TI gcc installation
      does not install `mspdebug`
    - Set the correct `CMAKE_MODULE_PATH` (to your toolchains folder) so that 
      cmake can find toolchains/Platforms.

* Add the toolchain to your PATH by appending the following to `~/.bashrc`:

    ~~~
    export PATH="/opt/ti/msp430/gcc/bin:${PATH}"
    ~~~


Debugging using the LP5529 on-board device:
-------------------------------------------

* Program the device as usual by `make install` or `make firmware-<device>-load`.

* Run `gdb_agent_console`, which should find the debugger and prepare for the 
  connection. If you happen to have more than one `gdb_agent_console` in your
  `PATH`, make sure to use the correct one (located in `/opt/ti/gcc/bin`)

    ~~~
    $ gdb_agent_console /opt/ti/msp430/gcc/msp430.dat
    ~~~

* Run `msp430-elf-gdb`. You should give it the `elf` file as well so that it knows
  the symbols. 

    ~~~
    $ cd <build_folder>
    $ msp430-elf-gdb application/firmware-msp430f5529.elf 
    ... [GDB initialization output]
    (gdb) target remote :55000
    ... [Wait for firmware update]
    (gdb) target remote :55000 
    Remote debugging using :55000
    0x000044e4 in __crt0_start ()
    (gdb) 
    ~~~

* `gdb` throws some `python` errors during initialization. It seems to work fine anyway, 
  though at some point they should be looked into. 

* Ideally, `insight` should be able to run as well. The python errors might be related. 
  Some TI docs suggest the `GUI`, presumably `insight`, is supported on windows only.

* Firmware issue : `mspdebug` and `msp430-elf-gdb` seem to require different `ezFET`
  firmware versions. This is fairly problematic, resulting in the need to reflash the 
  programmer when switching between programming and debugging sessions. Not only is this
  painfully slow, constantly reflashing the device is likely to reduce it's life. A way to 
  program using `msp430-elf-gdb` would probably be nicer. For now, perhaps use the 
  debugger only when absolutely necessary, and program into RAM during most of debugging
  using `msp430-elf-gdb` instead of by `make install`, `make firmware-load`, etc which use
  `mspdebug`. Another alternative is to roll your own `libmsp430.so` from TI sources. See 
  the section `Installing 64-bit libmsp430.so v3` for instructions to build a 64-bit 
  version of `libmsp430.so` from TI's sources. Using this version of the driver allows you 
  to use the same firmware for both `mspdebug` and `msp430-elf-gdb`.

* The ability to `detach` and let the process go on isn't there, or atleast isn't 
  immediately apparant. On detach, the target seems to be held in reset until power
  is cycled. There are ways to do this with `mspdebug`, so an option could be to let
  it die and then respawn it using `mspdebug`. ~~Beware of the aforementioned firmware 
  issue.~~ Make sure to use the new version of the firmware to avoid having to upgrade 
  firmware on each switch.

    ~~~
    $ gdb_agent_console /opt/ti/gcc/msp430.dat 
    Successfully configured /opt/ti/gcc/msp430.dat
    CPU Name             Port
    --------             ----
    MSP430              :55000

    Starting all cores
    CPU Name             Status
    --------             ------
    MSP430               Waiting for client
    MSP430               Client connected...Connecting to Target
    Found USB FET at ttyACM0
    Target connected...Starting server
    MSP430               Client disconnected...Stopping server
    Disconnecting from Target
    MSP430               Waiting for client
    ^C
    $ mspdebug -n tilib --allow-fw-update "run"
    ~~~

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
  automatically generated by the `CMAKE` `Platform` file, and can be found alongside
  the primary build outputs in their respective build folder.


Installing 64-bit libmsp430.so v3.8
-----------------------------------

* Get slac460r.zip from TI, containing MSP430.DLLv3.08.000.002 Open Source version, 
  Released 02/24/2016

    <http://processors.wiki.ti.com/index.php/MSPDS_Open_Source_Package>
    

* According to the install docs, boost with BOOST_THREAD_PATCH is needed. Install
  libboost-thread-dev and hope for the best. Building boost itself is a pain. Version
  3.08 also requires libboost-filesystem. (Running apt-get update and upgrade first 
  is probably a good idea).

    ~~~
    $ sudo aptitude install libboost-thread-dev
    $ sudo aptitude install libboost-filesystem-dev
    $ sudo aptitude install libusb-1.0-0-dev libudev-dev
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
    $ unzip slac460k.zip -d MSPDebugStack
    $ cd MSPDebugStack
    ~~~
    
* Copy the necessary files to the MSPDebug ThirdParty folder. 
    - `hidapi/hidapi.h` to `ThirdPary/include` 
    - `libusb/hid.o` to `ThirdParty/lib64`

* Edit the Makefile to point to the correct hidapi object. 
    - Replace `HIDOBJ := $(LIBTHIRD)/hid-libusb.o` with `HIDOBJ := $(LIBTHIRD)/hid.o`
    
* Run `make` as usual to generate a shared object file, and install the .so. The 
  STATIC=1 build fails with a problem linking against boot-filesystems, so remember 
  that the generated binary is linked against system boost and will need to be 
  recompiled if the boost version changes.

    ~~~
    $ make
    $ cp /usr/lib/libmsp430.so libmsp430.so.bak
    $ sudo cp libmsp430.so /usr/lib/
    ~~~

Installing python-msp430-tools and using the MSP430 USB BSL
-----------------------------------------------------------

MSP430s hve built-in bootloaders on their ROM which can be used to write to 
their flash. The USB MSP430s, such as the msp430f5529, around which a launchpad
is also available, make this bootloader available over a HID endpoint using the 
USB peripheral. 

The included Python firmware downloader in the USB Developers Pack doesn't 
seem to work, and doesn't actually seem to add much value even if it does. 
The firmware downloader tool is based on the open-source (and unmaintained) 
`python-msp430-tools`, which can be used directly.

The tools are available on PyPI at v0.6, though the setup script doesn't 
actually work. v0.7, avaialble from the repository, should be installed instead.

    sudo pip install -e bzr+lp:python-msp430-tools#egg=python-msp430-tools

Once installed, the tools can be used from the command line. Note that prior 
steps are needed to put the MSP430 into the BSL mode. The simplest way to do this
for the USB MSP430s is applying PUR during a reset. Refer to TI documentation for
other options and more detail. Writing to the device looks like :
    
    sudo python -m msp430.bsl5.hid -i elf -eErw application/firmware-msp430f5529.elf -PVv
    
Further details and command line options are available at 
<https://pythonhosted.org/python-msp430-tools/commandline_tools.html#msp430-bsl5>

Root access (`sudo`) is required on Ubuntu/Linux for the application to obtain
hidraw access to the USB device. There are probably some `udev` rules that can 
be installed to avoid the need for previlege escalation every time you want to 
write to the device.

^[To convert this file to `pdf`, use `pandoc README.md -o README.pdf`. See 
<http://johnmacfarlane.net/pandoc/README.html> for further information]
