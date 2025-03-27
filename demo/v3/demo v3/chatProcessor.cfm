<cfscript>
// Chat Processor (chatProcessor.cfm)
// Improved validation, error logging, and session handling
try {
    // Check if a form submission exists
    if (structKeyExists(form, "action")) {
        // Normalize the action value for case-insensitive comparison
        actionValue = ucase(trim(form.action));

        // If clear history action is triggered
        if (actionValue EQ "CLEAR CHAT HISTORY") {
            session.chatHistory = [];  // Reset chat history; consider resetting other chat-related session data if needed.
            // Optionally log the clear action:
            // writeLog(file="chatLog", text="Chat history cleared at " & now());
            writeOutput(serializeJSON({ STATUS = "ok", HISTORY = session.chatHistory }));
            abort;  // Stop further processing.
        }
        
        // Retrieve and trim the user’s message
        userMessage = trim(form.userInput);
        if (len(userMessage)) {
            // Limit message length to 500 characters. Optionally notify if truncated.
            if (len(userMessage) gt 500) {
                userMessage = left(userMessage, 500);
            }
            
            // Initialize chatbot session if not already created.
            if (NOT structKeyExists(session, "chatbot")) {
                session.chatbot = LuceeCreateAISession(
                    name = "mychatgpt",
                    systemMessage = "You are a helpful chatbot."
                );
            }
            // Initialize chat history if not present.
            if (NOT structKeyExists(session, "chatHistory")) {
                session.chatHistory = [];
            }
            
            // Append the user's message to chat history.
            arrayAppend(session.chatHistory, { TYPE = "User", TEXT = HTMLEditFormat(userMessage) });
            
            // Retrieve chatbot's response.
            botResponse = LuceeInquiryAISession(session.chatbot, userMessage);
            if (!len(trim(botResponse))) {
                botResponse = "Sorry, I did not get that. Please rephrase.";
            }
            // Append bot's response.
            arrayAppend(session.chatHistory, { TYPE = "Bot", TEXT = HTMLEditFormat(botResponse) });
        }
    }
    // Output the current chat history JSON.
    writeOutput(serializeJSON({ STATUS = "ok", HISTORY = session.chatHistory }));
} catch (any e) {
    // Log error details internally; do not expose sensitive info to end users.
    // writeLog(file="chatErrorLog", text=e.message & " - " & e.detail);
    writeOutput(serializeJSON({ STATUS = "error", MESSAGE = "An internal error occurred." }));
}
</cfscript>