def github_api_request(method, url, headers, json_payload=None, expected_status=None):
    """Makes a request to the GitHub API and handles errors."""
    try:
        if method.upper() == 'GET':
            response = requests.get(url, headers=headers, timeout=30)
        elif method.upper() == 'POST':
            response = requests.post(url, headers=headers, json=json_payload, timeout=30)
        elif method.upper() == 'PUT':
            response = requests.put(url, headers=headers, json=json_payload, timeout=30)
        else:
            raise ValueError(f"Unsupported HTTP method: {method}")

        logger.info(f"GitHub API {method} {url} - Status: {response.status_code}")

        # Check if the status code matches *any* of the expected statuses
        if expected_status:
             if isinstance(expected_status, int):
                 expected_status = [expected_status] # Make it a list if single int
             if response.status_code not in expected_status:
                  logger.error(f"GitHub API Error: Expected status {expected_status}, got {response.status_code}. Response: {response.text}")
                  response.raise_for_status() # Raise exception for unexpected status
        else:
             response.raise_for_status() # Raise exception for any 4xx or 5xx status

        # Handle specific GitHub rate limiting
        if response.status_code == 403 and 'rate limit exceeded' in response.text.lower():
             logger.warning("GitHub rate limit exceeded. Check token usage.")
             # Consider adding retry logic or exponential backoff here

        # For successful POST/PUT resulting in 201 or 200, or successful GET (200)
        if response.status_code in [200, 201] and response.content:
            return response.json()
        elif response.status_code == 204: # No content success (e.g. some PUTs)
            return None
        else:
            return response # Return the full response object if no JSON body or other success code

    except requests.exceptions.RequestException as e:
        logger.error(f"GitHub API Request failed for {method} {url}: {e}")
        raise
    except Exception as e:
        logger.error(f"An unexpected error occurred during GitHub API call to {url}: {e}")
        raise