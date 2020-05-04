---
title: Node.js 每周 PR 资讯 （2020-04-13 ~ 2020-04-19）
date: 2020-04-20 11:30:39
tags: [Node.js]
categories: 
- Node.js 每周 PR 资讯
---

## 背景

周末去团建的时候突然有个想法，大多数 `Node.js` 和前端开发人员受限于环境等因素，比较少去了解自己平常使用的 `Node.js` 核心库的代码变更。那不如自己做一个转化，把每周 `merge` 主分支的 `PR` 做个消化整理，挑选具有意义（包括不限于新功能、性能优化、BUG 修复、代码结构优化和上游依赖变更）的进行分析和背景资料归整，让更多的同学可以低门槛、高效率的去了解 `Node.js`。

## 前言

本文是 [Node.js 每周 PR 资讯](/categories/JavaScript/) 第 `1` 期 （2020-04-13 ~ 2020-4-19），挑选了 `9` 个 具有代表性的 `PR` 进行讲解：

* [#32745](https://github.com/nodejs/node/pull/32745) - **worker**: fix type check in receiveMessageOnPort (addaleax) 
* [#32770](https://github.com/nodejs/node/pull/32770) - **buffer**: add type check in bidirectionalIndexOf (Flarna) 
* [#32778](https://github.com/nodejs/node/pull/32778) - **src**: add AliasedStruct utility (jasnell) 
* [#32797](https://github.com/nodejs/node/pull/32797) - **process**: suggest --trace-warnings when printing warning (addaleax) 
* [#32798](https://github.com/nodejs/node/pull/32798) - **src**: use basename(argv0) for --trace-uncaught suggestion (addaleax) 
* [#32801](https://github.com/nodejs/node/pull/32801) - **http**: refactor agent 'free' handler (ronag) 
* [#32763](https://github.com/nodejs/node/pull/32763) - **stream**: simplify Transform stream implementation (ronag) 
* [#32882](https://github.com/nodejs/node/pull/32882) - **stream**: simplify Writable.end() (ronag) 
* [#32844](https://github.com/nodejs/node/pull/32844) - **stream**: close iterator in Readable.from (ronag) 

## Pull Request

#### 1. fix type check in receiveMessageOnPort

> PR-URL: [#32745](https://github.com/nodejs/node/pull/32745)
>
> 作者: addaleax
>
> 所属模块：worker_threads
>
> 描述：修复 receiveMessageOnPort 函数类型检查失败未正确抛出错误堆栈

##### 示例

`v12.3.0` 版本新增了 `receiveMessageOnPort` 函数，  接收来自单个来自 `MessagePort` 实例的消息，先看官网的示例：

``` js
const { MessageChannel, receiveMessageOnPort } = require('worker_threads');
const { port1, port2 } = new MessageChannel();
port1.postMessage({ hello: 'world' });

console.log(receiveMessageOnPort(port2));
// Prints: { message: { hello: 'world' } }
console.log(receiveMessageOnPort(port2));
// Prints: undefined
```

上面的例子用 `MessageChannel` 类初始化一个双向通信通道，`port1` 和 `port2`可以相互监听到彼此发送的消息，可以使用监听 `message` 事件持续的接收来自对端发送的消息，也可以使用 `receiveMessageOnPort`方式接收单个消息（消息队列里最老的一个）。

##### 问题

 `receiveMessageOnPort ` 函数入参为 `MessagePort` 实例，传入非对象类型参数例如数字会抛出 `Abort` 错误，原因在于简单的使用了 `CHECK` 宏函数进行类型检查，失败的时候直接中断代码运行 ：

``` c++
CHECK(args[0]->IsObject())
```

`CHECK` 宏函数定义如下：

``` c++
#define CHECK(expr)                                                           \
  do {                                                                        \
    if (UNLIKELY(!(expr))) {                                                  \
      ERROR_AND_ABORT(expr);                                                  \
    }                                                                         \
  } while (0)
```

##### 修复

判断入参是否为对象或 `MessagePort`实例，否则使用 `THROW_ERR_INVALID_ARG_TYPE `内联函数指定错误信息调用 `v8`的 `ThrowException`方法抛出错误。

