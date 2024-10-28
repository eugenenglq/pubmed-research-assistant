
output "agent_id" {
  value = aws_bedrockagent_agent.pubmed_agent.id
}

output "agent_alias_id" {
  value = aws_bedrockagent_agent_alias.pubmed_agent_alias.id
}