# lambda function integrated with an AI agent
import json
import base64
import gzip

def process_cloud_watch_events(event):
    print("Received event:", event)
    # Ensure the `awslogs` key exists
    if 'awslogs' not in event or 'data' not in event['awslogs']:
        print("Invalid event format: Missing 'awslogs.data'")
        return {'statusCode': 400, 'body': json.dumps({'error': 'Invalid event format'})}

    try:
        decoded_data = base64.b64decode(event['awslogs']['data'])
        decompressed_data = gzip.decompress(decoded_data)
        log_data = json.loads(decompressed_data)
        print("Successfully decoded and parsed CloudWatch log data.")
    except Exception as e:
        print(f"Error processing CloudWatch log data: {e}")
        return {'statusCode': 400, 'body': json.dumps({'error': 'Error processing log data'})}

    # --- 3. Iterate Through Log Events and Find First Error ---
    for log_event in log_data.get('logEvents', []):
        message = log_event.get('message', '')

        # Simple check for "ERROR" - refine this if needed for Spring Boot specifics
        if "ERROR" in message:
            # --- Extract Error Details---
            try:
                # Attempt to parse the JSON part containing stack trace details
                json_start = message.find('{')
                json_end = message.rfind('}')
                if json_start != -1 and json_end != -1:
                    json_string = message[json_start:json_end + 1]
                    error_details = json.loads(json_string)

                    # Extract filename and line number - ADJUST KEYS IF NEEDED
                    stack_trace_info = error_details.get("stackTrace", {}) # Safely get stackTrace
                    file_name = stack_trace_info.get("fileName") 
                    line_number = stack_trace_info.get("lineNumber")
                    full_stack_trace = message # Use the whole message as the stack trace for context

                    if not file_name:
                        print(f"Could not extract 'fileName' from error details in message: {message[:500]}...")
                        continue 

                    print(f"Extracted file: {file_name}, line: {line_number}")

                else:
                    print(f"No JSON structure found in error message: {message[:500]}...")
                    continue # Skip if no JSON found

            except (json.JSONDecodeError, KeyError, TypeError) as e:
                print(f"Error parsing error details JSON or missing keys: {e}. Message: {message[:500]}...")
                continue # Skip to next log event on parsing failure

            return {
                'statusCode': 200,
                'body': json.dumps({
                    'file_name': file_name,
                    'line_number': line_number,
                    'full_stack_trace': full_stack_trace
                })
            }