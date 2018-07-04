
Warning : Nothing here has been tested with actual hardware yet. In most cases, I've just checked that the compiler runs with no input files and spits out the usage instructions. This is a woefully inadequate test. So if you do use these instruction, well, let me know if they happen to work.


Toolchain Location
------------------

This is going to be a toolchain with a number of tools, most of which need manual installations. In order to try to maintain some degree of sanity, we're going to push as much as possible into a single folder which lives outside the usual folders. Consider the choice of permissions to give to these folders. The commands here expect you to give yourself ownership over the installed files. A more traditional approach would leave ownership to root, with read permissions set for the appropriate user / group. Whatever you decide, keep permissions in mind when you execute commands that copy files into that folder. 

    ~~~
    $ sudo mkdir -p /opt/parallax/propeller
    $ sudo chown -R [username]:[group] /opt/parallax
    $ mkdir /opt/parallax/propeller/openspin
    $ mkdir /opt/parallax/propeller/bin
    ~~~

We'll also add the bin folder to system `$PATH`, so that the tools are readily available. To do this, add the following line to `~/.bashrc`. If you ever need the propeller tools to disappear from system $PATH, remove or comment this line out and restart the shell. 

    ~~~
    export PATH="/opt/parallax/propeller/bin:$PATH"
    ~~~

Spin is a langauge designed specifically for Propeller by the same chap who designed the processor. While this toolchain should (hopefully) provide a full gcc toolchain capable of handling C and C++ code, it probably is a good idea to have a Spin toolchain available as well. 


OpenSpin
--------

See <https://forums.parallax.com/discussion/comment/1441567/#Comment_1441567>

> The official Spin tool for linux is called openspin. ...  It's a command line only tool. There are also 3rd party Spin compilers: bstc, homespun, and fastspin. All have Linux ports. fastspin differs from the others in that it produces native code rather than the standard interpreted Spin bytecode.

I don't yet know what the practical tradeoffs between these tools are. The official OpenSpin is what these instructions are for, though instructions for the other spin tools may be added as and when I find reason to try to install them. 

NOTE : The binary distribution from TeamCity used for the GCC installation includes OpenSpin as well, so it should not be necessary to install it separately. There are instructions to do so here, though, if you just want a spin tool or if you compile GCC from sources. Note that if you do install OpenSpin with these instructions and then install GCC from the TeamCity build with these instuctions, you will end up not having your own OpenSpin on the $PATH, since both create the `/opt/parallax/propeller/bin/openspin` file.

<https://github.com/parallaxinc/OpenSpin/releases>

Download the latest release from the link above and untar it somewhere. Run make to build the compiler. Note that the repository only explicitly lists GCC 4.6 and 4.8 as acceptable GCC versions, though it does say later versions should be fine. For the moment, we assume it compiles fine with system GCC (at the time of this writing 7.3.0-16ubuntu3).
  
    ~~~
    $ tar xvzf OpenSpin-1.00.78.tar.gz
    $ cd OpenSpin-1.00.78/
    $ make
    ~~~

This generates build files in a folder called `build`. We move these files into the toolchain folder we created earlier and create a symlink to the compiler binary to expose it on the $PATH.

    ~~~
    $ cd build
    $ mv * /opt/parallax/propeller/openspin
    $ ln -s /opt/parallax/propeller/openspin/openspin /opt/parallax/propeller/bin/openspin 
    ~~~

This should put openspin into path and allow it to be used directly.

    ~~~
    $ openspin
    ~~~

There is a bweir fork of OpenSpin. I'm not sure what it does differently. It seems to also do wildly different release numbering. <https://github.com/bweir/OpenSpin>


GCC Versions
------------

See again <https://forums.parallax.com/discussion/comment/1441567/#Comment_1441567>

> The "official" port of gcc to the propeller is gcc 4.6.1. There is also a beta port of gcc 6.0.0. ... Both work reasonably well, although the gcc 6.0.0 port is incompatible with the 4.6.1 port in some way that affects the Parallax educational libraries, and so it's never been officially adopted. Basically gcc 4.6.1 worked well enough for Parallax's purposes, so it's been frozen (which is why the repositories haven't been updated for a long time). The IDE for gcc 4.6.1 is called SimpleIDE.

There are two major propeller-gcc github repositories on github :

 - The official repository with only 4.6.1 <https://github.com/parallaxinc/propgcc> 
 - A repository owned by dbetz which seems to compile both 4.6.1 and 6.0.0 <https://github.com/dbetz/propeller-gcc>. This repository is the one used by the [propeller gcc docker images](https://forums.parallax.com/discussion/168418/building-propgcc-with-docker/p1) and possibly the one used by PropWare. (While PropWare links to the official repository, David Zemon, who made the docker images, also maintains PropWare. Also, there are GCC 6 builds there.) 

While I would typically stick with the official repository, given that the official repository hasn't changed in over 2 years, it _might_ be a relatively safe bet that the dbetz fork is stable enough for 4.6.1. It also should make it less of a hassle to switch to GCC 6.0.0 if necessary. 

The following instructions install GCC using the binary tarballs linked to within PropWare, presumably the TeamCity version. It's probably not worth the trouble to compile it from source.

GCC 4.6.1 ("Official")
----------------------

Download the GCC4 binary from <https://david.zemon.name/PropWare/#/related-links>. Untar it somewhere. You will see that there is a parallax folder created, which contains the toolchain entirely within it. We're just going to move the toolchain wholesale into our toolchain folder. If any of those folders existed previously, such as a bin folder from an OpenSpin install, make sure to move the contents of that folder to the correct place as well. These should be immediately apparant by files left in the source tree after the first move is completed.

    ~~~
    $ tar xvzf propellergcc-alpha_v1_9_0-gcc4-linux-x64.tar.gz
    $ mv parallax/* /opt/parallax/propeller/
    $ mv parallax/bin/* /opt/parallax/propeller/bin/
    ~~~

At the end of this, you should have the gcc (v4.6.1) toolchain with the propeller-elf- prefix installed and in your $PATH. The following programs will also now exist on your path :
    - openspin
    - gdbstub
    - propeller-load
    - spin2cpp
    - spinsim

These instructions would probably work as is for the GCC 6 build as well, though I haven't check. Note that having both GCC 4 and GCC 6 installed simultaneously is probably not a good idea, and you will have to play around with $PATH to switch between them, besides having to make sure they are both installed into separate folders since the executable names are the same.

