import json
import boto3
import base64
import os
import requests
import logging

# Configure logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

def get_code_details(file_name):
    try:
        # Parse input from event 
        if not file_name:
            logger.warning("Input 'file_name' is missing or empty.")
            raise ValueError("Missing 'filename' in input")

        # GitHub setup
        logger.info("Retrieving GitHub configuration from environment variables.")
        github_token = os.environ['GITHUB_TOKEN']
        repo_owner = os.environ['GITHUB_REPO_OWNER']
        repo_name = os.environ['GITHUB_REPO_NAME']
        branch = os.environ.get('GITHUB_BRANCH', 'feature/backend')

        headers = {'Authorization': f'token {github_token}'}

        # Step 1: Get repo tree
        tree_url = f'https://api.github.com/repos/{repo_owner}/{repo_name}/git/trees/{branch}?recursive=1'
        tree_response = requests.get(tree_url, headers=headers)
        tree_response.raise_for_status()
        tree_data = tree_response.json()
        logger.info("Successfully retrieved and parsed repository tree data.")

        # Step 2: Match only based on file name
        matching_files = [
            item['path'] for item in tree_data['tree']
            if item['type'] == 'blob' and item['path'].endswith(file_name)
        ]
        if not matching_files:
            logger.warning(f"No file ending with '{file_name}' found in branch '{branch}'.")
            raise FileNotFoundError(f"No file named '{file_name}' found in the repository.")

        file_path = matching_files[0]
        logging.info(f"Found matching file path: {file_path}")

        # Step 3: Get file content
        file_url = f'https://api.github.com/repos/{repo_owner}/{repo_name}/contents/{file_path}?ref={branch}'
        file_response = requests.get(file_url, headers=headers)
        file_response.raise_for_status()
        file_data = file_response.json()
        logger.info(f"Successfully retrieved file data for path: {file_path}")

        file_content_base64 = file_data.get('content', '')
        if not file_content_base64:
            logger.warning(f"No content found for file: {file_path}")
            raise ValueError(f"No content found for file: {file_path}")
        decoded_content = base64.b64decode(file_content_base64).decode('utf-8')
        # logging.info(f"Retrieved code content:\n{decoded_content}")
        logging.info(f"Successfully retrieved code content")

    except requests.exceptions.HTTPError as http_err:
        # Specific logging for HTTP errors from GitHub API
        logger.error(f"GitHub API HTTP Error occurred: {http_err} - Response Status: {http_err.response.status_code} - Response Text: {http_err.response.text}")
        return {
            'statusCode': http_err.response.status_code, # Return GitHub's status code if possible
            'body': json.dumps({'error': f'GitHub API Error: {str(http_err)}', 'details': http_err.response.text})
            }
    except KeyError as key_err:
         # Catch missing environment variables specifically
        logger.error(f"Configuration Error: Missing environment variable: {key_err}")
        return {
            'statusCode': 500, 
            'body': json.dumps({'error': f'Configuration Error: Missing environment variable {key_err}'})
            }
    except Exception as e:
        # General exception logging
        logger.exception(f"An unexpected error occurred while retrieving code for {file_name}: {e}") 
        return {
            'statusCode': 500, 
            'body': json.dumps({'error': f'An unexpected error occurred: {str(e)}'})
            }

    logger.info(f"Successfully processed file: {file_name}. Returning details.")
    return {
        'statusCode': 200,
        'body': json.dumps({
            'filename': file_name,
            'filepath': file_path,
            'code': decoded_content
            })
    }