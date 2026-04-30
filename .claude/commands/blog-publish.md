# 博客发布

验证所有新增文章，提交 git 并部署到 GitHub Pages。

## 参数

- $ARGUMENTS: 可选，"push" 直接推送，"deploy" 推送并部署。留空则逐步确认。

## 执行流程

### 1. Lint 全部新增文章

```bash
markdownlint source/_posts/YYYY-MM-DD-*.md
```

有错误则修复后重新检查。

### 2. Hexo 验证

```bash
npx hexo clean && npx hexo generate
```

关注是否有新增的 ERROR 类型（主题本身的 sidebar widget ERROR 是已知问题）。验证通过后继续。

### 3. Git 提交

```bash
git add source/_posts/YYYY-MM-DD-*.md [其他修改的文件]
git commit -m "新增 N 篇 PowerShell 技能连载博客"
```

### 4. 推送（需确认）

```bash
git push origin source
```

### 5. 部署（需确认）

```bash
npx hexo deploy
```

部署会将静态文件推送到 master 分支，自动生效于 blog.vichamp.com。

**注意**：推送和部署步骤默认需要用户确认。只有当参数包含 "push" 或 "deploy" 时才跳过确认。
