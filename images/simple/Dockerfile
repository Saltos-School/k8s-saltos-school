FROM nginx:1.22.1

MAINTAINER Paul Saltos "paul@csaltos.com"

RUN apt-get update

RUN apt-get install -y net-tools curl wget dnsutils

COPY etc/nginx/templates/* /etc/nginx/templates/

COPY usr/share/nginx/html/* /usr/share/nginx/html

ENTRYPOINT ["/docker-entrypoint.sh"]

CMD ["nginx", "-g", "daemon off;"]
