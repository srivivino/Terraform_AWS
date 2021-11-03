import boto3

ec2 = boto3.client('ec2')

Instance_ID = input("Enter the Instance_ID to see the meta_data details: ")
response = ec2.describe_instances(
    InstanceIds=[
        Instance_ID,
    ]
)

meta_data = response['Reservations'][0]['Instances']

#Printing all the meta-data for the given instance
print(meta_data)

# If you want to filter the specific meta-data of the instance ex: InstanceType
print("\n Filtering the Specific meta-data of the instance")
for i in meta_data:
    print(i['InstanceType'])