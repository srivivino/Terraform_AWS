## Query the MetaData of single instance in AWS with json output

An easy method to query and get a single EC2 instance metadata with boto3 module.

A quick example:

.. code-block:: pycon

    >>> import boto3
    >>> ec2 = boto3.client('ec2')
    >>> response = ec2.describe_instances(InstanceIds=[Instance_ID,])
    >>> meta_data = response['Reservations'][0]['Instances']
    >>> print(meta_data)

Method_1 Execution
==================

Use **python**:

.. code-block:: sh

    python Method_1.py

Enter the Instance_ID to see the meta data information of a single instance with json output.

Python 3.6 to 3.9 supported.


