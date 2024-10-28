resource "aws_bedrockagent_agent" "pubmed_agent" {
  agent_name = "${var.project_name}-pubmed-agent"
  description = "Bedrock agent for pubmed research"

  agent_resource_role_arn = aws_iam_role.bedrock_agent_role.arn

  instruction = "You are a research assistant specialize in genomics, but currently you are only able to answer if the user ask about these genomic codes. You have access to API that allow you to search and summarize a list of pubmed articles, the list will have abstract of the articles. So, if the user ask about the genomic information, you are able to perform search and summarization. You have access to API to list down in a list that will list down the consists of columns - PMID, Title, PMCID, DOI, PII, Authors, PubDate. So if the user just want to find out the list of pubmed articles, you will list down in a list that consists of PMID, Title, PMCID. You have access to pubmed API to summarize the full article. If the user ask to summarize the full article, ask for the PMCID in order for you to pass to the API to summarize the full article."

  foundation_model = var.model_id  # Use the appropriate model ID
  
}

resource "aws_bedrockagent_agent_action_group" "search_pubmed_from_opensearch" {
  agent_id = aws_bedrockagent_agent.pubmed_agent.id
#   agent_version = aws_bedrockagent_agent.pubmed_agent.agent_version
  agent_version = "DRAFT"
  action_group_name = "search_pubmed_from_opensearch"
  description = "Trigger this action group if the user ask about genes. This action will not be performing API call to PubMed but only internal OpenSearch."
  skip_resource_in_use_check = true
  action_group_executor {
    lambda = var.search_os_pubmed_lambda_function_arn
  }
  prepare_agent = false

  action_group_state = "ENABLED"

  api_schema {
    payload = file("${path.module}/search_pubmed_from_opensearch_schema.yaml")
  }
}

resource "aws_bedrockagent_agent_action_group" "search_and_summarize_pubmed_full_article" {
  agent_id = aws_bedrockagent_agent.pubmed_agent.id
#   agent_version = aws_bedrockagent_agent.pubmed_agent.agent_version
  agent_version = "DRAFT"
  action_group_name = "search_and_summarize_pubmed_full_article"
  description = "This API allow user to search PubMed directly and summarize the full article. The user would need to provide the PMCID."
  skip_resource_in_use_check = true
  prepare_agent = false
  action_group_executor {
    lambda = var.search_pubmed_summarize_lambda_function_arn
  }

  action_group_state = "ENABLED"

  api_schema {
    payload = file("${path.module}/search_and_summarize_pubmed_full_article_scheme.yaml")
  }
}

resource "aws_bedrockagent_agent_alias" "pubmed_agent_alias" {
  agent_id = aws_bedrockagent_agent.pubmed_agent.id
  agent_alias_name = "prod"
}

resource "aws_iam_role" "bedrock_agent_role" {
  name = "${var.project_name}-bedrock-agent-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "bedrock.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "bedrock_agent_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonBedrockFullAccess"
  role       = aws_iam_role.bedrock_agent_role.name
}

resource "null_resource" "bedrock_agent_prepare" {
  triggers = {
    search_and_summarize_pubmed_full_article = sha256(jsonencode(aws_bedrockagent_agent_action_group.search_and_summarize_pubmed_full_article))
    search_pubmed_from_opensearch  = sha256(jsonencode(aws_bedrockagent_agent_action_group.search_pubmed_from_opensearch))
  }
  provisioner "local-exec" {
    command = "aws bedrock-agent prepare-agent --agent-id ${aws_bedrockagent_agent.pubmed_agent.id}"
  }
  depends_on = [
    aws_bedrockagent_agent_action_group.search_and_summarize_pubmed_full_article,
    aws_bedrockagent_agent_action_group.search_pubmed_from_opensearch
  ]
}
