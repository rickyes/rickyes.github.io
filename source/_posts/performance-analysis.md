---
title: Node.js 应用性能调优
date: 2018-11-06 16:24:22
tags: [Node.js, profiler, v8, 火焰图, wrk]
categories: 
- Node.js
---

## 前提

`Node.js`是天才屌丝程序员`Ryan Dahl`于2009年发布，经过几年的发展，`Node.js`已经是成熟的`JavaScript`运行时了。用`Node.js`开发的应用被分发到世界各地的云主机上，随着公司的发展和壮大、应用`PV`和`UV`的剧增，如何保障`Node.js`应用的高性能是如今作为一个`Node.js`开发者必须面对的问题。

### 通过`V8/Node`自带的`profiler`能力

通过`v8/Node`的`profiler`能力，能够列出各函数的执行占比。

我们通过对一段经典简单的http服务的示例代码进行分析：

```js
// index.js
'use strict'

const Koa = require('koa');
const Router = require('koa-router');
const { etagger, timestamp, fetch } = require('./util')();
const server = new Koa();
const router = new Router();

router.get('/test', async function (ctx, next) {
  const content = await fetch(ctx.request.url);
  ctx.body = {data: content, url: ctx.request.url, ts: timestamp()};
  server.emit('after', ctx.body);
});

server.use(etagger().bind(server))
      .use(router.routes())
      .use(router.allowedMethods())

server.listen(3000);
```

```js
// util.js
'use strict'

require('events').defaultMaxListeners = Infinity
const crypto = require('crypto')

module.exports = () => {
  const content = crypto.rng(5000).toString('hex')
  const ONE_MINUTE = 60000
  var last = Date.now()

  function timestamp () {
    var now = Date.now()
    if (now - last >= ONE_MINUTE) last = now
    return last
  }

  function etagger () {
    var cache = {}
    var afterEventAttached = false
    function attachAfterEvent (server) {
      if (attachAfterEvent === true) return
      afterEventAttached = true
      server.on('after', (result) => {
        const key = crypto.createHash('sha512')
          .update(result.url)
          .digest()
          .toString('hex')
        const etag = crypto.createHash('sha512')
          .update(JSON.stringify(result.data))
          .digest()
          .toString('hex')
        if (cache[key] !== etag) cache[key] = etag
      })
    }
    return async function (ctx, next) {
      attachAfterEvent(this);
      const key = crypto.createHash('sha512')
        .update(ctx.request.url)
        .digest()
        .toString('hex')
      if (key in cache) ctx.response.set('Etag', cache[key])
      ctx.response.set('Cache-Control', 'public, max-age=120')
      await next()
    }
  }

  function fetch (url) {
    return new Promise(resolve => {
      if (url !== '/test') resolve(Object.assign(Error('Not Found'), {statusCode: 404}))
      else resolve(content)
    });
  }

  return { timestamp, etagger, fetch }

}
```

这个例子响应`/test`路由，返回计算密集型处理的数据。

以`--prof`参数标识启动`Node`应用:

```sh
$ node --prof index.js
```

使用性能压测工具对接口`http://127.0.0.1:3000/test`进行压测，这里使用`wrk`，使用8个线程运行30秒的基准测试，并保持打开200个HTTP连接：

```sh
$ wrk -t8 -c200 -d30s http://127.0.0.1:3000/test
```

跑完基准测试，得到评估结果：

```sh
Running 30s test @ http://127.0.0.1:3000/test
  8 threads and 200 connections
  Thread Stats   Avg      Stdev     Max   +/- Stdev
    Latency   933.40ms  588.82ms   2.00s    56.50%
    Req/Sec    15.05     15.87   180.00     92.63%
  1012 requests in 30.07s, 10.00MB read
  Socket errors: connect 0, read 186, write 0, timeout 681
Requests/sec:     33.66
Transfer/sec:    340.71KB
```

从上面的接口评估结果可以看到，延迟平均有将近`900ms`，`qps`平均只有`15.05`，这是非常坏的结果。

通过`--prof`标识得到一个v8的log文件：`isolate-0x103001000-v8.log`，该文件人眼难阅读：

```sh
v8-version,6,8,275,32,-node.36,0
shared-library,/Users/ricky/.nvm/versions/node/v10.13.0/bin/node,0x100001000,0x100ccc35d,0
shared-library,/System/Library/Frameworks/CoreFoundation.framework/Versions/A/CoreFoundation,0x7fff34051d70,0x7fff341f2217,148725760
shared-library,/usr/lib/libSystem.B.dylib,0x7fff5e59694c,0x7fff5e596b2e,148725760
shared-library,/usr/lib/libc++.1.dylib,0x7fff5e7f0950,0x7fff5e839236,148725760
shared-library,/usr/lib/libobjc.A.dylib,0x7fff6003dbc0,0x7fff6005ec52,148725760
shared-library,/usr/lib/libDiagnosticMessagesClient.dylib,0x7fff5e1e3f7b,0x7fff5e1e4956,148725760
shared-library,/usr/lib/libicucore.A.dylib,0x7fff5f4ab928,0x7fff5f698b46,148725760
shared-library,/usr/lib/libz.1.dylib,0x7fff60f20390,0x7fff60f2bbd5,148725760
shared-library,/usr/lib/libc++abi.dylib,0x7fff5e848da0,0x7fff5e857f00,148725760
shared-library,/usr/lib/system/libcache.dylib,0x7fff60fa2b30,0x7fff60fa556e,148725760
shared-library,/usr/lib/system/libcommonCrypto.dylib,0x7fff60fa7c14,0x7fff60fb0c7d,148725760
shared-library,/usr/lib/system/libcompiler_rt.dylib,0x7fff60fb2e8c,0x7fff60fb7a6e,148725760
...
```

通过`--prof-process`处理该文件：

```sh
$ node --prof-process isolate-0x103001000-v8.log > profile.txt
```

先查看总览部分：

```sh
 [Summary]:
   ticks  total  nonlib   name
    660    2.4%    2.4%  JavaScript
  26749   96.6%   97.4%  C++
   1243    4.5%    4.5%  GC
    228    0.8%          Shared libraries
     49    0.2%          Unaccounted
```

可以看到，在收集的样本中有`97%`发生在`C++`代码中，再去看看`C++`代码中发生了什么事：

```sh
 [C++]:
   ticks  total  nonlib   name
  12361   44.6%   45.0%  T node::crypto::Hash::HashUpdate(v8::FunctionCallbackInfo<v8::Value> const&)
   9659   34.9%   35.2%  T v8::internal::JsonStringifier::SerializeString(v8::internal::Handle<v8::internal::String>)
    850    3.1%    3.1%  T node::crypto::Hash::New(v8::FunctionCallbackInfo<v8::Value> const&)
    219    0.8%    0.8%  t sha512_block_data_order_avx2
    162    0.6%    0.6%  T __kernelrpc_mach_port_request_notification
    149    0.5%    0.5%  t _tiny_malloc_should_clear
    127    0.5%    0.5%  t _tiny_malloc_from_free_list
    101    0.4%    0.4%  t __malloc_initialize
 ...
```

排名前三的条目占用了`83.3%`的CPU时间和`82.6%`的栈调用。从这个输出可以看到`HashUpdate`函数占用了`45%`的CPU时间，从该函数看不出是由哪里的代码产生的问题，接下来看看` [Bottom up (heavy) profile]`部分, 这部分提供了每个函数的主要调用者的信息：

```sh
12361   44.6%  T node::crypto::Hash::HashUpdate(v8::FunctionCallbackInfo<v8::Value> const&)
  12361  100.0%    T v8::internal::Builtin_HandleApiCall(int, v8::internal::Object**, v8::internal::Isolate*)
  12166   98.4%      LazyCompile: *server.on /Users/ricky/app/node/flamegraph/koa-test/util.js:23:26
  12049   99.0%        LazyCompile: *emit events.js:140:44
  12049  100.0%          LazyCompile: ~<anonymous> /Users/ricky/app/node/flamegraph/koa-test/index.js:9:36
  12049  100.0%            Builtin: AsyncFunctionAwaitResolveClosure
    129    1.0%      LazyCompile: *update internal/crypto/hash.js:52:40
    128   99.2%        LazyCompile: *server.on /Users/ricky/app/node/flamegraph/koa-test/util.js:23:26
    125   97.7%          LazyCompile: *emit events.js:140:44
    125  100.0%            LazyCompile: ~<anonymous> /Users/ricky/app/node/flamegraph/koa-test/index.js:9:36
      3    2.3%          LazyCompile: ~emit events.js:140:44
      3  100.0%            LazyCompile: ~<anonymous> /Users/ricky/app/node/flamegraph/koa-test/index.js:9:36

   9659   34.9%  T v8::internal::JsonStringifier::SerializeString(v8::internal::Handle<v8::internal::String>)
   9659  100.0%    T v8::internal::Builtin_JsonStringify(int, v8::internal::Object**, v8::internal::Isolate*)
   9594   99.3%      LazyCompile: *server.on /Users/ricky/app/node/flamegraph/koa-test/util.js:23:26
   9512   99.1%        LazyCompile: *emit events.js:140:44
   9512  100.0%          LazyCompile: ~<anonymous> /Users/ricky/app/node/flamegraph/koa-test/index.js:9:36
   9512  100.0%            Builtin: AsyncFunctionAwaitResolveClosure

    850    3.1%  T node::crypto::Hash::New(v8::FunctionCallbackInfo<v8::Value> const&)
    850  100.0%    T v8::internal::Builtin_HandleApiCall(int, v8::internal::Object**, v8::internal::Isolate*)
    841   98.9%      LazyCompile: *server.on /Users/ricky/app/node/flamegraph/koa-test/util.js:23:26
    835   99.3%        LazyCompile: *emit events.js:140:44
    835  100.0%          LazyCompile: ~<anonymous> /Users/ricky/app/node/flamegraph/koa-test/index.js:9:36
    835  100.0%            Builtin: AsyncFunctionAwaitResolveClosure
```

在上面的每个调用栈中，看到每个函数占用父类的百分比：

1. `util.js:23:26(server.on)`占用了`Builtin_HandleApiCall`函数`98%`的时间，`Builtin_HandleApiCall`函数占用了`HashUpdate`函数`100%`的时间
2. `util.js:23:26(server.on)`占用了`Builtin_JsonStringify`函数`99%`的时间，`Builtin_JsonStringify`函数占用了`SerializeString`函数`100%`的时间
3. `util.js:23:26(server.on)`占用了`Builtin_HandleApiCall`函数`98%`的时间，`Builtin_HandleApiCall`函数占用了`New`函数`100%`的时间

综合上面的百分比可以看到`util.js`中的`server.on`是我们此次优化的目标。再看到`util.js`中，结合上面的信息，热点代码出现在`events`上，先看下面的代码：

```js
require('events').defaultMaxListeners = Infinity
```

这里设置了`events`的默认最大句柄数是`1e309`, 如果不修改默认配置，`Node.js`配置的`events`的默认最大句柄数是`10`, 也就是一个实例只能监听同一个事件`10`次。把这行代码注释掉，然后以`--trace-warnings`标识启动应用，该标识可以打印进程警告的堆栈跟踪：

```sh
$ node --trace-warnings index.js
```

再次进行压测，可以看到警告信息：

```sh
(node:11356) MaxListenersExceededWarning: Possible EventEmitter memory leak detected. 11 after listeners added. Use emitter.setMaxListeners() to increase limit
    at _addListener (events.js:243:17)
    at Application.addListener (events.js:259:10)
    at attachAfterEvent (/Users/ricky/app/node/flamegraph/koa-test/util.js:23:14)
    at Application.<anonymous> (/Users/ricky/app/node/flamegraph/koa-test/util.js:36:7)
    at dispatch (/Users/ricky/app/node/flamegraph/koa-test/node_modules/koa-compose/index.js:42:32)
    at /Users/ricky/app/node/flamegraph/koa-test/node_modules/koa-compose/index.js:34:12
    at Application.handleRequest (/Users/ricky/app/node/flamegraph/koa-test/node_modules/koa/lib/application.js:151:12)
    at Server.handleRequest (/Users/ricky/app/node/flamegraph/koa-test/node_modules/koa/lib/application.js:133:19)
    at Server.emit (events.js:182:13)
    at parserOnIncoming (_http_server.js:652:12)
```

句柄达到了`11`个，可以知道代码中有大量发生`server.on`监听事件的行为。

查看代码中逻辑，看到了一个问题：

```js
function etagger () {
    var cache = {}
    var afterEventAttached = false
    function attachAfterEvent (server) {
      if (attachAfterEvent === true) return // 应该是afterEventAttached
      afterEventAttached = true
      server.on('after', (result) => {
        const key = crypto.createHash('sha512')
          .update(result.url)
          .digest()
          .toString('hex')
        const etag = crypto.createHash('sha512')
          .update(JSON.stringify(result.data))
          .digest()
          .toString('hex')
        if (cache[key] !== etag) cache[key] = etag
      })
    }
    return async function (ctx, next) {
      attachAfterEvent(this);
      const key = crypto.createHash('sha512')
        .update(ctx.request.url)
        .digest()
        .toString('hex')
      if (key in cache) ctx.response.set('Etag', cache[key])
      ctx.response.set('Cache-Control', 'public, max-age=120')
      await next()
    }
  }
```

看到有个条件永远满足，所以每次请求就会产生一次`server.on("after", () => {})`，解决这个bug：

```js
// if (attachAfterEvent === true) return
if (afterEventAttached === true) return
```

再次进行压测，得到评估结果：

```sh
Running 30s test @ http://127.0.0.1:3000/test
  8 threads and 200 connections
  Thread Stats   Avg      Stdev     Max   +/- Stdev
    Latency    34.93ms    7.02ms 206.34ms   92.51%
    Req/Sec   722.16    109.92     1.39k    79.91%
  172565 requests in 30.10s, 1.67GB read
  Socket errors: connect 0, read 25, write 4, timeout 0
Requests/sec:   5733.90
Transfer/sec:     56.68MB
```

`qps`平均值增加了`48`倍，延迟平均值减少了`23`倍！后面还有一些优化空间，比如：

1. `JSON.stringify`
2. `crypto.createHash`
3. `crypto.rng`

这几个API都是CPU计算大户，换另外种实现方式可以将`qps`再次增加几倍。



### 通过火焰图可视化分析

`火焰图（flamegraph）`是`brendangregg`处理MySQL性能问题时发明的。它利用常规的剖析器/示踪器得到的文本产生可视化，允许快速准确地识别最频繁的代码路径, 可以更快的找出热点代码和调用堆栈之间的关系。恢复上面代码原来的样子，我们使用`0x(github@davidmarkclements)`这个工具进行分析，它可以通过分析`CPU profile`文件生成svg火焰图。

举个例子说明火焰图的调用堆栈，伪代码如下：

```js
function a() {
  if (条件) {
    b();
  } else {
    c();
  }
}

function b() {
  d();
}

function c() {
  if (条件) {
    e();
  } else {
    f();
  }
}

function d() {}

function e() {}

function f() {}
```

对应的火焰图如下：

![7](https://raw.githubusercontent.com/rickyes/rickyes.github.io-2/master/images/7.jpg)

以下命令启动应用：

```sh
$ 0x -o index.js
🔥  Profiling
```

然后用`wrk`进行压测：

```sh
$ wrk -t8 -c200 -d30s http://127.0.0.1:3000/test
```

评估报告参考第一次压测结果。然后`ctrl + c`退出当前进程, 等待分析并生成火焰图：

![1](https://raw.githubusercontent.com/rickyes/rickyes.github.io-2/master/images/1.jpg)

横轴表示抽样数，宽度越大表示该函数的抽取次数越多，也就是占用CPU总时间越多。每一层表示一个调用栈一个函数，调用栈越深火焰越高，每一层的父类在下一层。一个出现平顶的火焰图表示有可能瓶颈就是出现在最顶层的函数上。

`*`表示经过`v8`优化的代码，`~`表示未经过优化的代码，如果优化状态对我们不重要，可以点击`merge`按钮合并：

![2](https://raw.githubusercontent.com/rickyes/rickyes.github.io-2/master/images/2.jpg)

可以看到`server.on`占用了大部分的CPU时间。现在开启的分析结果是app、依赖包、和node核心，现在点击`v8`和`cpp`开启内置的模块调用栈：

![3](https://raw.githubusercontent.com/rickyes/rickyes.github.io-2/master/images/3.jpg)

`Node.js`的JSON解析器是直接用了v8的json引擎，所以看不到js的函数调用，只是看到了c++的调用函数`SerializeString`，现在试着把`JSON.stringify`去掉：

```js
server.on('after', (req, res) => {
     const key = crypto.createHash('sha512')
          .update(result.url)
          .digest()
          .toString('hex')
        const etag = crypto.createHash('sha512')
          .update(result.data)
          .digest()
          .toString('hex')
        if (cache[key] !== etag) cache[key] = etag
})
```

再次压测，得到的火焰图如下：

![4](https://raw.githubusercontent.com/rickyes/rickyes.github.io-2/master/images/4.1.jpg)

可以看到平顶的情况已经好很多了，但是更突出了一个问题，`emit`函数成为了热点代码, 原因可能就是`events`的句柄太多，去掉`require('events').defaultMaxListeners = Infinity`这一行代码，检查代码并修复一处bug:

```js
if (afterEventAttached === true) return
// if (attachAfterEvent === true) return
```

再次压测，得到的评估报告：

```sh
Running 30s test @ http://127.0.0.1:3000/test
  8 threads and 200 connections
  Thread Stats   Avg      Stdev     Max   +/- Stdev
    Latency    23.16ms    8.36ms 218.06ms   95.75%
    Req/Sec     1.11k   191.79     2.08k    93.37%
  265424 requests in 30.10s, 2.53GB read
  Socket errors: connect 0, read 27, write 3, timeout 0
Requests/sec:   8818.89
Transfer/sec:     86.04MB
```

得到的火焰图：

![5](https://raw.githubusercontent.com/rickyes/rickyes.github.io-2/master/images/5.1.jpg)

该火焰图表示已经改善了巨大的平顶的函数了，现在的热点代码是在node核心的定时器上了，现在得到的火焰图已经修复了最大的问题区域了，当然还是可以继续优化下去，直到火焰图的平顶函数越来越少。
