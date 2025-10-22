# --- 阶段 1: 构建 ---
# 使用一个稳定的 Node.js Alpine 长期支持版本作为基础镜像
# Alpine 镜像是最小的 Node.js 官方镜像
FROM node:18-alpine AS builder

# 在容器内创建一个工作目录
WORKDIR /app

# 拷贝 package.json 和 package-lock.json (如果存在)
# 将这步分开是为了利用 Docker 的层缓存机制。
# 只要 package.json 没有变化，就不需要重新安装依赖。
COPY package*.json ./

# 安装生产环境依赖
# --only=production 确保只安装 dependencies 中的包，不安装 devDependencies
RUN npm install --only=production

# 拷贝项目的其余文件
COPY . .

# --- 阶段 2: 运行 ---
# 再次使用相同的最小镜像，创建一个干净的生产环境
FROM node:18-slim

# 设置工作目录
WORKDIR /app

# 从构建阶段拷贝已经安装好的 node_modules
COPY --from=builder /app/node_modules ./node_modules

# 从构建阶段拷贝应用代码
COPY --from=builder /app/server.js ./server.js


cmd ["node","./app.js"]