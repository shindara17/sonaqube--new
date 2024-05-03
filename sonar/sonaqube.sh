#!/bin/bash
sudo cp /etc/sysctl.conf /root/sysctl.conf_backup

# Modify Kernel System Limits for Sonarqube
    sudo sh -c 'cat <<EOF> /etc/sysctl.conf
    vm.max_map_count=262144
    fs.file-max=65536
    ulimit -n 65536
    ulimit -u 4096
EOF'
    sudo apt update -y
    sudo apt-get install openjdk-11-jdk -y

# Postgres Database installation and setup
    wget -q https://www.postgresql.org/media/keys/ACCC4CF8.asc -O - | sudo apt-key add -

    sudo sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt/ $(lsb_release -cs)-pgdg main" >> /etc/apt/sources.list.d/pgdg.list'
    sudo apt install postgresql postgresql-contrib -y

    sudo systemctl enable postgresql.service
    sudo systemctl start  postgresql.service
    sudo echo "postgres:admin123" | sudo chpasswd
    sudo runuser -l postgres -c "createuser sonar"
    sudo -i -u postgres psql -c "ALTER USER sonar WITH ENCRYPTED PASSWORD 'admin123';"
    sudo -i -u postgres psql -c "CREATE DATABASE sonarqube OWNER sonar;"
    sudo -i -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE sonarqube to sonar;"
    sudo systemctl restart  postgresql

# Sonarqube installation and setup
    sudo mkdir /sonarqube/
    cd /sonarqube/
    sudo curl -O https://binaries.sonarsource.com/Distribution/sonarqube/sonarqube-8.3.0.34182.zip
    sudo apt-get install zip -y
    sudo unzip -o sonarqube-8.3.0.34182.zip -d /opt/
    sudo mv /opt/sonarqube-8.3.0.34182/ /opt/sonarqube
    sudo groupadd sonar
    sudo useradd -c "SonarQube - User" -d /opt/sonarqube/ -g sonar sonar

    sudo cp /opt/sonarqube/conf/sonar.properties /root/sonar.properties_backup
    sudo chown sonar:sonar /opt/sonarqube/ -R
    sudo sh -c 'cat <<EOF> /opt/sonarqube/conf/sonar.properties
    sonar.jdbc.username=sonar
    sonar.jdbc.password=admin123
    sonar.jdbc.url=jdbc:postgresql://localhost/sonarqube
    sonar.web.host=0.0.0.0
    sonar.web.port=9000
    sonar.web.javaAdditionalOpts=-server
    sonar.search.javaOpts=-Xmx512m -Xms512m -XX:+HeapDumpOnOutOfMemoryError
    sonar.log.level=INFO
    sonar.path.logs=logs
EOF'
# Setup Systemd service for Sonarqube
    sudo sh -c 'cat <<EOF> /etc/systemd/system/sonarqube.service
    [Unit]
    Description=SonarQube service
    After=syslog.target network.target

    [Service]
    Type=forking

    ExecStart=/opt/sonarqube/bin/linux-x86-64/sonar.sh start
    ExecStop=/opt/sonarqube/bin/linux-x86-64/sonar.sh stop

    User=sonar
    Group=sonar
    Restart=always

    LimitNOFILE=65536
    LimitNPROC=4096

    [Install]
    WantedBy=multi-user.target
EOF'
# Enable and restart service
    sudo systemctl daemon-reload
    sudo systemctl enable sonarqube.service
    sudo systemctl start sonarqube.service
    sudo /opt/sonarqube/bin/linux-x86-64/sonar.sh start
    sudo reboot