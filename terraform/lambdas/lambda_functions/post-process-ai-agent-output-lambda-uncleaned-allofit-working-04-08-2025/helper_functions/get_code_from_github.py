import json
import boto3
import base64
import os
import requests
import logging

# Configure logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

# Initialize AWS SDK clients
bedrock_runtime = boto3.client(service_name='bedrock-runtime')

# Fetch model ID from environment variables
# model_id = os.environ['BEDROCK_MODEL_ID']

def get_code_details(file_name):
    generated_text = ""

    try:
        # Parse input from event (assumes the event contains 'filename')
        if not file_name:
            raise ValueError("Missing 'filename' in input")

        # --- GitHub setup ---
        github_token = os.environ['GITHUB_TOKEN']
        repo_owner = os.environ['GITHUB_REPO_OWNER']
        repo_name = os.environ['GITHUB_REPO_NAME']
        branch = os.environ.get('GITHUB_BRANCH', 'main')

        headers = {'Authorization': f'token {github_token}'}

        # Step 1: Get repo tree
        tree_url = f'https://api.github.com/repos/{repo_owner}/{repo_name}/git/trees/{branch}?recursive=1'
        tree_response = requests.get(tree_url, headers=headers)
        tree_response.raise_for_status()
        tree_data = tree_response.json()

        # Step 2: Match only based on file name
        matching_files = [
            item['path'] for item in tree_data['tree']
            if item['type'] == 'blob' and item['path'].endswith(file_name)
        ]
        if not matching_files:
            raise FileNotFoundError(f"No file named '{file_name}' found in the repository.")

        file_path = matching_files[0]
        logging.info(f"Matched path: {file_path}")

        # Step 3: Get file content
        file_url = f'https://api.github.com/repos/{repo_owner}/{repo_name}/contents/{file_path}?ref={branch}'
        file_response = requests.get(file_url, headers=headers)
        file_response.raise_for_status()
        file_data = file_response.json()

        file_content_base64 = file_data.get('content', '')
        decoded_content = base64.b64decode(file_content_base64).decode('utf-8')
        # logging.info(f"Retrieved code content:\n{decoded_content}")

    except Exception as e:
        logging.error(f"Error while retrieving code: {e}")
        return {'statusCode': 500, 'body': json.dumps({'error': str(e)})}

    return {
        'statusCode': 200,
        'body': json.dumps({
            'filename': file_name,
            'filepath': file_path,
            'code': decoded_content
            })
    }