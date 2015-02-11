
MSP430-GCC-TI Toolchain
=======================

The TI GCC (aka "msp430-gcc-opensource", aka "redhat-gcc for msp430") is newer 
than the GCC included with various mspgcc versions. Having the uC manufacturer
actively support the compiler and toolchain is usually a good thing. Presumably, 
it should also provide better support for TI's `driverlib` and hopefully for TI's 
`USP-API`. For these reasons, using the TI msp430-gcc-opensource toolchain is the 
preferred way for MSP430 development.

Installing the MSP430-GCC-TI toolchain
--------------------------------------

* Download TI GCC installer including support packages from the TI website
  <http://www.ti.com/tool/msp430-gcc-opensource>

* Make the file executable and run the installer. Run as root to be able to 
  install to system folders (installing to /opt)
    
    ~~~
    $ chmod a+x msp430-gcc-full-linux-installer-3.2.2.0.run
    $ sudo ./msp430-gcc-full-linux-installer-3.2.2.0.run
    ~~~
    
* Install the toolchain. Recommended location is `/opt/ti/gcc` unless there 
  is a good reason to install it elsewhere.

* Use the `toolchain-msp430-gcc-ti.cmake` toolchain file for cmake. The system
  specific changes that may need to be made are : 
    - `MSP430_TI_COMPILER_FOLDER` : Path of TI GCC installation
    - `mspdebug` location etc. should be crosschecked, since TI gcc installation
      does not install `mspdebug`

* Add the toolchain to your PATH by appending the following to `~/.bashrc`:

    ~~~
    export PATH="/opt/ti/gcc/bin:${PATH}"
    ~~~


Debugging using the LP5529 on-board device:
-------------------------------------------

* Program the device as usual by `make install` or `make firmware-<device>-load`.

* Run `gdb_agent_console`, which should find the debugger and prepare for the 
  connection. If you happen to have more than one `gdb_agent_console` in your
  `PATH`, make sure to use the correct one (located in `/opt/ti/gcc/bin`)

    ~~~
    $ gdb_agent_console /opt/ti/gcc/msp430.dat
    ~~~

* Run `msp430-elf-gdb`. You should give it the `elf` file as well so that it knows
  the symbols. 

    ~~~
    $ cd <build_folder>/application/
    $ msp430-elf-gdb firmware-msp430f5529.elf 
    ... [GDB initialization output]
    (gdb) target remote :55000
    ... [Wait for firmware update]
    (gdb) target remote :55000
      Remote debugging using :55000
      _start () at /opt/redhat/msp430-14r1-98/sources/tools/libgloss/msp430/crt0.S:36
      36      /opt/redhat/msp430-14r1-98/sources/tools/libgloss/msp430/crt0.S: No such file or directory.
    (gdb) 
    ~~~

* `gdb` throws various not recognized errors (specifically `timeout`), as well as some 
  scary `python` errors during initialization. It seems to work fine anyway, though at 
  some point they should be looked into. 

* Ideally, `insight` should be able to run as well. The python errors seem to be the
  blocking issue there. Some TI docs suggest the `GUI`, presumably `insight`, is supported
  on windows only.

* **Firmware issue** : `mspdebug` and `msp430-elf-gdb` seem to require different `ezFET`
  firmware versions. This is fairly problematic, resulting in the need to reflash the 
  programmer when switching between programming and debugging sessions. Not only is this
  painfully slow, constantly reflashing the device is likely to reduce it's life.A way to 
  program using `msp430-elf-gdb` would probably be a better bet. For now, perhaps use the 
  debugger only when absolutely necessary, and program into RAM during most of debugging
  using `msp430-elf-gdb` instead of by `make install`, `make firmware-load`, etc which use
  `mspdebug`. 

* The ability to `detach` and let the process go on isn't there, or atleast isn't 
  immediately apparant. On detach, the target seems to be held in reset until power
  is cycled. There are ways to do this with `mspdebug`, so an option could be to let
  it die and then respawn it using `mspdebug`. Beware of the aforementioned firmware 
  issue.
  
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
      Loading section .data, size 0x6 lma 0x2400
      Loading section .rodata, size 0x3c lma 0x4400
      Loading section .lowtext, size 0x5e lma 0x443c
      Loading section .text, size 0x1004 lma 0x449a
      Loading section __reset_vector, size 0x2 lma 0xfffe
      Start address 0x443c, load size 4262
      Reading symbols from <some path>/firmware-msp430f5529.elf...done.
      Transfer rate: 1 KB/sec, 473 bytes/write.
    
    # load <filename> may also work
    # Reset the device by reconnecting to the target.
    
    (gdb) target remote :55000
    A program is being debugged already.  Kill it? (y or n) y
    Remote debugging using :55000
    _start () at /opt/redhat/msp430-14r1-98/sources/tools/libgloss/msp430/crt0.S:36
    36      /opt/redhat/msp430-14r1-98/sources/tools/libgloss/msp430/crt0.S: No such file or directory.
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



^[To convert this file to `pdf`, use `pandoc README.md -o README.pdf`. See 
<http://johnmacfarlane.net/pandoc/README.html> for further information]

