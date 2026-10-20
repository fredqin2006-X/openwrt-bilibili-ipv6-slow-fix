# 排障

## 服务 running，但没有命中

先打开一个新的 B 站视频或切换到未缓冲的分集。客户端已经走 IPv4、正在使用现有连接、只播放已缓存内容，都可能不增加拒绝计数。

```sh
/usr/libexec/bili-ipv4-control status
/usr/libexec/bili-ipv4-control refresh
nft list set inet bili_ipv4 targets6
```

检查 `LAN_IFACE` 是否为客户端实际进入的桥接口；DNS 是否使用本机 dnsmasq；该 DNS 实例是否实际加载 `/etc/dnsmasq.conf`。如果浏览器走本机代理，浏览器显示的 `127.0.0.1` 只代表代理入口，需确认代理的实际出口地址族。

## 集合有地址，但仍然卡

实际检查视频请求，而不只看网页或头像。确认新的视频连接使用 IPv4，留意是否存在未覆盖的新域名或端口。如果 IPv4 本身也慢，本服务不能解决；先临时停止对照，必要时完整卸载。

自动清晰度切换、播放器自身重试、服务器限流、IPv4 链路拥塞及解码问题都可能出现类似现象。切换分集或拖动进度也会主动取消旧请求，不能把所有 `ERR_ABORTED` 都算成网络故障。

## 防火墙重载后失效

```sh
/usr/libexec/bili-ipv4-control ensure
/usr/libexec/bili-ipv4-control refresh
```

维护进程应在最多约 15 秒内检查自己的表。确认两个 procd 实例都存在；不要执行 `nft flush ruleset` 来处理本服务问题，这会影响其他服务和防火墙。

## 学习器退出或资源异常

```sh
logread -e bili-ipv4
/etc/init.d/bili-ipv4 restart
```

检查 `/var/run/bili-ipv4/live.pcap` 是否为 FIFO（文件类型显示为 `p`）。服务不应持续写入普通 pcap 文件。解析器最多缓存 1024 个短时 TCP 片段流，集合上限 4096；若自定义域名范围过大，应恢复视频域名范围后重启。

## 一键撤销

```sh
/usr/libexec/bili-ipv4-uninstall
```

卸载后重新打开视频，观察新连接。保留的 `/etc/bili-ipv4-backup/dnsmasq.conf.original` 只用于人工核对，不应直接覆盖已经发生其他变更的当前 DNS 配置。
