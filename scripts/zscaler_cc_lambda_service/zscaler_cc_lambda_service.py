import json
import logging
import os

import utils.event_processor
from utils.metric_dimensions import test_dimensions
from utils.secret_manager import get_secret_value
from zscaler_client.zscaler_api_client import test_zscaler_resouce_deletion

# Configure the logger
logger = logging.getLogger()
logger.setLevel(logging.INFO)

# Create a formatter
formatter = logging.Formatter('%(asctime)s - %(levelname)s - %(funcName)s - %(message)s')

# Create a handler and set the formatter
handler = logging.StreamHandler()
handler.setFormatter(formatter)

# Add the handler to the logger
logger.addHandler(handler)


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

    result = utils.event_processor.process_data(event)

    # Return a response
    return {
        'statusCode': 200,
        'body': json.dumps(result)
    }


def invoke_lambda_locally():
    # Define the test event payload
    test_termination_event = {
        "version": "0",
        "id": "f74e985d-c3ff-415d-b5fa-d3614c5e3434",
        "detail-type": "EC2 Instance State-change Notification",
        "source": "aws.ec2",
        "account": "123456789012",
        "time": "2015-11-11T21:36:48Z",
        "region": "us-east-1",
        "resources": [
            "arn:aws:ec2:us-east-1:123456789012:instance/i-abcd5555"
        ],
        "detail": {
            "instance-id": "i-03200d11a5163947e",
            "state": "terminated"
        }
    }

    # trying this event for end-end
    test_asg_termination_event = {
      "version": "0",
      "id": "468fe059-f4b7-445f-bb22-2a271b94974d",
      "detail-type": "EC2 Instance-terminate Lifecycle Action",
      "source": "aws.autoscaling",
      "account": "123456789012",
      "time": "2015-12-22T18:43:48Z",
      "region": "us-east-2",
      "resources": [
        "arn:aws:autoscaling:us-east-1:123456789012:autoScalingGroup:59fcbb81-bd02-485d-80ce-563ef5b237bf:autoScalingGroupName/sampleASG"
      ],
      "detail": {
        "LifecycleActionToken": "630aa23f-48eb-45e7-aba6-799ea6093a0f",
        "AutoScalingGroupName": "vkjune8-cc-asg-1-bu4wgv5y",
        "LifecycleHookName": "vkjune8-cc-asg-1-lifecyclehook-terminate-bu4wgv5y",
        "EC2InstanceId": "i-03200d11a5163947e",
        "LifecycleTransition": "autoscaling:EC2_INSTANCE_TERMINATING"
      }
    }

    test_scheduled_fault_management_event =  {
        "id": "cdc73f9d-aea9-11e3-9d5a-835b769c0d9c",
        "detail-type": "Scheduled Event",
        "source": "aws.events",
        "account": "123456789012",
        "time": "1970-01-01T00:00:00Z",
        "region": "us-east-2",
        "resources": [
            "arn:aws:events:us-east-1:123456789012:rule/ExampleRule"
        ],
        "detail": {}
    }

    # This was tested and worked all the way to deletion
    test_scheduled_fault_management_received_event = {
        "version": "0",
        "id": "99952124-e6fc-eac9-57a2-74675b478a17",
        "detail-type": "Scheduled Event",
        "source": "aws.events",
        "account": "223544365242",
        "time": "2023-06-10T23:33:45Z",
        "region": "us-east-2",
        "resources": [
            "arn:aws:events:us-east-2:223544365242:rule/vkjune8-cc-asg-scheduled-event-rule-l0nk6zcm"
        ],
        "detail": {}
    }

    # Invoke the lambda_handler with the test event
    response = lambda_handler(test_termination_event, None)

    # Print the response
    print(response)


if __name__ == '__main__':
    # Call the method to invoke lambda_handler locally with a test event
    invoke_lambda_locally()
