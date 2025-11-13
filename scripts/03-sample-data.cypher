// ============================================
// Sample Data for Testing
// ============================================
// Creates realistic test data for development

// ============================================
// 1. CREATE SAMPLE SERVER & CHANNELS
// ============================================

MERGE (s:Server {
  id: 'server-dev-001',
  name: 'Chorus Dev Team',
  createdAt: datetime()
});

MERGE (c1:Channel {
  id: 'channel-general',
  name: 'general',
  createdAt: datetime()
});

MERGE (c2:Channel {
  id: 'channel-architecture',
  name: 'architecture',
  createdAt: datetime()
});

MERGE (c3:Channel {
  id: 'channel-ai-experiments',
  name: 'ai-experiments',
  createdAt: datetime()
});

MATCH (s:Server {id: 'server-dev-001'})
MATCH (c1:Channel {id: 'channel-general'})
MATCH (c2:Channel {id: 'channel-architecture'})
MATCH (c3:Channel {id: 'channel-ai-experiments'})
MERGE (s)-[:HAS_CHANNEL]->(c1)
MERGE (s)-[:HAS_CHANNEL]->(c2)
MERGE (s)-[:HAS_CHANNEL]->(c3);

// ============================================
// 2. CREATE SAMPLE USERS
// ============================================

MERGE (u1:User {
  id: 'user-001',
  username: 'alice',
  displayName: 'Alice Chen',
  createdAt: datetime(),
  isAI: false
});

MERGE (u2:User {
  id: 'user-002',
  username: 'bob',
  displayName: 'Bob Martinez',
  createdAt: datetime(),
  isAI: false
});

MERGE (ai:User:AI {
  id: 'user-ai',
  username: 'chorus',
  displayName: 'Chorus AI',
  createdAt: datetime(),
  isAI: true
});

// Link users to server
MATCH (s:Server {id: 'server-dev-001'})
MATCH (u1:User {id: 'user-001'})
MATCH (u2:User {id: 'user-002'})
MATCH (ai:User {id: 'user-ai'})
MERGE (u1)-[:MEMBER_OF]->(s)
MERGE (u2)-[:MEMBER_OF]->(s)
MERGE (ai)-[:MEMBER_OF]->(s);

// ============================================
// 3. CREATE SAMPLE TOPICS
// ============================================

MERGE (t1:Topic {
  id: 'topic-architecture',
  name: 'System Architecture',
  category: 'Technical',
  firstMentioned: datetime(),
  lastMentioned: datetime(),
  mentionCount: 5
});

MERGE (t2:Topic {
  id: 'topic-database',
  name: 'Database Design',
  category: 'Technical',
  firstMentioned: datetime(),
  lastMentioned: datetime(),
  mentionCount: 3
});

MERGE (t3:Topic {
  id: 'topic-ai-memory',
  name: 'AI Memory System',
  category: 'Technical',
  firstMentioned: datetime(),
  lastMentioned: datetime(),
  mentionCount: 7
});

// Create topic relationships
MATCH (t1:Topic {id: 'topic-architecture'})
MATCH (t2:Topic {id: 'topic-database'})
MATCH (t3:Topic {id: 'topic-ai-memory'})
MERGE (t2)-[:SUBTOPIC_OF]->(t1)
MERGE (t3)-[:SUBTOPIC_OF]->(t1)
MERGE (t2)-[:RELATES_TO]->(t3);

// Link topics to channels
MATCH (c2:Channel {id: 'channel-architecture'})
MATCH (c3:Channel {id: 'channel-ai-experiments'})
MATCH (t1:Topic {id: 'topic-architecture'})
MATCH (t3:Topic {id: 'topic-ai-memory'})
MERGE (c2)-[:FOCUSES_ON]->(t1)
MERGE (c3)-[:FOCUSES_ON]->(t3);

// ============================================
// 4. CREATE SAMPLE ENTITIES
// ============================================

MERGE (e1:Entity {
  id: 'entity-supabase',
  name: 'Supabase',
  type: 'Technology',
  description: 'PostgreSQL with real-time and auth',
  createdAt: datetime()
});

MERGE (e2:Entity {
  id: 'entity-neo4j',
  name: 'Neo4j',
  type: 'Technology',
  description: 'Graph database for knowledge graph',
  createdAt: datetime()
});

MERGE (e3:Entity {
  id: 'entity-gemini',
  name: 'Google Gemini',
  type: 'Technology',
  description: 'AI model for chat and embeddings',
  createdAt: datetime()
});

MERGE (e4:Entity {
  id: 'entity-pgvector',
  name: 'pgvector',
  type: 'Technology',
  description: 'PostgreSQL vector extension',
  createdAt: datetime()
});

// Create entity relationships
MATCH (e1:Entity {id: 'entity-supabase'})
MATCH (e2:Entity {id: 'entity-neo4j'})
MATCH (e3:Entity {id: 'entity-gemini'})
MATCH (e4:Entity {id: 'entity-pgvector'})
MERGE (e1)-[:RELATED_TO]->(e4)
MERGE (e2)-[:MENTIONED_WITH]->(e1)
MERGE (e3)-[:RELATED_TO]->(e4);

// ============================================
// 5. CREATE SAMPLE DECISIONS
// ============================================

MERGE (d1:Decision {
  id: 'decision-001',
  title: 'Use Supabase for primary database',
  description: 'Chosen for integrated auth, real-time, and pgvector support',
  status: 'Accepted',
  madeAt: datetime(),
  implementedAt: datetime()
});

MERGE (d2:Decision {
  id: 'decision-002',
  title: 'Add Neo4j for knowledge graph',
  description: 'Separate graph database for long-term memory and entity relationships',
  status: 'Proposed',
  madeAt: datetime()
});

// Link decisions
MATCH (d1:Decision {id: 'decision-001'})
MATCH (d2:Decision {id: 'decision-002'})
MATCH (u1:User {id: 'user-001'})
MATCH (u2:User {id: 'user-002'})
MATCH (t2:Topic {id: 'topic-database'})
MATCH (e1:Entity {id: 'entity-supabase'})
MATCH (e2:Entity {id: 'entity-neo4j'})
MERGE (d1)-[:MADE_BY]->(u1)
MERGE (d2)-[:MADE_BY]->(u2)
MERGE (d1)-[:ABOUT]->(t2)
MERGE (d2)-[:ABOUT]->(t2)
MERGE (d1)-[:INVOLVES]->(e1)
MERGE (d2)-[:INVOLVES]->(e2);

// ============================================
// 6. CREATE SAMPLE MESSAGES
// ============================================

MERGE (m1:Message {
  id: 'msg-001',
  content: 'Should we use Supabase or Firebase for the backend?',
  timestamp: datetime('2025-11-10T10:00:00Z'),
  isAI: false,
  channelId: 'channel-architecture'
});

MERGE (m2:Message {
  id: 'msg-002',
  content: 'I think Supabase is better because it has native PostgreSQL and pgvector support for our AI features.',
  timestamp: datetime('2025-11-10T10:05:00Z'),
  isAI: false,
  channelId: 'channel-architecture'
});

MERGE (m3:Message {
  id: 'msg-003',
  content: '@chorus what do you think about Supabase vs Firebase?',
  timestamp: datetime('2025-11-10T10:07:00Z'),
  isAI: false,
  channelId: 'channel-architecture'
});

MERGE (m4:Message {
  id: 'msg-004',
  content: 'Based on your requirements for vector embeddings and real-time chat, Supabase is the better choice. It provides native pgvector support and PostgreSQL which will scale well with your knowledge graph integration.',
  timestamp: datetime('2025-11-10T10:07:30Z'),
  isAI: true,
  channelId: 'channel-architecture'
});

MERGE (m5:Message {
  id: 'msg-005',
  content: 'Agreed! Let\'s go with Supabase. Should we also add Neo4j for the long-term memory graph?',
  timestamp: datetime('2025-11-10T10:10:00Z'),
  isAI: false,
  channelId: 'channel-architecture'
});

// Link messages to users, channels, and topics
MATCH (m1:Message {id: 'msg-001'})
MATCH (m2:Message {id: 'msg-002'})
MATCH (m3:Message {id: 'msg-003'})
MATCH (m4:Message {id: 'msg-004'})
MATCH (m5:Message {id: 'msg-005'})
MATCH (u1:User {id: 'user-001'})
MATCH (u2:User {id: 'user-002'})
MATCH (ai:User {id: 'user-ai'})
MATCH (c2:Channel {id: 'channel-architecture'})
MATCH (t2:Topic {id: 'topic-database'})
MATCH (e1:Entity {id: 'entity-supabase'})
MATCH (e2:Entity {id: 'entity-neo4j'})
MATCH (e4:Entity {id: 'entity-pgvector'})
MERGE (u1)-[:SENT]->(m1)
MERGE (u2)-[:SENT]->(m2)
MERGE (u1)-[:SENT]->(m3)
MERGE (ai)-[:SENT]->(m4)
MERGE (u2)-[:SENT]->(m5)
MERGE (m1)-[:IN_CHANNEL]->(c2)
MERGE (m2)-[:IN_CHANNEL]->(c2)
MERGE (m3)-[:IN_CHANNEL]->(c2)
MERGE (m4)-[:IN_CHANNEL]->(c2)
MERGE (m5)-[:IN_CHANNEL]->(c2)
MERGE (m1)-[:DISCUSSES]->(t2)
MERGE (m2)-[:DISCUSSES]->(t2)
MERGE (m4)-[:DISCUSSES]->(t2)
MERGE (m5)-[:DISCUSSES]->(t2)
MERGE (m1)-[:MENTIONS]->(e1)
MERGE (m2)-[:MENTIONS]->(e1)
MERGE (m2)-[:MENTIONS]->(e4)
MERGE (m4)-[:MENTIONS]->(e1)
MERGE (m4)-[:MENTIONS]->(e4)
MERGE (m5)-[:MENTIONS]->(e1)
MERGE (m5)-[:MENTIONS]->(e2);

// Create temporal links between messages
MERGE (m1)-[:NEXT]->(m2)
MERGE (m2)-[:NEXT]->(m3)
MERGE (m3)-[:NEXT]->(m4)
MERGE (m4)-[:NEXT]->(m5);

// Create semantic similarity (simulate)
MERGE (m1)-[:SEMANTICALLY_SIMILAR {score: 0.85}]->(m5);

// ============================================
// VERIFICATION
// ============================================

// Count all nodes
MATCH (n) RETURN labels(n) as Label, count(*) as Count;

// Show conversation flow
MATCH path = (u:User)-[:SENT]->(m:Message)-[:NEXT*0..5]->(next:Message)
WHERE m.id = 'msg-001'
RETURN path;

// Show topic relationships
MATCH path = (t1:Topic)-[:RELATES_TO|SUBTOPIC_OF*1..2]-(t2:Topic)
RETURN path;
