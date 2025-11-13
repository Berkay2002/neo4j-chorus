# Neo4j Chorus - Knowledge Graph Service

[![Neo4j](https://img.shields.io/badge/Neo4j-5.26-blue.svg)](https://neo4j.com/)
[![Docker](https://img.shields.io/badge/Docker-Compose-blue.svg)](https://www.docker.com/)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)

Neo4j-based knowledge graph service for the **Chorus** AI chat platform. This provides long-term memory, entity relationships, and semantic context for AI conversations.

## Overview

This repository contains a production-ready Neo4j deployment with:

- **Neo4j 5.15 Community Edition** with APOC plugins
- **Docker Compose** for easy deployment
- **Pre-configured schema** for Chorus data model
- **Sample data** for development/testing
- **Digital Ocean deployment guide**

## Architecture

### Three-Tier Memory System

Chorus uses a three-tier memory architecture:

1. **Short-term** (Zustand) - Last 15 messages in browser memory
2. **Mid-term** (Supabase pgvector) - Semantic search across all messages
3. **Long-term** (Neo4j) - Knowledge graph with entity relationships ← **This repo**

### Graph Data Model

**Nodes:**
- `User` - Chat participants (human & AI)
- `Message` - Individual chat messages
- `Topic` - Extracted conversation topics
- `Entity` - Named entities (technologies, concepts, people)
- `Decision` - Important group decisions
- `Channel` / `Server` - Lightweight references to Supabase data

**Relationships:**
- `SENT`, `MENTIONS`, `DISCUSSES`, `INVOLVES` - Core associations
- `NEXT` - Temporal message flow
- `SEMANTICALLY_SIMILAR` - AI-detected similarity
- `RELATES_TO`, `SUBTOPIC_OF` - Topic hierarchy

See `scripts/02-data-model.cypher` for complete schema.

## Quick Start (Local Development)

### Prerequisites

- Docker & Docker Compose installed
- At least 4GB RAM available
- Port 7474 (HTTP), 7687 (Bolt) available

### 1. Clone and Setup

```bash
# Clone the repository
git clone https://github.com/yourusername/neo4j-chorus.git
cd neo4j-chorus

# Copy environment file
cp .env.example .env

# Edit .env and set a strong password
nano .env
```

### 2. Start Neo4j

```bash
# Build and start Neo4j
docker-compose up -d

# Check logs
docker-compose logs -f

# Wait for "Started." message
```

### 3. Access Neo4j Browser

Open [http://localhost:7474](http://localhost:7474) in your browser.

**Login credentials:**
- Username: `neo4j`
- Password: (from your `.env` file, default: `chorus_dev_password`)

### 4. Initialize Schema

In Neo4j Browser, run:

```cypher
// Copy contents of scripts/01-init-schema.cypher
// Paste and execute
```

Or use cypher-shell:

```bash
docker exec -it chorus-neo4j cypher-shell -u neo4j -p your_password < scripts/01-init-schema.cypher
```

### 5. Load Sample Data (Optional)

```bash
docker exec -it chorus-neo4j cypher-shell -u neo4j -p your_password < scripts/03-sample-data.cypher
```

## Project Structure

```
neo4j-chorus/
├── Dockerfile                 # Neo4j container with APOC
├── docker-compose.yml         # Docker Compose configuration
├── .env.example              # Environment variables template
├── .env                      # Your local config (gitignored)
├── .gitignore                # Git ignore rules
├── README.md                 # This file
├── DEPLOY.md                 # Digital Ocean deployment guide
├── data/                     # Neo4j data (gitignored)
├── logs/                     # Neo4j logs (gitignored)
├── plugins/                  # APOC & plugins (gitignored)
└── scripts/                  # Cypher initialization scripts
    ├── 01-init-schema.cypher      # Constraints & indexes
    ├── 02-data-model.cypher       # Graph model documentation
    └── 03-sample-data.cypher      # Test data
```

## Configuration

### Environment Variables

Edit `.env` to configure:

```bash
# Authentication
NEO4J_USER=neo4j
NEO4J_PASSWORD=your_secure_password_here

# Ports
NEO4J_HTTP_PORT=7474    # Browser interface
NEO4J_BOLT_PORT=7687    # Client connections

# Memory (adjust based on server RAM)
NEO4J_HEAP_INITIAL=512m
NEO4J_HEAP_MAX=2G
NEO4J_PAGECACHE=1G
```

### Memory Recommendations

| Server RAM | Heap Max | Page Cache |
|-----------|----------|------------|
| 4GB       | 1G       | 512m       |
| 8GB       | 2G       | 1G         |
| 16GB      | 4G       | 2G         |
| 32GB+     | 8G       | 4G+        |

**Rule of thumb:** 
- Heap: 50% of server RAM (for dedicated server)
- Page cache: 25-50% of remaining RAM

## Common Operations

### Start/Stop/Restart

```bash
# Start
docker-compose up -d

# Stop
docker-compose down

# Restart
docker-compose restart

# View logs
docker-compose logs -f neo4j
```

### Backup Data

```bash
# Create backup
docker exec chorus-neo4j neo4j-admin database dump neo4j --to-path=/backups

# Copy to host
docker cp chorus-neo4j:/backups/neo4j.dump ./backups/

# Restore backup
docker exec chorus-neo4j neo4j-admin database load neo4j --from-path=/backups
```

### Update Neo4j

```bash
# Edit Dockerfile to change Neo4j version
nano Dockerfile

# Rebuild
docker-compose down
docker-compose build --no-cache
docker-compose up -d
```

## Integration with Chorus

### Connection from Next.js

```typescript
// lib/neo4j/client.ts
import neo4j from 'neo4j-driver';

const driver = neo4j.driver(
  process.env.NEO4J_URI || 'bolt://localhost:7687',
  neo4j.auth.basic(
    process.env.NEO4J_USER || 'neo4j',
    process.env.NEO4J_PASSWORD || ''
  )
);

export async function getRelatedTopics(topicName: string) {
  const session = driver.session();
  try {
    const result = await session.run(
      `MATCH (t1:Topic {name: $name})-[:RELATES_TO*1..2]-(t2:Topic)
       RETURN DISTINCT t2.name, count(*) as strength
       ORDER BY strength DESC LIMIT 10`,
      { name: topicName }
    );
    return result.records.map(r => ({
      name: r.get('t2.name'),
      strength: r.get('strength').toNumber()
    }));
  } finally {
    await session.close();
  }
}
```

### API Endpoints

You can create a separate API service (see `DEPLOY.md`) or integrate directly in Next.js API routes.

## Useful Cypher Queries

### Find conversation context

```cypher
MATCH (m:Message {id: $messageId})-[:NEXT*0..10]->(context:Message)
RETURN context ORDER BY context.timestamp;
```

### Get user expertise

```cypher
MATCH (u:User {id: $userId})-[:SENT]->(m:Message)-[:DISCUSSES]->(t:Topic)
RETURN t.name, count(*) as mentions
ORDER BY mentions DESC LIMIT 10;
```

### Find related topics

```cypher
MATCH (t1:Topic {name: $topicName})-[:RELATES_TO*1..2]-(t2:Topic)
RETURN DISTINCT t2.name, count(*) as strength
ORDER BY strength DESC;
```

### Search decisions by status

```cypher
MATCH (d:Decision)
WHERE d.status = 'Accepted'
RETURN d.title, d.description, d.madeAt
ORDER BY d.madeAt DESC;
```

See `scripts/02-data-model.cypher` for more example queries.

## Troubleshooting

### Container won't start

```bash
# Check logs
docker-compose logs neo4j

# Check disk space
df -h

# Ensure ports are available
netstat -tuln | grep 7474
netstat -tuln | grep 7687
```

### Out of memory errors

```bash
# Increase heap/pagecache in .env
NEO4J_HEAP_MAX=4G
NEO4J_PAGECACHE=2G

# Restart
docker-compose down
docker-compose up -d
```

### Cannot connect from Chorus app

```bash
# Check Neo4j is running
docker-compose ps

# Test connection
docker exec -it chorus-neo4j cypher-shell -u neo4j -p your_password

# Check firewall (if on remote server)
sudo ufw status
sudo ufw allow 7687
```

### Slow queries

```cypher
// Create missing indexes
CREATE INDEX missing_idx IF NOT EXISTS
FOR (n:NodeType) ON (n.property);

// View query plan
EXPLAIN MATCH (n:Message) WHERE n.timestamp > datetime('2025-11-01') RETURN n;

// Profile query
PROFILE MATCH (n:Message) WHERE n.timestamp > datetime('2025-11-01') RETURN n;
```

## Security Best Practices

### For Production

1. **Change default password** in `.env`
2. **Use HTTPS** (enable in `docker-compose.yml`)
3. **Restrict ports** with firewall (only allow from app server)
4. **Enable auth** (already configured in Dockerfile)
5. **Regular backups** (automate with cron)
6. **Update Neo4j** regularly for security patches

### Firewall Configuration (Digital Ocean)

```bash
# Allow only from Chorus app server
sudo ufw allow from YOUR_APP_SERVER_IP to any port 7687

# Deny public access to Neo4j Browser
sudo ufw deny 7474

# For development, allow SSH
sudo ufw allow 22

sudo ufw enable
```

## Performance Tuning

### Query Optimization

- Always use indexes for lookups
- Use `LIMIT` to constrain result sets
- Use `EXPLAIN`/`PROFILE` to analyze queries
- Avoid Cartesian products (`MATCH (a), (b)`)

### Database Maintenance

```cypher
// View index statistics
CALL db.stats.retrieve('GRAPH COUNTS');

// Rebuild indexes (if needed)
DROP INDEX index_name;
CREATE INDEX index_name FOR (n:Label) ON (n.property);
```

## Monitoring

### Check database stats

```cypher
// Node counts
MATCH (n) RETURN labels(n) as Label, count(*) as Count;

// Relationship counts
MATCH ()-[r]->() RETURN type(r) as Type, count(*) as Count;

// Database size
CALL apoc.meta.stats();
```

### Docker stats

```bash
docker stats chorus-neo4j
```

## Next Steps

1. **Deploy to Digital Ocean** - See [DEPLOY.md](DEPLOY.md) for step-by-step guide
2. **Integrate with Chorus** - Connect Next.js app to Neo4j
3. **Implement entity extraction** - Extract entities from messages
4. **Build API layer** - Create REST/GraphQL API for graph queries

## Resources

- [Neo4j Documentation](https://neo4j.com/docs/)
- [APOC Documentation](https://neo4j.com/labs/apoc/)
- [Cypher Manual](https://neo4j.com/docs/cypher-manual/current/)
- [Neo4j Docker Guide](https://neo4j.com/docs/operations-manual/current/docker/)

## License

MIT License - See LICENSE file

## Support

For issues related to:
- **Neo4j setup** - Open issue in this repo
- **Chorus integration** - See main Chorus repo
- **Neo4j bugs** - Report to [Neo4j GitHub](https://github.com/neo4j/neo4j)

---

**Built for Chorus** - AI-enhanced social chat with perfect memory
