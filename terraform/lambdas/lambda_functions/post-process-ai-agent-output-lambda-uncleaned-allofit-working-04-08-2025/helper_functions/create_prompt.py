def create_ai_prompt(full_error_context, source_code):
    """Creates the prompt for the Bedrock model."""
    # Prompt structure
    prompt = f"""Human:
    You are a code debugging assistant.
    You will debug stack traces to identify the issues in the provided source code.
    Generate a modified version of the source code to prevent the error from occurring.
    Modify only the code relevant to the fix.
    Add meaningful short comments to the parts of the code that you will modify.
    Return ONLY the JSON object containing the fix details, with short explanation of whats the error and what changes you are doing to the code.

    The JSON object should have the following structure:
    {{
    "description": "A brief description of the fix",
    "detailed_description": "A Short explanation of whats the error and what changes you are doing to the code",
    "title": "A concise title for the pull request",
    "commit_message": "Short commit message", 
    "source_code": [
        {{
        "filename": "The full path of the file that needs modification",
        "contents": "The complete, modified , formatted source code for the specified file ONLY that will be used to raise a pull request in github."
        }}
    ]
    }}

    <example response>
    {{
    "description": "Handle potential None value for 'order_items' key before access.",
    "detailed_description": "This bug ... has been brought to my attenstion through cloudwatch .... The error means ... I am planning to ... to resolve the issue",
    "title": "[AI Generated code]Fix KeyError: 'order_items' by adding check",
    "commit_message": "Fixing ... ", 
    "source_code": [
        {{
        "filename": "OrderService.java",
        "contents": "
                        import com.amazonaws.services.lambda.runtime.Context;
                        import com.amazonaws.services.lambda.runtime.RequestHandler;
                        import com.fasterxml.jackson.databind.ObjectMapper;
                        import java.util.Map;

                        public class OrderHandler implements RequestHandler<Map<String, Object>, String> {{

                            @Override
                            public String handleRequest(Map<String, Object> event, Context context) {{
                                ObjectMapper mapper = new ObjectMapper();

                                try {{
                                    String bodyJson = (String) event.get(\"body\");

                                    Map<String, Object> body = mapper.readValue(bodyJson, Map.class);

                                    Object orderItems = body.get(\"order_items\"); // Safe access with .get()

                                    if (orderItems != null) {{
                                        // Process order_items
                                    }}

                                }} catch (Exception e) {{
                                    context.getLogger().log(\"Error parsing request: \" + e.getMessage());
                                }}

                                return \"Done\";
                            }}
                        }}
        "
        }}
    ]
    }}
    </example response>

    Now, analyze the following stack trace and source code:

    <full error context>
    {full_error_context}
    </full error context>

    <source code>
    {source_code}
    </source code>

    Assistant:"""

    return prompt