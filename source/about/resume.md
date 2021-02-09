## 联系方式
- 手机：15818139876
- email：0x19951125@gmail.com

## 个人信息
- 周明雀/男/1995
- 工作年限：3 年
- 专科/广州番禺职业技术学院/计算机专业
- 博客：[ricky.im](https://ricky.im)
- Github：[rickyes](https://github.com/rickyes)
- NPM: [zhoumq](https://www.npmjs.com/~zhoumq)
- 期望岗位：Node.js 高级研发工程师/广州

## 社区贡献
- Node.js Collaborator， HTTP 工作组成员
- 阿里巴巴前端机器学习应用框架 [Pipcook/Boa](https://github.com/alibaba/pipcook) 贡献者，Boa 跨语言工作组成员
- CNode 社区精华文章 **2** 篇 ([cnodejs.org](https://cnodejs.org/user/zhoumingque))
- NPM Package **19** 个 , **1** 个月下载量 **1.7 k+** （[#jasypt](https://www.npmjs.com/package/jasypt)）

## 工作经历

### SHOPLINE （2020.6 ~ 至今）
- 岗位：研发工程师
- 职责：SHOPLINE-Live 直播导购 /  SHOPLINE 2.0 渲染服务
- 技术栈
    1. Web Framework: express/midway
    2. DB: MongoDB
    3. APM: NewRelic
    
    【2020.6 ~ 2021.1 】 负责 SHOPLINE 1.0 Live 后端服务 、 Node.js 应用性能调优和 MongoDB 查询性能调优。
    【2021.1 - 至今】负责 SHOPLINE 2.0 全站 C 端 SSR 渲染服务系统稳定性保障。

### 杭州数澜科技 （2018.5 ~ 2020.5）
- 岗位：Node.js 研发工程师
- 职责：负责内部基础设施 **API Gateway** 的维护与设计开发，设计和实施大数据应用的开发

项目：
1. 内容资产平台 （负责管理后台、小程序的开发）
    - 开发二级缓存模块，采用 **Mysql + Redis** 绑定的方案，将每次生成的 **SQL + param** 哈希化生成 **Cache Key** 进行缓存业务数据提升 QPS 指标
    - 沉淀多个通用 NPM 包，包括数据库通用函数库 （[sequelize-base](https://www.npmjs.com/package/sequelize-base)）、数据库二级缓存（[ficache](https://www.npmjs.com/package/ficache)）和 配置项加密（[jasypt](https://www.npmjs.com/package/jasypt)）
2. API 网关（维护与开发）
    - Redis Lua Script 方式，使用令牌桶算法对指定时间窗口的接口高效限流
    - 开发协议转换，接口级别请求分发将 HTTP 转换为 Dubbo 协议报文，提高公司内部通用组件的复用性。

### 广州翔梦信息 （2017.9 ~ 2018.5）
- 岗位：Node.js 游戏服务端工程师
- 职责：负责几款微信小游戏、跨平台终端游戏后端的开发

项目：
1. 棋牌游戏
    - 使用 pomelo 重构 Express 应用，将单机应用转换为多节点的分布式服务应用，每个玩法单独部署到不同节点，提升了机器的资源利用率和服务的高可用


## 开源项目
- [polix](https://github.com/polixjs/polix) ：Node.js 装饰器、插件式 Web 框架
- [jasypt](https://github.com/rickyes/jasypt)：和 Java/jasypt 保持一致的配置项加解密库
- [kiritobuf](https://github.com/rickyes/kiritobuf)：类似 Protobuf 语法的 IDL 语言
- [polix-rpc](https://github.com/polixjs/polix-rpc)：基于 kiritobuf 序列化的 RPC 库

## 技术文章

- [Node.js 应用性能调优](https://www.ricky.im/2018/11/06/performance-analysis/)
- [从 unref 看事件循环](https://www.ricky.im/2020/03/29/time-unref/)
- [浅谈一致性哈希](https://www.ricky.im/2020/03/11/consistent-hashing/)
- [从零开始实现一个IDL+RPC框架](https://cnodejs.org/topic/5b63b25e792f59ae501bf71c)
- [Boa 如何使用 ES Module 加载 Python 包](https://cnodejs.org/topic/5ec4b241a87fc8583363d488)
