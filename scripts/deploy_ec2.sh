#!/usr/bin/env bash
set -euo pipefail

: "${EC2_HOST:?Set EC2_HOST to the instance public IP}"
: "${EC2_KEY_FILE:?Set EC2_KEY_FILE to the local .pem path}"
REMOTE_DIR="/home/ec2-user/claude-ec2-lab"

command -v scp >/dev/null || { echo "scp is required" >&2; exit 1; }
chmod 400 "$EC2_KEY_FILE"
ssh -i "$EC2_KEY_FILE" -o StrictHostKeyChecking=accept-new "ec2-user@$EC2_HOST" \
  'sudo dnf install -y docker >/dev/null && sudo systemctl enable --now docker && sudo usermod -aG docker ec2-user && mkdir -p ~/claude-ec2-lab'
scp -i "$EC2_KEY_FILE" -r app Dockerfile docker-compose.yml .env.example "ec2-user@$EC2_HOST:$REMOTE_DIR/"
ssh -i "$EC2_KEY_FILE" "ec2-user@$EC2_HOST" \
  "set -e; cd $REMOTE_DIR; test -f .env || cp .env.example .env; sudo docker build -t claude-ec2-lab .; sudo docker rm -f claude-ec2-lab >/dev/null 2>&1 || true; sudo docker run -d --restart unless-stopped --name claude-ec2-lab --env-file .env -p 8000:8000 claude-ec2-lab"
printf 'Deployed. Test: curl http://%s:8000/health\n' "$EC2_HOST"
