FROM node AS builder

COPY . /app
WORKDIR /app
RUN npm install && npm run radicale


FROM alpine:edge

# 国内环境换源（如不需要可删除）
RUN sed -i 's/dl-cdn.alpinelinux.org/mirrors.aliyun.com/g' /etc/apk/repositories

RUN apk update \
  && apk add --no-cache python3 py3-pip \
  && pip3 install --no-cache-dir radicale --break-system-packages \
  && rm -rf /var/cache/apk/* \
  \
  # 创建必要目录
  && mkdir -p /etc/radicale /app/vcards/collection-root/cn /app/vcards/collection-root/cnmacos \
  \
  # 写 rights 文件
  && { \
    echo '[root]'; \
    echo 'user: .+'; \
    echo 'collection:'; \
    echo 'permissions: R'; \
    echo; \
    echo '[principal]'; \
    echo 'user: .+'; \
    echo 'collection: {user}'; \
    echo 'permissions: R'; \
    echo; \
    echo '[collections]'; \
    echo 'user: .+'; \
    echo 'collection: {user}/[^/]+'; \
    echo 'permissions: rR'; \
  } > /etc/radicale/rights \
  \
  # 写 config 文件
  && { \
    echo '[server]'; \
    echo 'hosts = 0.0.0.0:5232, [::]:5232'; \
    echo; \
    echo '[auth]'; \
    echo 'type = none'; \
    echo; \
    echo '[web]'; \
    echo 'type = none'; \
    echo; \
    echo '[storage]'; \
    echo 'type = multifilesystem'; \
    echo 'filesystem_folder = /app/vcards'; \
    echo; \
    echo '[rights]'; \
    echo 'type = from_file'; \
    echo 'file = /etc/radicale/rights'; \
  } > /etc/radicale/config

COPY --from=builder /app/radicale/ios/   /app/vcards/collection-root/cn/
COPY --from=builder /app/radicale/macos/ /app/vcards/collection-root/cnmacos/

EXPOSE 5232

CMD ["python3", "-m", "radicale"]
