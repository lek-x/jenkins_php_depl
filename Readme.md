# Symfony PHP deploying with Jenkins

## Description


This Jenkins code deploy php symfony demo app in symlink-deployment mode into Jenkins worker with db migrations, also it rotates old builds. 
**Extra:**  for quick start and prepare your server, use **prep.sh** to install nginx, mysql, create DB, install composer, create .env.

## Requrements

1. Jenkins Server (master)
2. SSH access to Jenkins worker
3. Mysql-server
4. php 8.1
5. nginx

## Quick preparing (if needed)
To quick prepare your  jenkins worker, copy prep.sh, and run
```
sudo ./prep.sh
```

It installs php8.1, nginx, mysql-server, creating DB, installs composer, installs NGINX with config, and creates dir "project_sys" in your /home/jenkins directory with .env file.

## How to use Jenkins task
1. Create task in Jenkins master 
    1.2. Edit label according to name of your Jenkins worker
    1.3. Edit stage "Clone repo" according to your remote repo
3. Run task
5. Check site in your browser 

