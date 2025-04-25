# Lambda function orchestrator for AI Agent
import json
import boto3
import base64
import os
import gzip
import logging
from helper_functions.process_cloud_watch_events import process_cloud_watch_events
from helper_functions.get_code_from_github import get_code_details
from helper_functions.invoke_llm_for_fix import get_fix
from helper_functions.raise_pull_request import raise_PR

# Configure logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

def lambda_handler(event, context):
    try:

        # 1. Retrieve full error context and file name
        logger.info(f"STEP 1: Retrieving full error context and file name")
        full_error_context = process_cloud_watch_events(event)
        # logger.info(f"full error context retreived: {full_error_context}")
        error_context_body = json.loads(full_error_context['body'])
        file_name = error_context_body.get('file_name')

        # 2. Retrieve code details (code and file path)
        logger.info(f"STEP 2: Retrieving code details")
        code_details = get_code_details(file_name)
        # logger.info(f"code details retreived: {code_details}")
        code_details_body = json.loads(code_details['body'])
        file_path = code_details_body.get('filepath')

        # 3.Calling LLM for FIX by providing error context and details of the code
        logger.info(f"STEP 3: Retrieving code fix")
        code_fix_and_status = get_fix(full_error_context , code_details)
        code_fix_details = json.loads(code_fix_and_status['body'])
        # logger.info(f"code fix retreived: {code_fix_details}")

        # 4.Raise a pull request to fix the issue by providing code fix and path to the file
        logger.info(f"STEP 4: Raising a pull request to fix the issue")
        final_status = raise_PR(code_fix_details , file_path)
        logger.info(f"Lambda function executed successfully, final status: {final_status}")
        
    except Exception as e:
        return {
            'statusCode': 500,
            'body': json.dumps({'error': f'Error occored in the Main Lambda Function , {e}'})
         }
    return {
        'statusCode': 200,
        'body': json.dumps({'message': 'Lambda function executed successfully' })
    } 