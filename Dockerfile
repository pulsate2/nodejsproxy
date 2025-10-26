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

run apt-get update && apt-get install curl wget -y

run mkdir -p --mode=0755 /usr/share/keyrings
run curl -fsSL https://pkg.cloudflare.com/cloudflare-main.gpg | tee /usr/share/keyrings/cloudflare-main.gpg >/dev/null
run echo 'deb [signed-by=/usr/share/keyrings/cloudflare-main.gpg] https://pkg.cloudflare.com/cloudflared any main' | tee /etc/apt/sources.list.d/cloudflared.list
run apt-get update
run apt-get install cloudflared -y
run apt-get install sudo -y

# 设置工作目录
WORKDIR /app

# 从构建阶段拷贝已经安装好的 node_modules
COPY --from=builder /app/node_modules ./node_modules

COPY . .

RUN chmod 777 ./entrypoint.sh
EXPOSE 8080

cmd ["./entrypoint.sh"]