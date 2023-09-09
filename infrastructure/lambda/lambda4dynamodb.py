import json
import boto3
dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table('resume-count-table')
def lambda_handler(event, context):
    response = table.get_item(Key={
        'ID':'0'
    })
    views = response['Item']['visit_count']
    views = views + 1
    print(views)
    response = table.put_item(Item={
            'ID':'0',
            'visit_count': views
    })

    return views