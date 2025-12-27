# ============================================
# Stage 1: Builder - Instala dependências e faz build
# ============================================
FROM node:22-alpine AS builder

# Instala dependências do sistema necessárias para compilar módulos nativos
RUN apk update && apk add --no-cache \
    build-base \
    gcc \
    autoconf \
    automake \
    zlib-dev \
    libpng-dev \
    nasm \
    bash \
    vips-dev \
    git \
    python3 \
    make

# Configura variáveis de ambiente
ARG NODE_ENV=production
ENV NODE_ENV=${NODE_ENV}
ENV YARN_ENABLE_IMMUTABLE_INSTALLS=false

# Habilita Corepack e prepara Yarn 4.5.0
RUN corepack enable && corepack prepare yarn@4.5.0 --activate

# Instala node-gyp globalmente para compilar módulos nativos
RUN npm install -g node-gyp

# Define diretório de trabalho
WORKDIR /opt/app

# Copia arquivos de dependências (otimização de cache)
COPY package.json yarn.lock .yarnrc.yml* ./
COPY .yarn ./.yarn

# Instala dependências
RUN yarn install --immutable

# Copia o código fonte
COPY . .

# Build da aplicação
RUN yarn build

# ============================================
# Stage 2: Runtime - Imagem final otimizada
# ============================================
FROM node:22-alpine AS runtime

# Instala apenas dependências de runtime necessárias
RUN apk update && apk add --no-cache \
    bash \
    vips \
    git \
    && rm -rf /var/cache/apk/*

# Configura variáveis de ambiente
ARG NODE_ENV=production
ENV NODE_ENV=${NODE_ENV}
ENV YARN_ENABLE_IMMUTABLE_INSTALLS=false

# Habilita Corepack
RUN corepack enable && corepack prepare yarn@4.5.0 --activate

# Cria usuário não-root para segurança
RUN addgroup -g 1001 -S nodejs && \
    adduser -S strapi -u 1001

# Define diretório de trabalho
WORKDIR /opt/app

# Copia arquivos de dependências
COPY package.json yarn.lock .yarnrc.yml* ./
COPY .yarn ./.yarn

# Instala dependências
# Para monorepo do Strapi, instalamos todas as dependências
# (devDependencies podem ser necessárias para o build já ter sido feito)
RUN yarn install --immutable && \
    yarn cache clean

# Copia todo o código buildado do stage builder (exceto node_modules)
# Usa RUN com --mount para copiar apenas arquivos/diretórios que existem
RUN --mount=from=builder,source=/opt/app,target=/tmp/builder \
    cd /tmp/builder && \
    ( [ -d dist ] && cp -r dist /opt/app/ || true ) && \
    ( [ -d build ] && cp -r build /opt/app/ || true ) && \
    ( [ -d public ] && cp -r public /opt/app/ || true ) && \
    ( [ -d packages ] && cp -r packages /opt/app/ || true ) && \
    ( [ -d scripts ] && cp -r scripts /opt/app/ || true ) && \
    ( [ -d examples ] && cp -r examples /opt/app/ || true ) && \
    ( [ -d templates ] && cp -r templates /opt/app/ || true ) && \
    ( [ -d docs ] && cp -r docs /opt/app/ || true ) && \
    ( [ -d tests ] && cp -r tests /opt/app/ || true ) && \
    for pattern in "*.js" "*.json" "*.ts"; do \
      for file in $pattern; do \
        [ -f "$file" ] && [ "$file" != "$pattern" ] && cp "$file" /opt/app/ || true; \
      done; \
    done && \
    chown -R strapi:nodejs /opt/app

# Define permissões corretas
RUN chown -R strapi:nodejs /opt/app

# Muda para usuário não-root
USER strapi

# Expõe a porta padrão do Strapi
EXPOSE 1337

# Healthcheck (ajuste a URL conforme sua configuração do Strapi)
HEALTHCHECK --interval=30s --timeout=3s --start-period=40s --retries=3 \
    CMD node -e "require('http').get('http://localhost:1337/api', (r) => {process.exit(r.statusCode === 200 || r.statusCode === 401 ? 0 : 1)})" || exit 1

# Comando padrão (pode ser sobrescrito)
CMD ["yarn", "start"]
