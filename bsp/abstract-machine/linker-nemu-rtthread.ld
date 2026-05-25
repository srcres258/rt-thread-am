ENTRY(_start)
PHDRS { text PT_LOAD; data PT_LOAD; }

SECTIONS {
  /* ====== 平坦内存布局（与 scripts/linker.ld 一致） ====== */
  . = _pmem_start + _entry_offset;

  .text : {
    *(entry)
    *(.text*)
  } : text
  etext = .;
  _etext = .;

  .rodata : {
    *(.rodata*)
  }

  /* ====== RT-Thread 专用数据段（原 extra.ld INSERT BEFORE .data） ====== */
  .data.extra : {
    /* finsh shell 符号表 */
    __fsymtab_start = .;
    KEEP(*(FSymTab))
    __fsymtab_end = .;
    . = ALIGN(8);
    __vsymtab_start = .;
    KEEP(*(VSymTab))
    __vsymtab_end = .;
    . = ALIGN(8);

    /* 组件初始化表 */
    . = ALIGN(8);
    __rt_init_start = .;
    KEEP(*(SORT(.rti_fn*)))
    __rt_init_end = .;
    . = ALIGN(8);

    /* 单元测试表 */
    __rt_utest_tc_tab_start = .;
    KEEP(*(UtestTcTab))
    __rt_utest_tc_tab_end = .;

    /* AM apps 嵌入数据 */
    . = ALIGN(8);
    __am_apps_data_start = .;
    *(__am_apps.data*)
    *(__am_apps.sdata*)
    __am_apps_data_end = .;
    . = ALIGN(8);
  } : data

  /* ====== 标准 .data 段（原 scripts/linker.ld） ====== */
  .data : {
    *(.data*)
  } : data
  edata = .;
  _data = .;

  /* ====== AM apps BSS 段（原 extra.ld INSERT BEFORE .bss） ====== */
  .bss.extra : {
    . = ALIGN(8);
    __am_apps_bss_start = .;
    *(__am_apps.bss*)
    *(__am_apps.sbss*)
    *(__am_apps.scommon*)
    __am_apps_bss_end = .;
    . = ALIGN(8);
  }

  /* ====== 标准 .bss 段（原 scripts/linker.ld） ====== */
  .bss : {
    _bss_start = .;
    *(.bss*)
    *(.sbss*)
    *(.scommon)
  }

  /* ====== 堆栈布局（与 scripts/linker.ld 一致） ====== */
  _stack_top = ALIGN(0x1000);
  . = _stack_top + 0x8000;
  _stack_pointer = .;
  end = .;
  _end = .;
  _heap_start = ALIGN(0x1000);
}
