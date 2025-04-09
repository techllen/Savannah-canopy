# lambda function integrated with an AI agent
import json
import boto3
import base64
import os
import gzip
import requests
from helper_functions.process_cloud_watch_events import process_cloud_watch_events
from helper_functions.get_code_from_github import get_code
from helper_functions.invoke_llm_for_fix import get_fix

def lambda_handler(event, context):
    message = process_cloud_watch_events(event)
    body = json.loads(message['body'])
    file_name = body.get('file_name')

    code = get_code(file_name)

    # print(f'message : {code}')
    context = {'body': json.dumps({
        'message': message, 
        'code': code
        })
    }

    fix = get_fix(context)

    return {
        'statusCode': 200,
        'body': json.dumps({'Retreived': fix})
    }