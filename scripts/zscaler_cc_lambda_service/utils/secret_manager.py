"""
Copyright (C) 2007-2023 Zscaler, Inc. All rights reserved.
Unauthorized copying of this file, via any medium is strictly prohibited
Proprietary and confidential
"""
import json
import logging

import boto3

# Configure the logger
logger = logging.getLogger()
logger.setLevel(logging.DEBUG)

# Create a formatter
formatter = logging.Formatter('%(asctime)s - %(levelname)s - %(funcName)s - %(message)s')

# Create a handler and set the formatter
handler = logging.StreamHandler()
handler.setFormatter(formatter)

# Add the handler to the logger
logger.addHandler(handler)

# Create a Secrets Manager client
secretmanager_client = boto3.client('secretsmanager')


def get_secret_value(secret_name):
    logger.debug(f'Entering get_secret_value()')

    try:
        # Retrieve the secret value
        response = secretmanager_client.get_secret_value(SecretId=secret_name)

        # Extract the secret value from the response
        if 'SecretString' in response:
            secret_value = response['SecretString']
            # logger.info(f"Secret value: {secret_value}")
            # Parse the JSON string into a dictionary
            data = json.loads(secret_value)
            # Access the values by key
            api_key = data['api_key']
            username = data['username']
            password = data['password']

            # logger.info(f"get_secret_value() api_key: {api_key}  username: {username} password: {password}")
            return (api_key, username, password)
        else:
            logger.info("get_secret_value(): No secret value found.")

    except Exception as e:
        logger.error(f"get_secret_value(): Error retrieving secret: {str(e)}")
