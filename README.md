# Claude EC2 Lab

Proyecto pequeño para pasar de teoría a práctica: lanzar una instancia EC2,
conectarse por SSH, desplegar una API FastAPI en Docker y probar una llamada a
Claude. Los endpoints `/`, `/health` y `/config` funcionan sin una clave API;
`POST /ask` requiere `ANTHROPIC_API_KEY`.

## Qué vas a practicar

- AWS CLI, región, VPC, security group, key pair e instancia EC2.
- Amazon Linux 2023, SSH y Docker.
- Despliegue reproducible con scripts y Docker Compose.
- FastAPI, variables de entorno y una llamada al API de Claude.
- Control de costes: terminar la instancia cuando acabes.

## Requisitos y coste

Necesitas AWS CLI configurado (`aws configure`), permisos para EC2, un key
pair creado en la región elegida y `curl`, `ssh` y `scp`. El script abre SSH y
el puerto 8000 únicamente para tu IP pública actual. EC2 puede generar costes:
revisa los precios y tu Free Tier en la cuenta antes de lanzar nada.

Puedes validar la API localmente antes de tocar AWS:

```bash
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements-dev.txt
pytest -q
```

## 1. Lanzar EC2

Desde esta carpeta, usando una key pair existente:

```bash
export AWS_REGION=eu-west-1
export EC2_KEY_NAME=mi-key-pair
./scripts/launch_ec2.sh
```

Guarda el `INSTANCE_ID` y `PUBLIC_IP` que imprime. El script usa la AMI de
Amazon Linux 2023 vía el parámetro público de SSM y exige IMDSv2.

## 2. Desplegar la API

```bash
export EC2_HOST=203.0.113.10
export EC2_KEY_FILE="$HOME/.ssh/mi-key-pair.pem"
./scripts/deploy_ec2.sh
curl "http://$EC2_HOST:8000/health"
```

Para activar Claude, entra por SSH y edita `.env` en la instancia:

```bash
ssh -i "$EC2_KEY_FILE" ec2-user@$EC2_HOST
cd claude-ec2-lab
nano .env
sudo docker rm -f claude-ec2-lab
sudo docker run -d --restart unless-stopped --name claude-ec2-lab \
  --env-file .env -p 8000:8000 claude-ec2-lab
```

Prueba la API en `http://$EC2_HOST:8000/docs` o:

```bash
curl -X POST "http://$EC2_HOST:8000/ask" \
  -H 'content-type: application/json' \
  -d '{"prompt":"Explica qué es una instancia EC2 en tres frases."}'
```

Nunca pongas una clave real en Git ni en `launch_ec2.sh`.

## 3. Terminar la instancia

Cuando termines la práctica:

```bash
export EC2_INSTANCE_ID=i-xxxxxxxxxxxxxxxxx
./scripts/terminate_ec2.sh
```

Terminar la instancia es la opción segura para esta práctica. Si solo la
detienes, algunos recursos asociados pueden seguir generando costes.

## Próximas iteraciones

1. Añadir una prueba de integración para `/health`.
2. Añadir GitHub Actions para ejecutar tests y construir la imagen.
3. Sustituir el acceso público por HTTPS detrás de un reverse proxy.
4. Añadir CloudWatch y un rol IAM con permisos mínimos.
