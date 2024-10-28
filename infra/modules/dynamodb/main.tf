resource "aws_dynamodb_table" "pubmed_search_term" {
  name           = "${var.project_name}-pubmed-search-term"
  billing_mode = "PAY_PER_REQUEST"
  hash_key       = "searchTerm"

  attribute {
    name = "searchTerm"
    type = "S"
  }

  stream_enabled   = true
  stream_view_type = "NEW_IMAGE"
}

resource "aws_dynamodb_table" "web_sample_prompts" {
  name            = "${var.project_name}-sample-prompts"
  billing_mode    = "PAY_PER_REQUEST"
  hash_key        = "group"

  attribute {
    name = "group"
    type = "S"
  }
}

locals {
  items = [
    {
      group = "Characteristics of gene"
      samples = [
        "In which types of immune cells is GZMK primarily expressed?",
        "What are the key differences between CD4+ and CD8+ T cells?",
        "What are the potential therapeutic applications targeting GZMK in cancer immunotherapy?"
      ]
    },
    {
      group = "List related PubMed articles"
      samples = [
        "List down articles from PubMed related to GZMK",
        "List down articles from PubMed related to CD4"
      ]
    },
    {
      group = "Summarize full article"
      samples = [
        "Summarize the full article for PMCID 11309442.",
        "Summarize the full article for PMCID 5123456."
      ]
    }
  ]
}

resource "aws_dynamodb_table_item" "web_sample_prompts" {
  for_each = { for idx, item in local.items : idx => item }

  table_name = aws_dynamodb_table.web_sample_prompts.name
  hash_key   = aws_dynamodb_table.web_sample_prompts.hash_key

  item = jsonencode({
    group = { S = each.value.group }
    samples = { L = [for s in each.value.samples : { S = s }] }
  })
}

# Event source mapping to connect DynamoDB stream to Lambda
resource "aws_lambda_event_source_mapping" "pubmed_search_term_mapping" {
  event_source_arn  = aws_dynamodb_table.pubmed_search_term.stream_arn
  function_name     = var.invoke_ingestion_lambda_function_arn
  starting_position = "LATEST"
}