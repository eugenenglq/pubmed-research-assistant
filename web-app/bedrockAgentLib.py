import logging
import json
import os
from requests import request
import base64
import io
import sys

logger = logging.getLogger(__name__)

class BedrockAgentLib:
    def __init__(self, client, agent_id, agent_alias_id, region="us-east-1"):
        self.agent_id = agent_id
        self.agent_alias_id = agent_alias_id
        self.region = region
        self.client = client

    
    def invoke_agent(self, session_id, prompt, end_session=False):
        """
        Sends a prompt for the agent to process and respond to.

        :param agent_id: The unique identifier of the agent to use.
        :param agent_alias_id: The alias of the agent to use.
        :param session_id: The unique identifier of the session. Use the same value across requests
                            to continue the same conversation.
        :param prompt: The prompt that you want Claude to complete.
        :return: Inference response from the model.
        """

        try:
            # Note: The execution time depends on the foundation model, complexity of the agent,
            # and the length of the prompt. In some cases, it can take up to a minute or more to
            # generate a response.

            response = self.client.invoke_agent(
                agentId=self.agent_id,
                agentAliasId=self.agent_alias_id,
                sessionId=session_id,
                inputText=prompt,
                endSession=end_session
            )

            completion = ""

            for event in response.get("completion"):
                chunk = event["chunk"]
                if "bytes" in chunk:
                    completion = completion + chunk["bytes"].decode()
                print(chunk)

        except Exception as e:
            logger.error(f"Couldn't invoke agent. {e}")
            raise

        return completion

    def end_session(self, session_id):
        return self.ask_question("End session", session_id, end_session=True)