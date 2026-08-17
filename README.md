# Salesforce DX Project

This repository contains the Salesforce DX source code and metadata retrieved and converted to standard source format.

## Project Structure

```
├── .forceignore                  # Files ignored by Salesforce CLI during deploy/retrieve
├── .gitignore                    # Files ignored by Git
├── .vscode/                      # Recommended VS Code configuration and extensions
│   ├── extensions.json
│   ├── launch.json
│   └── settings.json
├── config/
│   └── project-scratch-def.json  # Scratch org definition configuration
├── force-app/main/default/       # Salesforce DX Source Code (Classes, LWC, Aura, Objects, etc.)
│   ├── aura/                     # Aura Components
│   ├── classes/                  # Apex Classes
│   ├── flexipages/               # Lightning Pages
│   ├── flows/                    # Salesforce Flows
│   ├── labels/                   # Custom Labels
│   ├── layouts/                  # Page Layouts
│   ├── lwc/                      # Lightning Web Components
│   ├── objects/                  # Custom and Standard Objects & Fields
│   ├── permissionsets/           # Permission Sets
│   ├── profiles/                 # Profiles
│   ├── triggers/                 # Apex Triggers
│   └── ...                       # Other metadata types
├── manifest/
│   └── package.xml               # Metadata manifest for manifest-based deployments
├── unpackaged/                   # Original Metadata API retrieve package
└── sfdx-project.json             # Salesforce DX Project configuration
```

## Getting Started

### Prerequisites
- [Salesforce CLI (`sf`)](https://developer.salesforce.com/tools/salesforcecli)
- [Visual Studio Code](https://code.visualstudio.com/) with the [Salesforce Extension Pack](https://marketplace.visualstudio.com/items?itemName=salesforce.salesforcedx-vscode)

---

## Common Salesforce CLI (`sf`) Commands

### 1. Authorize an Org
```bash
# Authorize a sandbox or scratch org
sf org login web --alias my-sandbox --instance-url https://test.salesforce.com

# Authorize a developer / production org
sf org login web --alias my-org --instance-url https://login.salesforce.com --set-default
```

### 2. Deploy Metadata to Org
```bash
# Deploy entire default package directory
sf project deploy start --target-org my-org

# Deploy using manifest file (package.xml)
sf project deploy start --manifest manifest/package.xml --target-org my-org

# Deploy specific component or directory
sf project deploy start --source-dir force-app/main/default/classes --target-org my-org

# Validate deployment without saving changes (check-only)
sf project deploy start --dry-run --manifest manifest/package.xml --target-org my-org
```

### 3. Retrieve Metadata from Org
```bash
# Retrieve metadata using manifest
sf project retrieve start --manifest manifest/package.xml --target-org my-org

# Retrieve specific metadata component
sf project retrieve start --metadata ApexClass:MyClassName --target-org my-org
```

### 4. Running Apex Tests
```bash
# Run all tests in the target org
sf apex run test --code-coverage --result-format human --target-org my-org

# Run specific test class
sf apex run test --class-names MyTestClass --result-format human --target-org my-org
```

---

## Version Information
- **Source API Version**: `64.0`
- **Default Package Directory**: `force-app`
