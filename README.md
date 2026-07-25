# 泽阳的涂鸦空间

个人博客 **繁星 の 夜** 的源码仓库,线上地址:<https://www.ricky.im>

## 文章索引

### Node.js
- [从零开始实现一个IDL+RPC框架](https://github.com/rickyes/rickyes.github.io/issues/1)
- [Node.js 应用性能调优](https://github.com/rickyes/rickyes.github.io/issues/4)
- [从 unref 看事件循环](https://www.ricky.im/2020/03/29/time-unref/)
- [Boa 如何使用 ES Module 加载 Python 包](https://www.ricky.im/2020/05/18/nodejs-esm-loader/)

## 项目开发

### 技术栈

| 项目 | 说明 |
| --- | --- |
| 静态生成器 | [Hexo](https://hexo.io/) 8.x |
| 主题 | [hexo-theme-sagiri](themes/sagiri)(NexT 分支,Swig 模板 + Stylus,已内置于仓库) |
| 托管 | GitHub Pages(<https://rickyes.github.io>),GitHub Actions 自动构建 |
| Node.js | >= 18 |

主要插件:`hexo-renderer-swig`(主题模板)、`hexo-renderer-marked`(Markdown)、`hexo-renderer-stylus`(主题样式)、`hexo-generator-search`(站内搜索 `search.xml`)、`hexo-wordcount`(字数统计)等,完整列表见 [package.json](package.json)。

### 目录结构

```
├── _config.yml          # 站点配置(Hexo 主配置)
├── scaffolds/           # 新建文章/页面的模板
├── source/
│   ├── _posts/          # 博客文章(Markdown)
│   ├── images/          # 文章图片,文中用 /images/xxx.jpg 引用
│   ├── about/ read/ project/ ...  # 独立页面
│   └── _redirects       # Netlify 重定向规则(迁移 Pages 后仅作备份)
├── themes/
│   ├── sagiri/          # 当前使用的主题(themes/sagiri/_config.yml 为主题配置)
│   └── next/            # 历史留存的 NexT 主题,未使用
├── .github/workflows/   # GitHub Pages 自动部署
└── public/              # 构建产物(已 gitignore,勿手动修改)
```

### 环境准备

```bash
node -v        # 要求 >= 18
npm install    # 统一使用 npm(仓库仅维护 package-lock.json)
```

### 常用命令

| 命令 | 作用 |
| --- | --- |
| `npm start` | 本地预览,默认 <http://localhost:4000> |
| `npm run dev` | 本地预览并渲染草稿 |
| `npm run new -- "文章标题"` | 按 `scaffolds/post.md` 模板创建文章到 `source/_posts/` |
| `npm run build` | 清理并生成静态文件到 `public/` |
| `npm run clean` | 清理缓存(db.json)与 `public/` |

### 写作流程

1. `npm run new -- "文章标题"` 创建文章,或直接复制已有文章;
2. 编辑 `source/_posts/xxx.md`,按需补充 front-matter(`title`、`date`、`tags`、`categories`);
3. `npm start` 本地预览确认排版;
4. 提交并推送到 `master` 即自动发布。

### 图片管理

- 图片统一放在 `source/images/`,文章中用**根相对路径**引用:`![描述](/images/xxx.jpg)`;
- 该目录会被 Hexo 原样拷贝到 `public/images/`,本地 `npm start` 预览与 GitHub Pages 线上路径一致,均可正常显示;
- 新增图片直接提交到 `source/images/` 即可,无需任何额外配置;
- 主题前端依赖(Font Awesome、jQuery、Fancybox CSS 等)已全部内嵌到 `themes/sagiri/source/lib/`,不再依赖 `cdn.bootcss.com` 等外部 CDN;
- 历史图片已从旧 CDN(cdn.zhoumq.cn → cdn.hypertextlink.cn)全部取回并内嵌到仓库,不再依赖外部图床。

### 部署

推送 `master` 分支后由 GitHub Actions 自动构建并发布到 GitHub Pages(见 [.github/workflows/deploy.yml](.github/workflows/deploy.yml))。

首次启用需在仓库设置中操作:**Settings → Pages → Build and deployment → Source 选择 "GitHub Actions"**。

- 构建命令:`npm run build`(即 `hexo clean && hexo generate`)
- 发布目录:`public/`(由 Actions 上传,无需提交到仓库)
- 绑定自定义域名后,记得把 `_config.yml` 中的 `url` 改回对应域名

### 升级备忘(2026-07)

- Hexo 3.7 → 8.1,全部插件升级到最新大版本;
- Hexo 4+ 移除了内置 Swig 渲染器,需显式安装 `hexo-renderer-swig`;
- 主题引用的 `nprogress.css`、`balloon.css` 原依赖主题目录下的 `node_modules`,已内嵌到 `themes/sagiri/source/css/vendor/`,构建自包含、无需额外安装步骤;
- `_config.yml` 中 `external_link` 改为对象写法,并新增 `include: [_redirects]`(Hexo 默认忽略 `_` 开头文件);
- 移除未使用的 `hexo-deployer-git` 部署配置与 `yarn.lock`,统一 npm;
- 图片从 raw.githubusercontent.com / cdn.zhoumq.cn 全部迁移到仓库内 `source/images/`,主题 favicon、头像、头图改为本地资源;
- 主题前端依赖(Font Awesome 4.7、jQuery 2.1、Fancybox 2.1 CSS)从 `cdn.bootcss.com` 内嵌到 `themes/sagiri/source/lib/`,构建零外部 CDN 引用;
- 修复 Hexo 7+ `paginator()` 默认转义导致翻页按钮 HTML 实体泄露的问题,给模板加了 `escape: false`。
- 托管从 Netlify 切换到 GitHub Pages(Actions 构建部署),`url` 改为 `https://rickyes.github.io`。

## License

[MIT](LICENSE)
