#!/bin/bash

nginx_conf_path="/srv/nginx/conf.d/"

apt-get update -y
apt-get install -y  apt-transport-https \
    ca-certificates \
    curl \
    gnupg-agent \
    software-properties-common
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository \
   "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
   $(lsb_release -cs) \
   stable"
apt-get update -y
apt-get install -y docker-ce docker-ce-cli containerd.io
mkdir -p $nginx_conf_path
cat <<-EOT >> $nginx_conf_path/default.conf
# nginx.vh.default.conf  --  docker-openresty
#
# This file is installed to:
#   `/etc/nginx/conf.d/default.conf`
#
# It tracks the `server` section of the upstream OpenResty's `nginx.conf`.
#
# This config (and any other configs in `etc/nginx/conf.d/`) is loaded by
# default by the `include` directive in `/usr/local/openresty/nginx/conf/nginx.conf`.
#
# See https://github.com/openresty/docker-openresty/blob/master/README.md#nginx-config-files
#
server {
    listen       80;
    server_name  localhost;


    location /hello {
        default_type text/html;
        content_by_lua '
            local s, n = string.gsub(ngx.var.uri, "(/hello/)", "Hello, ", 1)
            ngx.say(s .. ".")
        ';

}
# redirect server error pages to the static page /50x.html
#
error_page   500 502 503 504  /50x.html;
location = /50x.html {
root   /usr/local/openresty/nginx/html;
}

# proxy the PHP scripts to Apache listening on 127.0.0.1:80
#
#location ~ \.php$ {
#    proxy_pass   http://127.0.0.1;
#}

# pass the PHP scripts to FastCGI server listening on 127.0.0.1:9000
#
#location ~ \.php$ {
#    root           /usr/local/openresty/nginx/html;
#    fastcgi_pass   127.0.0.1:9000;
#    fastcgi_index  index.php;
#    fastcgi_param  SCRIPT_FILENAME  /scripts$fastcgi_script_name;
#    include        fastcgi_params;
#}

# deny access to .htaccess files, if Apache's document root
# concurs with nginx's one
#
#location ~ /\.ht {
#    deny  all;
#}
}
EOT


docker run -p 80:80 -itd -v $nginx_conf_path:/etc/nginx/conf.d/  openresty/openresty:alpine-fat
