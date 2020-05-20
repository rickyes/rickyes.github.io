---
title: Boa 如何使用 ES Module 加载 Python 包
date: 2020-05-18 22:53:37
tags: [Boa,ES Module,Python]
categories: 
- ES Module
---

## 前言
> 项目地址：[https://github.com/alibaba/pipcook](https://github.com/alibaba/pipcook)

如果看到此文章之前，不知道 `Boa` 是啥，可以先看看 `Yorkie` 的分享 [Boa: 在 Node.js 中使用 Python](https://cnodejs.org/topic/5e917ec158ab6717beb7f1e0) 

<!-- more -->

## 介绍

在未实现此功能之前，`Boa` 加载 `Python` 库是下面这样子的：
```js
const boa = require('@pipcook/boa');
const { range, len } = boa.builtins();
const { getpid } = boa.import('os');
const numpy = boa.import('numpy');
```

通过 `boa.import` 函数传入 `Python` 库的名称来进行导入，如果需要加载的包很多的话可能 `import()` 会显得冗余。
为此我们开发了自定义的导入语义声明，使用 `ES Module` 实现更简洁的导入语句：
```js
import { getpid } from 'py:os';
import { range, len } from 'py:builtins';
import {
  array as NumpyArray,
  int32 as NumpyInt32,
} from 'py:numpy';
```

上面的功能实现依赖于 Node 的实验性功能 `--experimental-loader`, 它还有个未公开的别名 `--loader`, 一开始这个功能刚推出来的时候其实是 `--loader` , 因为是考虑到是实验性的所以后面的版本加上了 `experimental`. 

## --experimental-loader

启动程序的时候通过指定此 flag , 接受指定后缀为 `mjs` 的文件来实现自定义加载器，`mjs` 文件提供几种钩子来拦截默认的加载器：
- resolve
- getFormat
- getSource
- transformSource
- getGlobalPreloadCode
- dynamicInstantiate

执行的顺序为：
```
                                      ( Each `import` runs the process once )                                  
                          |- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -|
  ( run once )            |                         ---> dynamicInstantiate             |
getGlobalPreloadCode  ->  | resolve -> getFormat -> |                                   |
                          |                         ---> getSource -> transformSource   |
                          |_ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _|
```

### getGlobalPreloadCode Hook

只运行一次，用于在应用程序启动时在全局范围内运行一些代码，可以通过 `globalThis` 对象将变量挂在到全局范围内，目前只提供一个 `getBuiltin（类似 require）` 函数加载内置模块：
```js
/**
 * @returns {string} Code to run before application startup
 */
export function getGlobalPreloadCode() {
  return `\
globalThis.someInjectedProperty = 42;
console.log('I just set some globals!');

const { createRequire } = getBuiltin('module');

const require = createRequire(process.cwd() + '/<preload>');
`;
}
```

那么在所有的模块中都可以使用 `someInjectedProperty` 这个变量了。


### resolve Hook

是加载器的入口，拦截 `import` 语句和 `import()` 函数，可以对导入的字符串进行判断返回特定逻辑的 `url`：

```js
const protocol = 'py:';

/**
 * @param {string} specifier
 * @param {object} context
 * @param {string} context.parentURL
 * @param {function} defaultResolve
 * @returns {object} response
 * @returns {string} response.url
 */
export function resolve(specifier, context, defaultResolve) {
  if (specifier.startsWith(protocol)) {
    return {
      url: specifier
    };
  }
  return defaultResolve(specifier, context, defaultResolve);
}
```

参数定义：
- specifier - `import` 语句 或 `import()` 表达式中的字符串
```js
// eg:

import os from 'py:os'; // 'py:os'
async function load() {
  const sys = await import('py:sys'); // 'py:sys'
}
```

- parentURL - 导入该模块的父模块 url
```js
// eg: 
// app.mjs

import os from 'py:os'; // file:///.../app.mjs
```

这里有个细节点，`defaultResolve` 函数的第一个参数只接受三种协议的字符串：
- `data:` - javascript wasm 字符串
- `nodejs:` - built-in 模块
- `file:` - 第三方或用户自定义模块

`Boa` 自定义的 `py:` 协议并不能通过默认 `resolve Hook` 的参数检查，所以上面做了判断匹配后直接返回 `url` 传递给 `getFormat Hook`.


### getFormat Hook

提供多种方式定义如何解析 `resolve Hook` 传递下来的 `url`:
- `builtin` - Node.js 内置模块
- `commonjs` - CommonJS 模块
- `dynamic` - 动态实例化, 触发 `dynamicInstantiate Hook` 
- `json` - JSON 文件
- `module` - ECMAScript 模块
- `wasm` - WebAssembly 模块

从功能描述来看，只有 `dynamic` 符合我们的需求：
```js
export function getFormat(url, context, defaultGetFormat) {
  // DynamicInstantiate hook triggered if boa protocol is matched
  if (url.startsWith(protocol)) {
    return {
      format: 'dynamic'
    }
  }

  // Other protocol are assigned to nodejs for internal judgment loading
  return defaultGetFormat(url, context, defaultGetFormat);
}
```
当 `url` 匹配上 `boa` 协议则触发 `dynamicInstantiate Hook`, 其他情况下都交给默认的解析器去判断加载。


### dynamicInstantiate Hook

提供不同于 `getFormat` 几种解析格式的动态加载模块方式：
```js
/**
 * @param {string} url
 * @returns {object} response
 * @returns {array} response.exports
 * @returns {function} response.execute
 */
export function dynamicInstantiate(url) {
  const moduleInstance = boa.import(url.replace(protocol, ''));
  // Get all the properties of the Python Object to construct named export
  // const { dir } = boa.builtins();
  const moduleExports = dir(moduleInstance);
  return {
    exports: ['default', ...moduleExports],
    execute: exports => {
      for (let name of moduleExports) {
        exports[name].set(moduleInstance[name]);
      }
      exports.default.set(moduleInstance);
    }
  };
}
```

使用 `boa.import()` 加载 `Python` 模块，并使用 `Python builtins`  内置的 `dir` 函数获取模块的全部属性。
钩子需要预先提供导出列表传递给 `exports` 参数，用于支持 `Named exports`，加上 `default` 是为了支持 `Default exports`。
`execute` 函数在初始化动态钩子时设置指定命名对应的属性。


### getSource Hook

用于传递源码字符串，提供不同于默认加载器从磁盘读取文件的方式获取源码，比如网络、内存和硬编码等：
```js
export async function getSource(url, context, defaultGetSource) {
  const { format } = context;
  if (someCondition) {
    // For some or all URLs, do some custom logic for retrieving the source.
    // Always return an object of the form {source: <string|buffer>}.
    return {
      source: `export const message = 'Woohoo!'.toUpperCase();`
    };
  }
  // Defer to Node.js for all other URLs.
  return defaultGetSource(url, context, defaultGetSource);
}
```

这里比较有意思的是可以从不同渠道获取源码，比如实现和 `Deno` 一样的方式从网络获取源码。

### transformSource Hook

等待 `getSource Hook` 执行完毕加载完源码后，该钩子可以对已加载的源码进行修改操作：
```js
export async function transformSource(source,
                                      context,
                                      defaultTransformSource) {
  const { url, format } = context;
  if (source && source.replace) {
    // For some or all URLs, do some custom logic for modifying the source.
    // Always return an object of the form {source: <string|buffer>}.
    return {
      source: source.replace(`'A message';`, `'A message'.toUpperCase();`)
    };
  }
  // Defer to Node.js for all other sources.
  return defaultTransformSource(
    source, context, defaultTransformSource);
}
```

上面提供的例子将源码中的特定字符串替换成新字符串, 还可以实现即时编译：
```js
export function transformSource(source, context, defaultTransformSource) {
  const { url, format } = context;

  if (extensionsRegex.test(url)) {
    return {
      source: CoffeeScript.compile(source, { bare: true })
    };
  }

  // Let Node.js handle all other sources.
  return defaultTransformSource(source, context, defaultTransformSource);
}
```

## 最后
相比之前 `Node.js` 只能用内置的几种方式加载模块，如今开放出来的几种钩子可以组合出很多有趣的功能，大家可以去挖掘更多有意思的场景，可以参考实现这个功能的 [`PR#191`](https://github.com/alibaba/pipcook/pull/191)。


## 参考链接
- [Experimental Loaders](https://nodejs.org/dist/latest-v14.x/docs/api/esm.html#esm_experimental_loaders)
- [ECMAScript Modules Export](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Statements/export)


