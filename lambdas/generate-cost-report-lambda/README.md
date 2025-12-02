# Generate AWS Cost and Usage Report

## What are AWS Cost and Usage Reports?
The AWS Cost and Usage Reports (AWS CUR) contains the most comprehensive set of cost and usage data available. You can use Cost and Usage Reports to publish your AWS billing reports to an Amazon Simple Storage Service (Amazon S3) bucket that you own. AWS updates the report in your bucket once a day in comma-separated value (CSV) format.

AWS Cost and Usage Reports tracks your AWS usage and provides estimated charges associated with your account. Each report contains line items for each unique combination of AWS products, usage type, and operation that you use in your AWS account. You can customize the AWS Cost and Usage Reports to aggregate the information either by the hour, day, or month.

AWS Cost and Usage Reports can do the following:
* Deliver report files to your Amazon S3 bucket
* Update the report up to three times a day
* Create, retrieve, and delete your reports using the AWS CUR API Reference

## Automated CUR  architecture diagram:
<img height="300" src="automated-cur-architecture.svg" width="500"/>


## Automated AWS Cost and Usage Monthly Report
### AWS Components configured in the automation process:
* AWS Billing Service 
   - The Billing Service generates a monthly report in Amazon S3
   - <a href="https://docs.aws.amazon.com/cur/latest/userguide/cur-create.html"><font color="#ffb703">Click here for the user guide to create cost and usage report</font></a>
   - <a href="https://docs.aws.amazon.com/cur/latest/userguide/understanding-report-versions.html"><font color="#ffb703">Click here for creating new cost and usage report versions</font></a>
   - <font color="#a2d2ff">**Configuration: Manually via AWS Console** </font>
* AWS S3  
   - The CUR report is stored in the S3 bucket `"{environment}-cost-and-usage"` path `s3://dev-cost-and-usage/reports/aws-cost-report/aws-cost-report/` as configured in the Billing Service.
   - Athena query results are stored in the S3 bucket in the output location `s3://dev-cost-and-usage/reports/aws-cost-report/manual-test-results/`.
   - <font color="#a2d2ff">**Configuration : Terraform script** </font>
* AWS Glue 
    - Glue crawler is scheduled to run on the 8th of every month at 8am.
    - The Glue crawler crawls over the S3 path `s3://{environment}-cost-and-usage/reports/aws-cost-report/aws-cost-report/`, looks for any change in the folders and then creates the cost report table `{environment}-generate-cost-report-catalog-database`.`aws_cost_report`
    - <font color="#a2d2ff">**Configuration : Terraform script** </font>
* AWS Athena 
    - We use Athena service `arn:aws:athena:{region}:{account-id}:workgroup/primary` to query the cost report which is populated in the Glue table.
    - <font color="#a2d2ff">**Configuration: Lambda function** </font>
* AWS SES   
    - We use SES to email the reports to the capacity management team.
    - Types of emails configured: 
      - sender
      - receiver list
      - support list in case of any failures
    - <font color="#a2d2ff">**Configuration : Terraform script** </font>
* AWS Lambda   
   - Lambda function generates the cost report and sends it to the capacity management team.
   - Email IDs are configured as a manual user input in the SSM parameters:
     - sender - `/repo/{environment}/user-input/sender-cost-report-email-id`
     - receiver list - `/repo/{environment}/user-input/receiver-cost-report-email-id`
     - support list in case of any failures - `/repo/{environment}/user-input/support-cost-report-email-id`
   - Lambda function is a Python script which is deployed via GoCD.
   - <font color="#a2d2ff">**Configuration: Lambda function** </font>
* AWS CloudWatch EventBridge Rule   
    - An EventBridge rule invokes the Lambda function on the 8th of every month at 9am.
    - <font color="#a2d2ff">**Configuration : Terraform script** </font>
* AWS IAM   
  - Necessary IAM permissions are provided for the above services.
  - <font color="#a2d2ff">**Configuration : Terraform script** </font>

### Report Naming Convention
* `{billing-date}-{environment}-{account-id}-aws-cost-and-usage-report.csv`

### Manual User Testing
* Enabled users to manually input `year` and `month` in lambda environment variable configuration.