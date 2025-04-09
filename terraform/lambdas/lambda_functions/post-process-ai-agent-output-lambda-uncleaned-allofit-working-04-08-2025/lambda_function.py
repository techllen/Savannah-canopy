# lambda function integrated with an AI agent
import json
import boto3
import base64
import os
import gzip
import requests
import logging
from helper_functions.process_cloud_watch_events import process_cloud_watch_events
from helper_functions.get_code_from_github import get_code_details
from helper_functions.invoke_llm_for_fix import get_fix
from helper_functions.raise_pull_request import raise_PR

# Configure logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

def lambda_handler(event, context):

    # 1. Retrieve full error context
    full_error_context = process_cloud_watch_events(event)
    error_context_body = json.loads(full_error_context['body'])
    file_name = error_context_body.get('file_name')

    # 2. Retrieve code details (code , file path and name)
    code_details = get_code_details(file_name)
    code_details_body = json.loads(code_details['body'])
    file_path = code_details_body.get('filepath')

    # 3.Calling LLM for FIX
    code_fix = get_fix(full_error_context , code_details)
    # code_fix_dict = json.loads(code_fix)
    # logger.info(f"Retrieved code fix: {code_fix_dict.get('source_code')}")

    # 4.Raise a pull request to fix the issue
    raise_PR(code_fix , file_path)

    return {
        'statusCode': 200,
        # 'body': json.dumps({'Retreived': code_fix})
    }