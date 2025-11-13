// ============================================
// Chorus Knowledge Graph - Schema Initialization
// ============================================
// This script sets up the initial schema for the Chorus AI chat platform
// Run this after first Neo4j deployment

// ============================================
// 1. CREATE CONSTRAINTS (Uniqueness)
// ============================================

// User nodes must have unique IDs
CREATE CONSTRAINT user_id_unique IF NOT EXISTS
FOR (u:User) REQUIRE u.id IS UNIQUE;

// Message nodes must have unique IDs
CREATE CONSTRAINT message_id_unique IF NOT EXISTS
FOR (m:Message) REQUIRE m.id IS UNIQUE;

// Channel nodes must have unique IDs
CREATE CONSTRAINT channel_id_unique IF NOT EXISTS
FOR (c:Channel) REQUIRE c.id IS UNIQUE;

// Server nodes must have unique IDs
CREATE CONSTRAINT server_id_unique IF NOT EXISTS
FOR (s:Server) REQUIRE s.id IS UNIQUE;

// Topic nodes must have unique names
CREATE CONSTRAINT topic_name_unique IF NOT EXISTS
FOR (t:Topic) REQUIRE t.name IS UNIQUE;

// Entity nodes must have unique IDs
CREATE CONSTRAINT entity_id_unique IF NOT EXISTS
FOR (e:Entity) REQUIRE e.id IS UNIQUE;

// Decision nodes must have unique IDs
CREATE CONSTRAINT decision_id_unique IF NOT EXISTS
FOR (d:Decision) REQUIRE d.id IS UNIQUE;

// ============================================
// 2. CREATE INDEXES (Performance)
// ============================================

// Index on User username for fast lookups
CREATE INDEX user_username_idx IF NOT EXISTS
FOR (u:User) ON (u.username);

// Index on Message timestamp for temporal queries
CREATE INDEX message_timestamp_idx IF NOT EXISTS
FOR (m:Message) ON (m.timestamp);

// Index on Message content for text search
CREATE INDEX message_content_idx IF NOT EXISTS
FOR (m:Message) ON (m.content);

// Index on Channel name
CREATE INDEX channel_name_idx IF NOT EXISTS
FOR (c:Channel) ON (c.name);

// Index on Server name
CREATE INDEX server_name_idx IF NOT EXISTS
FOR (s:Server) ON (s.name);

// Index on Topic name for topic searches
CREATE INDEX topic_name_idx IF NOT EXISTS
FOR (t:Topic) ON (t.name);

// Index on Entity name
CREATE INDEX entity_name_idx IF NOT EXISTS
FOR (e:Entity) ON (e.name);

// Index on Decision status
CREATE INDEX decision_status_idx IF NOT EXISTS
FOR (d:Decision) ON (d.status);

// ============================================
// 3. CREATE NODE KEY CONSTRAINTS (Data Integrity)
// ============================================

// Ensure Message nodes have required properties
CREATE CONSTRAINT message_required IF NOT EXISTS
FOR (m:Message) REQUIRE m.id IS NOT NULL;

// Ensure User nodes have required properties
CREATE CONSTRAINT user_required IF NOT EXISTS
FOR (u:User) REQUIRE u.id IS NOT NULL;

// ============================================
// 4. SAMPLE DATA (Optional - for testing)
// ============================================

// Create sample server
MERGE (s:Server {
  id: 'server-test-001',
  name: 'Test Server',
  description: 'Initial test server for Chorus',
  createdAt: datetime()
});

// Create sample channel
MERGE (c:Channel {
  id: 'channel-test-001',
  name: 'general',
  description: 'General discussion',
  createdAt: datetime()
});

// Link channel to server
MATCH (s:Server {id: 'server-test-001'})
MATCH (c:Channel {id: 'channel-test-001'})
MERGE (s)-[:HAS_CHANNEL]->(c);

// Create AI user
MERGE (ai:User:AI {
  id: 'user-ai-chorus',
  username: 'Chorus',
  displayName: 'Chorus AI',
  createdAt: datetime(),
  isAI: true
});

// ============================================
// 5. UTILITY FUNCTIONS (APOC)
// ============================================

// These queries demonstrate APOC usage for Chorus

// Function to get message context (last N messages)
// CALL apoc.cypher.run('
//   MATCH (c:Channel {id: $channelId})<-[:IN_CHANNEL]-(m:Message)
//   RETURN m ORDER BY m.timestamp DESC LIMIT $limit
// ', {channelId: 'channel-id', limit: 10});

// Function to find related topics
// CALL apoc.path.expandConfig(
//   startNode, 
//   {relationshipFilter: "RELATES_TO>", minLevel: 1, maxLevel: 3}
// );

// ============================================
// VERIFICATION
// ============================================

// Show all constraints
SHOW CONSTRAINTS;

// Show all indexes
SHOW INDEXES;

// Count nodes by label
MATCH (n) RETURN labels(n) as Label, count(*) as Count;

// Show sample server structure
MATCH path = (s:Server)-[:HAS_CHANNEL]->(c:Channel)
RETURN path LIMIT 5;
