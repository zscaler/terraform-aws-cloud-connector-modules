import datetime
import json
import logging
import os
import time
from datetime import datetime, timedelta
from typing import List
from urllib.parse import urlparse

import boto3
import botocore
from botocore.exceptions import ClientError


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
custom_metric = 'cloud_connector_aggr_health'


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
        logger.warning(f"Not supported: Unknown event detail-type: {detail_type} Ignoring")

    return "Data processed successfully"


def read_environment_variables():
    # Read Environment Variables
    logger.info(f'## ENVIRONMENT VARIABLES')
    log_group_name = os.environ.get('AWS_LAMBDA_LOG_GROUP_NAME', 'local-log-group')
    log_stream_name = os.environ.get('AWS_LAMBDA_LOG_STREAM_NAME', 'local-log-stream')
    logger.info(f"log_group_name: {log_group_name}")
    logger.info(f"log_stream_name: {log_stream_name}")

    # asg_list = os.environ.get('ASG_NAMES', '["vkjune8-cc-asg-1-bu4wgv5y","vkjune8-cc-asg-2-bu4wgv5y"]')
    asg_list = os.environ.get('ASG_NAMES', '["vkjune8-cc-asg-1-bu4wgv5y"]')
    cc_url = os.environ.get('CC_URL', 'connector.zscalerbeta.net/api/v1/provUrl?name=aws_prov_template1')
    secret_name = os.environ.get('SECRET_NAME', 'zscloudbeta11584294/CC/credentials')
    hc_data_points = os.environ.get('HC_DATA_POINTS', '10')
    hc_unhealthy_threshold = os.environ.get('HC_UNHEALTHY_THRESHOLD', '7')
    logger.info(
        f'#asg_list# {asg_list} #cc_url# {cc_url} #secret_name# {secret_name} #hc_data_points# {hc_data_points} #hc_unhealthy_threshold# {hc_unhealthy_threshold}')


def process_scheduled_event(event):
    logger.info(f"event: {event}")
    # Check health of the instance and set custom autoscale health if unhealthy
    result = process_fault_management_event(event)
    logger.info(f'result is : {result}')


def process_terminate_lifecycle_action(event):
    logger.info(f"event: {event}")
    # processing the EC2 Instance-terminate Lifecycle Action
    result = process_lifecycle_termination_events(event)
    logger.info(f'result is : {result}')


def process_terminated_instance_action(event):
    logger.info(f"event: {event}")
    # processing the EC2 Instance-terminate Lifecycle Action
    result = process_terminated_instance_events(event)
    logger.info(f'result is : {result}')


def get_asg_names():
    # asg_names_str = os.environ.get('ASG_NAMES', '["vkjune8-cc-asg-1-bu4wgv5y","vkjune8-cc-asg-2-bu4wgv5y"]')
    asg_names_str = os.environ.get('ASG_NAMES', '["vkjune8-cc-asg-1-bu4wgv5y"]')
    asg_names = json.loads(asg_names_str)
    if not asg_names:
        raise ValueError("No ASG names provided in the environment variable.")
    return asg_names


# FIXME Can't use this call yet as no IAM rules setup lets use the other one for now
# def get_instances_in_service(asg_name):
#     response = autoscaling_client.describe_auto_scaling_groups(AutoScalingGroupNames=[asg_name])
#     instances = response['AutoScalingGroups'][0]['Instances']
#     return [instance for instance in instances if instance['LifecycleState'] == 'InService']


def get_instances_by_pool_membership(asg_name):
    response = autoscaling_client.describe_auto_scaling_groups(AutoScalingGroupNames=[asg_name])
    instances = response['AutoScalingGroups'][0]['Instances']

    in_service_instances = []
    in_warm_pool_instances = []
    ten_minutes = timedelta(minutes=10)

    # Check if warm pool is configured for the Auto Scaling group
    if 'WarmPoolConfiguration' in response['AutoScalingGroups'][0]:
        warm_pool_response = autoscaling_client.describe_warm_pool(AutoScalingGroupName=asg_name)
        warm_pool_instances = [instance['InstanceId'] for instance in warm_pool_response['Instances']]

        for instance in instances:
            if instance['InstanceId'] in warm_pool_instances:
                in_warm_pool_instances.append(instance)
            elif instance['LifecycleState'] == 'InService':
                instance_uptime = get_instance_uptime(instance['InstanceId'])
                if instance_uptime >= ten_minutes:
                    in_service_instances.append(instance)
    else:
        for instance in instances:
            if instance['LifecycleState'] == 'InService':
                instance_uptime = get_instance_uptime(instance['InstanceId'])
                if instance_uptime >= ten_minutes:
                    in_service_instances.append(instance)

    return in_service_instances, in_warm_pool_instances


def get_instance_uptime(instance_id):
    response = ec2_client.describe_instances(InstanceIds=[instance_id])
    launch_time = response['Reservations'][0]['Instances'][0]['LaunchTime']
    current_time = datetime.now(launch_time.tzinfo)
    uptime = current_time - launch_time
    return uptime


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
    hc_data_points = int(os.environ.get('HC_DATA_POINTS', '10'))
    # Get the Auto Scaling group name
    try:
        asg_names = get_asg_names()

        for asg_name in asg_names:
            # instances, warm_pool_instances = get_instances_in_service(asg_name)
            instances, warm_pool_instances = get_instances_by_pool_membership(asg_name)
            # TODO check which is correct
            instances_minus_warmpool = get_inservice_instances_not_in_warm_pool(asg_name)
            # instances = get_in_service_instances(asg_name)
            for instance in instances:
                # instance_id = instance['InstanceId']
                instance_id = instance
                log_instance_info(instance_id, asg_name)
                # query the custom health metric for this pair and get 10 entries at least. If HC_UNHEALTHY_THRESHOLD
                # out of HC_DATA_POINTS entries are unhealthy these are in env than mark instance as unhealthy
                base_url, dimensions = get_dimensions_for_health_metrics(asg_name, instance_id['InstanceId'])
                health_stats_datapoints_results = getstats_cloud_connector_gw_health(asg_name, instance_id, dimensions)
                # TODO check if instance is up for at least 10 minutes
                # not needed as we already check if instance uptime is 10 minute
                # if not is_instance_in_service_for_x_amount_of_time(instance_id, hc_data_points):
                #     logger.info(f'instance_id: {instance_id} is running for less than {hc_data_points} minutes'
                #                 f'and hence Skipping health check')
                #     continue
                if if_unhealthy_ask_autoscaling_to_replace_instance(instance_id, asg_name,
                                                                    health_stats_datapoints_results):
                    logger.info(f'if_unhealthy_ask_autoscaling_to_replace_instance(): returned True, for instance: '
                                f'{instance_id} asg_name: {asg_name} '
                                f'health_stats_datapoints_results: {health_stats_datapoints_results}')
                    # delete the Zscaler resource as well
                    get_asg_instance_metadata_and_delete_zscaler_cloud_resource(asg_name, instance_id)
                else:
                    logger.info(f'if_unhealthy_ask_autoscaling_to_replace_instance(): returned False, for instance: '
                                f'{instance_id} asg_name: {asg_name} hence it is HEALTHY')

        return f'health checked for all Inservice instances for autoscalinggroup list  successfully.'
    except Exception as e:
        logger.error(f"Error: {str(e)}")
        return "process_fault_management_event(): Error occurred while processing the ASGs."


def getstats_cloud_connector_gw_health(cgh_asgname, cgh_instanceid, dimensions):
    # Retrieve cloud_connector_aggr_health
    # dimensions is a list of dict
    # get first item
    hc_data_points = int(os.environ.get('HC_DATA_POINTS', '10'))
    dimensions_formatted_list = []
    for dimension in dimensions:
        for name, value in dimension.items():
            dimensions_formatted_list.append({
                'Name': name,
                'Value': value
            })

    # Needs to be Name, value pair dimensions when sent to get_metric_statistics
    logger.info(f'dimensions_formatted_list: {dimensions_formatted_list}')
    endtime = datetime.utcnow()
    # configured time +
    starttime = endtime - timedelta(minutes=hc_data_points + 2)
    response = []
    try:
        response = cloudwatch_client.get_metric_statistics(
            Namespace=custom_namespace,
            MetricName=custom_metric,

            Dimensions=dimensions_formatted_list,
            StartTime=starttime,
            EndTime=endtime,
            Period=60,
            Statistics=['Average']
        )
    except Exception as e:
        logger.error(f"An error occurred while retrieving  cloud_connector_aggr_health: {str(e)} ")
    logger.info(
        f"cloud_connector_aggr_health for {cgh_asgname}, "
        "{cgh_instanceid} after get_metric_statistics response is : {response}")
    # Sort data points by timestamp
    datapoints = sorted(response['Datapoints'], key=lambda x: x['Timestamp'], reverse=True)
    if len(datapoints) == 0:
        logger.info(
            f'[cloud_connector_aggr_health for {cgh_asgname}, {cgh_instanceid}] No datapoints found between StartTime:'
            f' {starttime} and EndTime: {endtime}')
    else:
        logger.info(
            f'[cloud_connector_aggr_health for {cgh_asgname}, {cgh_instanceid}] '
            f'Number of datapoints processed between StartTime: {starttime} and EndTime: {endtime}: {len(datapoints)}')
    # Verify data
    if datapoints:
        average = datapoints[0]['Average']
        timestamp = datapoints[0]['Timestamp']
        logger.info(
            f"[cloud_connector_aggr_health for {cgh_asgname}, {cgh_instanceid}] Sum for FIRST datapoint Only : {average} "
            f"at {timestamp}")
    else:
        logger.info(f"[cloud_connector_aggr_health for {cgh_asgname}, {cgh_instanceid}] No data available ")

    return datapoints


'''
retrieve_last_n_entries() not used
'''


def retrieve_last_n_entries():
    start_time = datetime.datetime.now() - datetime.timedelta(minutes=30)
    end_time = datetime.datetime.now() - datetime.timedelta(minutes=10)
    logger.info('Retrieving metric data from {} to {}'.format(start_time, end_time))
    # need to add 2 extra to ensure we have at least HC_DATA_POINTS
    num_of_data_points_to_retrieve = os.environ.get('HC_DATA_POINTS', '10') + 2

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
    response = cloudwatch_client.list_metrics(
        Namespace=custom_namespace,
        MetricName=custom_metric
    )
    logger.debug(f'response: {response}')
    dimensions = [metric['Dimensions'] for metric in response['Metrics']]
    logger.debug(f'dimensions: {dimensions}')


def is_stats_reported_unhealthy(datapoints):
    hc_data_points = int(os.environ.get('HC_DATA_POINTS', '10'))
    hc_unhealthy_threshold = int(os.environ.get('HC_UNHEALTHY_THRESHOLD', '7'))

    if hc_unhealthy_threshold:
        if datapoints is None or not datapoints:
            missing_datapoints_unhealthy = bool(os.environ.get('MISSING_DATAPOINTS_UNHEALTHY', 'True'))
            if missing_datapoints_unhealthy:
                logger.info('Either none or empty and hence marking instance as unhealthy')
                return True

    datapoints_to_evaluate = len(datapoints)
    logger.info(f"Number of datapoints to evaluate: {datapoints_to_evaluate}")

    if datapoints_to_evaluate <= hc_data_points:
        # Need to have a minimum number of datapoints; otherwise, skip
        return False

    consecutive_count = 0
    max_consecutive_count = 0
    count_less_than_100 = 0

    for datapoint in datapoints:
        if datapoint['Average'] < 100:
            consecutive_count += 1
            if consecutive_count > max_consecutive_count:
                max_consecutive_count = consecutive_count
            count_less_than_100 += 1
        else:
            consecutive_count = 0

    if count_less_than_100 >= hc_unhealthy_threshold or max_consecutive_count >= 5:
        return True
    else:
        return False


def if_unhealthy_ask_autoscaling_to_replace_instance(instance_id, asg_name, health_stats_recent_datapoints_results):
    # Check if HC_UNHEALTHY_THRESHOLD out of HC_DATA_POINTS health probe results are 0 %

    if is_stats_reported_unhealthy(health_stats_recent_datapoints_results):
        logger.info(f"process_results found asg_name: {asg_name} instance {instance_id} unhealthy datapoint count of'"
                    f" {health_stats_recent_datapoints_results.count(0)}")
        # Set the custom Auto Scaling group health check for the instance as unhealthy
        logger.info(f'Found instance {instance_id} in asg {asg_name} Unhealthy, breaching threshold'
                    f'sending message to autoscaling orchestration svc to terminate the instance')
        autoscaling_client.set_instance_health(
            InstanceId=instance_id,
            HealthStatus='Unhealthy',
            ShouldRespectGracePeriod=False
        )
        return True


def is_instance_in_service_for_x_amount_of_time(instance_id, inservice_age):
    response = autoscaling_client.describe_auto_scaling_instances(InstanceIds=[instance_id])
    instance_status = response['AutoScalingInstances'][0]['LifecycleState']
    transition_time = response['AutoScalingInstances'][0]['LifecycleTransitionStart']

    if instance_status == 'InService':
        current_time = datetime.now(transition_time.tzinfo)
        elapsed_time = current_time - transition_time
        elapsed_minutes = elapsed_time.total_seconds() / 60

        if elapsed_minutes >= inservice_age:
            return True

    return False


def get_inservice_instances_not_in_warm_pool(auto_scaling_group_name):
    # Get the Auto Scaling group details
    response = autoscaling_client.describe_auto_scaling_groups(AutoScalingGroupNames=[auto_scaling_group_name])
    instances = response['AutoScalingGroups'][0]['Instances']
    warm_pool_instances = response['AutoScalingGroups'][0].get('WarmPoolConfiguration', {}).get('Instances', [])

    # Find instances that are InService and not in the warm pool
    inservice_instances = []
    for instance in instances:
        instance_id = instance['InstanceId']
        if instance_id not in warm_pool_instances and instance['LifecycleState'] == 'InService':
            inservice_instances.append(instance_id)

    return inservice_instances


# TODO Somehow this returns warm pool instances that are initializing
# maybe I  have to filter this out
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
            if not instance['LaunchTime'] >= 10 * 60:
                logger.info(f'launchtime less than 10 minutes instanceid: {instance_id} skipping')
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
            f'Find out the autoscaling group name for instanceId: {ec2_instance_id}')
        autoscaling_group_name = get_autoscaling_group_name(ec2_instance_id)
        if autoscaling_group_name:
            logger.info(
                f'Found instanceId: {ec2_instance_id} autoscaling_group_name {autoscaling_group_name}')
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
    logger.info(f"received: {event}")

    # Get the instance ID, asg_name from the event
    instance_id, asg_name = extract_ec2_instance_id_and_asg_name(event)
    # Get lifecycle action token from the event
    token = event['detail']['LifecycleActionToken']

    # read the lifecycle hook name from asg
    hook_name = event['detail']['LifecycleHookName']
    logger.info(f"hook_name: {hook_name} asgName: {asg_name}")
    logger.info(f"instance_id: {instance_id}")

    # Determine if the instance is part of a warmed pool and is being terminated
    if event['detail']['LifecycleTransition'] == 'autoscaling:EC2_INSTANCE_TERMINATING' and event['detail']['LifecycleHookName'] == hook_name:
        response = autoscaling_client.describe_auto_scaling_instances(InstanceIds=[instance_id])
        logger.info(f"describe_auto_scaling_instances: {response}")
        instances = response['AutoScalingInstances']
        # if instances and instances[0]['LifecycleState'] == 'Warmed:Terminating:Wait':
        # handle terminating events and not just warmed:Terminating ones
        if instances:
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
    retry_attempts = 5
    retry_delay = 60  # Initial delay in seconds
    max_delay = 300  # Maximum delay in seconds

    try:
        if hook_name is None:
            # Get the termination lifecycle hook name from the ASG
            response = autoscaling_client.describe_lifecycle_hooks(AutoScalingGroupName=asg_name)
            hooks = response['LifecycleHooks']
            for hook in hooks:
                if hook['LifecycleTransition'] == 'autoscaling:EC2_INSTANCE_TERMINATING':
                    hook_name = hook['LifecycleHookName']

        # Check if the instance is in a 'Terminating:Wait' or 'Warmed:Terminating:Wait' state
        response = autoscaling_client.describe_auto_scaling_instances(InstanceIds=[instance_id])
        if 'AutoScalingInstances' in response:
            asg_instance = response['AutoScalingInstances'][0]
            lifecycle_state = asg_instance['LifecycleState']
            if lifecycle_state.startswith('Terminating:Wait') or lifecycle_state.startswith('Warmed:Terminating:Wait'):
                for attempt in range(retry_attempts):
                    try:
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

                    except Exception as e:
                        logger.warning("Failed to complete the lifecycle action.")
                        logger.exception(e)

                    logger.warning("Retrying...")
                    time.sleep(retry_delay)
                    retry_delay = min(2 * retry_delay, max_delay)

                logger.warning("Exceeded maximum retry attempts. Failed to complete the lifecycle action.")
                return False
            else:
                logger.warning(f"Instance is not in the expected 'Terminating:Wait' or 'Warmed:Terminating:Wait' state. Current state: {lifecycle_state}")
                return False
        else:
            logger.warning("Failed to retrieve instance information. Skipping lifecycle action.")
            return False

    except Exception as e:
        logger.warning("Failed to complete the lifecycle action.")
        logger.exception(e)
        return False


def extract_zs_group_vm_ids(data):
    try:
        if not isinstance(data, list) or len(data) == 0:
            raise ValueError("Invalid data object")

        zs_group_id = data[0].get('ZsGroupId')
        zs_vm_id = data[0].get('ZsVmId')

        if zs_group_id is None or zs_vm_id is None:
            raise ValueError("Missing ZsGroupId or ZsVmId")

        return zs_group_id, zs_vm_id

    except (ValueError, IndexError) as e:
        print("Error occurred:", str(e))
        return None, None


def get_asg_instance_metadata_and_delete_zscaler_cloud_resource(asg_name, instance_id):
    if asg_name is None or instance_id is None:
        logger.info(f'asg_name: {asg_name} instance_id: {instance_id} one of them is None and hence '
                    f'cannot retreive statistics, cannot handle this event, processing is complete')
        return False
    base_url, dimensions = get_dimensions_for_health_metrics(asg_name, instance_id)
    # TODO check if I broke code by changing this method
    # retrieve zsgroupid and zsvmid
    #  extract_zsgroupid_zsvmid_from_dimensions() expects dimensions in Name,value pair
    # zsgroupid, zsvmid = extract_zsgroupid_zsvmid_from_dimensions(dimensions)

    zsgroupid, zsvmid = extract_zs_group_vm_ids(dimensions)
    if zsgroupid is not None and zsvmid is not None:
        logger.info(f"Zscaler resource deletion planned for zsgroupid: {zsgroupid} zsvmid: {zsvmid}"
                    f"asg_name: {asg_name} instance_id: {instance_id}")

    if zsgroupid and zsvmid:
        # get secret value
        secret_name = os.environ.get('SECRET_NAME', 'zscloudbeta11584294/CC/credentials')

        # Call the method to retrieve the secret value
        myapi_key, my_username, my_password = get_secret_value(secret_name)

        # create an authenticated session and delete the zsvmid and logout
        zscaler_api = ZscalerApiClient(myapi_key, my_username, my_password, base_url)
        zscaler_api.process_data(zsgroupid, zsvmid)
        return True


def get_dimensions_for_health_metrics(asg_name, instance_id):
    # Specify the namespace and metric name cloud_connector_aggr_health to get metadata
    namespace = 'Zscaler/CloudConnectors'
    metric_name = 'cloud_connector_aggr_health'
    logger.info(
        f"get_asg_instance_metadata_and_delete_zscaler_cloud_resource: asg_name: {asg_name} instance_id: {instance_id}")
    base_url = extract_base_url()
    dimension_pairs = [('AutoScalingGroupName', asg_name),
                       ('InstanceId', instance_id)]
    dimensions = retrieve_dimensions(namespace, metric_name, dimension_pairs)
    return base_url, dimensions


def extract_base_url():
    cc_url = os.environ.get('CC_URL', 'connector.zscalerbeta.net/api/v1/provUrl?name=aws_prov_template1')
    prov_url = "https://" + cc_url
    parsed_url = urlparse(prov_url)
    base_url = "https://" + parsed_url.netloc
    logger.info(f"Zscaler Cloud url: {base_url}")
    return base_url


def is_asg_name_in_list(asg_name):
    # asg_names_list = os.getenv('ASG_NAMES')
    # asg_names_list = os.environ.get('ASG_NAMES', '["vkjune8-cc-asg-1-bu4wgv5y","vkjune8-cc-asg-2-bu4wgv5y"]')
    asg_names_list = os.environ.get('ASG_NAMES', '["vkjune8-cc-asg-1-bu4wgv5y"]')
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
        # can't get hook_name or token from this event
        # let complete_lifecycle_action() handle those case using different API
        if asg_name is not None and instance_id is not None:
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
        else:
            success_code = 404
            message_body = f"one of ASG name or instance_id is None. no work to be done"

    elif instance_id:
        message_body = f"{instance_id} is valid, but ASG name is missing. Zscaler cloud resources won't be cleaned"
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
