#!/bin/bash
# ===========================================
# SonarQube + Sonar Scanner Full Setup (Ubuntu)
# ===========================================

set -e

# --- Variables ---
SONARQUBE_VERSION="10.5.0.89998"
SONARQUBE_USER="sonar"
SONARQUBE_DIR="/opt/sonarqube"
SONAR_SCANNER_VERSION="5.0.1.3006"
SONAR_SCANNER_DIR="/opt/sonar-scanner"

echo "🔄 Updating system..."
sudo apt update
sudo apt install -y openjdk-17-jdk unzip curl

# --- Clean old installation ---
echo "🧹 Cleaning old SonarQube (if exists)..."
sudo rm -rf /opt/sonarqube /opt/sonarqube.zip

# --- Create user ---
echo "👤 Creating sonar user..."
if id "$SONARQUBE_USER" &>/dev/null; then
    echo "User already exists"
else
    sudo useradd -m -d $SONARQUBE_DIR -r -s /bin/bash $SONARQUBE_USER
fi

# --- Download SonarQube ---
echo "📥 Downloading SonarQube..."
cd /opt
sudo curl -L -o sonarqube.zip \
https://binaries.sonarsource.com/Distribution/sonarqube/sonarqube-${SONARQUBE_VERSION}.zip

# --- Extract ---
echo "📦 Extracting SonarQube..."
sudo unzip sonarqube.zip
sudo mv sonarqube-${SONARQUBE_VERSION} sonarqube
sudo chown -R $SONARQUBE_USER:$SONARQUBE_USER sonarqube
sudo rm sonarqube.zip

# --- Install Sonar Scanner ---
echo "📥 Installing Sonar Scanner..."
cd /opt
sudo rm -rf sonar-scanner sonar-scanner.zip

sudo curl -L -o sonar-scanner.zip \
https://binaries.sonarsource.com/Distribution/sonar-scanner-cli/sonar-scanner-cli-${SONAR_SCANNER_VERSION}-linux.zip

sudo unzip sonar-scanner.zip
sudo mv sonar-scanner-${SONAR_SCANNER_VERSION}-linux sonar-scanner
sudo chown -R $USER:$USER sonar-scanner
sudo rm sonar-scanner.zip

# --- Add scanner to PATH ---
if ! grep -q "$SONAR_SCANNER_DIR/bin" ~/.bashrc; then
    echo "export PATH=\$PATH:$SONAR_SCANNER_DIR/bin" >> ~/.bashrc
fi
export PATH=$PATH:$SONAR_SCANNER_DIR/bin

# --- System tuning (VERY IMPORTANT) ---
echo "⚙️ Applying system limits..."

sudo sysctl -w vm.max_map_count=262144
sudo sysctl -w fs.file-max=65536

echo "vm.max_map_count=262144" | sudo tee -a /etc/sysctl.conf
echo "fs.file-max=65536" | sudo tee -a /etc/sysctl.conf

# --- Reduce memory usage (for small EC2) ---
echo "⚙️ Configuring memory..."

sudo sed -i 's/#sonar.web.javaOpts.*/sonar.web.javaOpts=-Xmx512m -Xms256m/' $SONARQUBE_DIR/conf/sonar.properties
sudo sed -i 's/#sonar.ce.javaOpts.*/sonar.ce.javaOpts=-Xmx512m -Xms256m/' $SONARQUBE_DIR/conf/sonar.properties

# --- Create systemd service ---
echo "⚙️ Creating SonarQube service..."

sudo tee /etc/systemd/system/sonarqube.service > /dev/null <<EOL
[Unit]
Description=SonarQube service
After=network.target

[Service]
Type=forking
ExecStart=$SONARQUBE_DIR/bin/linux-x86-64/sonar.sh start
ExecStop=$SONARQUBE_DIR/bin/linux-x86-64/sonar.sh stop
User=$SONARQUBE_USER
Group=$SONARQUBE_USER
Restart=always
LimitNOFILE=65536
LimitNPROC=4096

[Install]
WantedBy=multi-user.target
EOL

# --- Start service ---
echo "🚀 Starting SonarQube..."
sudo systemctl daemon-reload
sudo systemctl enable sonarqube
sudo systemctl restart sonarqube

sleep 15

echo "📊 Checking status..."
sudo systemctl status sonarqube --no-pager

echo "====================================="
echo "✅ SonarQube Installed Successfully!"
echo "🌐 Access: http://<your-server-ip>:9000"
echo "👤 Login: admin / admin"
echo "====================================="
