---
title: Redis 高效删除大集合键
date: 2019-12-15 20:09:29
tags: [Lua, Redis]
categories: 
- Redis
---

在平常的业务中，很多情况下都会有大集合的场景，这批数据等活动结束后就需要删除掉。
一想到删除就用del啊，但是大家都知道，redis 的 del 删除复杂数据结构的时间复杂度是O(N), 其中N是集合的元素个数，
而且 redis 是单线程的，N要是巨大的话是会阻塞其他命令执行的。

## 准备数据

首先用 lua 构造了 1千万 元素的集合
``` lua
local i = 0
local key = KEYS[1]
local sadd_result = nil

while (true) do
  i = i + 1
  sadd_result = redis.call('sadd', key, i)
  if (i >= 10000000) then
    break
  end
end

return 1
```

可以看到这一千万的集合有566.65M的内存占用
``` sh
127.0.0.1:6379> info memory
# Memory
used_memory:594177464
used_memory_human:566.65M
used_memory_rss:607588352
used_memory_rss_human:579.44M
used_memory_peak:594177464
used_memory_peak_human:566.65M
used_memory_peak_perc:100.00%
used_memory_overhead:836230
used_memory_startup:786456
used_memory_dataset:593341234
used_memory_dataset_perc:99.99%
total_system_memory:2096058368
total_system_memory_human:1.95G
used_memory_lua:44032
used_memory_lua_human:43.00K
maxmemory:0
maxmemory_human:0B
maxmemory_policy:noeviction
mem_fragmentation_ratio:1.02
mem_allocator:jemalloc-4.0.3
active_defrag_running:0
lazyfree_pending_objects:0
```

## 删除大数据集合

#### del

``` sh
127.0.0.1:6379> del t
(integer) 1
(5.55s)
```

可以看到，del 操作用了 5.55 秒！

对于这个问题，官方在 4.0.0 版本开始，提供了新的非阻塞API : unlink, 该命令执行的时候会先删除元数据， 后续才会在另一个线程中回收内存。
对于 4.x 以下版本，只能拆分为N个O(1)操作的删除了。


#### Node.js 分批删除


#### unlink