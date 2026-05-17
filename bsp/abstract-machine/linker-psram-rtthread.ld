ENTRY(_start)

MEMORY {
    flash (rx) : ORIGIN = _flash_start, LENGTH = 16M
    sram  (rwx): ORIGIN = _sram_start,  LENGTH = 8K
    psram (rwx): ORIGIN = _psram_start, LENGTH = 4M
}

SECTIONS {
    . = ORIGIN(flash);

    .boot : {
        KEEP(*(.boot))
    } > flash : boot

    .rodata : {
        *(EXCLUDE_FILE(*ssbl.o) .rodata*)
    } > flash : rodata

    . = ORIGIN(sram);

    .ssbl : {
        _ssbl_start = .;
        *ssbl.o(.text .text.* .rodata .rodata.* .data .data.* .sdata .sdata.*)
        *ssbl.o(.bss .bss.* .sbss .sbss.* .scommon)
        . = ALIGN(4);
        _ssbl_end = .;
    } > sram AT> flash : ssbl

    _ssbl_lma = LOADADDR(.ssbl);

    . = ORIGIN(psram);

    .text : {
        _text_start = .;
        *(EXCLUDE_FILE(*ssbl.o) .text*)
        _text_end = .;
    } > psram AT> flash : text

    _text_lma = LOADADDR(.text);

    .data.extra : {
        __fsymtab_start = .;
        KEEP(*(FSymTab))
        __fsymtab_end = .;
        . = ALIGN(8);
        __vsymtab_start = .;
        KEEP(*(VSymTab))
        __vsymtab_end = .;
        . = ALIGN(8);

        . = ALIGN(8);
        __rt_init_start = .;
        KEEP(*(SORT(.rti_fn*)))
        __rt_init_end = .;
        . = ALIGN(8);

        __rt_utest_tc_tab_start = .;
        KEEP(*(UtestTcTab))
        __rt_utest_tc_tab_end = .;

        . = ALIGN(8);
        __am_apps_data_start = .;
        *(__am_apps.data*)
        *(__am_apps.sdata*)
        __am_apps_data_end = .;
        . = ALIGN(8);
    } > psram AT> flash : data

    .data : {
        _data_start = .;
        *(EXCLUDE_FILE(*ssbl.o) .data*)
        *(EXCLUDE_FILE(*ssbl.o) .sdata*)
        _data_end = .;
    } > psram AT> flash : data

    _data_lma = LOADADDR(.data);

    .bss.extra : {
        . = ALIGN(8);
        __am_apps_bss_start = .;
        *(__am_apps.bss*)
        *(__am_apps.sbss*)
        *(__am_apps.scommon*)
        __am_apps_bss_end = .;
        . = ALIGN(8);
    } > psram

    .bss (NOLOAD) : {
        _bss_start = .;
        *(EXCLUDE_FILE(*ssbl.o) .bss*)
        *(EXCLUDE_FILE(*ssbl.o) .sbss*)
        *(EXCLUDE_FILE(*ssbl.o) .scommon)
        _bss_end = .;
    } > psram

    _heap_start = ALIGN(0x1000);
    _heap_end = ORIGIN(psram) + LENGTH(psram);
    _stack_top = ORIGIN(sram) + LENGTH(sram);
    _stack_pointer = _stack_top;

    end = .;
    _end = .;
}

PHDRS {
    boot   PT_LOAD;
    rodata PT_LOAD;
    ssbl   PT_LOAD;
    text   PT_LOAD;
    data   PT_LOAD;
}
