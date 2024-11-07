import os
import boto3

def lambda_handler(event, context):
    print(event)
    
    # Check if there are any records in the event
    if not event.get('Records'):
        return {
            'statusCode': 200,
            'body': 'No records to process'
        }

    # Process only new INSERT events from DynamoDB Streams
    new_items = [record for record in event['Records'] 
                 if record['eventName'] == 'INSERT' and 
                 record['eventSource'] == 'aws:dynamodb']

    if not new_items:
        return {
            'statusCode': 200,
            'body': 'No new items inserted'
        }

    client = boto3.client('ecs')
    cluster_arn = os.environ['CLUSTER_ARN']
    task_definition_arn = os.environ['TASK_DEFINITION_ARN']

    # Process each new item
    for item in new_items:
        # Extract the search term from the new DynamoDB item
        # Adjust this based on your DynamoDB item structure
        search_terms = item['dynamodb']['NewImage'].get('searchTerm', {}).get('S', '')

        response = client.run_task(
            cluster=cluster_arn,
            taskDefinition=task_definition_arn,
            overrides={
                'containerOverrides': [
                    {
                        'name': 'ingest',
                        'environment': [
                            {
                                'name': 'SEARCH_TERMS',
                                'value': search_terms
                            }
                        ]
                    }
                ]
            },
            launchType='FARGATE',
            networkConfiguration={
                'awsvpcConfiguration': {
                    'subnets': [os.environ['SUBNET_ID']],
                    'securityGroups': [os.environ['SECURITY_GROUP_ID']],
                    'assignPublicIp': 'DISABLED'
                }
            }
        )

        print(f"Started task for search term: {search_terms}")

    return {
        'statusCode': 200,
        'body': f"Processed {len(new_items)} new items"
    }
