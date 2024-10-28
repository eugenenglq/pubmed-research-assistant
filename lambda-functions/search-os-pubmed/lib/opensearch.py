import boto3
from requests_aws4auth import AWS4Auth
from opensearchpy import OpenSearch, RequestsHttpConnection
from opensearchpy.helpers import bulk
from langchain_community.vectorstores import OpenSearchVectorSearch
import time

region = 'us-east-1'

def get_opensearch_cluster_client(host):
    credentials = boto3.Session().get_credentials()
    awsauth = AWS4Auth(credentials.access_key, credentials.secret_key,
                       region, 'aoss', session_token=credentials.token)

    opensearch_client = OpenSearch(
        hosts=[{'host': host, 'port': 443}],
        http_auth=awsauth,
        use_ssl=True,
        verify_certs=True,
        connection_class=RequestsHttpConnection,
        timeout=300
    )
    return opensearch_client


def waitForCollectionCreation(client, collection_name):
    """Waits for the collection to become active"""
    response = client.batch_get_collection(
        names=[collection_name])
    # Periodically check collection status
    while (response['collectionDetails'][0]['status']) == 'CREATING':
        print('Creating collection...')
        time.sleep(30)
        response = client.batch_get_collection(
            names=[collection_name])
    print('\nCollection successfully created:')
    print(response["collectionDetails"])
    # Extract the collection endpoint from the response
    host = (response['collectionDetails'][0]['collectionEndpoint'])
    final_host = host.replace("https://", "")
    return final_host


def createIndex(client, index_name):
    settings = {
        "settings": {
            "index": {
                "knn": True,
                # "knn.space_type": "cosinesimil"
                }
            }
        }
    response = client.indices.create(index=index_name, body=settings)
    return response

def createIndexMapping(client, index_name):
    response = client.indices.put_mapping(
        index=index_name,
        body={
            "properties": {
                "vector_field": {
                    "type": "knn_vector",
                    "dimension": 1024
                },
                "pmid": { "type": "keyword" },
                "title": { "type": "text" },
                "pubDate": { "type": "date" },
                "text": { "type": "text" },
                "authors": { "type": "keyword" },
                "keywords": { "type": "keyword" },
                "articleIdList": { "type": "text" }
            }
        }
    )
    return bool(response['acknowledged'])
    
def indexData(client, index_name, doc):
    # Add a document to the index.
    response = client.index(
        index=index_name,
        body=doc
    )
    print('\nDocument added:')
    print(response)
    return response


def put_bulk_in_opensearch(list, client):
    success, failed = bulk(client, list)
    return success, failed

def create_opensearch_vector_search_client(index_name, bedrock_embeddings_client, opensearch_endpoint, _is_aoss=False):
    credentials = boto3.Session().get_credentials()
    awsauth = AWS4Auth(credentials.access_key, credentials.secret_key, region, 'aoss', session_token=credentials.token)
    docsearch = OpenSearchVectorSearch(
        index_name=index_name,
        embedding_function=bedrock_embeddings_client,
        opensearch_url=f"https://{opensearch_endpoint}",
        use_ssl=True,
        verify_certs=True,
        connection_class=RequestsHttpConnection,
        http_auth=awsauth,
        is_aoss=_is_aoss
    )
    return docsearch
    
def check_opensearch_index(client, index_name):
    return client.indices.exists(index=index_name)