# SpaceliftAPI

Setup needed:

  - create aws profile named "demo"
  - access to an AWS environment with permissions to create the following
    - API Gateway
    - DynamoDB Table  

To Use:

  - terraform init
  - terraform apply
  - No input variable required for out of the box use

Description

This terraform module allows for the automated created of an API endpoint to receive JSON documents and store them in a DynamoDB Table.
The API Gateway acts as a proxy to receive the events and pass them through to DynamoDB.
** If you need to transform the JSON document in any manner, you would inject an extra step to include a Lambda function between the API Gateway and the Dynamo DB table **

How to use with Spacelift:

  - Go to 'Stack'
  - 'Settings'
  - 'Integrations'
  - Click 'edit'
  - Choose 'Add Webhook' from 'Select integration set up' dropdown list
  - Insert the output from the terraform apply labeled "API_Gateway_endpoint_url"
  - Click 'Save'

To test:

  - After confirmation that the terraform apply has completed
  - Go back to your stack and trigger an event
  - You should see all of the information unmodified in a dynamoDB table named 'myDB' if no changes have been made to the defaults
 
 
 Writted by Michael Silva 
 Last edited April 5, 2021
