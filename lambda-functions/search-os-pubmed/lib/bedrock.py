import boto3
from langchain_aws import BedrockEmbeddings, ChatBedrock

def get_bedrock_client(region):
    bedrock_client = boto3.client("bedrock-runtime", region_name=region)
    return bedrock_client

def create_bedrock_llm(bedrock_client, model_version_id):
    bedrock_llm = ChatBedrock(model_id=model_version_id, client=bedrock_client, model_kwargs={'temperature': 0})
    return bedrock_llm
    
def create_langchain_vector_embedding_using_bedrock(bedrock_client, bedrock_embedding_model_id):
    bedrock_embeddings_client = BedrockEmbeddings(client=bedrock_client,model_id=bedrock_embedding_model_id)
    return bedrock_embeddings_client
    