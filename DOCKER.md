# Docker para Strapi

Este Dockerfile foi otimizado para o Strapi usando multi-stage build, reduzindo o tamanho final da imagem e melhorando a segurança.

## Características

- ✅ **Multi-stage build** - Imagem final otimizada (~300MB vs ~1GB)
- ✅ **Yarn 4.5.0** - Configurado via Corepack
- ✅ **Segurança** - Executa como usuário não-root
- ✅ **Healthcheck** - Monitoramento automático da saúde do container
- ✅ **Cache otimizado** - Layers organizados para melhor cache do Docker

## Build da Imagem

### Build básico:

```bash
docker build -t strapi:latest .
```

### Build com tag específica:

```bash
docker build -t strapi:v1.0.0 -t strapi:latest .
```

### Build sem cache (força rebuild completo):

```bash
docker build --no-cache -t strapi:latest .
```

## Executar o Container

### Modo desenvolvimento:

```bash
docker run -d \
  --name strapi-dev \
  -p 1337:1337 \
  -v $(pwd)/public/uploads:/opt/app/public/uploads \
  -v $(pwd)/database:/opt/app/database \
  -e NODE_ENV=development \
  strapi:latest \
  yarn develop
```

### Modo produção:

```bash
docker run -d \
  --name strapi-prod \
  -p 1337:1337 \
  -v $(pwd)/public/uploads:/opt/app/public/uploads \
  -v $(pwd)/database:/opt/app/database \
  -e NODE_ENV=production \
  -e DATABASE_CLIENT=postgres \
  -e DATABASE_HOST=postgres \
  -e DATABASE_PORT=5432 \
  -e DATABASE_NAME=strapi \
  -e DATABASE_USERNAME=strapi \
  -e DATABASE_PASSWORD=strapi \
  strapi:latest
```

## Usando Docker Compose

### Produção:

```bash
docker-compose -f docker-compose.prod.yml up -d
```

### Ver logs:

```bash
docker-compose -f docker-compose.prod.yml logs -f strapi
```

### Parar:

```bash
docker-compose -f docker-compose.prod.yml down
```

## Variáveis de Ambiente

Configure as seguintes variáveis de ambiente conforme necessário:

### Banco de Dados:

- `DATABASE_CLIENT` - postgres, mysql, sqlite
- `DATABASE_HOST` - Host do banco
- `DATABASE_PORT` - Porta do banco
- `DATABASE_NAME` - Nome do banco
- `DATABASE_USERNAME` - Usuário do banco
- `DATABASE_PASSWORD` - Senha do banco

### Segurança:

- `JWT_SECRET` - Secret para JWT
- `ADMIN_JWT_SECRET` - Secret para Admin JWT
- `APP_KEYS` - Chaves da aplicação (separadas por vírgula)

### Servidor:

- `HOST` - Host do servidor (padrão: 0.0.0.0)
- `PORT` - Porta do servidor (padrão: 1337)
- `NODE_ENV` - Ambiente (development, production)

## Estrutura do Dockerfile

### Stage 1: Builder

- Instala todas as dependências (incluindo devDependencies)
- Compila módulos nativos
- Faz build da aplicação

### Stage 2: Runtime

- Apenas dependências de produção
- Código buildado
- Imagem final otimizada

## Troubleshooting

### Erro de permissão:

```bash
# Ajuste permissões dos volumes
sudo chown -R 1001:1001 ./public/uploads ./database
```

### Rebuild completo:

```bash
docker build --no-cache -t strapi:latest .
```

### Ver logs do container:

```bash
docker logs -f strapi-prod
```

### Acessar shell do container:

```bash
docker exec -it strapi-prod sh
```

## Otimizações

O Dockerfile está otimizado para:

- Cache de layers do Docker
- Tamanho mínimo da imagem final
- Segurança (usuário não-root)
- Performance (multi-stage build)
