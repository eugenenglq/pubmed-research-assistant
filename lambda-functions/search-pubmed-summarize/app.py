import os
import json
import boto3
import requests
from xml.etree import ElementTree as ET

region = os.environ['AWS_REGION']
model = os.environ['MODEL_ID']
bedrock_client = boto3.client(service_name='bedrock-runtime')

def lambda_handler(event, context):
    print(event)
    action_group = event['actionGroup']
    api_path = event['apiPath']
    pmc_id = event.get('pmc_id')
    extra_prompt = event.get('extra_prompt', '')
    inputText = event.get('inputText', '')
    if not pmc_id:
        properties = event.get('requestBody', {}).get('content', {}).get('application/json', {}).get('properties', [])
        for prop in properties:
            if prop.get('name') == 'pmc_id':
                pmc_id = prop.get('value')
                pmc_id = pmc_id.replace('PMC', '')
            if prop.get('name') == 'extra_prompt':
                extra_prompt = prop.get('value')

    print('pmc_id', pmc_id)
    print('extra_prompt', extra_prompt)

    # Make request to NCBI E-utilities
    url = f"https://eutils.ncbi.nlm.nih.gov/entrez/eutils/efetch.fcgi?db=pmc&id={pmc_id}"
    
    print(url)
    response = requests.get(url)
    if response.status_code != 200:
        return {
            'statusCode': response.status_code,
            'body': json.dumps('Failed to fetch data from NCBI')
        }

    # Parse XML and extract body
    root = ET.fromstring(response.text)
    body_element = root.find(".//body")
    if body_element is None:
        return {
            'statusCode': 404,
            'body': json.dumps('No body content found in the XML')
        }

    body_text = ET.tostring(body_element, encoding='unicode', method='text')

    contributors_list = []
    contributors_text = ''
    # Find all contributor elements
    contributors = root.findall(".//contrib")

    # Loop through each contributor and extract surname and given names
    for contrib in contributors:
        # Get the surname and given-names elements
        name = contrib.find("name")
        if name is not None:
            surname = name.find("surname").text if name.find("surname") is not None else "No surname"
            given_names = name.find("given-names").text if name.find("given-names") is not None else "No given names"
            
            # Print the extracted information
            contributors_list.append(surname + given_names)
    contributors_text += ', '.join(contributors_list)
    
    # Summarize using Bedrock
    bedrock_runtime = boto3.client('bedrock-runtime', region_name=region)
    
    prompt = f"""<article>{body_text}</article>
    <authors>{contributors_text}</authors>
    The article in <article> tag and the authors list is in <authors> tag for the PMCID: {pmc_id}.
    {inputText}"""
    prompt_template = f"""Summarize the following scientific article:

    Provide a concise summary that captures the authors, main points, methods, results, and conclusions of the article. 
    {extra_prompt}
    The summary should be no more than 500 words and need to break down into titles. Do not need to tell me total how many words."""

    print('Final prompt: ', prompt_template)


    # body = json.dumps({
    #     "anthropic_version": "bedrock-2023-05-31",
    #     "max_tokens": 4096,
    #     "messages": [
    #         {
    #             "role": "user",
    #             "content": prompt
    #         }
    #     ]
    # })

    try:
        response = bedrock_client.converse(
            modelId=model,
            messages=[
                {
                    "role": "user",
                    "content": [{"text": prompt }]
                }
            ],
            # system=system_prompts,
            inferenceConfig={"maxTokens": 4096}
        )
            
        # response = bedrock_runtime.invoke_model(
        #     modelId="anthropic.claude-3-sonnet-20240229-v1:0",
        #     body=body
        # )
        # br_response = json.loads(response.get('body').read())
        # summary = br_response['content'][0]['text']
        summary = response['output']['message']
        
        response_body = {
                    'application/json': {
                        'body': json.dumps({'answer': summary})
                    }
                }
        
        action_response = {
            "messageVersion": "1.0",
            "response": {
                'actionGroup': action_group,
                'apiPath': api_path,
                'httpMethod': event.get('httpMethod'),
                'httpStatusCode': 200,
                'responseBody': response_body
            }
        }
        
        return action_response
    except Exception as e:
        print(str(e))
        return {
            'statusCode': 500,
            'body': json.dumps(f'Error in Bedrock processing: {str(e)}')
        }
