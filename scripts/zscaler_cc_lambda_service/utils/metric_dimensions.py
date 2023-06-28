import boto3
import logging
from typing import List, Dict, Tuple, Any

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


def retrieve_dimensions(namespace: str, metric_name: str, dimension_pairs: List[Tuple[str, str]]) \
        -> List[Dict[str, str]]:
    # Retrieve all metrics matching the namespace and metric name
    dimensions: List[Dict[str, str]] = []
    for name, value in dimension_pairs:
        if value is None:
            return []
        dimensions.append({
            'Name': name,
            'Value': value
        })

    logger.info(f"Retrieving dimensions for namespace: {namespace}, metric_name: {metric_name}, "
                f"dimensions: {dimensions}")

    try:
        response: Dict[str, Any] = cloudwatch_client.list_metrics(Namespace=namespace, Dimensions=dimensions)
        if 'Metrics' in response:
            metrics: List[Dict[str, Any]] = response['Metrics']
            dimensions_list: List[Dict[str, str]] = []
            for metric in metrics:
                dimensions = metric['Dimensions']
                dimensions_dict = {dimension['Name']: dimension['Value'] for dimension in dimensions}

                # Check if the metric dimensions match all the specified key names and values
                if all(dimensions_dict.get(key) == value for key, value in dimension_pairs):
                    dimensions_list.append(dimensions_dict)

            return dimensions_list
        else:
            logger.error(f"Failed to retrieve dimensions. Response: {response}")
            return []

    except Exception as e:
        logger.error(f"Error occurred: {str(e)}")
        return []


def test_dimensions():
    # Specify the namespace and metric name
    namespace = 'Zscaler/CloudConnectors'
    metric_name = 'cloud_connector_gw_health'
    dimension_pairs = [('AutoScalingGroupName', 'vkjune8-cc-asg-1-l0nk6zcm'), ('InstanceId', 'i-0beab4f0232f1bec2')]

    dimensions = retrieve_dimensions(namespace, metric_name, dimension_pairs)
    logger.info(f'test_dimensions(): Found dimensions: {dimensions}')


if __name__ == '__main__':
    test_dimensions()
