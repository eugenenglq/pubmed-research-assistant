resource "aws_ecr_repository" "web_app" {
  name                 = "${var.project_name}-web-app"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}

resource "aws_ecr_repository" "search_os_pubmed_lambda" {
  name                 = "${var.project_name}-search-opensearch-pubmed-lambda"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}


resource "aws_ecr_repository" "pubmed_ingest_data" {
  name                  = "${var.project_name}-pubmed-ingest-data"
  image_tag_mutability  = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}