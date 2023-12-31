## Running the AppScan Enterprise task

This toolkit brings in data from AppScan Enterprise

To run this task you need the following information from AppScan Enterprise:

1. AppScan User ID e.g. 'YOUR_DOMAIN\Administrator'. Only one backslash between domain and username and single quoted.
1. AppScan User Password. Is recommended to wrap the password with single quotes.
1. AppScan instance hostname, e.g. host.example.com, should not include https:// prefix.
1. The application name for which the task will import data. Only one application is allowed.

## Command Line

See the main Toolkit for instructions on running tasks. For this task, if you leave off the Kenna API Key and Kenna Connector ID, the task will create a json file in the default or specified output directory. You can review the file before attempting to upload to the Kenna directly.

Recommended Steps:

1. Run with AppScan Enterprise Keys only to ensure you are able to get data properly from the scanner
1. Review output for expected data
1. Create Kenna Data Importer connector in Kenna (example name: AppScan Enterprise KDI)
1, Manually run the connector with the json from step 1
1. Click on the name of the connector to get the connector id
1. Run the task with AppScan Enterprise Keys and Kenna Key/connector id

Complete list of Options:

| Option | Required | Description | default |
| --- | --- | --- | --- |
| appscan_user_id | true | AppScan User ID e.g. 'YOUR_DOMAIN\Administrator'. Only one backslash between domain and username and single quoted. | n/a |
| appscan_password | true | AppScan User Password. Is recommended to wrap the password with single quotes. | n/a |
| appscan_api_host | true | AppScan instance hostname, e.g. host.example.com, should not include https:// prefix. | n/a |
| appscan_api_port | false | If AppScan runs in a non standard http port. | n/a |
| appscan_application | true | The application name for which the task will import data. Only one application is allowed. | n/a |
| appscan_issue_severity | false | A list of [Critical, High, Medium, Low, Information, Undetermined] (comma separated). If not present ALL issues are imported. | n/a |
| appscan_days_back | false | Get results n days back up to today. Get all history if not present. | n/a |
| appscan_page_size | false | Maximum number of issues to retrieve in each api call. | 500 |
| appscan_verify_ssl | false | Whether should verify ssl certificates for appscan api. | true |
| kenna_api_key | false | Kenna API Key | n/a |
| kenna_api_host | false | Kenna API Hostname | api.kennasecurity.com |
| kenna_connector_id | false | If set, we'll try to upload to this connector | n/a |
| output_directory | false | If set, will write a file upon completion. Path is relative to toolkit root directory | output/appscan_enterprise |

