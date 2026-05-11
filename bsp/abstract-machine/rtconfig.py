import os

# Detect AM's target architecture from environment variable
_AM_ARCH = os.getenv('ARCH', '')

# toolchains options (CPU/ARCH for SCons libcpu discovery;
# actual compilation flags come from AM's build system)
CPU        = 'virt64'
ARCH       = 'risc-v'
CROSS_TOOL = 'gcc'

RTT_ROOT = os.getenv('RTT_ROOT') or os.path.join(os.getcwd(), '..', '..')

if os.getenv('RTT_CC'):
    CROSS_TOOL = os.getenv('RTT_CC')

if  CROSS_TOOL == 'gcc':
    PLATFORM    = 'gcc'
    EXEC_PATH   = r'/usr/bin'
else:
    print('Please make sure your toolchains is GNU GCC!')
    exit(0)

if os.getenv('RTT_EXEC_PATH'):
    EXEC_PATH = os.getenv('RTT_EXEC_PATH')

BUILD = 'debug'

if PLATFORM == 'gcc':
    # toolchains
    # Select correct cross-compiler prefix:
    # For RISC-V targets, use 'riscv64-unknown-linux-gnu-' (matches AM's riscv.mk).
    # This toolchain can target both RV64 and RV32E via -march/-mabi flags.
    if _AM_ARCH.startswith('riscv'):
        PREFIX = os.getenv('RTT_CC_PREFIX') or 'riscv64-unknown-linux-gnu-'
    else:
        PREFIX = os.getenv('RTT_CC_PREFIX') or 'riscv64-linux-gnu-'

    CC      = PREFIX + 'gcc'
    CXX     = PREFIX + 'g++'
    AS      = PREFIX + 'gcc'
    AR      = PREFIX + 'ar'
    LINK    = PREFIX + 'gcc'
    TARGET_EXT = 'elf'
    SIZE    = PREFIX + 'size'
    OBJDUMP = PREFIX + 'objdump'
    OBJCPY  = PREFIX + 'objcopy'

    # Select march/mabi based on the RISC-V variant
    if _AM_ARCH.startswith('riscv32e'):
        # RV32E: 32-bit embedded, 16 GPRs, with Zicsr extension
        DEVICE = ' -mcmodel=medany -march=rv32e_zicsr -mabi=ilp32e '
    elif _AM_ARCH.startswith('riscv64'):
        DEVICE = ' -mcmodel=medany -march=rv64imac -mabi=lp64 '
    elif _AM_ARCH.startswith('riscv32'):
        DEVICE = ' -mcmodel=medany -march=rv32imac_zicsr -mabi=ilp32 '
    else:
        # Default: RV64 (native / unknown platforms)
        DEVICE = ' -mcmodel=medany -march=rv64imac -mabi=lp64 '

    CFLAGS  = DEVICE + '-ffreestanding -flax-vector-conversions -Wno-cpp -fno-common -ffunction-sections -fdata-sections -fstrict-volatile-bitfields -fdiagnostics-color=always'
    AFLAGS  = ' -c' + DEVICE + ' -x assembler-with-cpp -D__ASSEMBLY__ '
    LFLAGS  = DEVICE + ' -nostartfiles -Wl,--gc-sections,-Map=rtthread.map,-cref,-u,_start -T link.lds' + ' -lgcc -static'
    CPATH   = ''
    LPATH   = ''

    if BUILD == 'debug':
        CFLAGS += ' -O0 -ggdb -fvar-tracking '
        AFLAGS += ' -ggdb'
    else:
        CFLAGS += ' -O2 -Os'

    CXXFLAGS = CFLAGS

DUMP_ACTION = OBJDUMP + ' -D -S $TARGET > rtthread.asm\n'
POST_ACTION = OBJCPY + ' -O binary $TARGET rtthread.bin\n' + SIZE + ' $TARGET \n'
