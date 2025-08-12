# n8n-hbrm

A fully automated, self-hosted deployment pipeline for [n8n](https://n8n.io), powered by GitHub Actions, Docker, and cloud-native tooling.

This project simplifies provisioning, deployment, and backups of the n8n workflow automation platform on any remote virtual machine (VM).

---

## 🚀 Features

### ✅ **IMPLEMENTED**
- ✅ **Secure Remote Provisioning** – Set up VMs over SSH via GitHub Actions
- ✅ **Docker & Git Automation** – Automated installation on target VMs
- ✅ **n8n Deployment via Docker Compose** – Full container orchestration
- ✅ **NGINX Reverse Proxy with SSL** – Automatic HTTPS with Let's Encrypt
- ✅ **Google Drive Backup Support** – Daily automated backups with `rclone`
- ✅ **Backup Restoration** – Easy restore from any backup point

### 🔄 **PLANNED**
- 🔄 **Monitoring with Beszel** – System metrics and alerts
- 🔄 **Uptime Monitoring** – URL monitoring with Uptime-Kuma
- 🔄 **Complete Integration** – One-click full setup workflow

---

## 📋 Quick Start

### Prerequisites
- A Linux VM (Ubuntu 20.04+ recommended)
- SSH access to your VM
- A domain name (for SSL setup)
- GitHub repository with this code

### 1. Configure GitHub Secrets

Go to your GitHub repository → Settings → Secrets and variables → Actions, and add:

**Required Secrets:**
```
VM_SSH_KEY     # Your private SSH key (base64 encoded for deploy-n8n.yml)
VM_IP          # Your VM's IP address
VM_USER        # SSH username for your VM
```

**Optional (for Google Drive backups):**
```
RCLONE_CONFIG_GDRIVE_TYPE          # drive
RCLONE_CONFIG_GDRIVE_CLIENT_ID     # Your Google Drive API client ID
RCLONE_CONFIG_GDRIVE_CLIENT_SECRET # Your Google Drive API client secret
RCLONE_CONFIG_GDRIVE_TOKEN         # Your rclone token (JSON format)
RCLONE_CONFIG_GDRIVE_SCOPE         # drive
```

### 2. Run Workflows

1. **Setup Server**: Go to Actions → "Setup Server" → Run workflow
2. **Deploy n8n**: Go to Actions → "Deploy n8n" → Run workflow
3. **Setup NGINX** (optional): Go to Actions → "Setup NGINX Reverse Proxy with SSL" → Run workflow
4. **Setup Backups** (optional): Go to Actions → "Backup n8n to Google Drive" → Run workflow

## 📁 Project Structure

```
hbrm-test/
├── .github/workflows/          # GitHub Actions workflows
│   ├── setup-server.yml       # VM setup and Docker installation
│   ├── deploy-n8n.yml         # n8n deployment
│   ├── setup-nginx.yml        # NGINX reverse proxy with SSL
│   ├── backup.yml              # Daily Google Drive backups
│   └── restore.yml             # Backup restoration
├── docker/                     # Docker configurations
│   ├── docker-compose.n8n.yml # Basic n8n setup
│   └── docker-compose.nginx.yml # n8n with NGINX proxy
├── nginx/                      # NGINX configurations
│   ├── nginx.conf              # Main NGINX config
│   └── conf.d/n8n.conf         # n8n-specific proxy config
├── scripts/                    # Automation scripts
│   ├── setup_vm.sh             # VM setup script
│   ├── deploy_n8n.sh           # n8n deployment script
│   ├── setup_nginx.sh          # NGINX setup script
│   ├── backup_n8n.sh           # Backup script
│   └── restore_backup.sh       # Restore script
└── .env.example                # Environment variables template
```

## 🔧 Detailed Setup Guide

### Step 1: VM Preparation

1. **Create a Linux VM** (Ubuntu 20.04+ recommended)
2. **Configure SSH access** with key-based authentication
3. **Point your domain** to the VM's IP address (for SSL)

### Step 2: GitHub Repository Setup

1. **Fork or clone** this repository
2. **Configure secrets** in GitHub repository settings
3. **Update .env.example** with your preferred settings

### Step 3: Automated Deployment

#### Option A: Basic Setup (HTTP only)
```bash
# 1. Run "Setup Server" workflow
# 2. Run "Deploy n8n" workflow
# Access n8n at: http://your-vm-ip:5678
```

#### Option B: Production Setup (HTTPS with domain)
```bash
# 1. Run "Setup Server" workflow
# 2. Run "Setup NGINX Reverse Proxy with SSL" workflow
# 3. Access n8n at: https://your-domain.com
```

### Step 4: Backup Configuration (Optional)

1. **Set up Google Drive API** credentials
2. **Configure rclone** secrets in GitHub
3. **Run "Backup n8n to Google Drive"** workflow
4. **Backups run daily** at 2:00 AM UTC automatically

---

## 🔐 Security Features

- **SSH key-based authentication** for all remote operations
- **HTTPS/TLS encryption** with automatic Let's Encrypt certificates
- **Rate limiting** on API endpoints and login attempts
- **Security headers** (HSTS, XSS protection, etc.)
- **Basic authentication** for n8n access
- **Firewall-friendly** setup (only ports 80, 443, and SSH needed)

---

## 🔄 Backup & Restore

### Automated Daily Backups
- **Scheduled daily** at 2:00 AM UTC
- **30-day retention** with automatic cleanup
- **Google Drive storage** with rclone
- **Zero-downtime** backup process

### Manual Backup
```bash
# Run "Backup n8n to Google Drive" workflow manually
```

### Restore Process
```bash
# 1. Run "Restore n8n from Google Drive Backup" workflow
# 2. Type "CONFIRM" when prompted
# 3. Choose backup file or leave empty to see list
```

---

## 🚨 Troubleshooting

### Common Issues

**SSH Connection Failed**
- Verify VM_SSH_KEY secret is correctly formatted
- Check VM_IP and VM_USER are correct
- Ensure SSH key has proper permissions on VM

**Docker Installation Failed**
- VM needs sudo access for Docker installation
- Check VM has internet connectivity
- Verify Ubuntu/Debian-based OS

**SSL Certificate Failed**
- Domain must point to VM IP address
- Port 80 must be accessible from internet
- Check domain DNS propagation

**Backup Failed**
- Verify Google Drive API credentials
- Check rclone configuration secrets
- Ensure sufficient Google Drive storage

### Getting Help

1. **Check workflow logs** in GitHub Actions tab
2. **SSH into your VM** to debug manually
3. **Review container logs**: `docker logs n8n`
4. **Check disk space**: `df -h`

---

## 📊 Current Implementation Status

| Stage | Feature | Status | Files |
|-------|---------|--------|-------|
| 1 | Project Structure | ✅ Complete | All directories and base files |
| 2 | VM Setup via GitHub Actions | ✅ Complete | `setup-server.yml`, `setup_vm.sh` |
| 3 | Deploy & Update n8n | ✅ Complete | `deploy-n8n.yml`, `deploy_n8n.sh` |
| 4 | Reverse Proxy (NGINX + SSL) | ✅ Complete | `setup-nginx.yml`, NGINX configs |
| 5 | Daily Backup to Google Drive | ✅ Complete | `backup.yml`, `backup_n8n.sh` |
| 6 | Restore Backups | ✅ Complete | `restore.yml`, `restore_backup.sh` |
| 7 | Monitoring with Beszel | 🔄 Planned | Not implemented |
| 8 | Uptime Monitoring | 🔄 Planned | Not implemented |
| 9 | Final Integration | 🔄 Planned | Not implemented |

---

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

---

## 📄 License

This project is open source and available under the [MIT License](LICENSE).

---


