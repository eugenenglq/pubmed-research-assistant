
import os
import uuid
from bedrockAgentLib import BedrockAgentLib
import streamlit as st
import json
import pandas as pd
import boto3

region = os.getenv('REGION')
samplePromptsDDName = os.getenv('SAMPLE_PROMPTS_DD')
bedrockAgentID = os.getenv('BEDROCK_AGENT_ID')
bedrockAgentAliasID = os.getenv('BEDROCK_AGENT_ALIAS_ID', '') 
bedrockAgentAliasID = bedrockAgentAliasID.split(',')[0] if ',' in bedrockAgentAliasID else bedrockAgentAliasID

runtime_client = boto3.client(service_name="bedrock-agent-runtime", region_name=region)
dynamodb = boto3.resource('dynamodb', region_name=region)  
samplePrompsTbl = dynamodb.Table(samplePromptsDDName) 
bedrockAgentLib = BedrockAgentLib(client=runtime_client, agent_id=bedrockAgentID, agent_alias_id=bedrockAgentAliasID)

# Streamlit page configuration
st.set_page_config(page_title="Genomics Research Assistant", page_icon=":robot_face:", layout="wide")

sessionId = str(uuid.uuid4())

# Session State Management
if 'history' not in st.session_state:
    st.session_state.history = []

# Title
st.title("Genomics Research Assistant")

# Display a button to end the session
end_session_button = st.button("End Session")

# Display a text box for input
prompt = st.chat_input("Please enter your query?")

# Display chat messages from history on app rerun
for message in st.session_state.history:
    with st.chat_message(message["role"]):
        st.markdown(message["content"])

# Sidebar for user input
st.sidebar.header("Sample Prompts")

# Fetch all records from DynamoDB
allSamplePrompts = samplePrompsTbl.scan()
for record in allSamplePrompts['Items']:
    group = record.get('group', '')
    samples = record.get('samples', [])
    
    st.sidebar.subheader(group)
    for sample in samples:
        st.sidebar.code(sample)

# Handling user input and responses
if prompt:
    event = {
        "sessionId": sessionId,
        "question": prompt
    }
    with st.chat_message("user"):
        st.markdown(prompt)
    # Add user message to chat history
    st.session_state.history.append({"role": "user", "content": prompt})

    response = bedrockAgentLib.invoke_agent(sessionId, prompt)

    st.session_state['trace_data'] = response
    
    with st.chat_message("assistant"):
        st.markdown(response)
    # Add assistant response to chat history
    st.session_state.history.append({"role": "assistant", "content": response})

if end_session_button:
    st.session_state.history.append({"role": "user", "content": "Session Ended"})
    
    event = {
        "sessionId": sessionId,
        "question": "placeholder to end session",
        "endSession": True
    }
    bedrockAgentLib.end_session(sessionId)
    st.session_state.history.append({"role": "assistant", "content": "Thank you for using Genomics Research Assistant!"})
    st.session_state.history.clear()