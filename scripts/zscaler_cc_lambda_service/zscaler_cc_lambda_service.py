import os

import boto3
import logging
import utils.event_processor
from utils.secret_manager import get_secret_value
from utils.metric_dimensions import test_dimensions
from zscaler_client.ZscalerApiClient import test_zscaler_resouce_deletion
import json

# Configure the logger
logger = logging.getLogger()
logger.setLevel(logging.INFO)


def test_read_from_secretmanager():
    # Specify the AWS Secrets Manager secret name
    secret_name = os.getenv("SECRET_NAME")

    # Call the method to retrieve the secret value
    myapi_key, my_username, my_password = get_secret_value(secret_name)
    # logger.info(f"myapi_key: {myapi_key}  my_username: {my_username} my_password: {my_password}")


def test_all():
    test_read_from_secretmanager()
    test_dimensions()
    test_zscaler_resouce_deletion()


def lambda_handler(event, context):
    # dump the event and context
    logger.info(f'Zscaler lambda_handler: event={event} and context={context}')
    result = utils.helper.process_data(event)

    # test_all()

    # Return a response
    return {
        'statusCode': 200,
        'body': json.dumps('zscaler_cc_lambda_service completed')
    }


def invoke_lambda_locally():
    # Define the test event payload
    test_event = {
        # Add your test event payload here
    }

    # Invoke the lambda_handler with the test event
    response = lambda_handler(test_event, None)

    # Print the response
    print(response)


if __name__ == '__main__':
    # Call the method to invoke lambda_handler locally with a test event
    invoke_lambda_locally()
