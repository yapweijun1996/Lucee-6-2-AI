<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>Lucee Chatbot Demo</title>
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <!-- Link to external CSS file; fallback is provided via inline CSS below -->
    <link rel="stylesheet" href="styles.css">
    <style>
        /* Inline CSS - for demo purposes; consider moving to external styles.css */
        body {
            margin: 0;
            padding: 0;
            font-family: Arial, sans-serif;
            background: #eef;
        }
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
        .btn, .clearBtn {
            margin-top: 10px;
            padding: 10px;
            border: none;
            color: #fff;
            cursor: pointer;
            border-radius: 3px;
            font-size: 16px;
        }
        .btn {
            background: #007BFF;
        }
        .clearBtn {
            background: #c0392b;
        }
        .message {
            margin: 8px 0;
            clear: both;
        }
        .User {
            color: #007BFF;
            font-weight: bold;
            float: left;
        }
        .Bot {
            color: #d35400;
            font-weight: bold;
            float: left;
        }
        .msgText {
            margin-left: 60px;
            word-wrap: break-word;
        }
        @media only screen and (max-width: 600px) {
            .container { width: 95vw; height: 95vh; }
            textarea { height: 60px; }
        }
    </style>
    <script>
        // Global variable for chat history (optimistic UI update)
        let chatHistory = [];

        // Function to update the chatBox by creating DOM elements
        function updateChatBox(history) {
            const chatBox = document.getElementById('chatBox');
            chatBox.innerHTML = ""; // Clear previous content

            if(history && history.length > 0) {
                history.forEach(function(msg) {
                    const messageDiv = document.createElement('div');
                    messageDiv.className = "message";

                    const typeDiv = document.createElement('div');
                    typeDiv.className = msg.TYPE;
                    typeDiv.textContent = msg.TYPE + ":";

                    const textDiv = document.createElement('div');
                    textDiv.className = "msgText";
                    textDiv.textContent = msg.TEXT;

                    messageDiv.appendChild(typeDiv);
                    messageDiv.appendChild(textDiv);
                    chatBox.appendChild(messageDiv);
                });
            } else {
                const waitingPara = document.createElement('p');
                waitingPara.textContent = "Waiting for your input...";
                chatBox.appendChild(waitingPara);
            }
            // Auto-scroll to bottom.
            chatBox.scrollTop = chatBox.scrollHeight;
        }
        
        // Function to send chat messages using AJAX (Fetch API)
        async function sendChat(formData) {
            try {
                const response = await fetch('chatProcessor.cfm', {
                    method: 'POST',
                    headers: { "Content-Type": "application/x-www-form-urlencoded" },
                    body: new URLSearchParams(formData)
                });
                const result = await response.json();
                if(result.STATUS === "ok") {
                    // Reconcile local chat history with server response.
                    chatHistory = result.HISTORY;
                    updateChatBox(chatHistory);
                } else {
                    console.error("Error response: ", result.MESSAGE);
                    alert("Error: " + result.MESSAGE);
                }
            } catch (error) {
                console.error("AJAX error: ", error);
                alert("Failed to connect to server.");
            }
        }
        
        document.addEventListener("DOMContentLoaded", function(){
            const chatForm = document.getElementById('chatForm');
            const userMsg = document.getElementById('userMsg');
            
            // Initial fetch to populate chat history
            sendChat({});
            
            // Bind chat form submit event
            chatForm.addEventListener("submit", function(e){
                e.preventDefault();
                const formData = new FormData(chatForm);
                const messageText = formData.get('userInput').trim();
                if(messageText === ""){
                    alert("Please enter a message.");
                    return;
                }
                
                // Optimistic update: Display user's message immediately.
                chatHistory.push({ TYPE: "User", TEXT: messageText });
                updateChatBox(chatHistory);
                
                // Convert FormData to a plain object.
                const data = {};
                formData.forEach((value, key) => data[key] = value);
                sendChat(data);
                chatForm.reset();
            });
            
            // Bind clear chat history event
            const clearForm = document.getElementById('clearForm');
            clearForm.addEventListener("submit", function(e){
                e.preventDefault();
                // Optimistically clear chat history from UI.
                chatHistory = [];
                updateChatBox(chatHistory);
                
                const formData = new FormData(clearForm);
                const data = {};
                formData.forEach((value, key) => data[key] = value);
                sendChat(data);
            });
            
            // Enable Enter-to-send (Shift+Enter for new line) for textarea.
            userMsg.addEventListener('keydown', function(event) {
                if (event.key === 'Enter' && !event.shiftKey) {
                    event.preventDefault();
                    chatForm.dispatchEvent(new Event('submit', { cancelable: true }));
                }
            });
            
            // Poll for new updates every 5 seconds.
            setInterval(function(){
                sendChat({});
            }, 5000);
        });
    </script>
</head>
<body>
    <!-- Main container for layout -->
    <div style="height:100%; display:flex;">
        <div class="container">
            <!-- Chat display area -->
            <div id="chatBox" class="chatBox">
                <p>Waiting for your input...</p>
            </div>
            <!-- Input area: form for sending messages and clearing chat -->
            <div class="inputArea">
                <form id="chatForm" method="post" action="chatProcessor.cfm">
                    <textarea id="userMsg" name="userInput" placeholder="Enter your message... (Press Enter to send; Shift+Enter for new line)"></textarea>
                    <input type="hidden" name="action" value="Send Message">
                    <input type="submit" value="Send Message" class="btn" aria-label="Send Message">
                </form>
                <form id="clearForm" method="post" action="chatProcessor.cfm" style="margin-top:10px;">
                    <input type="hidden" name="action" value="Clear Chat History">
                    <input type="submit" value="Clear Chat History" class="clearBtn" aria-label="Clear Chat History">
                </form>
            </div>
        </div>
    </div>
</body>
</html>