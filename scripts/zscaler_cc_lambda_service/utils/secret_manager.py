import boto3
import logging
import json

# Configure the logger
logger = logging.getLogger()
logger.setLevel(logging.DEBUG)

def get_secret_value(secret_name):
    # Create a Secrets Manager client
    logger.debug(f'Entering get_secret_value()')
    client = boto3.client('secretsmanager')

    try:
        # Retrieve the secret value
        response = client.get_secret_value(SecretId=secret_name)

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
