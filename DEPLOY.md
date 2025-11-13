# Digital Ocean Deployment Guide

Complete step-by-step guide for deploying Neo4j Chorus to Digital Ocean.

## Prerequisites

- Digital Ocean account
- SSH key configured
- Domain name (optional, for HTTPS)
- Credit card for billing

## Cost Estimate

| Component | Specs | Monthly Cost |
|-----------|-------|--------------|
| Droplet (4GB RAM) | 2 vCPUs, 4GB RAM, 80GB SSD | $24/month |
| Droplet (8GB RAM) | 4 vCPUs, 8GB RAM, 160GB SSD | $48/month |
| Bandwidth | 1TB included | Free |
| Backups (optional) | 20% of droplet cost | +$4.80-$9.60/month |

**Recommended:** Start with 4GB droplet ($24/month), upgrade if needed.

---

## Step 1: Create Digital Ocean Droplet

### 1.1 Via Web Console

1. Log in to [Digital Ocean](https://cloud.digitalocean.com/)
2. Click **Create** → **Droplets**
3. Configure:

**Choose an image:**
- Distribution: **Ubuntu 24.04 LTS**

**Choose Size:**
- Droplet Type: **Basic**
- CPU options: **Regular**
- Size: **4GB RAM / 2 vCPUs / 80GB SSD** ($24/month)

**Choose a datacenter region:**
- Select closest to your users (e.g., New York, San Francisco, London)

**Authentication:**
- Select your SSH key (or create new one)
- ⚠️ **Do NOT use password authentication** (less secure)

**Finalize Details:**
- Hostname: `neo4j-chorus` (or your preference)
- Tags: `chorus`, `neo4j`, `production`
- Backups: Enable (recommended, +$4.80/month)

4. Click **Create Droplet**

### 1.2 Via CLI (Alternative)

```bash
# Install doctl (Digital Ocean CLI)
brew install doctl  # macOS
# or: snap install doctl  # Linux

# Authenticate
doctl auth init

# Create droplet
doctl compute droplet create neo4j-chorus \
  --image ubuntu-24-04-x64 \
  --size s-2vcpu-4gb \
  --region nyc1 \
  --ssh-keys YOUR_SSH_KEY_ID \
  --tag-names chorus,neo4j,production \
  --enable-backups
```

---

## Step 2: Initial Server Setup

### 2.1 SSH into Droplet

```bash
# Get droplet IP
doctl compute droplet list

# SSH in (replace with your IP)
ssh root@YOUR_DROPLET_IP
```

### 2.2 Create Non-Root User

```bash
# Create user
adduser chorus

# Grant sudo privileges
usermod -aG sudo chorus

# Copy SSH keys to new user
rsync --archive --chown=chorus:chorus ~/.ssh /home/chorus

# Test (open new terminal)
ssh chorus@YOUR_DROPLET_IP
```

### 2.3 Configure Firewall

```bash
# Enable UFW firewall
sudo ufw allow OpenSSH
sudo ufw allow 7687/tcp  # Neo4j Bolt (restrict later)
sudo ufw enable

# Check status
sudo ufw status verbose
```

---

## Step 3: Install Docker

```bash
# Update packages
sudo apt update
sudo apt upgrade -y

# Install prerequisites
sudo apt install -y apt-transport-https ca-certificates curl software-properties-common

# Add Docker GPG key
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

# Add Docker repository
echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Install Docker
sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io

# Add user to docker group
sudo usermod -aG docker ${USER}

# Apply group changes (or logout/login)
newgrp docker

# Verify installation
docker --version
docker run hello-world
```

---

## Step 4: Install Docker Compose

```bash
# Download Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/download/v2.24.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose

# Make executable
sudo chmod +x /usr/local/bin/docker-compose

# Verify installation
docker-compose --version
```

---

## Step 5: Deploy Neo4j Chorus

### 5.1 Clone Repository

```bash
# Install git
sudo apt install -y git

# Clone repo (replace with your repo URL)
cd ~
git clone https://github.com/yourusername/neo4j-chorus.git
cd neo4j-chorus
```

### 5.2 Configure Environment

```bash
# Copy example env file
cp .env.example .env

# Edit configuration
nano .env
```

**Update these values:**

```bash
# CRITICAL: Set strong password!
NEO4J_PASSWORD=YOUR_SUPER_SECURE_PASSWORD_HERE

# Memory settings for 4GB droplet
NEO4J_HEAP_INITIAL=512m
NEO4J_HEAP_MAX=2G
NEO4J_PAGECACHE=1G

# Production environment
NODE_ENV=production
```

Save and exit (Ctrl+X, Y, Enter)

### 5.3 Start Neo4j

```bash
# Build and start
docker-compose up -d

# Check logs
docker-compose logs -f

# Wait for "Started." message
# Press Ctrl+C to exit logs
```

### 5.4 Verify Deployment

```bash
# Check container status
docker-compose ps

# Should show:
# NAME           STATUS    PORTS
# chorus-neo4j   Up        0.0.0.0:7474->7474/tcp, 0.0.0.0:7687->7687/tcp

# Test connection
docker exec -it chorus-neo4j cypher-shell -u neo4j -p YOUR_PASSWORD

# You should see: neo4j@neo4j>
# Type :exit to quit
```

---

## Step 6: Initialize Database

### 6.1 Run Schema Initialization

```bash
# From neo4j-chorus directory
cd ~/neo4j-chorus

# Initialize schema
docker exec -i chorus-neo4j cypher-shell -u neo4j -p YOUR_PASSWORD < scripts/01-init-schema.cypher

# Should see: "Added X constraints, Added Y indexes"
```

### 6.2 Load Sample Data (Optional)

```bash
# Load test data
docker exec -i chorus-neo4j cypher-shell -u neo4j -p YOUR_PASSWORD < scripts/03-sample-data.cypher
```

### 6.3 Verify Schema

```bash
# Connect to cypher-shell
docker exec -it chorus-neo4j cypher-shell -u neo4j -p YOUR_PASSWORD

# Check constraints
SHOW CONSTRAINTS;

# Check indexes
SHOW INDEXES;

# Count nodes
MATCH (n) RETURN labels(n) as Label, count(*) as Count;

# Exit
:exit
```

---

## Step 7: Secure Production Deployment

### 7.1 Restrict Neo4j Access

**Only allow connections from Chorus app server:**

```bash
# Get your Chorus app server IP
# (e.g., Vercel IPs or your own server)

# Block public access to Neo4j Browser
sudo ufw delete allow 7687/tcp

# Allow only from app server
sudo ufw allow from YOUR_CHORUS_APP_IP to any port 7687

# Reload firewall
sudo ufw reload
sudo ufw status
```

### 7.2 Enable HTTPS (Optional, for Browser access)

**Requirements:** Domain name pointing to droplet IP

```bash
# Install Nginx
sudo apt install -y nginx

# Install Certbot
sudo apt install -y certbot python3-certbot-nginx

# Get SSL certificate
sudo certbot --nginx -d neo4j.yourdomain.com

# Configure Nginx reverse proxy
sudo nano /etc/nginx/sites-available/neo4j
```

**Nginx config:**

```nginx
server {
    listen 443 ssl;
    server_name neo4j.yourdomain.com;

    ssl_certificate /etc/letsencrypt/live/neo4j.yourdomain.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/neo4j.yourdomain.com/privkey.pem;

    location / {
        proxy_pass http://localhost:7474;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
```

```bash
# Enable site
sudo ln -s /etc/nginx/sites-available/neo4j /etc/nginx/sites-enabled/

# Test config
sudo nginx -t

# Restart Nginx
sudo systemctl restart nginx
```

### 7.3 Setup Automatic Backups

```bash
# Create backup script
sudo nano /usr/local/bin/backup-neo4j.sh
```

**Backup script:**

```bash
#!/bin/bash
BACKUP_DIR="/home/chorus/neo4j-backups"
DATE=$(date +%Y%m%d-%H%M%S)

mkdir -p $BACKUP_DIR

# Dump database
docker exec chorus-neo4j neo4j-admin database dump neo4j --to-path=/backups

# Copy to host
docker cp chorus-neo4j:/backups/neo4j.dump $BACKUP_DIR/neo4j-$DATE.dump

# Keep only last 7 backups
cd $BACKUP_DIR
ls -t | tail -n +8 | xargs rm -f

echo "Backup completed: neo4j-$DATE.dump"
```

```bash
# Make executable
sudo chmod +x /usr/local/bin/backup-neo4j.sh

# Test backup
sudo /usr/local/bin/backup-neo4j.sh

# Setup cron (daily at 2 AM)
sudo crontab -e

# Add line:
0 2 * * * /usr/local/bin/backup-neo4j.sh >> /var/log/neo4j-backup.log 2>&1
```

---

## Step 8: Monitoring & Maintenance

### 8.1 View Logs

```bash
# Docker logs
docker-compose logs -f neo4j

# System logs
journalctl -u docker -f

# Backup logs
tail -f /var/log/neo4j-backup.log
```

### 8.2 Monitor Resources

```bash
# Docker stats
docker stats chorus-neo4j

# System resources
htop  # (install: sudo apt install htop)

# Disk usage
df -h
du -sh ~/neo4j-chorus/data
```

### 8.3 Database Health

```cypher
// Connect to cypher-shell
docker exec -it chorus-neo4j cypher-shell -u neo4j -p YOUR_PASSWORD

// Check database info
CALL dbms.components();

// Check memory usage
CALL dbms.queryJmx("org.neo4j:instance=kernel#0,name=Store sizes");

// Performance stats
CALL apoc.meta.stats();
```

---

## Step 9: Connect from Chorus App

### 9.1 Environment Variables

In your **Chorus Next.js app**, add to `.env.production`:

```bash
NEO4J_URI=bolt://YOUR_DROPLET_IP:7687
NEO4J_USER=neo4j
NEO4J_PASSWORD=YOUR_SECURE_PASSWORD
```

### 9.2 Install Neo4j Driver

```bash
# In your Chorus repo
npm install neo4j-driver
```

### 9.3 Create Neo4j Client

```typescript
// lib/neo4j/client.ts
import neo4j from 'neo4j-driver';

const driver = neo4j.driver(
  process.env.NEO4J_URI!,
  neo4j.auth.basic(
    process.env.NEO4J_USER!,
    process.env.NEO4J_PASSWORD!
  )
);

export default driver;

// Test connection
export async function testConnection() {
  const session = driver.session();
  try {
    const result = await session.run('RETURN 1 as test');
    console.log('Neo4j connected:', result.records[0].get('test'));
  } finally {
    await session.close();
  }
}
```

### 9.4 Test Connection

```typescript
// app/api/neo4j/test/route.ts
import { testConnection } from '@/lib/neo4j/client';

export async function GET() {
  try {
    await testConnection();
    return Response.json({ success: true, message: 'Connected to Neo4j' });
  } catch (error) {
    return Response.json({ success: false, error: String(error) }, { status: 500 });
  }
}
```

Visit: `https://your-chorus-app.com/api/neo4j/test`

---

## Troubleshooting

### Issue: Cannot connect from Chorus app

**Check firewall:**
```bash
sudo ufw status
# Ensure app server IP is allowed on port 7687
```

**Check Neo4j is listening:**
```bash
docker exec chorus-neo4j netstat -tuln | grep 7687
```

**Test connection from app server:**
```bash
telnet YOUR_DROPLET_IP 7687
```

### Issue: Out of memory

**Check memory usage:**
```bash
docker stats chorus-neo4j
```

**Increase memory in `.env`:**
```bash
NEO4J_HEAP_MAX=3G  # (if you have 8GB droplet)
NEO4J_PAGECACHE=2G
```

**Restart:**
```bash
docker-compose down
docker-compose up -d
```

### Issue: Slow queries

**Create missing indexes:**
```cypher
CREATE INDEX IF NOT EXISTS FOR (m:Message) ON (m.timestamp);
```

**Profile queries:**
```cypher
PROFILE MATCH (m:Message) WHERE m.timestamp > datetime('2025-11-01') RETURN m;
```

### Issue: Disk full

**Check disk usage:**
```bash
df -h
du -sh ~/neo4j-chorus/data
```

**Clean old logs:**
```bash
docker exec chorus-neo4j find /logs -type f -mtime +7 -delete
```

**Upgrade droplet:**
- Go to Digital Ocean console
- Resize droplet to larger disk

---

## Scaling & Performance

### Vertical Scaling (Upgrade Droplet)

```bash
# From Digital Ocean console:
# 1. Power off droplet
# 2. Resize (CPU & RAM or Disk)
# 3. Power on

# Update .env with new memory settings
NEO4J_HEAP_MAX=4G  # For 8GB droplet
NEO4J_PAGECACHE=2G
```

### Horizontal Scaling (Clustering)

For high availability, see:
- [Neo4j Clustering Docs](https://neo4j.com/docs/operations-manual/current/clustering/)
- Requires Neo4j Enterprise License

### Read Replicas

For read-heavy workloads:
1. Create additional droplet
2. Deploy Neo4j in read-only mode
3. Use Causal Clustering

---

## Cost Optimization

### Reduce Costs

1. **Start small:** 4GB droplet is enough for MVP
2. **Use Volumes:** Separate data volume for easier upgrades
3. **Enable compression:** In Neo4j config
4. **Optimize queries:** Use indexes, limit results
5. **Archive old data:** Move to S3/Spaces after 6 months

### Alternative: Managed Neo4j

If self-hosting is complex, consider:
- [Neo4j Aura](https://neo4j.com/cloud/aura/) - Managed service
- Starts at $65/month
- No server management needed

---

## Next Steps

1. ✅ **Test connection** from Chorus app
2. ✅ **Set up monitoring** (logs, backups, alerts)
3. ✅ **Implement entity extraction** in Chorus app
4. ✅ **Create API endpoints** for graph queries
5. ✅ **Monitor performance** and scale as needed

---

## Resources

- [Digital Ocean Tutorials](https://www.digitalocean.com/community/tutorials)
- [Neo4j Operations Manual](https://neo4j.com/docs/operations-manual/current/)
- [Docker Security Best Practices](https://docs.docker.com/engine/security/)
- [UFW Firewall Guide](https://help.ubuntu.com/community/UFW)

---

**Deployment Complete!** 🎉

Your Neo4j knowledge graph is now running on Digital Ocean and ready to power Chorus's long-term memory.
