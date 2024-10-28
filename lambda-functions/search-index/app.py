import json
from langchain_aws import BedrockEmbeddings
from langchain_community.vectorstores import OpenSearchVectorSearch
from langchain_core.output_parsers import StrOutputParser
from langchain_community.chat_models import BedrockChat
from langchain.chains.combine_documents import create_stuff_documents_chain
from langchain.chains import create_retrieval_chain
from langchain_core.prompts import ChatPromptTemplate
from langchain_aws import ChatBedrock
import boto3
import sys
import os
import boto3
from opensearchpy import OpenSearch, RequestsHttpConnection
from opensearchpy.helpers import bulk
import sys
import os
import json
import argparse
import boto3
import sys
import os
from requests_aws4auth import AWS4Auth
region = 'us-east-1'
bedrock_client = boto3.client("bedrock-runtime", region_name=region)

# opensearch_client = boto3.client('opensearchserverless')
service = 'aoss'
region = 'us-east-1'

def get_opensearch_cluster_client(host):
    credentials = boto3.Session().get_credentials()
    awsauth = AWS4Auth(credentials.access_key, credentials.secret_key,
                       region, service, session_token=credentials.token)

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
    print(collection_name)
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


def check_opensearch_index(client, index_name):
    return client.indices.exists(index=index_name)


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


def get_bedrock_client(region):
    bedrock_client = boto3.client("bedrock-runtime", region_name=region)
    return bedrock_client


# Create a custom callback handler to capture the streamed output
class CaptureStreamingHandler(StreamingStdOutCallbackHandler):
    def __init__(self):
        self.full_response = ""

    def on_llm_new_token(self, token: str, **kwargs) -> None:
        self.full_response += token

# Create an instance of the custom handler

def create_bedrock_llm(bedrock_client, model_version_id):
    capture_handler = CaptureStreamingHandler()
    bedrock_llm = ChatBedrock(model_id=model_version_id, client=bedrock_client,
        model_kwargs={"max_tokens": 4096},  # Increase max_tokens if needed
        streaming=True,
        callbacks=[capture_handler])
    return bedrock_llm
    
def create_langchain_vector_embedding_using_bedrock(bedrock_client, bedrock_embedding_model_id):
    bedrock_embeddings_client = BedrockEmbeddings(client=bedrock_client,model_id=bedrock_embedding_model_id)
    return bedrock_embeddings_client
    
def create_opensearch_vector_search_client(index_name, bedrock_embeddings_client, opensearch_endpoint, _is_aoss=False):
    credentials = boto3.Session().get_credentials()
    awsauth = AWS4Auth(credentials.access_key, credentials.secret_key, region, service, session_token=credentials.token)
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
    
    
def lambda_handler(event, context):
    print(event)
    index_name = os.environ['INDEX_NAME']
    region = 'us-east-1'
    bedrock_model_id = os.environ['BEDROCK_MODEL_ID']
    bedrock_embedding_model_id = os.environ['BEDROCK_EMBEDDING_MODEL_ID']

    user_input = event.get('input', '')
    
    if user_input == '':
        user_input = event.get('inputText', '')

    # index_name = 'pubmed-genes'
    # region = 'us-east-1'
    # bedrock_model_id = 'anthropic.claude-3-sonnet-20240229-v1:0'
    # # bedrock_embedding_model_id = 'cohere.embed-english-v3'
    # bedrock_embedding_model_id = 'amazon.titan-embed-text-v2:0'

    opensearch_client = boto3.client('opensearchserverless')
    hostname = waitForCollectionCreation(opensearch_client, 'pubmed')

    bedrock_client = get_bedrock_client(region)


    bedrock_llm = create_bedrock_llm(bedrock_client, bedrock_model_id)
    bedrock_embeddings_client = create_langchain_vector_embedding_using_bedrock(bedrock_client, bedrock_embedding_model_id)
    opensearch_vector_search_client = create_opensearch_vector_search_client(index_name, bedrock_embeddings_client, hostname)

    # Get the input from the event
    osResults = opensearch_vector_search_client.similarity_search("gzmk", k=20)
    osContext = ''
    i = 1
    for res in osResults:
        osContext += 'Result ' + str(i) + '\n'
        
        for key, value in res.metadata.items():
            if key != 'vector_field':
                osContext += f"- {key}: {value}\n"

        osContext += '\n'
        i += 1

    print(osContext)

    # Create a simple LLMChain
    prompt = ChatPromptTemplate.from_template("""Format the results into table that consists of columns - PMID, Title, PMCID, DOI, PII, Authors, PubDate

        If I ask for the abstract of the item, it is the text of the item.
        <results>
            {context}
        </results>

        Answer:""")

        # Create a simple LLMChain
    chain = prompt | bedrock_llm | StrOutputParser()
    response = chain.invoke({
            "context": osContext
        })

    
    response_code = 200
    action_group = event['actionGroup']

    response_body = {
        'application/json': {
            'body': str({'answer': response.get('text')})
        }
    }
    
    action_response = {
        "messageVersion": "1.0",
        "response": {
            'actionGroup': action_group,
            'httpStatusCode': response_code,
            'responseBody': response_body
        }
    }

    print(action_response)
    return action_response