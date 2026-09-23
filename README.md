# CAHighFPS — Overdrive 个人修改版

基于 [PoomSmart/CAHighFPS](https://github.com/PoomSmart/CAHighFPS) 的个人修改版，针对 **roothide（relaxin）越狱环境** 重新打包，并加入若干体验优化。

原项目的工作原理（CADisplayLink / CAMetalLayer 强制高帧率）见[上游 README](https://github.com/PoomSmart/CAHighFPS#readme)，此处不再重复。

## 与原版的区别

| 项目 | 原版 | Overdrive 修改版 |
|---|---|---|
| 软件包格式 | rootful / rootless | **roothide**（`iphoneos-arm64e`），依赖框架链接采用 `@loader_path/.jbroot` 相对路径规范 |
| 设置界面语言 | 英文 | 简体中文（保留英文回退，自动跟随系统语言） |
| 设置列表图标 | 无 | "120Hz" 图标 |
| 帧率下限 | `preferredFrameRateRange` 的 `minimum` 硬编码为 30 | 保留 App 自身请求的下限，不强制抬高；ProMotion 1–120Hz 自适应可进入低帧档，更省电 |
| 自定义帧率 | min/preferred/max 全部钉死在同一值 | 保留 15fps 缓冲带（`minimum = 目标值 − 15`），偶发掉帧时系统有降档余量 |
| Metal Hack（强制 `maximumDrawableCount = 2`） | 无条件生效 | 新增设置页独立开关（默认开启），Metal 游戏出现顿挫时可单独关闭 |

所有修改仅涉及打包方式与偏好设置侧；核心 hook 逻辑与原版一致。

## 适用情况

- **越狱环境**：roothide 系（relaxin 等），不适用于传统 rootful 或 rootless
- **系统**：iOS 15 及以上；已在 iOS 17.0 实测
- **设备**：arm64e 设备（iPhone XS 及之后）首选；已在 iPhone 15 Pro（A17 Pro / 120Hz ProMotion）测试
- **依赖**：`com.opa334.altlist`（roothide 版本，白名单 / 黑名单应用选择器所需）

## 安装

1. 从本仓库 [Releases](../../releases) 下载 deb
2. 通过 Filza 打开安装，或导入 Sileo（会自动补装 AltList 依赖）
3. 注销（respring）后进入 设置 → CAHighFPS

> 修改设置后需要**重新打开目标 App** 才会生效。

## 构建

通过 GitHub Actions（macOS runner + roothide Theos）自动构建，主插件与偏好设置包均为 arm64 + arm64e FAT 双架构。依赖框架 AltList 亦以 roothide scheme 编译，保证运行时动态库路径可解析。

## 声明

- 本项目**仅供个人测试与学习研究使用**，请勿用于商业用途或二次分发
- 使用风险自负：强制高帧率会增加耗电，Metal 应用表现因 App 而异
- 原项目版权归 [PoomSmart](https://github.com/PoomSmart) 所有，本修改版与原作者无关；修改版相关问题请在本仓库提 Issue，请勿打扰原作者
