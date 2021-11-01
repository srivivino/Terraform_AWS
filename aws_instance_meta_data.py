import boto3

ec2 = boto3.client('ec2')

response = ec2.describe_instances(
    InstanceIds=[
        'i-09970e46d96ce3d2e',
    ]
)

meta_data = response['Reservations'][0]['Instances']
for i in meta_data:
    print(i['InstanceId'])