# Pubmed Research Assistant

## Authors:
Eugene Ng

# Introduction
Researchers often face challenges when searching for relevant information on PubMed, as it can be time-consuming to sift through numerous abstracts and full-text articles. To address this issue, this solution offers a streamlined approach to exploring and summarizing PubMed articles, empowering researchers to work more efficiently.

Key Features:

1. **Query-based Information Retrieval**: Researchers can ask specific questions related to their topic of interest, and this solution will process the curated PubMed articles to provide relevant answers. This eliminates the need to manually scan through vast amounts of data, saving valuable time and effort.

2. **Curated Article Listing**: This solution can generate a list of relevant PubMed articles, along with their corresponding PubMed Central Identifiers (PMCIDs), based on the researcher's query or topic of interest. This curated list serves as a starting point for further exploration, allowing researchers to quickly identify potentially useful articles.

3. **Article Summarization**: By providing the PMCID of a specific PubMed article, this solution can retrieve and summarize the full-text content of that article. This feature enables researchers to quickly grasp the key points and findings of an article without having to read through the entire document, facilitating efficient decision-making regarding which articles warrant further in-depth examination.

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

