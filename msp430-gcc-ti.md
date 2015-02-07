
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

^[To convert this file to `pdf`, use `pandoc README.md -o README.pdf`. See 
<http://johnmacfarlane.net/pandoc/README.html> for further information]

