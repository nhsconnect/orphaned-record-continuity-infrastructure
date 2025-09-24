import boto3
import os
import json

def toggleServices(services, cluster, client):
    for service in services:
        if "tags" in service:
            desiredCount = getDesiredCount(service["tags"])

            for tag in service["tags"]:
                if (tag["key"]=="TurnOffAtNight" and tag["value"] == "True"):
                    print("Setting [" + service["serviceName"] + "] to desiredCount [" + str(desiredCount) + "] from [" + str(service["desiredCount"]) + "]")

                    response = client.update_service(
                        cluster=cluster,
                        service=service["serviceName"],
                        desiredCount=desiredCount
                    )


def getDesiredCount(tags):
    for tag in tags:
        if (tag["key"]=="Environment" and tag["value"] == "dev"):
            return int(os.environ['DESIRED_COUNT_DEV'])
        elif (tag["key"]=="Environment" and tag["value"] == "test"):
            return int(os.environ['DESIRED_COUNT_TEST'])
        else:
            pass

def getClusterArns(client):
    print("Retrieving list of clusters")
    response = client.list_clusters()
    return response["clusterArns"]

def getServiceArns(cluster, client):
    print("Retrieving list of Service Arns for Cluster: " + cluster)
    response = client.list_services(
        cluster=cluster,
        launchType='FARGATE',
    )
    return response["serviceArns"]

def describeServices(services, cluster, client):
    print("Retrieving list of Service Descriptions")
    response = client.describe_services(
        cluster=cluster,
        services=services,
        include=['TAGS']
    )
    return response["services"]

def lambda_handler(event, context):
    client = boto3.client('ecs')
    clusters = getClusterArns(client)
    for cluster in clusters:
        serviceArns = getServiceArns(cluster, client)
        services = describeServices(serviceArns, cluster, client)
        toggleServices(services, cluster, client)

    return {
        'statusCode': 200,
        'body': json.dumps('Completed')
    }