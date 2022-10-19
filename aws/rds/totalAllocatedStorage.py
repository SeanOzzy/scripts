# """
# This is a simple script to sum up the AllocatedStorage 
# for each RDS DB instance running postgres or mysql 
# in the region alonng with the number of DB instances.
#
# Ref: https://boto3.amazonaws.com/v1/documentation/api/latest/reference/services/rds.html#RDS.Client.describe_db_instances
# Tested in Python 3.8 with boto3 1.24.93
# """


import boto3
client = boto3.client('rds')
rdsDetails = client.describe_db_instances(
	Filters=[
		{
			'Name': 'engine',
			'Values': [
				'postgres', 'mysql',
			]
		}]
)
#print(rdsDetails)

rdsDBInstanceCount = 0
rdsAllocatedStorageSize = 0
for rdsId in rdsDetails['DBInstances']:
	#print(rdsId['AllocatedStorage'])
	rdsDBInstanceCount = rdsDBInstanceCount + 1
	rdsAllocatedStorageSize += rdsId['AllocatedStorage']

print(f"Total Allocated Storage for {rdsDBInstanceCount} DB instances is {rdsAllocatedStorageSize} in GB")
