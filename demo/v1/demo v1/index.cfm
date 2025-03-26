<cfscript>
// Create an AI session if not already started.
if (NOT structKeyExists(session, "slim")) {
    session.slim = LuceeCreateAISession(name="gemma2", systemMessage="Answer as Slim Shady.");
}
</cfscript>
<cfflush interval="100">
<html>
<head>
    <title>Direct AI Integration Demo - Stream with Flush</title>
    <style>
        body { font-family: Arial, sans-serif; background: #f4f4f4; padding: 20px; }
        .container { max-width: 700px; margin: auto; background: #fff; padding: 20px; border: 1px solid #ddd; }
        textarea { width: 100%; height: 50px; }
        .response { margin-top: 20px; padding: 10px; background: #fafafa; border: 1px solid #ccc; }
        .btn { padding: 8px 12px; background: #2196F3; border: none; color: #fff; cursor: pointer; margin-right: 10px; }
    </style>
</head>
<body>
<div class="container">
    <h2>Direct AI Integration Demo</h2>
    <p>
        Enter your message and choose an action.<br />
        <strong>Complete Response:</strong> Returns the full response at once.<br />
        <strong>Stream Response:</strong> Streams and accumulates output with immediate flush.
    </p>
    <form method="post" action="index.cfm">
        <textarea name="userInput" placeholder="Enter your query here..."></textarea><br/><br/>
        <input type="submit" name="action" value="complete" class="btn">
        <input type="submit" name="action" value="stream" class="btn">
    </form>
    
    <div class="response">
        <h3>Response:</h3>
        <cfif structKeyExists(form, "action")>
            <cfset userInput = trim(form.userInput)>
            <cfif len(userInput)>
                <cfif form.action EQ "complete">
                    <!-- Complete Response: One-shot response -->
                    <cfset completeResponse = LuceeInquiryAISession(session.slim, userInput)>
                    <cfoutput>#completeResponse#</cfoutput>
                <cfelseif form.action EQ "stream">
                    <!-- Stream Response: Accumulate and flush each chunk immediately -->
                    <cfset accumulatedResult = "">
                    <cfscript>
                        LuceeInquiryAISession(session.slim, userInput, function(chunk){
                            // Append the chunk (trim to remove extra spaces)
                            accumulatedResult &= chunk;
                            // Write out the chunk immediately
                            writeOutput(chunk);
                            // Flush the output buffer to the browser
                            cfflush(throwonerror=false);
                        });
                    </cfscript>
                    <cfoutput>
                        <hr />
                        <p><strong>Final Accumulated Result:</strong></p>
                        <p>#accumulatedResult#</p>
                    </cfoutput>
                </cfif>
            <cfelse>
                <p>Please enter a message above.</p>
            </cfif>
        <cfelse>
            <p>No response yet. Enter a query and click one of the buttons above.</p>
        </cfif>
    </div>
    
    <hr />
    <h3>Direct Interaction Example (Immediate Dump):</h3>
    <cfset immediateResponse = LuceeInquiryAISession(session.slim, "Who was the most influential person in your life?")>
    <cfoutput>
        <p><strong>Immediate Response:</strong></p>
        <p>#immediateResponse#</p>
    </cfoutput>
    
    <hr />
    <h3>Streamed Interaction Example (Server Output with Flush):</h3>
    <p>
        The below example streams output for "Count from 1 to 100".
    </p>
    <cfset streamAccum = "">
    <cfscript>
        LuceeInquiryAISession(session.slim, "Count from 1 to 100", function(chunk){
            streamAccum &= chunk;
            writeOutput(chunk);
            cfflush(throwonerror=false);
        });
    </cfscript>
    <cfoutput>
        <hr />
        <p><strong>Final Stream Accumulation:</strong></p>
        <p>#streamAccum#</p>
    </cfoutput>
    <p>End of stream.</p>
</div>
</body>
</html>