# Makefile for Lambda Python project

# Set the name of your Lambda function
FUNCTION_NAME = vk-june7-zip-test-drive

# Set the name of the zip file to be created
ZIP_FILE_NAME = zscaler_cc_lambda_service.zip

ZIP_FILE_NAME_LAMBDA_LAYER = zscaler_cc_lambda_service.zip.for_lambda_layer

DEST_TARGET_DIR = artifacts

# Set the path to your Python interpreter 3.9
PYTHON_INTERPRETER = python3

#Terraform module folder
TERRAFORM_TARGET_DIR = ../modules/terraform-zscc-asg-lambda-aws

#S3 folder
S3_FOLDER = zscc-dev/lambda_scripts

install:
	# Create a temporary directory
	mkdir -p temp
	# Install dependencies to the temporary directory
	$(PYTHON_INTERPRETER) -m pip install -r zscaler_cc_lambda_service/requirements.txt -t temp
	# Copy your Python files to the temporary directory
	cp -r zscaler_cc_lambda_service/* temp/
	# Create the zip file
	cd temp && zip -r ../$(ZIP_FILE_NAME) .
	cp $(ZIP_FILE_NAME) $(DEST_TARGET_DIR)/$(ZIP_FILE_NAME)
	# Clean up temporary directory
	rm -rf temp

deploy: install
	# Deploy the zip file to AWS Lambda using the AWS CLI or other deployment method
	aws lambda update-function-code --function-name $(FUNCTION_NAME) --zip-file fileb://$(ZIP_FILE_NAME) \
		--region us-west-2

fresh-deploy: install
	# Create a new AWS Lambda function using the zip file
	aws lambda create-function \
		--function-name $(FUNCTION_NAME) \
		--runtime python3.8 \
		--role arn:aws:iam::223544365242:role/zscc-asg-lambda-iam-role-5secz2st \
		--handler zscaler_cc_lambda_service.lambda_handler \
		--zip-file fileb://$(ZIP_FILE_NAME) \
		--region us-west-2


terraform_module_deploy: install
	cp $(ZIP_FILE_NAME) $(TERRAFORM_TARGET_DIR)/$(ZIP_FILE_NAME)

s3_deploy: 
	aws s3 cp $(ZIP_FILE_NAME) s3://$(S3_FOLDER)/$(ZIP_FILE_NAME)

lambdalayer_install:
	# Create a temporary directory
	mkdir -p temp_lambdalayer
	# Copy your Python files to the temporary directory
	cp -r zscaler_cc_lambda_service/* temp_lambdalayer/
	# Create the zip file
	cd temp_lambdalayer && zip -r ../$(ZIP_FILE_NAME_LAMBDA_LAYER) .
	cp $(ZIP_FILE_NAME_LAMBDA_LAYER) $(DEST_TARGET_DIR)/$(ZIP_FILE_NAME_LAMBDA_LAYER)
	# Clean up temporary directory
	rm -rf temp_lambdalayer

clean:
	rm -f $(DEST_TARGET_DIR)/$(ZIP_FILE_NAME)
	rm -rf temp temp_lambdalayer

all: clean install s3_deploy terraform_module_deploy
