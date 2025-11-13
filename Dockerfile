# Neo4j Dockerfile for Chorus Knowledge Graph
# Based on Neo4j 5.x Community Edition with APOC plugin

FROM neo4j:5.23.0-community

# Set labels for metadata
LABEL maintainer="Chorus Team"
LABEL description="Neo4j Knowledge Graph for Chorus AI Chat Platform"
LABEL version="1.0.0"

# Install APOC plugin (Awesome Procedures on Cypher)
# APOC provides hundreds of useful procedures and functions
ENV APOC_VERSION=5.23.0
RUN wget -P /var/lib/neo4j/plugins https://github.com/neo4j-contrib/neo4j-apoc-procedures/releases/download/${APOC_VERSION}/apoc-${APOC_VERSION}-core.jar

# Configure Neo4j settings
ENV NEO4J_AUTH=neo4j/password \
    NEO4J_ACCEPT_LICENSE_AGREEMENT=yes \
    NEO4J_dbms_memory_heap_initial__size=512m \
    NEO4J_dbms_memory_heap_max__size=2G \
    NEO4J_dbms_memory_pagecache_size=1G \
    NEO4J_dbms_security_procedures_unrestricted=apoc.* \
    NEO4J_dbms_security_procedures_allowlist=apoc.*

# Expose Neo4j ports
# 7474 - HTTP
# 7473 - HTTPS
# 7687 - Bolt
EXPOSE 7474 7473 7687

# Health check
HEALTHCHECK --interval=30s --timeout=10s --retries=3 \
    CMD wget --quiet --tries=1 --spider http://localhost:7474 || exit 1

# Volume for data persistence
VOLUME ["/data", "/logs"]

# Start Neo4j
CMD ["neo4j"]
