# 单篇博客创作

创建一篇 PowerShell 技能连载博客文章，完整流程包括去重检查、写作、lint 和复核。

## 参数

- $ARGUMENTS: 文章主题或日期（如 "2025-05-05 防火墙" 或 "正则表达式"）

## 执行流程

1. **解析输入**：从参数中提取日期和主题。如果只给了主题，日期用下一个工作日；如果只给了日期，根据日期附近的技术热点生成主题。

2. **去重检查**：
```bash
grep -rl "主题关键词" source/_posts/ | head -5
```
如果已有高度重复的文章，调整角度或主题。

3. **生成文章**：用 Write 工具创建 `source/_posts/YYYY-MM-DD-english-slug.md`，严格遵循 CLAUDE.md 中的写作规范：
   - Front matter 格式、基础 tags + 内容 tags（kebab-case）
   - 版本说明行、背景引入、代码块 + 文字说明、执行结果示例、注意事项
   - 不少于 200 行，代码块内不得嵌入三反引号
   - 必须用 Write 工具写文件，不要用 Bash heredoc

4. **Lint 检查**：
```bash
markdownlint source/_posts/YYYY-MM-DD-xxx.md
```
有错误则修复后重新检查。

5. **复核**：
```bash
python3 util/review-article.py --hexo source/_posts/YYYY-MM-DD-xxx.md
```
如果 fail，根据问题清单修复后重新复核，最多重试 2 次。

6. **报告结果**：输出文章路径、行数、复核结果。
