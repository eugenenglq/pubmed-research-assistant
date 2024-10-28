#!/bin/bash
set -e

# Navigate to the lambda-layers/python-common folder
cd lambda-layers/python-common

# Create a 'python' directory if it doesn't exist
mkdir -p python

# Install requirements into the 'python' directory
pip install -r requirements.txt -t python

# Navigate back to the original directory
cd ../..

echo "Dependencies installed successfully in lambda-layers/python-common/python"


# Apply Terraform changes
cd infra

# Function to check if a variable is set in terraform.tfvars
check_var() {
    grep -q "^$1 = " terraform.tfvars 2>/dev/null
}

# Initialize an array to store missing variables
missing_vars=()

# Check for terraform.tfvars and required variables
if [[ ! -f "terraform.tfvars" ]]; then
    echo "terraform.tfvars file not found."
    missing_vars+=("aws_region" "project_name")
else
    # Check for specific variables
    check_var "aws_region" || missing_vars+=("aws_region")
    check_var "project_name" || missing_vars+=("project_name")
fi

# If there are missing variables, prompt the user
if [ ${#missing_vars[@]} -ne 0 ]; then
    echo "Missing variables in terraform.tfvars: ${missing_vars[*]}"
    
    # Prompt for aws_region if missing
    if [[ " ${missing_vars[*]} " =~ "aws_region" ]]; then
        read -p "Enter AWS region (e.g., us-east-1): " aws_region
    fi
    
    # Prompt for project_name if missing
    if [[ " ${missing_vars[*]} " =~ "project_name" ]]; then
        read -p "Enter project name (e.g., research-assistant): " project_name
    fi
    
    # Create or update terraform.tfvars file
    cat <<EOL > terraform.tfvars
aws_region = "${aws_region:-}"
project_name = "${project_name:-}"
EOL
    echo "terraform.tfvars file has been created/updated."
else
    echo "All required variables are present in terraform.tfvars."
    # Load existing variables
    aws_region=$(grep "^aws_region = " terraform.tfvars | cut -d '"' -f 2)
    project_name=$(grep "^project_name = " terraform.tfvars | cut -d '"' -f 2)
fi

# Final check to ensure variables are not empty
if [[ -z "$aws_region" || -z "$project_name" ]]; then
    echo "Error: AWS region and project name cannot be empty."
    exit 1
fi

echo "Using AWS Region: $aws_region"
echo "Using Project Name: $project_name"

terraform init
terraform apply -auto-approve
terraform output -json | jq '{web_app_ecr_repository_url: .web_app_ecr_repository_url.value, pubmed_ingest_data_ecr_repository_url: .pubmed_ingest_data_ecr_repository_url.value, search_os_pubmed_lambda_repository_url: .search_os_pubmed_lambda_repository_url.value, web_app_ecr_repository_name: .web_app_ecr_repository_name.value, pubmed_ingest_data_ecr_repository_name: .pubmed_ingest_data_ecr_repository_name.value, search_os_pubmed_lambda_repository_name: .search_os_pubmed_lambda_repository_name.value}' > ../bin/tf-outputs.json


# Extract values using jq
web_app_ecr_repository_url=$(jq -r '.web_app_ecr_repository_url' ../bin/tf-outputs.json)
web_app_ecr_repository_name=$(jq -r '.web_app_ecr_repository_name' ../bin/tf-outputs.json)
pubmed_ingest_data_ecr_repository_url=$(jq -r '.pubmed_ingest_data_ecr_repository_url' ../bin/tf-outputs.json)
pubmed_ingest_data_ecr_repository_name=$(jq -r '.pubmed_ingest_data_ecr_repository_name' ../bin/tf-outputs.json)
search_os_pubmed_lambda_repository_url=$(jq -r '.search_os_pubmed_lambda_repository_url' ../bin/tf-outputs.json)
search_os_pubmed_lambda_repository_name=$(jq -r '.search_os_pubmed_lambda_repository_name' ../bin/tf-outputs.json)

# Print the extracted values (optional)
echo "web_app_ecr_repository_url: $web_app_ecr_repository_url"
echo "pubmed_ingest_data_ecr_repository_url: $pubmed_ingest_data_ecr_repository_url"
echo "search_os_pubmed_lambda_repository_url: $search_os_pubmed_lambda_repository_url"

# Authenticate Docker to ECR
# Get the AWS account ID
aws_account_id=$(aws sts get-caller-identity --query Account --output text)

aws ecr get-login-password --region $aws_region | docker login --username AWS --password-stdin ${aws_account_id}.dkr.ecr.${aws_region}.amazonaws.com


# echo "Building web application docker and push.."
# cd ../web-app/
# docker build -t $web_app_ecr_repository_name .
# docker tag $web_app_ecr_repository_name:latest $web_app_ecr_repository_url:latest
# docker push $web_app_ecr_repository_url:latest


# echo "Building ingest job docker and push.."
cd ../jobs/pubmed-ingest-data/
# docker build -t $pubmed_ingest_data_ecr_repository_name .
# docker tag $pubmed_ingest_data_ecr_repository_name:latest $pubmed_ingest_data_ecr_repository_url:latest
# docker push $pubmed_ingest_data_ecr_repository_url:latest

echo "Building lambda function image for summarizing pubmed docker and push.."
cd ../../lambda-functions/search-os-pubmed/
docker build -t $search_os_pubmed_lambda_repository_name .
docker tag $search_os_pubmed_lambda_repository_name:latest $search_os_pubmed_lambda_repository_url:latest
docker push $search_os_pubmed_lambda_repository_url:latest

