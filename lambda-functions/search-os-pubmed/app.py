import json
import os
import boto3
from langchain.chains.combine_documents import create_stuff_documents_chain
from langchain.chains import create_retrieval_chain
from langchain_core.prompts import ChatPromptTemplate
from langchain_core.output_parsers import StrOutputParser
from opensearchpy import OpenSearch, RequestsHttpConnection
import lib.bedrock as bedrocklib
import lib.opensearch as opensearchlib

region = 'us-east-1'
opensearch_client = boto3.client('opensearchserverless')

def lambda_handler(event, context):
    print(event)
    collection_name = os.environ['COLLECTION_NAME']
    index_name = os.environ['INDEX_NAME']
    bedrock_model_id = os.environ['BEDROCK_MODEL_ID']
    bedrock_embedding_model_id = os.environ['BEDROCK_EMBEDDING_MODEL_ID']
    action_group = event['actionGroup']
    api_path = event['apiPath']

    user_input = event.get('input', '')
    
    if user_input == '':
        user_input = event.get('inputText', '')

    hostname = opensearchlib.waitForCollectionCreation(opensearch_client, collection_name)
    bedrock_client = bedrocklib.get_bedrock_client(region)
    bedrock_llm = bedrocklib.create_bedrock_llm(bedrock_client, bedrock_model_id)
    bedrock_embeddings_client = bedrocklib.create_langchain_vector_embedding_using_bedrock(bedrock_client, bedrock_embedding_model_id)
    opensearch_vector_search_client = opensearchlib.create_opensearch_vector_search_client(index_name, bedrock_embeddings_client, hostname)

    response_body = None

    if event['apiPath'] == '/searchAndSummarize':
        # LangChain prompt template
        prompt = ChatPromptTemplate.from_template("""If the context is not relevant, please answer the question by using your own knowledge about the topic. If you don't know the answer, just say that you don't know, don't try to make up an answer. don't include harmful content

        {context}

        Question: {input}
        Answer:""")

        docs_chain = create_stuff_documents_chain(bedrock_llm, prompt)
        retrieval_chain = create_retrieval_chain(
            retriever=opensearch_vector_search_client.as_retriever(
            search_kwargs={
                "vector_field": "vector_field",
                "text_field": "text",
                "k": 20,
            }
        ),
            combine_docs_chain = docs_chain
        )
        
        response = retrieval_chain.invoke({"input": user_input})

        response_body = {
            'application/json': {
                'body': json.dumps({'answer': response.get('answer')})
            }
        }
    elif event['apiPath'] == '/searchAndListResults':
        # Get the input from the event
        osResults = opensearch_vector_search_client.similarity_search(user_input, k=20)
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
        prompt = ChatPromptTemplate.from_template("""Format the results into table that consists of columns - PMID, Title, PMCID, DOI, PII, PubDate

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
        response_body = {
            'application/json': {
                'body': json.dumps({'answer': response})
            }
        }
    
    action_response = {
        "messageVersion": "1.0",
        "response": {
            'actionGroup': action_group,
            'apiPath': api_path,
            'httpMethod': event['httpMethod'],
            'httpStatusCode': 200,
            'responseBody': response_body
        }
    }

    print(action_response)
    return action_response