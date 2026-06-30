# Status — Shared Libraries

> 当前项目状态。

## 当前概览

`SharedLibraries/` 现阶段是 eMathica 生态系统的真实物理 package root，当前维护 6 个 SwiftPM 包。

| Package | 当前状态 | 风险 | 下一步 |
|---------|---------|------|------|
| `EMathicaMathCore` | Active | Medium | 维持数学引擎稳定性，后续再考虑更细的模块拆分 |
| `EMathicaDocumentKit` | Active | Low-Medium | 稳定文档模型与 `ProjectStore` 协议边界 |
| `EMathicaThemeKit` | Active | Low | 维持视觉令牌与共享 UI 基础 |
| `EMathicaMathInputKit` | Active | Low-Medium | 继续作为共享输入基础 |
| `EMathicaWorkspaceKit` | Active | Medium | 继续收敛与 app 类型的边界 |
| `EMathicaHomeFeature` | Active | Low-Medium | 维持 package-backed 首页主链路，收口 public API |

## 下一步建议

- 保持现有包边界稳定，不急于创建最终 `Packages/` taxonomy
- 继续按需修正包 README，而不是在根目录堆积迁移日志
- 当有新的共享能力成熟时，再决定是否进入 future taxonomy
