# lambda function integrated with an AI agent 
import json 
import boto3 
import base64 
import os 
import gzip
from helper_functions.create_prompt import create_ai_prompt

import logging

# Configure logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

bedrock_runtime = boto3.client(service_name='bedrock-runtime') 

model_id = os.environ['BEDROCK_MODEL_ID'] #
# model_id = 'anthropic.claude-3-sonnet-20240229-v1:0'
# model_id = 'mistral.mistral-7b-instruct-v0:2'

"""Invokes the Bedrock model and parses the JSON response."""
def get_fix(full_error_context , code_details): 
    prompt = create_ai_prompt(full_error_context, code_details)

    payload = { 
        "prompt": f"<s>[INST] {prompt} [/INST]", 
        "max_tokens": 4096, 
        "temperature": 0.3 
    } 

    response = bedrock_runtime.invoke_model( 
        modelId=model_id, 
        accept='application/json', 
        contentType='application/json', 
        body=json.dumps(payload), 
    ) 

    response_body = json.loads(response['body'].read()) 

    ai_raw_output = response_body['outputs'][0]['text'] 

    # logging.info(f"Bedrock response: {ai_raw_output}") 

    # AI agent's output. 
    return ai_raw_output
    # return { 
    #     'statusCode': 200, 
    #     'body': json.dumps({'Fix': ai_raw_output}) 
    # } 