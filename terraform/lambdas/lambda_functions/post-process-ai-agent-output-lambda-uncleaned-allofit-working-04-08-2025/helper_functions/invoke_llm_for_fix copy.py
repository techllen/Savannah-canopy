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
try:
    bedrock_runtime = boto3.client(service_name='bedrock-runtime') 
    model_id = os.environ['BEDROCK_MODEL_ID']
except Exception as e:
    logger.error(f"Failed to initialize Bedrock client or load environment variable: {e}")
    raise e

def get_fix(full_error_context, code_details): 
    try:
        logger.info("Creating AI prompt...")
        prompt = create_ai_prompt(full_error_context, code_details)
        logger.debug(f"Generated prompt: {prompt[:20]}...") 

        payload = { 
            "prompt": f"<s>[INST] {prompt} [/INST]", 
            "max_tokens": 4096, 
            "temperature": 0.3 
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

        if 'outputs' not in response_body or not response_body['outputs']:
            raise ValueError("No outputs received from AI model.")

        ai_raw_output = response_body['outputs'][0].get('text', '')

        if not ai_raw_output:
            logger.warning("AI model response did not contain text.")
            return "AI model did not return any text."

        logger.info(f"Successfully received AI response")
        return ai_raw_output

    except Exception as e:
        logger.error(f"Error in get_fix function: {e}", exc_info=True)
        return f"Error invoking AI agent: {str(e)}"