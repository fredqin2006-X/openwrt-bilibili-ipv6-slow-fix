# bili-ipv4 运维说明

## 文件与状态

| 位置 | 用途 |
|---|---|
| `/etc/init.d/bili-ipv4` | 开机和 procd 管理入口 |
| `/etc/bili-ipv4/domains` | 精确的域名后缀集合，每行一个 |
| `/etc/bili-ipv4/hosts` | 定期刷新 AAAA 的种子主机名 |
| `/etc/bili-ipv4/options` | `LAN_IFACE` 接口配置 |
| `/etc/bili-ipv4/VERSION` | 当前安装版本 |
| `/usr/libexec/bili-ipv4-control` | 状态、规则恢复、DNS 刷新 |
| `/usr/libexec/bili-ipv4-monitor` | tcpdump/Lua 监测进程的生命周期 |
| `/usr/libexec/bili-ipv4-learn.lua` | 合成 pcap / 真实 TLS、HTTP 的解析器 |
| `/usr/libexec/bili-ipv4-uninstall` | 完整卸载 |
| `/var/run/bili-ipv4/live.pcap` | 内存 FIFO，不是不断增长的抓包文件 |
| `/etc/bili-ipv4-backup/dnsmasq.conf.original` | 首次安装时的固定备份 |

查看状态及命中数：

```sh
/usr/libexec/bili-ipv4-control status
/etc/init.d/bili-ipv4 enabled
nft list chain inet bili_ipv4 forward
logread -e bili-ipv4
```

`running` 表示服务受 procd 管理；还应检查两个实例和实际视频连接。集合出现地址并不代表客户端已经回退；需要同时看新连接使用的地址族。

## 暂停、启动、开机状态

```sh
/etc/init.d/bili-ipv4 stop
/etc/init.d/bili-ipv4 start
/etc/init.d/bili-ipv4 restart
/etc/init.d/bili-ipv4 disable
/etc/init.d/bili-ipv4 enable
```

`stop` 停止两个实例并清空自己的 `forward` 链，使规则停止限制 IPv6；地址集合留给 DNS 写入，避免引用不存在的集合。`start` 恢复两条规则。`disable` 仅取消开机启动，需同时执行 `stop` 才会立即暂停。

停止状态下，路由器重启后内存中的表会消失，DNS 配置仍含 nftset 引用。因此长期不用时请完整卸载，不建议长期只禁用开机启动。

## 域名、种子和接口调整

`domains` 决定学习器允许的后缀；`hosts` 用来在启动和周期维护时刷新该后缀下的具体主机名。仅增加 `hosts` 不会扩大域名范围。改变种子主机后执行：

```sh
/usr/libexec/bili-ipv4-control refresh
```

修改 `domains` 时，必须同步 `/etc/dnsmasq.conf` 中 `BEGIN BILI-IPV4` / `END BILI-IPV4` 之间的 `nftset` 行，然后验证并重启 DNS、重启本服务。不要直接加入 `bilibili.com` 或其他大范围域名来处理单个视频节点问题。

改变 LAN 接口时，应完整卸载后使用安装器的 `--interface` 参数重装。这样可以重新检查接口与已有配置。

## 完整卸载与升级

```sh
/usr/libexec/bili-ipv4-uninstall
```

卸载顺序是：删除自己的 DNS 标记段 → 校验 DNS 配置 → 重启 DNS → 取消本服务启动并停止 → 删除自有 nft 表和文件。它不会把旧备份整份覆盖到当前 DNS 配置上，也不会删除其他项目的配置段。

升级操作：保存需要保留的 `hosts` 调整，卸载，上传新版本，先 `sh install.sh --check`，再安装。首次原始备份固定保留，不会在升级或定时任务中重复创建。

若安装期间失败，安装器会尝试恢复本次操作前的 DNS 文件并移除本次安装。若卸载因 DNS 标记不完整而退出，应先查看当前 DNS 文件和备份，修复自己的标记段后重试；不要用历史备份覆盖后来新增的其他服务配置。

## 验收流程

1. 确认代理状态和真实浏览器路径，与变更前一致。
2. 打开此前卡顿的分集，在未缓冲位置跳转，记录首帧、恢复时间、缓冲剩余量。
3. 检查视频分片新连接确实使用 IPv4，并检查规则命中。不要把改走本机代理当成路由器规则的效果。
4. 对照网络、firewall、DHCP、Open-Box 和已有小红书服务配置，确认接口和 IPTV 状态。
5. 如果不能改善或导致兼容性问题，执行完整卸载，再观察新连接。

短期播放通过不能证明所有终端、所有课程或长期网络条件均已覆盖。手机应用、加密 DNS 和新 CDN 需要在各自终端上验证。
