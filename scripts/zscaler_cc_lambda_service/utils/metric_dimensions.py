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
cloudwatch_client = boto3.client('cloudwatch')


def retrieve_dimensions(namespace, metric_name, dimension_pairs):
    # Retrieve all metrics matching the namespace and metric name
    dimensions = []
    for name, value in dimension_pairs:
        if value is None:
            return []
        dimensions.append({
            'Name': name,
            'Value': value
        })

    # response = cloudwatch_client.list_metrics(Namespace=namespace, MetricName=metric_name,
    #   Dimensions=dimensions)
    response = cloudwatch_client.list_metrics(Namespace=namespace,
                                              Dimensions=dimensions)

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
    dimension_pairs = [('AutoScalingGroupName', 'vkjune8-cc-asg-1-l0nk6zcm'), ('InstanceId', 'i-0beab4f0232f1bec2')]

    dimensions = retrieve_dimensions(namespace, metric_name, dimension_pairs)
    logger.info(f'test_dimensions(): Found dimensions: {dimensions}')


if __name__ == '__main__':
    test_dimensions()
