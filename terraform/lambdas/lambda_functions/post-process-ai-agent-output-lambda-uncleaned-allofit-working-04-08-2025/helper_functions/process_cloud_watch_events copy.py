# lambda function integrated with an AI agent
import json
import base64
import gzip
import logging

# Configure logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

def process_cloud_watch_events(event):
    # prlogger.info("Received event:", event)
    # Ensure the `awslogs` key exists
    if 'awslogs' not in event or 'data' not in event['awslogs']:
        logger.error("Invalid event format: Missing 'awslogs.data'")
        return {'statusCode': 400, 'body': json.dumps({'error': 'Invalid event format'})}

    try:
        decoded_data = base64.b64decode(event['awslogs']['data'])
        decompressed_data = gzip.decompress(decoded_data)
        log_data = json.loads(decompressed_data)
        logger.info("Successfully decoded and parsed CloudWatch log data.")
    except Exception as e:
        logger.error(f"Error processing CloudWatch log data: {e}")
        return {'statusCode': 400, 'body': json.dumps({'error': 'Error processing log data'})}

    # Finding Error
    for log_event in log_data.get('logEvents', []):
        message = log_event.get('message', '')

        # Check for "ERROR"
        if "ERROR" in message:
            # --- Extract Error Details---
            try:
                # Parsing  JSON part containing stack trace details
                json_start = message.find('{')
                json_end = message.rfind('}')
                if json_start != -1 and json_end != -1:
                    json_string = message[json_start:json_end + 1]
                    error_details = json.loads(json_string)

                    # Extract filename and line number
                    stack_trace_info = error_details.get("stackTrace", {})
                    file_name = stack_trace_info.get("fileName") 
                    line_number = stack_trace_info.get("lineNumber")
                    error_context = message # Use the whole message as the stack trace for context

                    if not file_name:
                        logger.warning(f"Could not extract 'fileName' from error details in message: {message[:500]}...")
                        continue 

                    logger.info(f"Extracted file: {file_name}, line: {line_number}")

                else:
                    logger.warning(f"No JSON structure found in error message: {message[:500]}...")
                    continue 

            except (json.JSONDecodeError, KeyError, TypeError) as e:
                logger.warning(f"Error parsing error details JSON or missing keys: {e}. Message: {message[:500]}...")
                # continue
                return {
                    'statusCode': 500, 
                    'body': json.dumps({'error': str(e)})
                    }

            return {
                'statusCode': 200,
                'body': json.dumps({
                    'file_name': file_name,
                    'line_number': line_number,
                    'error_context': error_context
                })
            }