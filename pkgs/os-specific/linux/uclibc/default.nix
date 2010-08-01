{stdenv, fetchurl, linuxHeaders, libiconv, cross ? null, gccCross ? null}:

assert stdenv.isLinux;
assert cross != null -> gccCross != null;

let
    enableArmEABI = (cross == null && stdenv.platform.kernelArch == "arm")
      || (cross != null && cross.arch == "arm");

    configArmEABI = if enableArmEABI then
        ''-e 's/.*CONFIG_ARM_OABI.*//' \
        -e 's/.*CONFIG_ARM_EABI.*/CONFIG_ARM_EABI=y/' '' else "";

    enableBigEndian = (cross != null && cross.bigEndian);
    
    configBigEndian = if enableBigEndian then ""
      else
        ''-e 's/.*ARCH_BIG_ENDIAN.*/#ARCH_BIG_ENDIAN=y/' \
        -e 's/.*ARCH_WANTS_BIG_ENDIAN.*/#ARCH_WANTS_BIG_ENDIAN=y/' \
        -e 's/.*ARCH_WANTS_LITTLE_ENDIAN.*/ARCH_WANTS_LITTLE_ENDIAN=y/' '';

    archMakeFlag = if (cross != null) then "ARCH=${cross.arch}" else "";
    crossMakeFlag = if (cross != null) then "CROSS=${cross.config}-" else "";
in
stdenv.mkDerivation {
  name = "uclibc-0.9.30.3" + stdenv.lib.optionalString (cross != null)
    ("-" + cross.config);

  src = fetchurl {
    url = http://www.uclibc.org/downloads/uClibc-0.9.30.3.tar.bz2;
    sha256 = "0f1fpdwampbw7pf79i64ipj0azk4kbc9wl81ynlp19p92k4klz0h";
  };

  # 'ftw' needed to build acl, a coreutils dependency
  configurePhase = ''
    make defconfig ${archMakeFlag}
    sed -e s@/usr/include@${linuxHeaders}/include@ \
      -e 's@^RUNTIME_PREFIX.*@RUNTIME_PREFIX="/"@' \
      -e 's@^DEVEL_PREFIX.*@DEVEL_PREFIX="/"@' \
      -e 's@.*UCLIBC_HAS_WCHAR.*@UCLIBC_HAS_WCHAR=y@' \
      -e 's@.*UCLIBC_HAS_FTW.*@UCLIBC_HAS_FTW=y@' \
      -e 's@.*UCLIBC_HAS_RPC.*@UCLIBC_HAS_RPC=y@' \
      -e 's@.*DO_C99_MATH.*@DO_C99_MATH=y@' \
      -e 's@.*UCLIBC_HAS_PROGRAM_INVOCATION_NAME.*@UCLIBC_HAS_PROGRAM_INVOCATION_NAME=y@' \
      -e 's@.*CONFIG_MIPS_ISA_1.*@#CONFIG_MIPS_ISA_1=y@' \
      -e 's@.*CONFIG_MIPS_ISA_3.*@CONFIG_MIPS_ISA_3=y@' \
      -e 's@.*CONFIG_MIPS_O32_ABI.*@#CONFIG_MIPS_O32_ABI=y@' \
      -e 's@.*CONFIG_MIPS_N32_ABI.*@CONFIG_MIPS_N32_ABI=y@' \
      ${configArmEABI} \
      ${configBigEndian} \
      -i .config
    make oldconfig
  '';

  # Cross stripping hurts.
  dontStrip = if (cross != null) then true else false;

  makeFlags = [ crossMakeFlag "VERBOSE=1" ];

  buildInputs = stdenv.lib.optional (gccCross != null) gccCross;

  installPhase = ''
    mkdir -p $out
    make PREFIX=$out VERBOSE=1 install ${crossMakeFlag}
    (cd $out/include && ln -s $(ls -d ${linuxHeaders}/include/* | grep -v "scsi$") .)
    sed -i s@/lib/@$out/lib/@g $out/lib/libc.so
  '';

  passthru = {
    # Derivations may check for the existance of this attribute, to know what to link to.
    inherit libiconv;
  };
  
  meta = {
    homepage = http://www.uclibc.org/;
    description = "A small implementation of the C library";
    license = "LGPLv2";
  };
}
