<cfscript>
// Process the form submission BEFORE any output
// Use try/catch for robust error handling
try {
    if (structKeyExists(form, "action")) {
        // If Clear Chat History button is pressed
        if (ucase(form.action) EQ "CLEAR CHAT HISTORY") {
            session.chatHistory = [];
            cflocation(url="index.cfm", addtoken="no");
        }
        
        // Sanitize user input
        userMessage = trim(form.userInput);
        if (len(userMessage)) {
            // Validate length, could limit maximum allowed characters (example: 500)
            if(len(userMessage) gt 500){
                userMessage = left(userMessage, 500);
            }
        
            // Ensure session variables are set
            if (NOT structKeyExists(session, "chatbot")) {
                // Added error handling if creation fails
                session.chatbot = LuceeCreateAISession(name="mychatgpt", systemMessage="You are a helpful chatbot.");
            }
            if (NOT structKeyExists(session, "chatHistory")) {
                session.chatHistory = [];
            }
            // Append user's message to conversation history after encoding for XSS prevention
            arrayAppend(session.chatHistory, { type="User", text=HTMLEditFormat(userMessage) });
            
            // Get chatbot's response and append it to conversation history
            botResponse = LuceeInquiryAISession(session.chatbot, userMessage);
            // Validate botResponse and prevent null reference if error
            if (!len(trim(botResponse))) {
                botResponse = "Sorry, I did not get that. Can you please rephrase?";
            }
            arrayAppend(session.chatHistory, { type="Bot", text=HTMLEditFormat(botResponse) });
        }
        // Redirect to refresh page and avoid form resubmission
        cflocation(url="index.cfm", addtoken="no");
    }
} catch (any e) {
    // Optionally log error e.message
    writeOutput("An unexpected error occurred. Please try again later.");
    abort;
}
</cfscript>
<cfflush />

<html>
<head>
    <title>Lucee Chatbot Demo</title>
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <link rel="stylesheet" href="styles.css">
    <style>
        /* In case external CSS is not loaded */
        body { margin: 0; padding: 0; font-family: Arial, sans-serif; background: #eef; }
        .container {
            width: 95vw;
            height: 95vh;
            margin: auto;
            background: #fff;
            display: flex;
            flex-direction: column;
            border: 1px solid #ccc;
            border-radius: 5px;
            overflow: hidden;
        }
        .chatBox {
            flex: 1;
            padding: 10px;
            background: #f9f9f9;
            border-bottom: 1px solid #ddd;
            overflow-y: auto;
        }
        .inputArea {
            display: flex;
            flex-direction: column;
            padding: 10px;
        }
        textarea {
            width: 100%;
            height: 70px;
            padding: 8px;
            font-family: inherit;
            border: 1px solid #ccc;
            border-radius: 3px;
            resize: vertical;
        }
        .btn {
            margin-top: 10px;
            padding: 10px;
            background: #007BFF;
            border: none;
            color: #fff;
            cursor: pointer;
            border-radius: 3px;
            font-size: 16px;
        }
        .clearBtn {
            margin-top: 10px;
            padding: 10px;
            background: #c0392b;
            border: none;
            color: #fff;
            cursor: pointer;
            border-radius: 3px;
            font-size: 16px;
        }
        .message { margin: 8px 0; clear: both; }
        .User { color: #007BFF; font-weight: bold; float: left; }
        .Bot { color: #d35400; font-weight: bold; float: left; }
        .msgText { margin-left: 60px; }
        @media only screen and (max-width: 600px) {
            .container { width: 95vw; height: 95vh; }
            textarea { height: 60px; }
        }
    </style>
    <script>
        // Scroll to bottom and attach event listener for enter-to-send functionality
        window.addEventListener('DOMContentLoaded', function() {
            var chatBox = document.getElementById('chatBox');
            if(chatBox) {
                chatBox.scrollTop = chatBox.scrollHeight;
            }
            // Enter-to-send functionality in textarea
            var textarea = document.getElementById('userMsg');
            textarea.addEventListener('keydown', function(event) {
                if (event.key === 'Enter' && !event.shiftKey) {
                    event.preventDefault();
                    document.querySelector('.submit_btn').click();
                }
            });
        });
    </script>
</head>
<body>
    <div style="height: 100%; display: flex;">
        <div class="container">
            <div id="chatBox" class="chatBox">
                <cfoutput>
                    <cfif structKeyExists(session, "chatHistory") and arrayLen(session.chatHistory) gt 0>
                        <cfloop array="#session.chatHistory#" index="msg">
                            <div class="message">
                                <div class="#msg.type#">#msg.type#:</div>
                                <div class="msgText">#msg.text#</div>
                            </div>
                        </cfloop>
                    <cfelse>
                        <p>Waiting for your input...</p>
                    </cfif>
                </cfoutput>
            </div>
            <div class="inputArea">
                <form id="chatForm" method="post" action="index.cfm">
                    <!-- CSRF token could be added here if framework supports -->
                    <textarea id="userMsg" name="userInput" placeholder="Enter your message... (Press Enter to send; Shift+Enter for new line)"></textarea>
                    <input type="submit" name="action" value="Send Message" class="btn submit_btn">
                </form>
                <form method="post" action="index.cfm" style="margin-top:10px;">
                    <!-- CSRF token could be added here as well -->
                    <input type="submit" name="action" value="Clear Chat History" class="clearBtn">
                </form>
            </div>
        </div>
    </div>
</body>
</html>