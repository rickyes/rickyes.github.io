---
title: 从 unref 看事件循环
date: 2020-03-25 23:02:31
tags: [timer,libuv,node.js]
categories: 
- libuv
---

### 描述

引用 `nodejs.cn` 的描述

> 调用时，活动的 `Timeout` 对象不需要 `Node.js` 事件循环保持活动状态。 如果没有其他活动保持事件循环运行，则进程可以在调用 `Timeout` 对象的回调之前退出。 多次调用 `timeout.unref()` 将无效。
调用 `timeout.unref()` 会创建一个内部定时器，它将唤醒 `Node.js` 事件循环。 创建太多这些定时器可能会对 `Node.js` 应用程序的性能产生负面影响。

总结的作用就是：`timer.unref` 标记的句柄事件，当进程中再无存活的事件，此时的 `timer` 句柄不会阻止进程退出。

<!-- more -->

### 示例

先看看没有使用 `unref` 标记的定时器实现：

``` js
console.log('a');

const timeout = setTimeout(() => {
  console.log('c');
}, 3000);

console.log('b');
```

执行上面代码，依次打印 `a, b` 后等待 `3s` 左右，打印 `c` 之后没有新的事件进程才会退出。使用 `unref` 标记后：

``` js
console.log('a');

const timeout = setTimeout(() => {
  console.log('c');
}, 3000);
timeout.unref();

console.log('b');
```

依次打印 `a, b` 后进程直接退出，`timeout` 句柄并没有阻止进程的退出。

### 引用计数

上面的例子 `timeout` 回调函数其实是已经推进了事件循环当中，不过为什么不会等待事件循环执行结束才退出进程呢？这时候引入了一个 `引用计数` 的概念，可以简单理解为当一个新的事件加入事件循环的队列中时，`引用计数` 就会 `+1` ，当执行完事件后，`引用计数` 就会 `-1`，直到没有新的事件进来，`引用计数` 等于 `0` 的时候进程退出。`unref` 调用后，`引用计数` 会 `-1`。

使用上面的规则对 `示例` 里的例子进行解析：

![unref](http://cdn.zhoumq.cn/unref.jpg)

当执行到 `setTimeout` 时，将回调函数推进事件循环，`引用计数 +1`，执行 `timeout.unref()` 时 `引用计数 -1`， `引用计数` 为 `0`，后面的代码也没有新的事件加入循环，执行文件末尾后进程退出。

### `node` 包装层

> 基于 Node.js v14.0.0-pre 版本

在 `node.js` 里，`setTimeout` 函数被挂载到运行时上下文中的 `global` 对象上，具体的实现代码在 `node/lib/timer.js` 中：

``` js

const {
  Timeout,
  // ...
} = require('internal/timers');

// ...

function setTimeout(callback, after, arg1, arg2, arg3) {
  if (typeof callback !== 'function') {
    throw new ERR_INVALID_CALLBACK(callback);
  }

  // ...

  const timeout = new Timeout(callback, after, args, false, true);
  insert(timeout, timeout._idleTimeout);

  return timeout;
}
```

可以看到执行 `setTimeout` 是返回了 `Timeout` 的实例，`Timeout` 里的实现如下：

``` js

const {
  toggleTimerRef,
} = internalBinding('timers');

let refCount = 0;

function incRefCount() {
  // 2. 引用计数 + 1, 如果是从 0 位开始 + 1，调用 c++ 层函数 toggleTimerRef 传值 true
  if (refCount++ === 0)
    toggleTimerRef(true);
}

function decRefCount() {
  // 4. 引用计数 - 1, 如果是相减的结果为 0，调用 c++ 层函数 toggleTimerRef 传值 false
  if (--refCount === 0)
    toggleTimerRef(false);
}

function Timeout(callback, after, args, isRepeat, isRefed) {

  // ...

  this._destroyed = false;

  // 1. 是否标记引用, 调用引用计数 + 1
  if (isRefed)
    incRefCount();
  this[kRefed] = isRefed;
}

Timeout.prototype.unref = function() {
  // 3. 已标记引用且未销毁实例，调用引用计数 - 1
  if (this[kRefed]) {
    this[kRefed] = false;
    if (!this._destroyed)
      decRefCount();
  }
  return this;
};
```

实例化 `Timeout` 时标记引用，全局的引用计数 + 1，并调用 c++ 层函数 `toggleTimerRef` 传值 true，再看看 c++ 层的封装：

``` cpp
// src/timer.cc
#include "env-inl.h"

// ...

void ToggleTimerRef(const FunctionCallbackInfo<Value>& args) {
  Environment::GetCurrent(args)->ToggleTimerRef(args[0]->IsTrue());
}

// src/env-inl.h

#include "env.h"

inline Environment* Environment::GetCurrent(const v8::FunctionCallbackInfo<v8::Value>& info) {
  return GetFromCallbackData(info.Data());
}

inline Environment* Environment::GetFromCallbackData(v8::Local<v8::Value> val) {
  // ...
  Environment* env = static_cast<Environment*>(obj->GetAlignedPointerFromInternalField(0));
  // ...
  return env;
}
```

结合两个文件， `Environment` 类调用内联函数 `GetCurrent` 返回 `Environment` 实例，最终调用到 `env.cc` 文件里的 `ToggleTimerRef` 函数：

``` cpp

void Environment::ToggleTimerRef(bool ref) {
  // ...

  if (ref) {
    uv_ref(reinterpret_cast<uv_handle_t*>(timer_handle()));
  } else {
    uv_unref(reinterpret_cast<uv_handle_t*>(timer_handle()));
  }
}

```

最终的逻辑走到了 `libuv` 的两个函数 `uv_ref` 和 `uv_unref` 上。

### `linuv` 实现层

> 基于Libuv v1.35.0 版本

函数实现在 `libuv/src/uv-common.c` ，逻辑比较简单的两个函数：

``` c
// uv-common.c
void uv_ref(uv_handle_t* handle) {
  uv__handle_ref(handle);
}


void uv_unref(uv_handle_t* handle) {
  uv__handle_unref(handle);
}

// uv-common.h

#define uv__handle_ref(h)                                                     \
  do {                                                                        \
    if (((h)->flags & UV_HANDLE_REF) != 0) break;                             \
    (h)->flags |= UV_HANDLE_REF;                                              \
    if (((h)->flags & UV_HANDLE_CLOSING) != 0) break;                         \
    if (((h)->flags & UV_HANDLE_ACTIVE) != 0) uv__active_handle_add(h);       \
  }                                                                           \
  while (0)

#define uv__handle_unref(h)                                                   \
  do {                                                                        \
    if (((h)->flags & UV_HANDLE_REF) == 0) break;                             \
    (h)->flags &= ~UV_HANDLE_REF;                                             \
    if (((h)->flags & UV_HANDLE_CLOSING) != 0) break;                         \
    if (((h)->flags & UV_HANDLE_ACTIVE) != 0) uv__active_handle_rm(h);        \
  }                                                                           \
  while (0)

#define uv__active_handle_add(h)                                              \
  do {                                                                        \
    (h)->loop->active_handles++;                                              \
  }                                                                           \
  while (0)

#define uv__active_handle_rm(h)                                               \
  do {                                                                        \
    (h)->loop->active_handles--;                                              \
  }                                                                           \
  while (0)
```

`uv_ref` 和 `uv_unref` 函数指向了头文件定义的两个宏函数，当句柄仍在活动状态时，标记引用或取消引用标记，并在事件循环的全局活动句柄计数器上 `+1` 或者 `-1`。

### 运行时

上面描述了初始化 `Timeout` 实例和使用 `unref` 函数 最终会在 `libuv` 层将事件循环的全局句柄活动计数器 `active_handles` 上 `±1`。这个计数器是如何个用途，回到 `node` 层，当我们执行 `node xxx.js` 时最开始走到了 `node_main.cc` 文件里的 `main` 函数，流程走到了 `node_main_instance.cc` 里：

``` cpp

int NodeMainInstance::Run() {

  // ...

    {
      bool more;
      do {
        // 默认模式启动 libuv 循环
        uv_run(env->event_loop(), UV_RUN_DEFAULT);

        // 检查事件循环是否有存活的句柄
        more = uv_loop_alive(env->event_loop());
        if (more && !env->is_stopping()) continue;

        if (!uv_loop_alive(env->event_loop())) {
          EmitBeforeExit(env.get());
        }
        
        // Emit `beforeExit` if the loop became alive either after emitting
        // event, or after running some callbacks.
        more = uv_loop_alive(env->event_loop());
        // 无存活的句柄，退出循环，进程退出
      } while (more == true && !env->is_stopping());
    }

    exit_code = EmitExit(env.get());
  }

  // ...
}

```

我删减了一些代码，这样看得主逻辑更清晰一点，`while` 里检查事件循环是否还有存活的句柄，如果没有则退出循环、退出进程。这里有使用了 `libuv` 的函数
 `uv_run` 和 `uv_loop_alive` ，看看逻辑实现：

 ``` c
// libuv/src/unix/core.c

static int uv__loop_alive(const uv_loop_t* loop) {
  return uv__has_active_handles(loop) ||
         uv__has_active_reqs(loop) ||
         loop->closing_handles != NULL;
}


int uv_loop_alive(const uv_loop_t* loop) {
  return uv__loop_alive(loop);
}


int uv_run(uv_loop_t* loop, uv_run_mode mode) {
  int timeout;
  int r;
  int ran_pending;

  r = uv__loop_alive(loop);
  if (!r)
    uv__update_time(loop);

  while (r != 0 && loop->stop_flag == 0) {
    uv__update_time(loop);
    // 1. timers 运行的定时器，并更新全局句柄活动计数器 `active_handles`，-1
    uv__run_timers(loop);
    // 2. I/O callbacks
    ran_pending = uv__run_pending(loop);
    // 3. idle、prepare
    uv__run_idle(loop);
    uv__run_prepare(loop);

    timeout = 0;
    if ((mode == UV_RUN_ONCE && !ran_pending) || mode == UV_RUN_DEFAULT)
      timeout = uv_backend_timeout(loop);
    
    // 4. poll 
    uv__io_poll(loop, timeout);
    // 5. check
    uv__run_check(loop);
    // 6. close
    uv__run_closing_handles(loop);

    // ...

    r = uv__loop_alive(loop);
    
    // ...
  }

  // ...

  return r;
}

// libuv/src/uv-common.h

#define uv__has_active_handles(loop)                                          \
  ((loop)->active_handles > 0)

#define uv__handle_stop(h)                                                    \
  do {                                                                        \
    if (((h)->flags & UV_HANDLE_ACTIVE) == 0) break;                          \
    (h)->flags &= ~UV_HANDLE_ACTIVE;                                          \
    if (((h)->flags & UV_HANDLE_REF) != 0) uv__active_handle_rm(h);           \
  }                                                                           \
  while (0)

// libuv/src/timer.c

void uv__run_timers(uv_loop_t* loop) {
  // ...
  for (;;) {
    // ...
    uv_timer_stop(handle);
    handle->timer_cb(handle);
    // ...
  }
}

int uv_timer_stop(uv_timer_t* handle) {
  // ...
  // 调用 uv-common.h 定义的宏函数 active_handles - 1 
  uv__handle_stop(handle);

  return 0;
}
 ```

在 `uv_run` 函数里就 `while` 是大家都听过无数遍的事件循环, 其中在第一步的 `timers` 阶段，执行到期的定时器的同时，还把上面 `ref` 标记的全局句柄活动计数器 `active_handles` 进行 `-1` 操作。流程走到这里就清晰了，再回到最初的地方：
 
1. 没有使用 `unref`：

``` js
console.log('a');

const timeout = setTimeout(() => {
  console.log('c');
}, 3000);

console.log('b');

// a -> b -> c 
```

代码执行到 `setTimeout`, 回调函数进入事件循环 `active_handles + 1 = 1`，因为代码没有其他的 `I/O` 事件，事件循环一直循环定时期定时的时间到了后，执行 `timers` 阶段的事务，执行回调函数，并对活动句柄计数器减一操作 `active_handles - 1 = 0`，这时候 `while (r != 0 && loop->stop_flag == 0)` 条件不满足，退出循环，`node` 层退出循环后进程退出。

2. 使用 `unref`：

``` js
console.log('a');

const timeout = setTimeout(() => {
  console.log('c');
}, 3000);
timeout.unref();

console.log('b');

// a -> b
```

代码执行到 `setTimeout`, 回调函数进入事件循环 `active_handles + 1 = 1`，随后执行 `unref` 操作 `active_handles - 1 = 0`，事件循环条件 `while (r != 0 && loop->stop_flag == 0)` 条件不满足，退出循环，`node` 层退出循环后进程退出。

最后以一层流程图结束本文：

![timer-unref](http://cdn.zhoumq.cn/timer-unref.jpg)
