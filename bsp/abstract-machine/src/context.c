#include <am.h>
#include <klib.h>
#include <rtthread.h>

// NOTE: STACK_SIZE defines the minimum stack size required by the context-switch
// mechanism. Every thread that uses rt_hw_stack_init() (i.e., ALL RT-Thread threads
// on this platform) MUST have a stack >= STACK_SIZE + sizeof(tentry_wrapper_args)
// + sizeof(Context). If a thread's stack is smaller, the HardwarePCB will overflow
// the allocated region and corrupt adjacent memory (typically the tentry_wrapper_args
// struct at the stack top, causing tentry_wrapper to jump to a garbage address).
#define STACK_SIZE (4096 * 2)
typedef union {
  uint8_t stack[STACK_SIZE];
  struct { Context *cp; };
} HardwarePCB;

struct tentry_wrapper_args {
  void *tentry;
  void *parameter;
  void *texit;
};

typedef void (*tentry_func_t)(void *parameter);
typedef void (*texit_func_t)(void);

struct context_switch_info {
  rt_ubase_t from;
  rt_ubase_t to;
};

static struct context_switch_info switch_info;
static struct context_switch_info *pending_switch = NULL;


static Context* ev_handler(Event e, Context *c) {
  rt_thread_t cur_thread = rt_thread_self();
  struct context_switch_info *info = pending_switch;
  switch (e.event) {
    case EVENT_YIELD:
      if (info == NULL) {
        cur_thread->sp = (void *)c;
        break;
      }
      if (info->from) {
        *(Context **)info->from = c;
      }
      if (info->to) {
        Context *to_ctx = *(Context **)info->to;
        pending_switch = NULL;
        return to_ctx;
      }
      pending_switch = NULL;
      break;
    default: printf("Unhandled event ID = %d\n", e.event); assert(0);
  }
  return c;
}

void __am_cte_init() {
  cte_init(ev_handler);
}

void rt_hw_context_switch_to(rt_ubase_t to) {
  switch_info.from = (rt_ubase_t) NULL;
  switch_info.to = (rt_ubase_t) to;
  pending_switch = &switch_info;

  yield();
  pending_switch = NULL;
}

void rt_hw_context_switch(rt_ubase_t from, rt_ubase_t to) {
  switch_info.from = (rt_ubase_t) from;
  switch_info.to = (rt_ubase_t) to;
  pending_switch = &switch_info;

  yield();
  pending_switch = NULL;
}

void rt_hw_context_switch_interrupt(void *context, rt_ubase_t from, rt_ubase_t to, struct rt_thread *to_thread) {
  assert(0); // TODO: Not implemented yet.
}

static void tentry_wrapper(void *args) {
  struct tentry_wrapper_args *twargs = (struct tentry_wrapper_args *) args;
  tentry_func_t tentry = (tentry_func_t) twargs->tentry;
  void *parameter = twargs->parameter;
  texit_func_t texit = (texit_func_t) twargs->texit;

  // 调用 tentry 函数.
  tentry(parameter);

  // 若 tentry 函数返回, 则调用 texit 函数, 该函数保证不会返回.
  texit();
}

rt_uint8_t *rt_hw_stack_init(void *tentry, void *parameter, rt_uint8_t *stack_addr, void *texit) {
  uintptr_t aligned_stack_addr = RT_ALIGN_DOWN((uintptr_t) stack_addr, sizeof(uintptr_t));
  void *stack_end = (void *) aligned_stack_addr;
  // 为了传递 tentry, parameter, texit 参数, 需在栈底后面先行分配内存
  // 以存放这几个参数.
  stack_end -= sizeof(struct tentry_wrapper_args);
  struct tentry_wrapper_args *args = (struct tentry_wrapper_args *) stack_end;
  args->tentry = tentry;
  args->parameter = parameter;
  args->texit = texit;

  // 接下来再分配栈空间并生成上下文信息.
  void *stack_start = stack_end - sizeof(HardwarePCB);
  Area stack_area = {
    .start = stack_start,
    .end   = stack_end
  };
  Context *ctx = kcontext(stack_area, tentry_wrapper, args);
  return (rt_uint8_t *) ctx;
}
