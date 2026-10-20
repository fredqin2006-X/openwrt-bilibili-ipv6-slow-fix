# B 站视频 IPv4 回退服务（OpenWrt / iStoreOS）

版本：0.1.0。面向部分 B 站视频 IPv6 连接间歇停滞、分片重试、拖动进度后长时间等待的情况，让视频连接尽快改用 IPv4。

这是独立的命令行服务 `bili-ipv4`，没有 LuCI 页面。服务利用路由器已有的 dnsmasq、nftables、tcpdump、Lua 和 procd；只对指定 LAN 接口进入、匹配视频目标地址和端口的 IPv6 流量生效。

## 范围与机制

- 识别域名后缀：`bilivideo.com`、`bilivideo.cn`、`bilivideo.net`。
- TCP 端口：80、443、8082、4483；UDP 端口：443、4483。
- dnsmasq 将目标域名的 AAAA 答案加入 IPv6 地址集合；内存中的 TLS SNI / HTTP Host 学习器补充已有 DNS 缓存和自行解析的连接。
- 自有 `inet bili_ipv4` 表快速拒绝这些 IPv6 连接，让支持双栈的客户端尝试 IPv4。
- 目标集合大小上限 4096，默认 1 小时过期；每 5 分钟刷新种子域名，每 15 秒检查自有规则。
- 不关闭系统 IPv6，不修改网络接口、VLAN、IPTV、既有 firewall4 或 Open-Box 配置。DNS 配置中仅增加自己的标记段，与 `xhs-ipv4` 独立运行。

地址集合按 IP 生效，共享同一 CDN 地址及端口的其他站点也可能受到影响。无法正常使用 IPv4 的环境不适合此方案。ECH、加密 DNS、新端口或绕过指定 LAN 接口的连接可能漏识别。

## 安装条件

需要 OpenWrt / iStoreOS 的 firewall4/nftables、procd、支持 `nftset` 的 dnsmasq，以及 `tcpdump`、Lua、`timeout`、`nslookup` 等现有工具。安装器检查这些条件，不自动更换软件包。当前安装器支持一个加载 `/etc/dnsmasq.conf` 的默认 dnsmasq 实例；该文件须为普通文件且以换行结束。

从本仓库的 **Code → Download ZIP** 下载并解压，将整个目录上传到路由器；也可以在有 Git 的电脑上获取：

```sh
git clone https://github.com/fredqin2006-X/openwrt-bilibili-ipv6-slow-fix.git
```

进入路由器上的项目目录后执行：

```sh
sh install.sh --check
sh install.sh
```

LAN 接口默认 `br-lan`，其他部署可指定：

```sh
sh install.sh --check --interface br-home
sh install.sh --interface br-home
```

安装会短暂重启 DNS 服务。首次安装将原始 DNS 配置保存至 `/etc/bili-ipv4-backup/dnsmasq.conf.original`，后续重装不会覆盖它，也不会定时创建备份。同版本、同接口重复安装直接返回。

## 日常使用

```sh
/usr/libexec/bili-ipv4-control status
/usr/libexec/bili-ipv4-control refresh
/etc/init.d/bili-ipv4 restart
logread -e bili-ipv4
```

修改后重新打开视频，观察新的连接，而不要只观察已缓存画面。规则命中计数表示拒绝过目标 IPv6 报文；客户端已经选择 IPv4 时，计数不会持续增长。

## 暂停与完整回退

暂时停止会停止学习和维护进程，并清空自己的转发规则；保留空规则表及地址集合供 DNS 安全使用：

```sh
/etc/init.d/bili-ipv4 stop
/etc/init.d/bili-ipv4 start
```

完整卸载：

```sh
/usr/libexec/bili-ipv4-uninstall
```

卸载仅移除自己的 DNS 标记段和文件，保留当前其他 DNS 配置、`xhs-ipv4` 和原始备份。升级到不同版本前先卸载旧版本。

完整说明见 [运维](docs/operations.md)、[原理](docs/architecture.md)、[排障](docs/troubleshooting.md)、[部署验证记录](docs/validation-2026-10-20.md)。本服务由[小红书 IPv4 回退项目](https://github.com/fredqin2006-X/openwrt-xiaohongshu-ipv6-slow-fix)改编，来源及许可证见 `NOTICE`、`LICENSE`。

## 解析器测试

在有 Python 和 Lua 的电脑上执行：

```sh
python tests/test_learner.py --lua lua
```

测试使用合成数据，不联网，不执行 nft 规则修改。本次路由器部署还用其实际 Lua 运行了 24 组合成报文用例，并完成浏览器播放验证；具体结果见[部署验证记录](docs/validation-2026-10-20.md)。
