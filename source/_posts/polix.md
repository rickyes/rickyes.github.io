---
title: 装饰器、插件式 node.js web / restful api 框架
date: 2018-07-22 23:49:15
tags: [Node.js, RestfulAPI,JavaScript,Koa]
categories: 
- Node.js
---

`polix`是基于`koa v2.5.0`的`IOC`、插件式开发框架,和平常的`Node.js Web Framework`相比，它无需另外绑定路由集合、可拓展、开发简单，依照`java`的著名依赖注入框架`spring`来制作，让开发者专注于逻辑。`polix`采用多服务多进程架构来保证服务的稳定和快速响应能力。`polix`的中间件和`koa v2.x`的中间件保持兼容。默认使用的`ORM`是`sequelize`(后续会提供`polix-orm`)。开发者可以选择ES6/7/8 或者 TypeScript来进行开发。

```bash
$ npm i polix --save
```

## Getting Started
> 使用`polix-cli`初始化应用
```bash
$ npm i polix-cli -g
$ pol init example && cd example
$ make build && make dev
```

<!-- more -->

## Service
> 在`service`文件夹下添加`user.js`

```javascript
const { Service } = require('polix');

class UserService extends Service {
  constructor(){
    super();
    this._name = {};
  }

  async addUser(userId,name){
    this._name[userId] = name;
    return this;
  }

  async getUser(userId){
    return this._name[userId];
  }
}

module.exports = UserService;
```

## Controller
> 在`controller`文件夹下添加`user.js`

```javascript
const { Controller, GET, POST, DEL, PUT  } = require('polix');

class UserController extends Controller {
  
  // POST /user/addUser
  @POST
  async addUser(param, ctx){
    await this.service.user.addUser(param.userId,param.name);
    ctx.body = {
      result: 'ok'
    };
  }

  // GET /user/getUser
  @GET
  async getUser(param, ctx){
    let user = await this.service.user.getUser(param.userId);
    ctx.body = {
      user
    };
  }

  // GET /user/info
  @GET('info')
  async getInfo(param, ctx){
    ctx.body = {
      v: 'v1.0'
    }
  }

  // PUT /user/updateUser
  @PUT
  async updateUser(param, ctx){
    ctx.body = {
      status: true
    }
  }

  // DEL /user/delUser
  @DEL
  async delUser(param, ctx){
    ctx.body = {
      status: true
    };
  }

  // GET /user/status/:userId
  @GET('status/:userId')
  async getStatus(param, ctx){
    ctx.body = {
      status: true,
      userId: param.userId
    };
  }

}

module.exports = UserController;
```

## Middware
`polix`的中间件与koa 2.x 的中间件保持兼容  
框架默认加载`koa-body`中间件，如需另外添加中间件则新建`middware`文件夹（与`controller`文件夹平级）  
添加跨域中间件 ，新建`cors.js`:  
```javascript
# cors.js

const cors = require('koa2-cors');
module.exports = function(){
  return cors({
    origin: function(ctx) {
      return '*';
    },
    exposeHeaders: ['WWW-Authenticate', 'Server-Authorization'],
    maxAge: 5,
    credentials: true,
    allowMethods: ['GET', 'POST', 'DELETE'],
    allowHeaders: ['Content-Type', 'Authorization', 'Accept']
  });
}
```
该文件夹下必须存在`index.js`文件作为总输出中间件文件,加载时根据导出对象的顺序进行绑定中间件

```javascript
# index.js

const cors = require('./cors');

module.exports = {
    cors // 必须是函数 ,绑定方式为：app.use(cors())
}
```

## Plugin
```shell
$ npm i --save polix-request
```
> 在项目根目录下的`config`文件夹下的`plugin.default.js`中添加以下代码

```js
// `curl`最终会挂载到`this.app`下
exports.curl = {
  // 表示是否启用该插件
  enable: true,
  // 插件`npm`包名
  package: 'polix-request'
};
```
> 在`controller`里用`polix-request`

```js
  @GET
  async getWebInfo(param, ctx){
    let result = await this.app.curl.get('https://www.baidu.com');
    ctx.body = {
      data: result
    }
  }
```
> `polix`已经内置`polix-request`插件了，这里只是个演示

## Start

```bash
$ make dev
```

> 通过这个框架，还是会学到挺多东西，继续加油

地址：[https://github.com/polixjs/polix](https://github.com/polixjs/polix)
