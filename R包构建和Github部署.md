# R包构建、文档编写和Github部署

> R 包构建（从“写代码”到“能安装、能发到 CRAN/GitHub”）核心就三件事：**搭骨架 → 写函数和文档 → 检查/构建/发布**。

## 摘要：

### 1) 搭一个包的骨架（Package skeleton）

- `usethis::create_package("path/mypkg")`：创建包目录结构
- `usethis::use_git()`：初始化 Git（可选但强烈建议）
- `usethis::use_mit_license("Your Name")` 或 `use_gpl3_license()`：加许可证
- `usethis::use_readme_rmd()`：生成 README（GitHub 很需要）
- `usethis::use_testthat()`：开启单元测试框架

### 2) 包的标准目录结构（你需要理解的“零件”）

一个最常见的 R 包目录大概这样：

- `DESCRIPTION`：包的“身份证”（名称、版本、作者、依赖、说明等）
- `NAMESPACE`：导出哪些函数、导入哪些函数（通常自动生成，不手写）
- `R/`：你写的函数代码（每个 `.R` 文件放一组相关函数）
- `man/`：帮助文档（`.Rd`，通常由 roxygen2 自动生成）
- `tests/`：测试代码（testthat）
- `vignettes/`：长文档/教程（可选）
- `inst/`：安装时原样拷贝的资源（示例数据、模板等）
- `data/`：随包发布的数据（`.rda`，用 `usethis::use_data()` 生成）
- `src/`：C/C++/Fortran（可选，高级用法）

### 3) 写函数 + 写文档（roxygen2 的位置）

你之前问过 `#'` 开头的行——这就是 **roxygen2** 的文档注释。

典型做法：

- 在 `R/xxx.R` 里写函数
- 函数上方用 `#' @param`、`#' @return`、`#' @export` 等写文档
- 然后用 `devtools::document()`（或 RStudio 的 “Document”）生成：
  - `man/*.Rd`
  - `NAMESPACE`

### 4) 依赖管理（Imports / Depends / Suggests 怎么放）

这是很多人第一次发包会踩坑的点：

- **Imports**：你的包运行时必须要用到的依赖（最常用）
- **Suggests**：可选依赖（例如只在示例、vignette、测试、某些可选功能中用到）

### 5) 测试与检查（决定你包“像不像正经包”）

必做三步：

1. `devtools::test()`：跑测试
2. `devtools::check()`：等同于 `R CMD check`（CRAN 最看重）
3. `devtools::build()`：打包成 `.tar.gz`

### 6) 版本管理与发布（GitHub / CRAN 两条路）

### GitHub 发布（最简单、最快）

- 推到 GitHub
- 用户用 `remotes::install_github("user/repo")` 安装
- 再配合 GitHub Actions 跑 `R CMD check`（强烈建议）



## 构建一个示例脚本



```R

```

## 一、创建包骨架

在 **RStudio** 中执行：

```R
install.packages(c("devtools", "roxygen2", "usethis"))
library(usethis)

# 创建一个新的 R 包项目（生成标准目录结构）
create_package("~/Desktop/simpleMath")

# 切换工作目录到包根目录（RStudio 通常会自动切）
setwd("~/Desktop/simpleMath")
```

目录会变成：

```powershell
simpleMath/
├── DESCRIPTION
├── NAMESPACE
├── R/
└── man/
```

## 二、编写核心函数（重点）

####  将示例脚本`quadratic.R`保存在 `R/` 目录下。

## 三、配置 Git 用户信息（整台机器只需一次）

```R
# 设置 Git 提交时使用的用户名和邮箱
usethis::use_git_config(
  user.name  = "Zhou Xudong",
  user.email = "haipizxd@gmail.com"
)

# 初始化 git 仓库，并进行 initial commit
# 会把当前包骨架作为第一次提交
use_git()

```

## 四、添加许可证、测试框架、README

```R
# 添加 MIT License（会修改 DESCRIPTION 并生成 LICENSE 文件）
use_mit_license("Zhou xudong")

# 添加 testthat 单元测试框架
# 会生成 tests/ 目录
use_testthat()

# 添加 README.Rmd（用于 GitHub 展示）
use_readme_rmd()

```

## 五、声明包依赖（非常重要）

```R
# 声明 ggplot2 是运行时依赖
# 会自动写入 DESCRIPTION 的 Imports
use_package("ggplot2", type = "Imports")

# ⚠️ 注意：
# 这里“只声明依赖”，不要 library(ggplot2)
# 包代码里应使用 ggplot2::xxx 或 requireNamespace()
```

## 六、生成帮助文档

```R
# 根据 roxygen2 注释生成：
# - man/*.Rd 帮助文件
# - NAMESPACE 导出规则
devtools::document()
```

## 七、检查、构建、安装 R 包

```R
# 运行 R CMD check（CRAN 标准）
# 会检查文档、依赖、示例、测试
devtools::check()

# 构建 tar.gz 包（用于发布/分发）
devtools::build()

# 安装当前开发版本到 R library
devtools::install()
```

## 九、GitHub 认证相关（通常只需要做一次）

```R
# 在浏览器中创建 GitHub Personal Access Token (PAT)
# 如果你已经创建并配置过，可以跳过
usethis::create_github_token()

# 打开 .Renviron 文件，用于安全保存 PAT
# 只需把 GITHUB_PAT=xxxx 写进去一次即可
usethis::edit_r_environ()
```

## 十、将本地包发布到 GitHub

```R
# 在 GitHub 上创建仓库，并将当前包推送上去
# 前提：Git 已初始化 + PAT 已配置
# 如果仓库已存在，这一步通常会提示已完成
usethis::use_github()
```

### github网址：

https://github.com/haipizxd-ux/lrdemo

