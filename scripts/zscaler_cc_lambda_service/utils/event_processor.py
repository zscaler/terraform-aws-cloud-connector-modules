import datetime
import json
import logging
import os
from typing import List
from urllib.parse import urlparse

import boto3
import botocore

from utils.metric_dimensions import retrieve_dimensions
from utils.secret_manager import get_secret_value
from zscaler_client.zscaler_api_client import ZscalerApiClient

# from zscaler_cc_lambda_service.utils.metric_dimensions import retrieve_dimensions
# from secret_manager import get_secret_value
# from zscaler_cc_lambda_service.zscaler_client.zscaler_api_client import ZscalerApiClient

# Set up logging
logger = logging.getLogger()
logger.setLevel(logging.DEBUG)

# Create a formatter
formatter = logging.Formatter('%(asctime)s - %(levelname)s - %(funcName)s - %(message)s')

# Create a handler and set the formatter
handler = logging.StreamHandler()
handler.setFormatter(formatter)

# Add the handler to the logger
logger.addHandler(handler)

# Set up the boto3 client for Auto Scaling and EC2
autoscaling_client = boto3.client('autoscaling')
ec2_client = boto3.client('ec2')
cloudwatch_client = boto3.client('cloudwatch')

custom_namespace = 'Zscaler/CloudConnectors'
custom_metric = 'cloud_connector_gw_health'


def process_data(event):
    # Process the event data

    try:
        read_environment_variables()
    except Exception as e:
        return {
            'statusCode': 500,
            'body': f'Error: {str(e)}'
        }

    detail_type = event.get('detail-type')
    if detail_type == 'Scheduled Event':
        process_scheduled_event(event)
    elif detail_type == 'EC2 Instance-terminate Lifecycle Action':
        process_terminate_lifecycle_action(event)
    elif detail_type == 'EC2 Instance State-change Notification':
        process_terminated_instance_action(event)
    else:
        logger.warning("Unknown event detail-type: %s", detail_type)

    return "Data processed successfully"


def read_environment_variables() -> object:
    # Read Environment Variables
    logger.info(f'## ENVIRONMENT VARIABLES')
    log_group_name = os.environ.get('AWS_LAMBDA_LOG_GROUP_NAME', 'local-log-group')
    log_stream_name = os.environ.get('AWS_LAMBDA_LOG_STREAM_NAME', 'local-log-stream')
    logger.info(f"log_group_name: {log_group_name}")
    logger.info(f"log_stream_name: {log_stream_name}")

    asg_list = os.environ.get('ASG_NAMES', '["vkjune8-cc-asg-1-l0nk6zcm","vkjune8-cc-asg-2-l0nk6zcm"]')
    cc_url = os.environ.get('CC_URL', 'connector.zscalerbeta.net/api/v1/provUrl?name=aws_prov_template1')
    secret_name = os.environ.get('SECRET_NAME', 'ZS/CC/credentials/15859684-zscalerbeta')
    hc_data_points = os.environ.get('HC_DATA_POINTS', '10')
    hc_unhealthy_threshold = os.environ.get('HC_UNHEALTHY_THRESHOLD', '7')
    logger.info(
        f'#asg_list# {asg_list} #cc_url# {cc_url} #secret_name# {secret_name} #hc_data_points# {hc_data_points} #hc_unhealthy_threshold# {hc_unhealthy_threshold}')


def process_scheduled_event(event):
    logger.info("event: %s", event)
    # Check health of the instance and set custom autoscale health if unhealthy
    process_fault_management_event(event)


def process_terminate_lifecycle_action(event):
    logger.info("event: %s", event)
    # processing the EC2 Instance-terminate Lifecycle Action
    process_lifecycle_termination_events(event)


def process_terminated_instance_action(event):
    logger.info("event: %s", event)
    # processing the EC2 Instance-terminate Lifecycle Action
    process_terminated_instance_events(event)


def get_asg_names():
    asg_names_str = os.environ.get('ASG_NAMES', '["vkjune8-cc-asg-1-l0nk6zcm","vkjune8-cc-asg-2-l0nk6zcm"]')
    asg_names = json.loads(asg_names_str)
    if not asg_names:
        raise ValueError("No ASG names provided in the environment variable.")
    return asg_names


# FIXME Can't use this call yet as no IAM rules setup lets use the other one for now
def get_instances_in_service(asg_name):
    response = autoscaling_client.describe_auto_scaling_groups(AutoScalingGroupNames=[asg_name])
    instances = response['AutoScalingGroups'][0]['Instances']
    return [instance for instance in instances if instance['LifecycleState'] == 'InService']


def get_autoscaling_group_name(instance_id):
    try:
        # Get the autoscaling group information for the instance
        response = ec2_client.describe_instances(InstanceIds=[instance_id])

        # Extract the autoscaling group name from the response
        autoscaling_group_name = None
        if 'Reservations' in response and len(response['Reservations']) > 0:
            instances = response['Reservations'][0]['Instances']
            if len(instances) > 0:
                tags = instances[0].get('Tags', [])
                for tag in tags:
                    if tag['Key'] == 'aws:autoscaling:groupName':
                        autoscaling_group_name = tag['Value']
                        break

        return autoscaling_group_name
    except botocore.exceptions.ClientError as e:
        error_message = e.response.get('Error', {}).get('Message', '')
        if 'InvalidInstanceID.NotFound' in error_message:
            logger.error(f"Instance ID '{instance_id}' does not exist")
        else:
            # Handle other ClientError exceptions if needed
            logger.error(f"An error occurred while retrieving the autoscaling group name")
        return None


def log_instance_info(instance_id, asg_name):
    logger.info(f"Instance ID: {instance_id}, ASG Name: {asg_name}")


def process_fault_management_event(event):
    logger.info(f"event: {event}")
    # Get the Auto Scaling group name
    try:
        asg_names = get_asg_names()

        for asg_name in asg_names:
            # instances = get_instances_in_service(asg_name)
            instances = get_in_service_instances(asg_name)
            for instance in instances:
                # instance_id = instance['InstanceId']
                instance_id = instance
                log_instance_info(instance_id, asg_name)
                # query the custom health metric for this pair and get 10 entries at least If HC_UNHEALTHY_THRESHOLD
                # out of HC_DATA_POINTS entries are unhealthy these are in env than mark instance as unhealthy

        return f'health checked for all Inservice instances for autoscalinggroup list  successfully.'
    except Exception as e:
        logger.error(f"Error: {str(e)}")
        return "process_fault_management_event(): Error occurred while processing the ASGs."


def retrieve_last_n_entries():
    logger.info("Entering")
    start_time = datetime.datetime.now() - datetime.timedelta(minutes=30)
    end_time = datetime.datetime.now() - datetime.timedelta(minutes=10)
    logger.info('Retrieving metric data from {} to {}'.format(start_time, end_time))
    # need to add 2 extra to ensure we have at least HC_DATA_POINTS
    num_of_data_points_to_retrieve = os.environ['HC_DATA_POINTS'] + 2

    # FIXME pass entire dimensions for the desired metric instance instead of 1 dimension
    dimension_name = 'AutoScalingGroupName'
    dimension_value = 'AutoScalingGroupValue'

    response = cloudwatch_client.get_metric_data(
        MetricDataQueries=[
            {
                'Id': 'm1',
                'MetricStat': {
                    'Metric': {
                        'Namespace': custom_namespace,
                        'MetricName': custom_metric,
                        'Dimensions': [
                            {
                                'Name': dimension_name,
                                'Value': dimension_value
                            }
                        ]
                    },
                    'Period': 60,
                    'Stat': ['Average'],
                    'Unit': 'Percent'
                }
            }
        ],
        StartTime=start_time,
        EndTime=end_time,
        ScanBy='TimestampDescending',
        MaxDatapoints=num_of_data_points_to_retrieve
    )
    logger.info(f"retrieved get_metric_data(): {response}")
    logger.info(f'response["MetricDataResults"][0]["Values"]')
    if response['ResponseMetadata']['HTTPStatusCode'] == 200:
        if response['Messages']:
            logger.warning('Partial data received. Some metric data points may be missing.')

        logger.info('Last {num_of_data_points_to_retrieve} entries retrieved successfully!')

        # Process the metric data points
        if 'MetricDataResults' in response:
            for result in response['MetricDataResults']:
                if 'Timestamps' in result and 'Values' in result:
                    timestamps = result['Timestamps']
                    values = result['Values']

                    for timestamp, value in zip(timestamps, values):
                        logger.info('Timestamp: {}, Value: {}'.format(timestamp, value))
                else:
                    logger.warning('Missing Timestamps or Values in MetricDataResults.')
    else:
        logger.error(
            'Failed to retrieve metric data. Status code: {}'.format(response['ResponseMetadata']['HTTPStatusCode']))


def retrieve_all_dimensions():
    logger.info("Entering retrieve_all_dimensions")
    response = cloudwatch_client.list_metrics(
        Namespace=custom_namespace,
        MetricName=custom_metric
    )
    logger.info(response)
    dimensions = [metric['Dimensions'] for metric in response['Metrics']]
    logger.info('Dimensions associated with the metric:')
    logger.info(dimensions)


def process_results(instance_id, health_probe_results):
    # Check if HC_UNHEALTHY_THRESHOLD out of HC_DATA_POINTS health probe results are 0 %
    hc_data_points = os.environ['HC_DATA_POINTS']
    hc_unhealthy_threshold = os.environ['HC_UNHEALTHY_THRESHOLD']
    if health_probe_results.count(0) >= hc_unhealthy_threshold:
        logger.info(f"process_results found unhealthy datapoint count of {health_probe_results.count(0)}")
        # Set the custom Auto Scaling group health check for the instance as unhealthy
        autoscaling_client.set_instance_health(
            InstanceId=instance_id,
            HealthStatus='Unhealthy',
            ShouldRespectGracePeriod=False
        )


def get_in_service_instances(auto_scaling_group_name):
    # Retrieve in-service instances from the Auto Scaling group
    response = ec2_client.describe_instances(
        Filters=[
            {'Name': 'tag:aws:autoscaling:groupName', 'Values': [auto_scaling_group_name]},
            {'Name': 'instance-state-name', 'Values': ['running']}
        ]
    )

    in_service_instances = []
    for reservation in response['Reservations']:
        for instance in reservation['Instances']:
            instance_id = instance['InstanceId']
            in_service_instances.append(instance_id)
            logger.info(f"In-Service Instance ID: {instance_id}")

    return in_service_instances


def extract_ec2_instance_id_and_asg_name(event):
    if event['detail-type'] == 'EC2 Instance-terminate Lifecycle Action':
        ec2_instance_id = event['detail']['EC2InstanceId']
        autoscaling_group_name = event['detail']['AutoScalingGroupName']
    elif event['detail-type'] == 'EC2 Instance State-change Notification':
        ec2_instance_id = event['detail']['instance-id']
        logger.info(
            f'extract_ec2_instance_id_and_asg_name(): Find out the autoscaling group name for instanceId: {ec2_instance_id}')
        autoscaling_group_name = get_autoscaling_group_name(ec2_instance_id)
        if autoscaling_group_name:
            logger.info(
                f'extract_ec2_instance_id_and_asg_name(): Found instanceId: {ec2_instance_id} autoscaling_group_name {autoscaling_group_name}')
    else:
        logger.info("Unsupported event type.")
        return None, None

    logger.info(f"EC2 Instance ID: {ec2_instance_id}")
    logger.info(f"Autoscaling Group Name: {autoscaling_group_name}")
    return ec2_instance_id, autoscaling_group_name


def extract_zsgroupid_zsvmid_from_dimensions(dimensions):
    zs_group_id = None
    zs_vm_id = None
    if dimensions and len(dimensions) > 0:
        for dimension in dimensions:
            dimension_name = dimension['Name']
            dimension_value = dimension['Value']
            if dimension_name == 'ZsGroupId':
                zs_group_id = dimension_value
            elif dimension_name == 'ZsVmId':
                zs_vm_id = dimension_value
            # Break out of the loop if both dimensions are found
            if zs_group_id and zs_vm_id:
                break

    return zs_group_id, zs_vm_id


def process_lifecycle_termination_events(event):
    logger.info(f"process_lifecycle_termination_events  received: {event}")

    # Get the instance ID, asg_name from the event
    instance_id, asg_name = extract_ec2_instance_id_and_asg_name(event)
    # Get lifecycle action token from the event
    token = event['detail']['LifecycleActionToken']

    # read the lifecycle hook name from asg
    hook_name = event['detail']['LifecycleHookName']
    logger.info(f"hook_name: {hook_name} asgName: {asg_name}")
    logger.info(f"instance_id: {instance_id}")

    # Determine if the instance is part of a warmed pool and is being terminated
    if event['detail']['LifecycleTransition'] == 'autoscaling:EC2_INSTANCE_TERMINATING' and event['detail'][
        'LifecycleHookName'] == hook_name:
        response = autoscaling_client.describe_auto_scaling_instances(InstanceIds=[instance_id])
        logger.info(f"describe_auto_scaling_instances: {response}")
        instances = response['AutoScalingInstances']
        if instances and instances[0]['LifecycleState'] == 'Warmed:Terminating:Wait':
            get_asg_instance_metadata_and_delete_zscaler_cloud_resource(asg_name, instance_id)

            success = complete_lifecycle_action(hook_name, asg_name, token, instance_id)

            if success:
                # Handle successful completion of the lifecycle action
                print("Lifecycle action completed successfully.")
            else:
                # Handle failure in completing the lifecycle action
                print("Failed to complete the lifecycle action.")

        else:
            logger.info(f"life cycle action NOT  Warmed:Terminating:Wait and IGNORING it")

    response = {
        'statusCode': 200,
        'body': 'Autoscale Lifecycle action completed and Zscaler cloud resources cleaned up successfully'
    }
    return response


def complete_lifecycle_action(hook_name, asg_name, token, instance_id):
    try:
        if hook_name is None:
            # Get the termination lifecycle hook name from the ASG
            response = autoscaling_client.describe_lifecycle_hooks(AutoScalingGroupName=asg_name)
            hooks = response['LifecycleHooks']
            for hook in hooks:
                if hook['LifecycleTransition'] == 'autoscaling:EC2_INSTANCE_TERMINATING':
                    hook_name = hook['LifecycleHookName']
                    break

        if token is None:
            response = autoscaling_client.complete_lifecycle_action(
                LifecycleHookName=hook_name,
                AutoScalingGroupName=asg_name,
                LifecycleActionResult='CONTINUE',
                InstanceId=instance_id
            )
        else:
            response = autoscaling_client.complete_lifecycle_action(
                LifecycleHookName=hook_name,
                AutoScalingGroupName=asg_name,
                LifecycleActionToken=token,
                LifecycleActionResult='CONTINUE',
                InstanceId=instance_id
            )

        logger.debug(f"Lifecycle action response: {response}")

        if response['ResponseMetadata']['HTTPStatusCode'] == 200:
            logger.info("Lifecycle action completed successfully.")
            return True
        else:
            logger.error("Failed to complete the lifecycle action.")
            return False

    except Exception as e:
        logger.error("Failed to complete the lifecycle action.")
        logger.exception(e)
        return False


def get_asg_instance_metadata_and_delete_zscaler_cloud_resource(asg_name, instance_id):
    # Specify the namespace and metric name cloud_connector_gw_health to get metadata
    namespace = 'Zscaler/CloudConnectors'
    metric_name = 'cloud_connector_gw_health'

    logger.info(
        f"get_asg_instance_metadata_and_delete_zscaler_cloud_resource: asg_name: {asg_name} instance_id: {instance_id}")

    base_url = extract_base_url()

    dimension_pairs = [('AutoScalingGroupName', asg_name),
                       ('InstanceId', instance_id)]
    dimensions = retrieve_dimensions(namespace, metric_name, dimension_pairs)
    # retrieve zsgroupid and zsvmid
    zsgroupid, zsvmid = extract_zsgroupid_zsvmid_from_dimensions(dimensions)
    logger.info(f"zsgroupid: {zsgroupid} zsvmid: {zsvmid}")
    if zsgroupid and zsvmid:
        # get secret value
        secret_name = os.environ['SECRET_NAME']

        # Call the method to retrieve the secret value
        myapi_key, my_username, my_password = get_secret_value(secret_name)

        # create an authenticated session and delete the zsvmid and logout
        zscaler_api = ZscalerApiClient(myapi_key, my_username, my_password, base_url)
        zscaler_api.process_data(zsgroupid, zsvmid)


def extract_base_url():
    cc_url = os.environ.get('CC_URL', 'connector.zscalerbeta.net/api/v1/provUrl?name=aws_prov_template1')
    prov_url = "https://" + cc_url
    parsed_url = urlparse(prov_url)
    base_url = "https://" + parsed_url.netloc
    logger.info(f"Zscaler Cloud url: {base_url}")
    return base_url


def is_asg_name_in_list(asg_name):
    asg_names_list = os.getenv('ASG_NAMES')
    logger.info(f"managed asg names are: {asg_names_list}")

    if asg_name in asg_names_list:
        return True

    return False


def check_name_in_list(name: str, string_list: List[str]) -> bool:
    return name in string_list


def process_terminated_instance_events(event: object) -> object:
    logger.info(f"process_terminated_instance_events  received: {event}")
    # is the instance static CC VM or ASG
    # if asg need to get validate is this one that is managed by lambda
    # only difference between this and lifecycle termination event is no complete lifecycle action needed.
    # Let's handle only if this instance is part of autoscale group
    response = {
        'statusCode': 200,
        'body': 'Zscaler cloud resources cleaned up successfully'
    }

    # Get the instance ID, asg_name from the event
    instance_id, asg_name = extract_ec2_instance_id_and_asg_name(event)

    if instance_id and asg_name:
        message_body = f"{instance_id} with ASG name {asg_name} is valid. Zscaler cloud resources will be cleaned + " \
                       f"lifecycle action"
        logger.info(message_body)
        is_asg_managed = is_asg_name_in_list(asg_name)
        logger.info(f"is_asg_managed: {is_asg_managed}")
        if not is_asg_managed:
            success_code = 404
            message_body = f"ASG name {asg_name} is valid. Lambda is not managing this asg. no work to be done"
            logger.info(message_body)
            response = {
                'statusCode': success_code,
                'body': message_body
            }
            return response

        get_asg_instance_metadata_and_delete_zscaler_cloud_resource(asg_name, instance_id)
        # can't get hook_name or toke from this event
        # let complete_lifecycle_action() handle those case using different API
        hook_name = None
        token = None
        success = complete_lifecycle_action(hook_name, asg_name, token, instance_id)

        if success:
            # Handle successful completion of the lifecycle action
            logger.info(f"Lifecycle action completed successfully.")
        else:
            # Handle failure in completing the lifecycle action
            logger.error(f"Failed to complete the lifecycle action.")

        success_code = 200

    elif instance_id:
        message_body = f"{instance_id} is valid, but ASG name is missing. Zscaler cloud resources will be cleaned"
        logger.info(message_body)
        get_asg_instance_metadata_and_delete_zscaler_cloud_resource(asg_name, instance_id)
        success_code = 200

    elif asg_name:
        success_code = 404
        message_body = f"ASG name {asg_name} is valid, but instance ID is missing. Lambda is not managing this asg"
        logger.info(message_body)
    else:
        message_body = f"Neither instance ID nor ASG name is valid. No need to perform Zscaler cloud resource cleanup."
        logger.info(message_body)
        success_code = 200

    response = {
        'statusCode': success_code,
        'body': message_body
    }

    return response
