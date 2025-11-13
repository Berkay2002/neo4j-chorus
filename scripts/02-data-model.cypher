// ============================================
// Chorus Knowledge Graph - Node & Relationship Models
// ============================================
// This defines the graph data model for Chorus

// ============================================
// NODE TYPES
// ============================================

// USER NODE
// Represents a human user or AI in the system
(:User {
  id: String,           // UUID from Supabase
  username: String,
  displayName: String,
  createdAt: DateTime,
  isAI: Boolean         // true for AI users
})

// MESSAGE NODE
// Individual chat message
(:Message {
  id: String,           // UUID from Supabase
  content: String,
  timestamp: DateTime,
  isAI: Boolean,        // true if sent by AI
  embedding: [Float],   // Optional: store embedding for graph-based similarity
  channelId: String     // Reference to Supabase channel
})

// TOPIC NODE
// Extracted topic/theme from conversations
(:Topic {
  id: String,
  name: String,         // e.g., "Architecture", "React", "Deployment"
  category: String,     // e.g., "Technical", "Social", "Planning"
  firstMentioned: DateTime,
  lastMentioned: DateTime,
  mentionCount: Integer
})

// ENTITY NODE
// Named entities extracted from messages
(:Entity {
  id: String,
  name: String,         // e.g., "Next.js", "Vercel", "PostgreSQL"
  type: String,         // "Technology", "Person", "Concept", "Product"
  description: String,
  createdAt: DateTime
})

// DECISION NODE
// Important decisions made by the group
(:Decision {
  id: String,
  title: String,
  description: String,
  status: String,       // "Proposed", "Accepted", "Rejected", "Implemented"
  madeAt: DateTime,
  implementedAt: DateTime
})

// CHANNEL NODE
// Chat channel (lightweight, main data in Supabase)
(:Channel {
  id: String,           // UUID from Supabase
  name: String,
  createdAt: DateTime
})

// SERVER NODE
// Server/community (lightweight, main data in Supabase)
(:Server {
  id: String,           // UUID from Supabase
  name: String,
  createdAt: DateTime
})

// ============================================
// RELATIONSHIP TYPES
// ============================================

// User relationships
(:User)-[:SENT]->(:Message)              // User authored a message
(:User)-[:MENTIONED_IN]->(:Message)      // User was @mentioned in message
(:User)-[:MEMBER_OF]->(:Server)          // User is member of server
(:User)-[:PARTICIPATED_IN]->(:Topic)     // User contributed to topic discussion

// Message relationships
(:Message)-[:IN_CHANNEL]->(:Channel)     // Message belongs to channel
(:Message)-[:REPLIES_TO]->(:Message)     // Message is a reply (future: threads)
(:Message)-[:MENTIONS]->(:Entity)        // Message mentions an entity
(:Message)-[:DISCUSSES]->(:Topic)        // Message discusses a topic
(:Message)-[:REFERENCES]->(:Decision)    // Message references a decision
(:Message)-[:NEXT]->(:Message)           // Temporal link to next message (for context)
(:Message)-[:SEMANTICALLY_SIMILAR {      // Semantic similarity link
  score: Float                           // Similarity score (0.0-1.0)
}]->(:Message)

// Topic relationships
(:Topic)-[:RELATES_TO]->(:Topic)         // Topics are related
(:Topic)-[:SUBTOPIC_OF]->(:Topic)        // Hierarchical topic structure
(:Topic)-[:EVOLVED_INTO]->(:Topic)       // Topic evolution over time

// Entity relationships
(:Entity)-[:RELATED_TO]->(:Entity)       // Entities are related
(:Entity)-[:MENTIONED_WITH]->(:Entity)   // Entities co-occur in messages
(:Entity)-[:ALTERNATIVE_TO]->(:Entity)   // Alternative options discussed

// Decision relationships
(:Decision)-[:MADE_BY]->(:User)          // Who made the decision
(:Decision)-[:ABOUT]->(:Topic)           // What the decision is about
(:Decision)-[:INVOLVES]->(:Entity)       // What entities are involved
(:Decision)-[:SUPERSEDES]->(:Decision)   // Newer decision replaces old one

// Server/Channel relationships
(:Server)-[:HAS_CHANNEL]->(:Channel)     // Server contains channels
(:Channel)-[:FOCUSES_ON]->(:Topic)       // Channel's primary topics

// ============================================
// EXAMPLE QUERIES
// ============================================

// 1. Find all messages discussing a specific topic
// MATCH (t:Topic {name: "Architecture"})<-[:DISCUSSES]-(m:Message)
// RETURN m ORDER BY m.timestamp DESC;

// 2. Find related topics for context expansion
// MATCH (t1:Topic {name: "React"})-[:RELATES_TO*1..2]-(t2:Topic)
// RETURN DISTINCT t2.name, count(*) as strength
// ORDER BY strength DESC;

// 3. Find decisions involving a specific technology
// MATCH (e:Entity {name: "Supabase"})<-[:INVOLVES]-(d:Decision)
// WHERE d.status = "Accepted"
// RETURN d;

// 4. Get conversation context for a message
// MATCH (m:Message {id: $messageId})-[:NEXT*0..10]->(context:Message)
// RETURN context ORDER BY context.timestamp;

// 5. Find semantically similar past discussions
// MATCH (m:Message {id: $messageId})-[sim:SEMANTICALLY_SIMILAR]->(similar:Message)
// WHERE sim.score > 0.7
// RETURN similar, sim.score ORDER BY sim.score DESC LIMIT 5;

// 6. Get user expertise (topics they've discussed most)
// MATCH (u:User {id: $userId})-[:SENT]->(m:Message)-[:DISCUSSES]->(t:Topic)
// RETURN t.name, count(*) as mentions
// ORDER BY mentions DESC LIMIT 10;

// 7. Find alternative solutions discussed
// MATCH (e1:Entity {name: "PostgreSQL"})-[:ALTERNATIVE_TO]-(e2:Entity)
// RETURN e2.name;

// 8. Get decision timeline for a topic
// MATCH (t:Topic {name: "Database"})<-[:ABOUT]-(d:Decision)
// RETURN d.title, d.status, d.madeAt
// ORDER BY d.madeAt DESC;
