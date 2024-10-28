# Pubmed Research Assistant

## Authors:
Eugene Ng

# Introduction
One of the pain points from researchers for their work is the amount of time spent on PubMed to research on the their topic. After reading through abstracts, researcher will pick the most relevant article to read through the actual paper itself. 
This solution allow users to do:
1. Ask questions on the curated Pubmed articles
2. List down relevant PubMed articles with the corresponding PMCID
3. Search and summarize Pubmed article by passing PMCID

# Architecture

<!-- ![architecture](/architecture-for-workflow-dependencies-pipeline.png) -->

## Deployment

> [!Pre-requisites]
   JQ
   For macOS
   brew install jq

   For Ubuntu/Debian
   sudo apt-get install jq


To deploy, run deploy.sh file for first time deployment.
For subsequent deployments, run "terraform apply -auto-approve" from the 'infra' folder.

