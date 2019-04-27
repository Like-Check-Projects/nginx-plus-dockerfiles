FROM centos:centos7.6.1810

LABEL maintainer="armand@nginx.com"

# Set Nginx Plus version
ENV NGINX_PLUS_VERSION 18

## Install Nginx Plus
# Download certificate and key from the customer portal https://cs.nginx.com
# and copy to the build context and set correct permissions
RUN mkdir -p /etc/ssl/nginx
COPY etc/ssl/nginx/nginx-repo.crt /etc/ssl/nginx/nginx-repo.crt
COPY etc/ssl/nginx/nginx-repo.key /etc/ssl/nginx/nginx-repo.key
RUN chmod 644 /etc/ssl/nginx/* \
# Install prerequisite packages and vim for editing:
 && yum install -y --setopt=tsflags=nodocs wget ca-certificates bind-utils wget bind-utils vim-minimal \
 # Prepare repo config and install NGINX Plus (https://cs.nginx.com/repo_setup)
 && wget -q -O /etc/yum.repos.d/nginx-plus-7.repo https://cs.nginx.com/static/files/nginx-plus-7.repo \
 # Set specifc version of Nginx plus
 && sed -i 's/plus-pkgs.nginx.com\//plus-pkgs.nginx.com\/R'"${NGINX_PLUS_VERSION}"'\//g' /etc/yum.repos.d/nginx-plus-7.repo \
 && yum install -y --setopt=tsflags=nodocs nginx-plus \
 ## Optional: Install NGINX Plus Modules from repo
 # See https://www.nginx.com/products/nginx/modules
 #&& yum install -y --setopt=tsflags=nodocs nginx-plus-module-modsecurity \
 #&& yum install -y --setopt=tsflags=nodocs nginx-plus-module-geoip \
 #&& yum install -y --setopt=tsflags=nodocs nginx-plus-module-njs \
 && yum clean all \
 # Remove default nginx config
 && rm /etc/nginx/conf.d/default.conf \
 # Optional: Create cache folder and set permissions for proxy caching
 && mkdir -p /var/cache/nginx \
 && chown -R nginx /var/cache/nginx

# Optional: COPY over any of your SSL certs for HTTPS servers
# e.g.
#COPY etc/ssl/www.example.com.crt /etc/ssl/www.example.com.crt
#COPY etc/ssl/www.example.com.key /etc/ssl/www.example.com.key

# COPY /etc/nginx (Nginx configuration) directory
COPY etc/nginx /etc/nginx
RUN chown -R nginx:nginx /etc/nginx \
 # Forward request logs to docker log collector
 && ln -sf /dev/stdout /var/log/nginx/access.log \
 && ln -sf /dev/stderr /var/log/nginx/error.log \
 # Raise the limits to successfully run benchmarks
 && ulimit -c -m -s -t unlimited \
 # **Remove the Nginx Plus cert/keys from the image**
 && rm /etc/ssl/nginx/nginx-repo.crt /etc/ssl/nginx/nginx-repo.key

# EXPOSE ports, HTTP 80, HTTPS 443 and, Nginx status page 8080
EXPOSE 80 443 8080
STOPSIGNAL SIGTERM
CMD ["nginx", "-g", "daemon off;"]