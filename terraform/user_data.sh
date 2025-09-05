#!/bin/bash
# terraform/user_data.sh

# Log everything
exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1

# Update system
yum update -y

# Install Docker
yum install -y docker
systemctl start docker
systemctl enable docker
usermod -a -G docker ec2-user

# Install Docker Compose
curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose
ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose

# Create app directory
mkdir -p /home/ec2-user/app
cd /home/ec2-user/app

# Create docker-compose.yml
cat > docker-compose.yml << EOF
version: '3.8'

services:
  postgres:
    image: postgres:13
    environment:
      POSTGRES_DB: myapp
      POSTGRES_USER: user
      POSTGRES_PASSWORD: password
    volumes:
      - postgres_data:/var/lib/postgresql/data
    ports:
      - "5432:5432"
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U user -d myapp"]
      interval: 30s
      timeout: 10s
      retries: 5

  backend:
    image: ${dockerhub_username}/python-backend:latest
    depends_on:
      postgres:
        condition: service_healthy
    environment:
      - DATABASE_URL=postgresql://user:password@postgres:5432/myapp
    ports:
      - "5000:5000"
    restart: unless-stopped

  frontend:
    image: ${dockerhub_username}/python-frontend:latest
    depends_on:
      - backend
    environment:
      - BACKEND_URL=http://backend:5000/api/data
    ports:
      - "8080:80"
    restart: unless-stopped

  logger:
    image: ${dockerhub_username}/python-logger:latest
    depends_on:
      - backend
    volumes:
      - ./logs:/app/logs
    environment:
      - BACKEND_URL=http://backend:5000
    restart: unless-stopped

volumes:
  postgres_data:
EOF

# Create logs directory
mkdir -p logs

# Change ownership
chown -R ec2-user:ec2-user /home/ec2-user/app

# Wait for Docker to be ready and pull images
sleep 30

# Start the application
docker-compose up -d

# Wait for services to be ready
sleep 60

echo "Application deployed successfully!"
echo "Frontend available at: http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4):8080"
echo "Backend API available at: http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4):5000/api/data"
