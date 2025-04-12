import json
import os
import requests

def lambda_handler(event, context):
    try:
        # Extract environment variables
        github_token = os.environ['GITHUB_TOKEN']
        repo_owner = os.environ['GITHUB_REPO_OWNER']
        repo_name = os.environ['GITHUB_REPO_NAME']
        file_path = os.environ['FILE_PATH']
        line_number = int(os.environ['LINE_NUMBER'])

        # Extract the AI agent's output
        body = json.loads(event['body'])
        generated_text = json.loads(body['generated_text'])

        # Format the output (you can refine this part)
        formatted_text = f"\\n# AI Agent Suggestion:\\n{generated_text}\\n"
        print('generated_text')

        # Get the file content
        headers = {'Authorization': f'token {github_token}'}
        file_url = f'https://api.github.com/repos/{repo_owner}/{repo_name}/contents/{file_path}?ref=main'
        file_response = requests.get(file_url, headers=headers)
        file_response.raise_for_status()
        file_data = file_response.json()
        file_content = file_data['content']
        file_sha = file_data['sha']

        # Decode and modify the file content
        decoded_content = requests.get(file_data['download_url']).text.splitlines()
        decoded_content.insert(line_number - 1, formatted_text)
        updated_content = '\\n'.join(decoded_content).encode('utf-8')
        updated_content_base64 = base64.b64encode(updated_content).decode('utf-8')

        # Commit the changes to a new branch
        branch_name = f'ai-suggestion-{context.aws_request_id}'
        create_branch_url = f'https://api.github.com/repos/{repo_owner}/{repo_name}/git/refs'
        default_branch_sha = requests.get(f'https://api.github.com/repos/{repo_owner}/{repo_name}/git/refs/heads/main', headers=headers).json()['object']['sha']
        requests.post(create_branch_url, headers=headers, json={'ref': f'refs/heads/{branch_name}', 'sha': default_branch_sha}).raise_for_status()

        # Update the file in the new branch
        update_file_url = f'https://api.github.com/repos/{repo_owner}/{repo_name}/contents/{file_path}'
        requests.put(update_file_url, headers=headers, json={'message': 'AI agent suggestion', 'content': updated_content_base64, 'sha': file_sha, 'branch': branch_name}).raise_for_status()

        # Create the pull request
        create_pr_url = f'https://api.github.com/repos/{repo_owner}/{repo_name}/pulls'
        requests.post(create_pr_url, headers=headers, json={'title': 'AI agent suggestion', 'head': branch_name, 'base': 'feature/test'}).raise_for_status()

        return {'statusCode': 200, 'body': json.dumps({'message': 'Pull request created'})}

    except Exception as e:
        print(f"Error: {e}")
        return {'statusCode': 500, 'body': json.dumps({'error': str(e)})}