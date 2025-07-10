#!/bin/bash
parent="odoo18pracice"
# all file names
ae="addons-extra"
db="db-backup"
dcf="dockerfile"
nc="nginx-config"
oc="odoo-config"
create_folder_and_files(){
    
    mkdir -p "$parent"
    mkdir -p "$parent/$ae"
    mkdir -p "$parent/$db"
    mkdir -p "$parent/$dcf"
    mkdir -p "$parent/$nc"
    mkdir -p "$parent/$oc"

    # file1="$parent/$dcf/nginx.Dockerfile"
    # file2="$parent/$dcf/odoo.Dockerfile"
    # file3="$parent/$nc/default.conf"
    # file4="$parent/$nc/odoo.conf"
    # file5="$parent/docker-compose.yml"

    touch "$parent/$dcf/nginx.Dockerfile"
    touch "$parent/$dcf/odoo.Dockerfile"
    touch "$parent/$nc/default.conf"
    touch "$parent/$oc/odoo.conf"
    touch "$parent/docker-compose.yml"

}
write_inside_files(){
cat <<EOF > "$parent/docker-compose.yml"
version: '3.1'
services:
  odoo-stack:
    container_name: odoo-stack
    build:
      context: ./dockerfile
      dockerfile: odoo.Dockerfile
    volumes:
      - ./addons-extra:/mnt/addons-extra
      - ./odoo-config:/etc/odoo
      - odoo-web-data:/var/lib/odoo

    ports:
      - 8069:8069

    depends_on:

      - database-stack

    restart: always
  
  database-stack:
    container_name: database-stack
    image: postgres:latest
    volumes:

      - database-stack-data:/var/lib/postgresql/data/pgdata

    ports:

      - 5432:5432

    # command: -p 5433
    environment:

      - POSTGRES_PASSWORD=odoo
      - POSTGRES_USER=odoo
      - POSTGRES_DB=postgres
      - PGDATA=/var/lib/postgresql/data/pgdata

    restart: always

  pgadmin-stack:
    container_name: pgadmin-stack
    image: dpage/pgadmin4:5.4
    volumes:

      - pgadmin-data:/var/lib/pgadmin

    ports:

      - 8080:80

    links:

      - "database-stack:pgsql-server"

    environment:
      PGADMIN_DEFAULT_EMAIL: shane@odootraining.ddns.net
      PGADMIN_DEFAULT_PASSWORD: secret
      PGADMIN_LISTEN_PORT: 80
    depends_on:

      - database-stack

    restart: always
    
  nginx-stack:
    container_name: nginx-stack
    build:
      context: ./dockerfile
      dockerfile: nginx.Dockerfile
    volumes:
      - ./nginx-config:/etc/nginx/conf.d

    ports:

      - 80:80   #non secure
      - 443:443 #ssl

    depends_on:

      - odoo-stack

    restart: always

volumes:
  odoo-web-data:
  database-stack-data:
  pgadmin-data:
EOF

cat <<EOF > "$parent/$dcf/nginx.Dockerfile"
FROM nginx:latest

USER root

RUN apt update && apt install -y \
    nano \
    apt-utils \
    certbot \
    python3-certbot-nginx \
    ca-certificates && \
    apt clean && \
    rm -rf /var/lib/apt/lists/*

EOF

cat <<EOF > "$parent/$dcf/odoo.Dockerfile"
FROM odoo:18.0
USER root
RUN apt update
RUN apt install curl python3-pandas nano -y
EOF

cat <<EOF > "$parent/$nc/default.conf"
server {
    listen 443 ssl;
    server_name localhost;

    ssl_certificate /etc/nginx/ssl/selfsigned.crt;
    ssl_certificate_key /etc/nginx/ssl/selfsigned.key;

    location / {
        proxy_pass http://odoo-stack:8069;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    # Let's Encrypt ACME challenge (optional)
    location ~ /.well-known/acme-challenge {
        allow all;
        root /usr/share/nginx/html;
    }
}
EOF

cat <<EOF > "$parent/$oc/odoo.conf"
[options]
admin_passwd = admin1234
db_host = database-stack
db_port = 5432
db_user = odoo
db_password = odoo
addons_path = /usr/lib/python3/dist-packages/odoo/addons
xmlrpc_port = 8069

EOF
    # Confirm
    echo "✅ All folders and files created inside $parent/"
}
create_folder_and_files
write_inside_files