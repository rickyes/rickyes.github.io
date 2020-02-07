---
title: 项目结构那些事
date: 2020-02-05 11:25:21
tags: [Koa, 项目结构]
categories: 
- 项目结构
---

### 背景
一开始项目的业务需要比较简单，采取了 `controller -> model` 的形式进行开发。随着业务量的增加，以前的结构已经不适应于快速的迭代节奏，代码耦合度高，很难复用，维护也很困难。参考着以前写 android 的经验和社区的优秀案例，采取了 `controller -> service -> model` 的模式重构了项目结构。

### 项目结构

![app](https://raw.githubusercontent.com/rickyes/rickyes.github.io/master/image/app.png)

### 接口处理流程

![appp](https://raw.githubusercontent.com/rickyes/rickyes.github.io/master/image/appp.png)

- 收到请求，middleware 打印请求日志、解析请求参数等
- 匹配接口路由，接口参数格式检查
- controller 接收接口参数，调用代理方法获取结果并返回给客户端
- service 接收方法入参，调用模型方法处理数据和逻辑计算
- model 将接收到的参数进行更新到数据库

### 开发
- 【 model 】sequelize 作为 orm 与数据库交互，但是写多了之后发现很多代码是可以复用的，需要让应用开发更简单，因此封装了 [sequelize-base](https://www.npmjs.com/package/sequelize-base) 这个库来操作数据库，本身也是对 `sequelize` 常用方法的包装，再加了缓存的一些配置项提供二级缓存的能力。

示例：

``` js

'use strict';
 
const Base = require('sequelize-base');
const {User} = require('./db');

class UserModel extends Base {

  constructor(opts) {
    super(opts);
  }

  static getInstance(opts = {
    entity: User,
  }) {
    if (!this.instance) {
      this.instance = new UserModel(opts);
    }
    return this.instance;
  }

}

module.exports = UserModel;
```

- 【 cache 】 我们封装了和 `sequelize-base` 联动的缓存插件 [ficache](https://www.npmjs.com/package/ficache), 在逻辑层不用改一行代码引入缓存的功能

示例：

``` js

'use strict';
 
const Cacher = require('ficache');
const Base = require('sequelize-base');
const {User,pool} = require('./db');
const redis = require('../cache/redis');
const log = require('../../common/log');

class UserModel extends Base {

  constructor(opts) {
    super(opts);
  }

  static getInstance(opts = {
    entity: User,
    cacher: new Cacher({
      dbClient: pool,
      cacheClient: redis.client,
      model: User,
      logger: log,
    }),
  }) {
    if (!this.instance) {
      this.instance = new UserModel(opts);
    }
    return this.instance;
  }

}

module.exports = UserModel;
```

- 【 config 】多环境配置，每个环境单独的配置文件，支持外部配置文件启动进程，公司主要是 Java 技术体系，在配置项加密那块为了和 Java 保持一致，封装了 [jasypt](https://www.npmjs.com/package/jasypt) 进行 Node.js 应用的配置项加密启动

示例：

``` js

// ....

const config = {
  mysql: {
    username: 'ENC(3pArQBqCCcIDfhVVmb3kKQ==)',
    host: '127.0.0.1',
    password: 'ENC(nM/WQd+0VRn6EpnmkXODgA==)',
  }
};

if (process.env.JASYPT_PASSWORD) {
  jasypt.setPassword(process.env.JASYPT_PASSWORD);
  jasypt.decryptConfig(config);
}
```