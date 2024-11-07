import json
import argparse
import boto3
from loguru import logger
import sys
import os
import lib.bedrock as bedrocklib
import lib.opensearch as opensearchlib
import lib.pubmed as pubmedlib
from datetime import datetime

region = os.getenv('REGION') 
searchTermDD = os.getenv('SEARCH_TERM_DD')
collection_name = os.getenv('COLLECTION_NAME')
index_name = os.getenv('INDEX_NAME')
termList = os.getenv('SEARCH_TERMS')
embedding_model = os.getenv('EMBEDDING_MODEL')

# region = 'us-east-1'
# searchTermDD = 'pubmed-assist-pubmed-search-term'
# collection_name = 'pubmed-assist-pubmed-collection'
# index_name = 'pubmed-genes'
# termList = 'cd14'
# embedding_model = 'amazon.titan-embed-text-v2:0'

bedrock_client = boto3.client("bedrock-runtime", region_name=region)

def main():
    print('Search Term: ', termList)
    opensearch_client = boto3.client('opensearchserverless')
    hostname = opensearchlib.waitForCollectionCreation(opensearch_client, collection_name)
    opensearch_con = opensearchlib.get_opensearch_cluster_client(hostname)
    
    # CREATE INDEX IN OPENSEARCH
    exists = opensearchlib.check_opensearch_index(opensearch_con, index_name)
    if not exists:
        print("Creating OpenSearch index")
        success = opensearchlib.createIndex(opensearch_con, index_name)
        if success:
            print("Creating OpenSearch index mapping")
            success = opensearchlib.createIndexMapping(opensearch_con, index_name)
            print("OpenSearch Index mapping created")


    terms = termList.split(',')

    # Search for pubmed articles
    pubmedSearchResults = pubmedlib.search_pubmed(terms)

    # Retrieve abstracts from search results
    pubmedAbstractResults = pubmedlib.fetch_pubmed_abstracts(pubmedSearchResults['idlist'])

    totalSuccess, totalFailed = loadToVectorStore(opensearch_con,pubmedAbstractResults)

    return {
        'statusCode': 200,
        'body': json.dumps(f'Successfully loaded {totalSuccess} documents, failed to load {totalFailed} documents')
    }

def loadToVectorStore(opensearch_con, pubmedAbstractResults):
    bedrock_embedding = bedrocklib.BedrockEmbedding(bedrock_client, embedding_model_id=embedding_model, index_name=index_name)
    embedding_records = []

    i = 0
    totalSuccess = 0
    totalFailed = 0

    for result in pubmedAbstractResults:
        i += 1
        record_with_embedding = bedrock_embedding.create_vector_embedding(
            result['pmid'],
            result['title'],
            result['abstract'],
            result['pubDate'] if 'pubDate' in result else '',
            result['authors'] if 'authors' in result else '',
            result['keywords'] if 'keywords' in result else '',
            result['pubmed'] if 'pubmed' in result else '',
            result['pmc'] if 'pmc' in result else '',
            result['doi'] if 'doi' in result else '',
            result['pii'] if 'pii' in result else ''
        )
        print(f"Embedding for record {i} created")
        # indexData(opensearch_con, index_name, record_with_embedding)
        # record_with_embedding['_index'] = index_name
        embedding_records.append(record_with_embedding)
        
        # # if i % 500 == 0 or i == len(results)-1:
        if i % 30 == 0 or i == len(pubmedAbstractResults)-1:
            # Bulk put all records to OpenSearch
            success, failed = opensearchlib.put_bulk_in_opensearch(embedding_records, opensearch_con)
            embedding_records = []
            totalSuccess += success
            totalFailed += len(failed)
            print(f"Documents saved {success}, documents failed to save {failed}")

    updateDynamoDBTimestamp(termList)
    return totalSuccess, totalFailed

def updateDynamoDBTimestamp(currentSearchTerm):
    dynamodb = boto3.resource('dynamodb')
    table = dynamodb.Table(searchTermDD)
    
    try:
        response = table.update_item(
            Key={'searchTerm': currentSearchTerm},
            UpdateExpression="SET updatedAt = :time",
            ExpressionAttributeValues={':time': datetime.now().isoformat()},
            ReturnValues="UPDATED_NEW"
        )
        print(f"UpdateItem succeeded: {response}")
        return True
    except Exception as e:
        print(f"Error updating item: {e}")
        return False

if __name__ == "__main__":
    main()