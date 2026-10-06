#!/usr/bin/env bash
set -euo pipefail

ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
mkdir -p "$ROOT/.local"
chmod 700 "$ROOT/.local"

python3 - "$ROOT" <<'PY'
import ipaddress
import json
import secrets
import sys
import tempfile
import time
from pathlib import Path

from scripts.lab import run_aws, verify

root = Path(sys.argv[1])
ctx = verify()
region = ctx["region"]
resources_path = root / ".local" / "resources.json"
db_env_path = root / ".local" / "db.env"

def aws(args):
    return run_aws(args, region)

def record(section, values):
    try:
        data = json.loads(resources_path.read_text(encoding="utf-8"))
        if not isinstance(data, dict):
            data = {}
    except (FileNotFoundError, json.JSONDecodeError):
        data = {}
    data.setdefault("W05", {})[section] = values
    with tempfile.NamedTemporaryFile("w", encoding="utf-8", dir=resources_path.parent,
                                    prefix=".resources.", delete=False) as stream:
        json.dump(data, stream, indent=2)
        stream.write("\n")
        temporary = Path(stream.name)
    temporary.chmod(0o600)
    temporary.replace(resources_path)

instances = aws([
    "ec2", "describe-instances",
    "--filters", "Name=instance-state-name,Values=running",
    "--query", "Reservations[].Instances[].{Id:InstanceId,Vpc:VpcId,SecurityGroups:SecurityGroups[].GroupId}",
])
if len(instances) != 1:
    raise SystemExit("Expected exactly one running EC2 instance in this Lab account.")
host = instances[0]
vpc_id = host["Vpc"]
host_sg = next((group for group in host["SecurityGroups"] if group != "sg-0a094864316485bfb"), None)
if not host_sg:
    raise SystemExit("Could not identify the non-default application security group.")

subnets = aws([
    "ec2", "describe-subnets", "--filters", f"Name=vpc-id,Values={vpc_id}",
    "--query", "Subnets[].{CIDR:CidrBlock,AZ:AvailabilityZone}",
])
used_networks = [ipaddress.ip_network(item["CIDR"]) for item in subnets]
candidate_networks = [ipaddress.ip_network("172.31.96.0/24"), ipaddress.ip_network("172.31.97.0/24")]
if any(candidate.overlaps(existing) for candidate in candidate_networks for existing in used_networks):
    raise SystemExit("Approved private subnet CIDRs overlap an existing subnet; stop and review.")

azs = aws([
    "ec2", "describe-availability-zones", "--filters", "Name=state,Values=available",
    "--query", "AvailabilityZones[].ZoneName",
])
if len(azs) < 2:
    raise SystemExit("Fewer than two available AZs were returned.")

route_table = aws(["ec2", "create-route-table", "--vpc-id", vpc_id])
route_table_id = route_table["RouteTable"]["RouteTableId"]
record("route_table", {"Id": route_table_id, "VpcId": vpc_id})

private_subnets = []
for index, network in enumerate(candidate_networks):
    result = aws([
        "ec2", "create-subnet", "--vpc-id", vpc_id,
        "--cidr-block", str(network), "--availability-zone", azs[index],
    ])
    subnet_id = result["Subnet"]["SubnetId"]
    aws(["ec2", "modify-subnet-attribute", "--subnet-id", subnet_id,
         "--no-map-public-ip-on-launch"])
    aws(["ec2", "associate-route-table", "--route-table-id", route_table_id,
         "--subnet-id", subnet_id])
    private_subnets.append({"Id": subnet_id, "CIDR": str(network), "AZ": azs[index]})
record("private_subnets", private_subnets)

group = aws([
    "ec2", "create-security-group", "--group-name", "w05-rds-db",
    "--description", "W05 private PostgreSQL access from the inspection host",
    "--vpc-id", vpc_id,
])
db_sg_id = group["GroupId"]
aws([
    "ec2", "authorize-security-group-ingress", "--group-id", db_sg_id,
    "--ip-permissions", json.dumps([{
        "IpProtocol": "tcp", "FromPort": 5432, "ToPort": 5432,
        "UserIdGroupPairs": [{"GroupId": host_sg}],
    }]),
])
record("db_security_group", {"Id": db_sg_id, "SourceSecurityGroupId": host_sg})

subnet_group_name = "w05-inspection-subnets"
aws([
    "rds", "create-db-subnet-group", "--db-subnet-group-name", subnet_group_name,
    "--db-subnet-group-description", "W05 private inspection database subnets",
    "--subnet-ids", *(item["Id"] for item in private_subnets),
])
record("db_subnet_group", {"Name": subnet_group_name,
                             "SubnetIds": [item["Id"] for item in private_subnets]})

db_identifier = "w05-inspection-db"
password = secrets.token_urlsafe(30)
aws([
    "rds", "create-db-instance", "--db-instance-identifier", db_identifier,
    "--engine", "postgres", "--db-instance-class", "db.t3.micro",
    "--allocated-storage", "20", "--storage-type", "gp3",
    "--storage-encrypted", "--no-publicly-accessible", "--no-multi-az",
    "--db-subnet-group-name", subnet_group_name, "--vpc-security-group-ids", db_sg_id,
    "--db-name", "inspection", "--master-username", "inspection",
    "--master-user-password", password, "--backup-retention-period", "0",
    "--no-auto-minor-version-upgrade",
])
record("rds", {"Id": db_identifier, "Status": "creating", "PubliclyAccessible": False})

print(f"RDS {db_identifier} is creating; waiting for available without printing credentials.")
for _ in range(40):
    status = aws([
        "rds", "describe-db-instances", "--db-instance-identifier", db_identifier,
        "--query", "DBInstances[0].{Status:DBInstanceStatus,Public:PubliclyAccessible,Endpoint:Endpoint.Address}",
    ])
    if status["Status"] == "available":
        if status["Public"] is not False:
            raise SystemExit("RDS became available but PubliclyAccessible was not false.")
        endpoint = status["Endpoint"]
        break
    if status["Status"] in {"failed", "incompatible-restore", "incompatible-network"}:
        raise SystemExit(f"RDS entered failure state: {status['Status']}")
    time.sleep(15)
else:
    raise SystemExit("RDS did not become available within the wait window; do not rerun db-up.sh.")

env = (
    f"DB_HOST={endpoint}\n"
    "DB_PORT=5432\n"
    "DB_NAME=inspection\n"
    "DB_USER=inspection\n"
    f"DB_PASSWORD={password}\n"
)
with tempfile.NamedTemporaryFile("w", encoding="utf-8", dir=db_env_path.parent,
                                prefix=".db-env.", delete=False) as stream:
    stream.write(env)
    temporary = Path(stream.name)
temporary.chmod(0o600)
temporary.replace(db_env_path)

record("rds", {"Id": db_identifier, "Status": "available", "PubliclyAccessible": False,
                 "Endpoint": endpoint})
print(f"RDS status=available publicly_accessible=false id_suffix={db_identifier[-4:]}")
print(f"Private subnets: {private_subnets[0]['Id'][-4:]}, {private_subnets[1]['Id'][-4:]}")
print(f"DB security group suffix: {db_sg_id[-4:]}")
PY