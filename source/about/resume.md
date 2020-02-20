## 联系方式
- 手机：13067979205
- email：mail@zhoumq.cn

## 个人信息
- 周明雀/男/1995
- 工作年限：2.5年
- 专科/广州番禺理工学院/计算机专业
- 博客：[ricky.im](https://www.ricky.im)
- Github：[rickyes](https://github.com/rickyes)
- 期望岗位：Node.js 高级研发工程师/杭州

## 社区贡献
- Nodejs Contributor 贡献 **2** 次 commit , **1** 次 **merge** ([#29673](https://github.com/nodejs/node/pull/29673))
- CNode 社区精华文章 **1** 篇 ([#5b63b25e792f59ae501bf71c](https://cnodejs.org/topic/5b63b25e792f59ae501bf71c))
- NPM Package **19** 个 , **1** 个月下载量 **780+** （[#jasypt](https://www.npmjs.com/package/jasypt)） 
- 博客文章 **15** 篇，**4** 篇阅读量 **100+** （[ricky.im](ricky.im)）

## 工作经历
### 杭州数澜科技 （2018.5 ~ 至今）
- 岗位：Node.js 研发工程师
- 职责：负责内部基础设施 **API Gateway** 的维护与设计开发，设计和实施大数据应用的开发

项目：
1. 内容资产平台 （负责管理后台、小程序的开发）
    - 开发二级缓存模块，采用 **Mysql + Redis** 绑定的方案，将每次生成的 **SQL + param** 哈希化生成 **Cache Key** 进行缓存业务数据，解决了小程序端接口并发请求过慢的问题，**QPS** 从 200 提升到了 **2700**，提升了用户体验。
    - 项目中用到分布式定时任务的功能，调研了社区多个技术方案后（包括多节点、重试、持久化），最后采取 **bull** 作为定时任务的工具库，由于业务需求需要每个月最后一天的功能项，但 **bull** 依赖的 **cron parser** 库不支持，遂向 **bull** 上游 **cron-parser** 提了 PR（[#133](https://github.com/harrisiirak/cron-parser/pull/133)），最后由于作者对于架构的考虑没合并只好维护在内部仓库使用。
2. API 网关（维护与开发）
    - 使用 Redis 作为 API 元信息存储，作为管理端与代理端的 API 元信息中的中间存储，加快了代理端转发请求时查询 API 元信息的速度
    - 使用加权轮询法负载多个后端节点，保证高低配机器之间流量的比例权重
    - 开发协议转换，将 HTTP 请求转换为 Dubbo 请求，解决了公司内部不同技术体系之间的服务不共用、重复造轮子的问题，公司节省了更多共用中间件的开发成本

### 广州翔梦信息 （2017.9 ~ 2018.5）
- 岗位：Node.js 游戏服务端工程师
- 职责：负责几款微信小游戏、跨平台终端游戏的开发

项目：
1. 棋牌游戏
    - 使用 pomelo 重构 Express 应用，将单机应用转换为多节点的分布式服务应用，每个玩法单独部署到不同节点，提升了机器的资源利用率和服务的高可用


## 开源项目
- [polix](https://github.com/polixjs/polix) ：Node.js 装饰器、插件式 Web 框架 (27 star , 2 fork)
- [jasypt](https://github.com/rickyes/jasypt)：和 Java/jasypt 保持一致的配置项加解密库
- [kiritobuf](https://github.com/rickyes/kiritobuf)：类似 Protobuf 语法的 IDL库
- [polix-rpc](https://github.com/polixjs/polix-rpc)：基于 kiritobuf 序列化的 RPC 库

## 技术文章
- [从零开始实现一个IDL+RPC框架](https://cnodejs.org/topic/5b63b25e792f59ae501bf71c)
- [Node.js 应用性能调优](https://www.ricky.im/2018/11/06/performance-analysis/)