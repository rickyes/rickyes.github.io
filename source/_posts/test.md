---
title: 变量声明之旅
date: 2017-12-01 00:28:10
tags: [JavaScript,let,const,var]
categories:
- JavaScript
---
## var、let、const 定义变量
var 定义的变量允许变量提升（Hoisting），还涉及到 变量进行 LHS（Left Hand Side）查找
```javascript
举个栗子：
console.log(x); // undefined
var x = 'var is up';
```
但是得注意一下，var声明的变量可以提升，但是如果是一个定义一个函数，函数表达式是不可以提升的，如下:
```javascript
var x = func();
var func = function(){
    return 'this is function';
}
// 相当于下面的代码：
var func;
var x = func();
func = function(){
    return 'this is function';
}
```
上面那段代码会被爆出TypeError,变量func被提升了，但是后面的函数表达式没被提升，提升的func的初始化是var func = undefined,上面的操作相当于undefined(),所以就爆TypeError了;

## 函数声明和函数表达式声明
函数声明会整体提升到当前作用域的顶端，而函数表达式声明只提升变量名，表达式并不会提升（栗子看上面👆代码），举个🌰 ：
```javascript
test() // 1
test2() // TypeError

// 函数声明
function test(){
    console.log(1);
}

// 函数表达式声明
var test2 = function(){
    console.log(2);
}
```

## 作用域
var 并不是块级作用域，所以容易造成作用域污染，在全局作用域下用var定义一个变量会被挂载到global或window中,看下面这段代码：
```javascript
function test(){
    for(var i = 0; i < 3; i++){}
    console.log(i); // 3
}
```
上面那段代码，在}外依旧能访问到 i 。
let 是块级作用域，而且在全局作用域定义的变量并不会被挂载到global货window中：
```javascript
function test(){
    for(let i = 0; i < 3; i++){}
    console.log(i); // i is defined
}
```
const 是定义常量，和java的final关键字类似，但是有一点区别的是，const定义的如果的对象，则对象里面的参数值是可以改变的，const的作用是保证初始定义的变量的内存地址是不变的。
```javascript
const a = 1;
a = 2; // Assignment to constant variable

const obj = {};
obj.a = 1;
console.log(obj.a); // 1
```
PS: 能用const定义的就用const
