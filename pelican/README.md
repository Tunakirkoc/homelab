# Install Pelican on a Proxmox cluster 

## Proxmox VMs Setup

### Create the VMs

Create the VMs with the following configuration.

```bash 
wget https://cdimage.debian.org/images/cloud/bookworm/latest/debian-12-generic-amd64.qcow2

qm create 5090 --name pelican-panel --ostype l26 -machine q35 --bios ovmf --agent 1 --cores 2 --cpu host --memory 1024 --net0 virtio,bridge=DMZ --scsihw virtio-scsi-single --efidisk0 local-lvm:1,efitype=4m,pre-enrolled-keys=1 --scsi0 local-lvm:0,import-from=/root/debian-12-generic-amd64.qcow2 --ide2 local-lvm:cloudinit --serial0 socket --ciuser root --sshkeys /root/.ssh/id_ed25519.pub --ipconfig0 ip=10.0.5.90/24,gw=10.0.5.254 --searchdomain kirkoc.net --nameserver 1.1.1.3
qm disk resize 5090 scsi0 32G
qm start 5090

qm create 5091 --name pelican-wings-1 --ostype l26 -machine q35 --bios ovmf --agent 1 --cores 8 --cpu host --memory 16384 --net0 virtio,bridge=DMZ --scsihw virtio-scsi-single --efidisk0 local-lvm:1,efitype=4m,pre-enrolled-keys=1 --scsi0 local-lvm:0,import-from=/root/debian-12-generic-amd64.qcow2 --ide2 local-lvm:cloudinit --serial0 socket --ciuser root --sshkeys /root/.ssh/id_ed25519.pub --ipconfig0 ip=10.0.5.91/24,gw=10.0.5.254 --searchdomain kirkoc.net --nameserver 1.1.1.3
qm disk resize 5091 scsi0 128G
qm start 5091
```

### Install the QEMU Guest Agent on the VMs

Install the QEMU Guest Agent on the VMs.

```bash
ssh root@10.0.5.90 "apt-get update; apt-get upgrade -y; apt-get install -y qemu-guest-agent cron;timedatectl set-timezone Europe/Paris; reboot"
ssh root@10.0.5.91 "apt-get update; apt-get upgrade -y; apt-get install -y qemu-guest-agent cron;timedatectl set-timezone Europe/Paris; reboot"
```

## Pelican Panel Setup

### Pre-Installation of Pelican Panel

Install the pre-requisites on the VMs.

On the panel VM, install the following packages.

```bash
apt-get install apt-transport-https
curl -sSLo /usr/share/keyrings/deb.sury.org-php.gpg https://packages.sury.org/php/apt.gpg
sh -c 'echo "deb [signed-by=/usr/share/keyrings/deb.sury.org-php.gpg] https://packages.sury.org/php/ $(lsb_release -sc) main" > /etc/apt/sources.list.d/php.list'
apt-get update
apt-get install -y php8.3 php8.3-{gd,mysql,mbstring,bcmath,xml,curl,zip,intl,sqlite3,fpm} nginx curl tar unzip
```

### Install Panel

Install the panel on the VMs.

```bash
mkdir -p /var/www/pelican
cd /var/www/pelican
curl -L https://github.com/pelican-dev/panel/releases/latest/download/panel.tar.gz | tar -xzv
curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer
composer install --no-dev --optimize-autoloader
```

### Creating SSL Certificates

#### Install acme.sh

Install acme.sh on the VMs.

```bash
curl https://get.acme.sh | sh -s email=contact@kirkoc.net
```

#### Create the SSL certificates

Create the SSL certificates for the panel.

```bash
export CF_Token="<Cloudflare API Token>"
acme.sh --issue --dns dns_cf -d panel.kirkoc.net
```

### Configure Nginx

Configure Nginx for the panel.

```bash
rm /etc/nginx/sites-enabled/default
nano /etc/nginx/sites-available/pelican.conf
ln -s /etc/nginx/sites-available/pelican.conf /etc/nginx/sites-enabled/pelican.conf
systemctl restart nginx
```

```nginx
server_tokens off;

server {
    listen 80;
    server_name panel.kirkoc.net;
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    server_name panel.kirkoc.net;

    root /var/www/pelican/public;
    index index.php;

    access_log /var/log/nginx/pelican.app-access.log;
    error_log  /var/log/nginx/pelican.app-error.log error;

    # allow larger file uploads and longer script runtimes
    client_max_body_size 100m;
    client_body_timeout 120s;

    sendfile off;

    ssl_certificate /root/.acme.sh/panel.kirkoc.net_ecc/fullchain.cer;
    ssl_certificate_key /root/.acme.sh/panel.kirkoc.net_ecc/panel.kirkoc.net.key;
    ssl_session_cache shared:SSL:10m;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers "ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384";
    ssl_prefer_server_ciphers on;

    # See https://hstspreload.org/ before uncommenting the line below.
    # add_header Strict-Transport-Security "max-age=15768000; preload;";
    add_header X-Content-Type-Options nosniff;
    add_header X-XSS-Protection "1; mode=block";
    add_header X-Robots-Tag none;
    add_header Content-Security-Policy "frame-ancestors 'self'";
    add_header X-Frame-Options DENY;
    add_header Referrer-Policy same-origin;

    location / {
        try_files $uri $uri/ /index.php?$query_string;
    }

    location ~ \.php$ {
        fastcgi_split_path_info ^(.+\.php)(/.+)$;
        fastcgi_pass unix:/run/php/php8.3-fpm.sock;
        fastcgi_index index.php;
        include fastcgi_params;
        fastcgi_param PHP_VALUE "upload_max_filesize = 100M \n post_max_size=100M";
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        fastcgi_param HTTP_PROXY "";
        fastcgi_intercept_errors off;
        fastcgi_buffer_size 16k;
        fastcgi_buffers 4 16k;
        fastcgi_connect_timeout 300;
        fastcgi_send_timeout 300;
        fastcgi_read_timeout 300;
        include /etc/nginx/fastcgi_params;
    }

    location ~ /\.ht {
        deny all;
    }
}
```

### Configure Panel

Configure the panel.

```bash
cd /var/www/pelican
php artisan p:environment:setup
chmod -R 755 storage/* bootstrap/cache/
chown -R www-data:www-data /var/www/pelican
```

Now, go to the panel URL and complete the installation.

```bash
nano /var/www/pelican/.env

APP_ENV=production
APP_DEBUG=false
APP_KEY=base64:dm07o8BdT33AiJEuOAwnwb8uJ34uDNWQ6RaJGAthr/s=
APP_URL="https://panel.kirkoc.net"
APP_INSTALLED=true
APP_TIMEZONE=Europe/Paris
APP_LOCALE=en

APP_NAME=Pelican
DB_CONNECTION=sqlite
DB_DATABASE=database.sqlite
CACHE_STORE=file
QUEUE_CONNECTION=database
SESSION_DRIVER=file
SESSION_SECURE_COOKIE=1
```

## Pelican Wings Setup

### Pre-Installation of Pelican Node

Install the pre-requisites on the VMs.

```bash
curl -sSL https://get.docker.com/ | CHANNEL=stable sh
systemctl enable --now docker
```

### Install Wings

Install the wings on the VMs.

```bash
mkdir -p /etc/pelican /var/run/wings
curl -L -o /usr/local/bin/wings "https://github.com/pelican-dev/wings/releases/latest/download/wings_linux_$([[ "$(uname -m)" == "x86_64" ]] && echo "amd64" || echo "arm64")"
chmod u+x /usr/local/bin/wings
```

### Creating SSL Certificates

#### Install acme.sh

Install acme.sh on the VMs.

```bash
curl https://get.acme.sh | sh -s email=contact@kirkoc.net
```

#### Create the SSL certificates

Create the SSL certificates for the wings.

```bash
export CF_Token="<Cloudflare API Token>"
acme.sh --issue --dns dns_cf -d pelican-wings-1.kirkoc.net 
```

### Configure Wings

Now, configure the wings.

```bash
nano /etc/pelican/config.yml
```

```yaml
. . .
    cert: /root/.acme.sh/pelican-wings-1.kirkoc.net_ecc/fullchain.cer
    key: /root/.acme.sh/pelican-wings-1.kirkoc.net_ecc/pelican-wings-1.kirkoc.net.key
. . .
  timezone: "Europe/Paris"
. . .
```

### Start Wings

Test wings with the following command.

```bash
wings --debug
```

CTRL+C to stop the wings.

### Autostart Wings

Create a systemd service for the wings.

```bash
nano /etc/systemd/system/wings.service
systemctl enable --now wings
```

```ini
[Unit]
Description=Wings Daemon
After=docker.service
Requires=docker.service
PartOf=docker.service

[Service]
User=root
WorkingDirectory=/etc/pelican
LimitNOFILE=4096
PIDFile=/var/run/wings/daemon.pid
ExecStart=/usr/local/bin/wings
Restart=on-failure
StartLimitInterval=180
StartLimitBurst=30
RestartSec=5s

[Install]
WantedBy=multi-user.target
```
