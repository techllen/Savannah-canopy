# lambda function integrated with an AI agent 
import json 
import boto3 
import base64 
import os 
import gzip 

bedrock_runtime = boto3.client(service_name='bedrock-runtime') 

# model_id = os.environ['BEDROCK_MODEL_ID'] # get id from env variable 
# model_id = 'anthropic.claude-3-sonnet-20240229-v1:0'
model_id = 'mistral.mistral-7b-instruct-v0:2'

def get_fix(message): 
    # *** AI AGENT INVOCATION *** 
    # The following call sends the error message as a prompt to the Amazon Bedrock model. 
    # # Agentic behavior. 
    # Compiling a prompt 
    prompt = f'As an software engineer Provide a solution and test cases for this error: {message}' 

    payload = { 
        "prompt": f"<s>[INST] {prompt} [/INST]", 
        "max_tokens": 500, 
        "temperature": 0.5 
    } 
    response = bedrock_runtime.invoke_model( 
        modelId=model_id, 
        accept='application/json', 
        contentType='application/json', 
        body=json.dumps(payload), 
    ) 

    response_body = json.loads(response['body'].read()) 
    generated_text = response_body['outputs'][0]['text'] 

    print(f"Bedrock response: {generated_text}") 

    # Return the AI agent's output. 
    return { 
        'statusCode': 200, 
        'body': json.dumps({'fix': generated_text}) 
    } 