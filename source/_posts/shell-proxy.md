---
title: 让设置终端代理更容易一点
date: 2018-10-29 17:38:22
tags: [shell, proxy]
categories: 
- shell
---

之前编译v8的时候，需要先去Google的代码仓库拉取depot_tools，所以就需要终端走代理才能走得通了，得让终端的http或https代理到本地的socks5协议。需求是这样的，可以用开关控制是否代理。
shell脚本如下：
``` shell
#!/bin/bash

# .socks5-proxy.sh
proxy=$1

if [ -z $proxy ]; then
read -p "请输入使用使用代理? (y/n) " -n 1 -r proxy
echo
fi

if [ $proxy = 'y' ]; then
export http_proxy=http://127.0.0.1:1087
export https_proxy=http://127.0.0.1:1087
echo "http_proxy:  "$http_proxy
echo "https_proxy: "$https_proxy
echo "已开启代理"
else
export http_proxy=
export https_proxy=
echo "已关闭代理"
fi
```
没权限的话，先执行下`chmod +x .socks5-proxy.sh`, 放在$HOME目录下
直接在当前目录执行这段脚本是不生效的，因为执行这段脚本的时候是单独的子shell进程，设置的变量退出后是不会同步到父进程的，需要在当前的进程source .socks5-proxy.sh，将脚本的变量设置到当前进程。

在bash_profile文件里设置别名：
`alias proxy='source "$HOME/.socks5-proxy.sh"'`

重启终端或新开个窗口
- 开启代理
``` shell
$ proxy y
```
- 关闭代理
``` shell
$ proxy n
```
效果图：
![image](https://user-images.githubusercontent.com/20432815/47641074-0f22f680-dba0-11e8-8367-1c2e95c9dcfd.png)
