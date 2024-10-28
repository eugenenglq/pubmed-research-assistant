data "aws_caller_identity" "current" {}

provider "aws" {
  region = "us-east-1"  # Replace with your desired region
}

resource "aws_opensearchserverless_security_policy" "security_policy" {
  name = "${var.project_name}-encryption-policy"
  type = "encryption"

  policy = jsonencode({
    Rules = [
      {
        ResourceType = "collection"
        Resource = [
          "collection/${var.project_name}-pubmed-collection"
        ]
      }
    ]
    AWSOwnedKey = true
  })
}

resource "aws_opensearchserverless_security_policy" "network_policy" {
  name = "${var.project_name}-network-policy"
  type = "network"

  policy = jsonencode([
    {
      Rules = [
        {
          ResourceType = "collection"
          Resource     = ["collection/${var.project_name}-pubmed-collection"]
        }
      ],
      AllowFromPublic = true,
      # SourceVPCEs = [
      #   var.aws_opensearchserverless_vpc_endpoint
      # ]
    }
  ])
}

resource "aws_opensearchserverless_access_policy" "access_policy" {
  name = "${var.project_name}-access-policy"
  type = "data"

  policy = jsonencode([
    {Rules = [
      {
        ResourceType = "collection"
        Resource = [
          "collection/${var.project_name}-*"
        ]
        Permission = [
          "aoss:CreateCollectionItems",
          "aoss:DeleteCollectionItems",
          "aoss:UpdateCollectionItems",
          "aoss:DescribeCollectionItems"
        ]
      }
    ]
    Principal = var.opensearch_granted_iam_role_arns
    },
    {Rules = [
      {
        ResourceType = "index"
        Resource = [
          "index/${var.project_name}-*/*"
        ]
        Permission = [
          "aoss:CreateIndex",
          "aoss:DeleteIndex",
          "aoss:UpdateIndex",
          "aoss:DescribeIndex",
          "aoss:ReadDocument",
          "aoss:WriteDocument",
        ]
      }
    ]
    Principal = var.opensearch_granted_iam_role_arns}
  ])
}


resource "aws_opensearchserverless_collection" "pubmed" {
  name = "${var.project_name}-pubmed-collection"
  type = "VECTORSEARCH"
  depends_on = [
    aws_opensearchserverless_security_policy.security_policy,
    aws_opensearchserverless_security_policy.network_policy,
    aws_opensearchserverless_access_policy.access_policy
  ]
}
