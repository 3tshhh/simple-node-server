#!/bin/bash
# Run this once on your EC2 instance to prepare it for deployments
set -e

echo "Updating system..."
sudo apt-get update -y

echo "Installing Docker..."
sudo apt-get install -y docker.io

sudo systemctl start docker
sudo systemctl enable docker
sudo usermod -aG docker $USER

echo "Installing Nginx..."
sudo apt-get install -y nginx

# Nginx reverse proxy config
sudo tee /etc/nginx/sites-available/simple-node-server > /dev/null <<'EOF'
server {
    listen 80;
    server_name _;

    location / {
        proxy_pass http://127.0.0.1:3000;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
EOF

sudo ln -sf /etc/nginx/sites-available/simple-node-server /etc/nginx/sites-enabled/simple-node-server
sudo rm -f /etc/nginx/sites-enabled/default

sudo nginx -t
sudo systemctl restart nginx
sudo systemctl enable nginx

echo "Installing AWS CLI..."
if ! command -v aws &> /dev/null; then
  sudo apt-get install -y unzip
  curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
  unzip awscliv2.zip
  sudo ./aws/install
  rm -rf aws awscliv2.zip
fi

echo ""
echo "Done! Log out and back in for Docker group to take effect."
echo "Then verify with: docker ps && curl localhost"
