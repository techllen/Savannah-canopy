def create_ai_prompt(full_error_context, source_code):
    """Creates the prompt for the Bedrock model."""
    # Prompt structure
    prompt = f"""Human:
You are an expert Java code debugging assistant. Your task is to analyze the provided error context and source code, identify the root cause of the error, and generate a fix.

**Instructions:**
1.  Carefully examine the `<full_error_context>` and `<source_code>` provided below.
2.  Determine the exact line(s) of code causing the error described in the context.
3.  Develop a corrected version of the source code that resolves the error. Modify only the necessary code sections.
4.  Add brief, meaningful comments ONLY to the lines of code you changed or added (e.g., `// Added null check`).
5.  Prepare a response containing the fix details and the complete modified code.

**CRITICAL OUTPUT REQUIREMENTS:**
-   Your **entire response** MUST be a single, valid JSON object.
-   Start your response **immediately** with `{{` and end it **immediately** with `}}`.
-   **DO NOT** include *any* text, explanations, apologies, greetings, or markdown formatting *outside* of the JSON structure.
-   The JSON object MUST strictly follow this structure:

    ```json
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
    ```
    <example response>
    **Example of Correctly Formatted JSON Output:**
    ```json
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
    ```
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