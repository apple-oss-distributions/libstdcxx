##
# libstdcxx Makefile
##

# Project info
Project               = libstdcxx
UserType              = Developer
ToolType              = Libraries
Extra_Configure_Flags = --disable-multilib \
	--build $(BUILD)$(DARWIN_VERS) \
	--host `echo $$arch | $(TRANSLATE_ARCH)`-apple-darwin$(DARWIN_VERS) \
	--target `echo $$arch | $(TRANSLATE_ARCH)`-apple-darwin$(DARWIN_VERS)
GnuAfterInstall       = post-install install-plist
Environment	     += CXX_FOR_TARGET="$(CXX) -arch $$arch" \
			RAW_CXX_FOR_TARGET="$(CC) -arch $$arch -shared-libgcc \
				-nostdinc++" \
			CC_FOR_TARGET="$(CC) -arch $$arch" \
			GCC_FOR_TARGET="$(CC) -arch $$arch" \
			CONFIGURED_AS_FOR_TARGET="$(AS) -arch $$arch" \
			CONFIGURED_LD_FOR_TARGET="$(LD) -arch $$arch" \
			CONFIGURED_NM_FOR_TARGET="nm -arch $$arch" \
			CONFIGURED_AR_FOR_TARGET="$(AR)" \
			CONFIGURED_RANLIB_FOR_TARGET="ranlib" \
			OPT_LDFLAGS="-Wl,-dead_strip"


# It's a GNU Source project
include ./GNUSource.make

# Automatic Extract & Patch
AEP            = YES
AEP_Project    = gcc
AEP_Version    = 4.0.0
AEP_ProjVers   = $(AEP_Project)-$(AEP_Version)
AEP_Filename   = $(AEP_ProjVers).tar.bz2
AEP_ExtractDir = $(AEP_ProjVers)
# LUNA LOCAL begin custom patches
AEP_Patches    = tilde-in-pathnames.patch emergency-buffer-reduction.patch \
		 keymgr.patch testing-installed.patch align-natural-abi.patch \
		 export-control.patch cross-configury.patch eprintf.patch \
		 testsuite-4.0.1.patch \
		 libtool-jaguar.patch jaguar-semun.patch jaguar-abilimits.patch \
		 stdexcept_vis.patch testuite-06-03-10.patch fstream.patch \
		 luna-4672604.patch luna-4757063.patch
# LUNA LOCAL end custom patches

ifeq ($(suffix $(AEP_Filename)),.bz2)
AEP_ExtractOption = j
else
AEP_ExtractOption = z
endif

Install_Target = install

ifeq ($(RC_ProjectName),libstdcxx_Jaguar)
DARWIN_VERS	= 6
MACOSX_DEPLOYMENT_TARGET=10.2
SYSROOT		= -isysroot /Developer/SDKs/MacOSX10.2.8.internal.sdk
CC		:= /usr/bin/gcc $(SYSROOT)
CXX		:= /usr/bin/g++ $(SYSROOT)
Extra_Cxx_Flags	+= -DLIBSTDCXX_FOR_JAGUAR
SDKPFXs		= /Developer/SDKs/MacOSX10.2.8.sdk \
		  /Developer/SDKs/MacOSX10.2.8.internal.sdk
SDKEXCLUDE	=
else
ifeq ($(RC_ProjectName),libstdcxx_SUPanWheat)
DARWIN_VERS	= 7
MACOSX_DEPLOYMENT_TARGET=10.3
# The internal SDK doesn't have GCC 4 support, Radar 4301583.
SYSROOT		= -isysroot /Developer/SDKs/MacOSX10.3.9.sdk
CC		:= /usr/bin/gcc $(SYSROOT)
CXX		:= /usr/bin/g++ $(SYSROOT)
SDKPFXs		= /Developer/SDKs/MacOSX10.3.9.sdk \
		  /Developer/SDKs/MacOSX10.3.internal.sdk
SDKEXCLUDE	= \! -name \*.dylib
else
DARWIN_VERS	= 8
endif
endif


# Extract the source.
install_source::
ifeq ($(AEP),YES)
	$(TAR) -C $(SRCROOT) -$(AEP_ExtractOption)xf $(SRCROOT)/$(AEP_Filename)
	$(RMDIR) $(SRCROOT)/$(Project)
	$(MV) $(SRCROOT)/$(AEP_ExtractDir) $(SRCROOT)/$(Project)
	for deldir in libada libcpp libgfortran libjava libobjc zlib \
		      boehm-gc fastjar fixincludes intl ; do \
		$(RMDIR) $(SRCROOT)/$(Project)/$$deldir ; \
	done
	for delconfigdir in gcc ; do \
		$(RM) $(SRCROOT)/$(Project)/$$delconfigdir/configure ; \
	done
	for patchfile in $(AEP_Patches); do \
		cd $(SRCROOT)/$(Project) && \
		patch -p0 < $(SRCROOT)/patches/$$patchfile || exit 1 ;  \
	done
endif

# Rearrange the final destroot to be just the way we want it.
post-install:
	for arch64 in ppc64 x86_64 v6 ; do \
	  if [ -d $(DSTROOT)/usr/lib/$$arch64 ] ; then \
	    install_name_tool -id /usr/lib/libstdc++.6.dylib \
	      $(DSTROOT)/usr/lib/$$arch64/libstdc++.6.*.dylib && \
	    for f in `cd $(DSTROOT)/usr/lib/$$arch64 && echo *.{dylib,a}` ; do \
	      if [ ! -f $(DSTROOT)/usr/lib/$$f ] ; then \
		  mv $(DSTROOT)/usr/lib/$$arch64/$${f} $(DSTROOT)/usr/lib/$${f} ; \
	      elif [ ! -L $(DSTROOT)/usr/lib/$$arch64/$$f ] ; then \
		  lipo -create -output $(DSTROOT)/usr/lib/$${f}~ \
		    $(DSTROOT)/usr/lib/$${f} $(DSTROOT)/usr/lib/$$arch64/$${f} && \
		  mv $(DSTROOT)/usr/lib/$${f}~ $(DSTROOT)/usr/lib/$${f} || \
		  exit 1 ; \
	      fi ; \
	    done && \
	    $(RM) -r $(DSTROOT)/usr/lib/$$arch64 ; \
	  fi ; \
	done
	if [ -d $(DSTROOT)/usr/include/c++/4.0.0/armv6-apple-darwin$(DARWIN_VERS) ] && \
	   [ ! -d $(DSTROOT)/usr/include/c++/4.0.0/arm-apple-darwin$(DARWIN_VERS) ] ; then \
	  mv $(DSTROOT)/usr/include/c++/4.0.0/armv6-apple-darwin$(DARWIN_VERS) \
	     $(DSTROOT)/usr/include/c++/4.0.0/arm-apple-darwin$(DARWIN_VERS) ; \
	fi
	$(RM) $(DSTROOT)/usr/lib/*.la
	$(RM) $(DSTROOT)/usr/lib/libiberty.a
	$(RM) $(DSTROOT)/usr/lib/libstdc++.dylib
	mv $(DSTROOT)/usr/lib/libstdc++.a $(DSTROOT)/usr/lib/libstdc++-static.a
	nmedit -p $(DSTROOT)/usr/lib/*.a
	cp -Rp $(DSTROOT)/usr/lib/*.{a,dylib} $(SYMROOT)/
	strip -x $(DSTROOT)/usr/lib/*.dylib
	strip -X -S $(DSTROOT)/usr/lib/*.a
	if [ "x$(SDKPFXs)" != x ] ; then \
	  for i in $(SDKPFXs) ; do \
	    $(MKDIR) $(DSTROOT)/$i && \
	    (cd $(DSTROOT) && find usr $(SDKEXCLUDE) -print | \
	     cpio -pdm $(DSTROOT)/$$i ) || exit 1 ; \
	    if [ $(MACOSX_DEPLOYMENT_TARGET) == 10.3 ] ; then \
	      ln -s powerpc-apple-darwin7 \
	            $(DSTROOT)/$$i/usr/include/c++/4.0.0/powerpc-apple-darwin8 ; \
	    fi ; \
	  done ; \
	  $(RM) -r $(DSTROOT)/[^D]* ; \
	fi

OSV = $(DSTROOT)/usr/local/OpenSourceVersions
OSL = $(DSTROOT)/usr/local/OpenSourceLicenses

install-plist:
	$(MKDIR) $(OSV)
	$(INSTALL_FILE) $(SRCROOT)/$(Project).plist \
	   $(OSV)/$(RC_ProjectName).plist
	if [ "x$(SDKPFXs)" == x ] ; then \
	  $(MKDIR) $(OSL) && \
	  $(INSTALL_FILE) $(Sources)/COPYING $(OSL)/$(Project).txt || exit 1 ;\
	fi
