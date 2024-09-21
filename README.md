# Governance Azure Functions Samples

Welcome to the **Governance Azure Functions Samples** repository by **17-Labs**! This project contains sample implementations of **Azure Functions** designed to help manage governance policies within an Azure environment. 

These samples demonstrate how to automate and streamline various tasks related to governance using Azure Functions and PowerShell, with direct calls to the Microsoft Graph API.

## Features

- **Azure Functions with PowerShell**: Learn how to create and deploy Azure Functions using PowerShell.
- **Microsoft Graph API Integration**: Make direct HTTP calls to Microsoft Graph API to manage resources such as App Registrations, users, and permissions.

## Prerequisites

- **Azure Subscription**: Ensure you have access to an active Azure subscription.
- **Azure Functions Core Tools**: Install the Azure Functions Core Tools to develop and run functions locally.
- **PowerShell**: This project uses PowerShell for the Azure Functions.
- **Azure CLI**: Useful for deploying and managing resources from the command line.

## Getting Started

### 1. Clone the Repository

```bash
git clone https://github.com/17-Labs/GovernanceAzureFunctionsSamples.git
cd GovernanceAzureFunctionsSamples
```

### 2. Install Azure Functions Core Tools

Follow the instructions [here](https://docs.microsoft.com/en-us/azure/azure-functions/functions-run-local) to install the Azure Functions Core Tools.

### 3. Run the Project Locally

```bash
func start
```

This will start the Azure Functions runtime, and you can begin testing the functions locally.

### 4. Deploy to Azure

Once your function app is ready, you can deploy it to Azure with:

```bash
func azure functionapp publish <FunctionAppName>
```

Make sure to replace `<FunctionAppName>` with the name of your Azure Function App.

## Configuration

- **Azure AD Tenant ID**: You will need your Azure AD tenant ID to configure the Graph API calls.
- **Graph API Permissions**: Ensure the function app has appropriate Graph API permissions (e.g., `Application.Read.All`, `User.Read.All`) for managing Azure AD resources.
  
Set the required configurations in the `local.settings.json` file for local testing, or use Azure Application Settings for a production deployment.

```json
{
  "IsEncrypted": false,
  "Values": {
    "AzureWebJobsStorage": "<Azure Storage Connection String>",
    "FUNCTIONS_WORKER_RUNTIME": "powershell",
    "TenantId": "<Azure AD Tenant ID>",
    "ClientId": "<Azure AD Client ID>",
    "ClientSecret": "<Azure AD Client Secret>",
  }
}
```

## Contributing

We welcome contributions! If you'd like to contribute, please fork the repository and submit a pull request.

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.

## Contact

For any questions or issues, feel free to reach out via GitHub issues or contact us at [17-Labs](https://github.com/17-Labs).
