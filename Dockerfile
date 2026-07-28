# alpine -> 다른 운영체제보다 경량화됨
FROM nginx:1.27.5-alpine

# docker -> 이미지 태그는 아님, ㄴ
LABEL org.opencontainers.image.title="AI/SW Workstation Lab" \
      org.opencontainers.image.description="NGINX static site for learning Docker images, ports, bind mounts, and volumes"

ENV APP_ENV=learning

COPY nginx/default.conf /etc/nginx/conf.d/default.conf
COPY site/ /usr/share/nginx/html/
# COPY default.conf /etc/nginx/conf.d/default.conf
# COPY ../site/ /usr/share/nginx/html/

RUN mkdir -p /usr/share/nginx/html/data \
    && chown -R nginx:nginx /usr/share/nginx/html

EXPOSE 80

HEALTHCHECK --interval=10s --timeout=3s --start-period=3s --retries=3 \
  CMD wget -qO- http://127.0.0.1/healthz || exit 1

CMD ["nginx", "-g", "daemon off;"]

