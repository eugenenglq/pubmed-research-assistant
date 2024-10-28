import os
import boto3

def lambda_handler(event, context):
    print(event)

    client = boto3.client('ecs')
    cluster_arn = os.environ['CLUSTER_ARN']
    task_definition_arn = os.environ['TASK_DEFINITION_ARN']
    search_terms = event.get('searchTerm', '')  # Assuming searchTerm is passed in the event

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

    # Process the response as needed
    return {
        'statusCode': 200,
        'body': f"Task started: {response['tasks'][0]['taskArn']}"
    }