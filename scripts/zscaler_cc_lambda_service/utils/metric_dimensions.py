import boto3
import logging

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

# Create a CloudWatch client
cloudwatch = boto3.client('cloudwatch')


def retrieve_dimensions(namespace, metric_name, dimension_pairs):
    # Retrieve all metrics matching the namespace and metric name
    response = cloudwatch.list_metrics(Namespace=namespace, MetricName=metric_name)

    # Process the response and retrieve the dimensions
    metrics = response['Metrics']
    dimensions_list = []
    for metric in metrics:
        dimensions = metric['Dimensions']
        dimensions_dict = {dimension['Name']: dimension['Value'] for dimension in dimensions}

        # Check if the metric dimensions match all the specified key names and values
        if all(dimensions_dict.get(key) == value for key, value in dimension_pairs):
            dimensions_list.append(dimensions_dict)

    return dimensions_list


def test_dimensions():
    # Specify the namespace and metric name
    namespace = 'Zscaler/CloudConnectors'
    metric_name = 'cloud_connector_gw_health'
    dimension_pairs = [('AutoScalingGroupName', 'vkmay20-cc-asg-xhlsy0ko'), ('InstanceId', 'i-093fdbd1e654be354')]
    dimensions = retrieve_dimensions(namespace, metric_name, dimension_pairs)
    logger.info(f'test_dimensions(): Found dimensions: {dimensions}')
