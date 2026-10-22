# AI 必读：本目录是工作副本

**日期：2026-10-17（2026-10-22 更新踩坑记录）**

本目录（`双准直-修改版\`）是从 `..\双准直\` **完整复制**出来的工作副本。原始工程 `..\双准直\` 已移出工作区，仅作对照参考。

- **所有修改只在本目录进行**；git 仓库也在本目录（`.git` 在 `双准直-修改版\` 这一层）；
- 工作区根目录 `..\README.md` 是变更台账（**注意：它在 git 仓库外，git 不管理它**），改动完成后请到该文件登记一条修改记录；
- 远程仓库：`https://github.com/shuaiqideqo/pabi-F103rct6`（master，已配置跟踪）。

主要代码位置：`pabi_F103rct6\Core\Src\main.c`（AUTO 流程 / PID / 协同协议 / 视觉纠偏协议）、`Core\Src\spi.c`（NRF24L01 驱动）。

---

## 踩坑记录（前人摔过的跟头，别再摔）

### 1. git 提交：绝不用 `git add -A`

工作区里有 126MB 的整包备份 zip 和各种产物。`git add -A` 会把它们卷进提交，导致 push 传输数 MB 二进制，走代理直接超时（curl 28 / RPC failed）。
**正确做法**：`git add <具体文件>` 只加源码和文档；提交前用 `git status` 确认没有 zip/产物混入。

### 2. git push：必须走本机代理

GitHub **直连会被重置/无法连接**（Connection reset / couldn't connect 443），这是本机网络的固定行为。
仓库配置里已写死 `http.proxy = http://127.0.0.1:7890`，直接 `git push` 即可。
**如果 push 报连接失败**：先确认本机代理工具（7890 端口）在运行，再重试；不要试图直连。

### 3. 推送失败的"假象"：Everything up-to-date ≠ 成功

push 报 RPC/curl 错误后又打出 "Everything up-to-date" 时，**不代表已推送**（真推送过会有 `master -> master` 进度行）。
**验证方法**：`git ls-remote origin master` 看远端哈希是否等于本地 HEAD。不相等就是没推上去。

### 4. OpenOCD 烧录：路径必须 ASCII + 正斜杠

OpenOCD 的 TCL 会把路径里的 `\b` 等当转义符吃掉，中文路径再叠一层编码问题——**直接烧 `build\` 下的 hex 必失败**。
**正确做法**：用 `_flash_fixed.bat`（先把 hex 拷到 `C:\Temp\pabi_flash` 短路径，再正斜杠烧录）。别用 `flash_now.bat`（它有这个 bug）。

### 5. OpenOCD 连接失败：init mode failed ≠ 立即换脚本

"unable to connect to the target" 且 Target voltage 有读数 → 大概率是 SWDIO/SWCLK 两根线接触不良（挪车蹭松最常见）。
**排查顺序**：重插 SWDIO(PA13)/SWCLK(PA14) 两根线 → 换杜邦线 → ST-LINK USB 重插 → 子机断电重上电。
降速(100kHz)+`connect_assert_srst` 变体可以试，但物理断线换什么参数都没用。

### 6. printf 不能用 %f

GCC nano.specs 下 `%f` 不生效。调试打印浮点用 `(int)(x*10)` 之类整数技巧。

### 7. STM32F103 注意

- `MA_V_GET` 的"转"按 **7 计数/转** 约定，别用错换算；
- 里程计/编码器读数要处理 **16 位回绕**（int16 差值法）；
- `printf` 走 `fputc`→USART1 重定向，MicroLib 下可用，阻塞式发送（每字符最多 100ms 超时）。