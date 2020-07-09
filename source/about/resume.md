## 联系方式
- 手机：13067979205
- email：ives199511@gmail.com

## 个人信息
- 周明雀/男/1995
- 工作年限：3 年
- 专科/广州番禺理工学院/计算机专业
- 博客：[ricky.im](https://ricky.im)
- Github：[rickyes](https://github.com/rickyes)
- 期望岗位：Node.js 高级研发工程师/广州

## 社区贡献
- Node.js Core 贡献 20 余次 commit ,  目前是 Contributor ，正在冲刺 Collaborator
- 阿里巴巴前端机器学习应用框架 [Pipcook](https://github.com/alibaba/pipcook) 贡献者，跨语言工作组成员
- CNode 社区精华文章 **2** 篇 ([cnodejs.org](https://cnodejs.org/user/zhoumingque))
- NPM Package **19** 个 , **1** 个月下载量 **780+** （[#jasypt](https://www.npmjs.com/package/jasypt)）

## 工作经历

### YY 欢聚时代 - SHOPLINE （2020.6 ~ 至今）
- 岗位：研发工程师
- 职责：SHOPLINE-Live 直播导购开发与维护

### 杭州数澜科技 （2018.5 ~ 2020.5）
- 岗位：Node.js 研发工程师
- 职责：负责内部基础设施 **API Gateway** 的维护与设计开发，设计和实施大数据应用的开发

项目：
1. 内容资产平台 （负责管理后台、小程序的开发）
    - 开发二级缓存模块，采用 **Mysql + Redis** 绑定的方案，将每次生成的 **SQL + param** 哈希化生成 **Cache Key** 进行缓存业务数据，解决了小程序端接口并发请求过慢的问题，**QPS** 从 200 提升到了 **2700**
    - 项目中用到分布式定时任务的功能，调研了社区多个技术方案后（包括多节点、重试、持久化），最后采取 **bull** 作为定时任务的工具库，由于业务需求需要每个月最后一天的功能项，但 **bull** 依赖的 **cron parser** 库不支持，遂向 **bull** 上游 **cron-parser** 提了 PR（[#133](https://github.com/harrisiirak/cron-parser/pull/133)），最后由于作者对于架构的考虑没合并只好维护在内部仓库使用。
    - 沉淀多个通用 NPM 包，包括数据库通用函数库 （[sequelize-base](https://www.npmjs.com/package/sequelize-base)）、数据库二级缓存（[ficache](https://www.npmjs.com/package/ficache)）和 配置项加密（[jasypt](https://www.npmjs.com/package/jasypt)）
2. API 网关（维护与开发）
    - 使用 Redis 作为 API 元信息存储，作为管理端与代理端的 API 元信息中的中间存储，加快了代理端转发请求时查询 API 元信息的速度
    - Redis Lua Script 方式，使用令牌桶算法对指定时间窗口的接口高效限流
    - 使用加权轮询法负载多个后端节点，保证高低配机器之间流量的比例权重
    - 开发协议转换，接口级别请求分发将 HTTP 转换为 Dubbo 协议报文，提高公司内部通用组件的复用性。
    - 使用 alinode 监控保障 SaaS 服务
    - 开发、压测阶段使用火焰图排查 CPU 热点函数

### 广州翔梦信息 （2017.9 ~ 2018.5）
- 岗位：Node.js 游戏服务端工程师
- 职责：负责几款微信小游戏、跨平台终端游戏的开发

项目：
1. 棋牌游戏
    - 使用 pomelo 重构 Express 应用，将单机应用转换为多节点的分布式服务应用，每个玩法单独部署到不同节点，提升了机器的资源利用率和服务的高可用


## 开源项目
- [polix](https://github.com/polixjs/polix) ：Node.js 装饰器、插件式 Web 框架 ( 29 star )
- [jasypt](https://github.com/rickyes/jasypt)：和 Java/jasypt 保持一致的配置项加解密库
- [kiritobuf](https://github.com/rickyes/kiritobuf)：类似 Protobuf 语法的 IDL 语言
- [polix-rpc](https://github.com/polixjs/polix-rpc)：基于 kiritobuf 序列化的 RPC 库

## 技术文章

- [Node.js 应用性能调优](https://www.ricky.im/2018/11/06/performance-analysis/)
- [从 unref 看事件循环](https://www.ricky.im/2020/03/29/time-unref/)
- [浅谈一致性哈希](https://www.ricky.im/2020/03/11/consistent-hashing/)
- [从零开始实现一个IDL+RPC框架](https://cnodejs.org/topic/5b63b25e792f59ae501bf71c)
- [Boa 如何使用 ES Module 加载 Python 包](https://cnodejs.org/topic/5ec4b241a87fc8583363d488)