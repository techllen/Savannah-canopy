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

# Initialize Bedrock runtime client
bedrock_runtime = boto3.client(service_name='bedrock-runtime') 
model_id = os.environ['BEDROCK_MODEL_ID']

def get_fix(full_error_context, code_details): 
    try:
        logger.info("Creating AI prompt...")
        prompt = create_ai_prompt(full_error_context, code_details)
        logger.debug(f"Generated prompt: {prompt[:20]}...") 
        
        payload = {} # Initialize empty payload

        ai_raw_output = None

        if model_id == 'mistral.mistral-7b-instruct-v0:2':
            payload = { 
                "prompt": f"<s>[INST] {prompt} [/INST]", 
                "max_tokens": 4096, 
                "temperature": 0.3 
            }

        elif model_id.startswith('anthropic.claude'):
            payload = {
                "anthropic_version": "bedrock-2023-05-31",
                "max_tokens": 1000,
                "messages": [
                {
                    "role": "user",
                    "content": [
                    {
                        "type": "text",
                        "text": f"{prompt}"
                    }
                    ]
                }
                ]
            }

        elif model_id == 'meta.llama3-8b-instruct-v1:0':
            payload = {
                "prompt": f"{prompt}",
                "max_gen_len": 512,
                "temperature": 0.3,
                "top_p": 0.9
            }    

        else:
             logger.error(f"Unsupported model_id configured: {model_id}")
             return {
                'statusCode': 400, # Bad Request due to config
                'body': json.dumps({'error': f"Unsupported model_id configured: {model_id}"})
             }            

        logger.info("Invoking Bedrock model...")
        response = bedrock_runtime.invoke_model( 
            modelId=model_id, 
            accept='application/json', 
            contentType='application/json', 
            body=json.dumps(payload)
        ) 

        logger.info("Reading and parsing model response...")
        response_body = json.loads(response['body'].read())

        logger.info(f"AI response {response_body}")
   
        if model_id.startswith('anthropic.claude'):
            ai_raw_output = response_body['content'][0].get('text', '')
        
        else:
            ai_raw_output = response_body['outputs'][0].get('text', '')

        if not ai_raw_output:
            logger.warning("AI model response did not contain text.")
            return "AI model did not return any text."

        logger.info(f"Successfully received AI response")
        logger.debug(f"AI response: {ai_raw_output[:20]}...")
        # return ai_raw_output
        return {
            'statuscode' : 200,
            'body' : ai_raw_output
        }

    except Exception as e:
        logger.error(f"Error in get_fix function: {e}", exc_info=True)
        return f"Error invoking AI agent: {str(e)}"