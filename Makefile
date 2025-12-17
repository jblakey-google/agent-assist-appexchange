.PHONY: help config org-login org-list org-open org-scratch-create org-delete-scratch deploy-preview deploy-start retrieve-preview retrieve-start package-version-list package-version-create package-version-install package-version-uninstall apex-run apex-run-file apex-list-log apex-run-test apex-run-test-file data-query get-setup-urls

PKG ?= agent-assist-experimental
PKG_FLAG = $(if $(PKG),--package $(PKG),)

help: ## Display this help message
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m<target>\033[0m\n\nTargets:\n"} /^[a-zA-Z0-9_-]+:.*?##/ { printf "  \033[36m%-30s\033[0m %s\n", $$1, $$2 }' $(MAKEFILE_LIST)

config: ## List all config settings
	sf config list

org-login: ## Login to an org using web login
	sf org login web

org-list: ## List all orgs authenticated to the CLI
	sf org list

org-open: ## Open the default org in a browser
	sf org open

org-scratch-create: ## Create a new scratch org
	sf org scratch create -f config/project-scratch-def.json --duration-days 1 --set-default --alias scratch
	sf apex run -f scripts/apex/modifyAppMenu.apex > /dev/null

org-delete-scratch: ## Delete the scratch org
	sf org delete scratch

deploy-preview: ## Deploy source to default org in preview mode
	sf project deploy preview

deploy-start: ## Deploy source to default org in start mode
	sf project deploy start

retrieve-preview: ## Retrieve source from default org in preview mode
	sf project retrieve preview

retrieve-start: ## Retrieve source from default org in start mode
	sf project retrieve start

package-version-list: ## List package versions in the Dev Hub org
	sf package version list --concise --packages $(PKG) | tail -n 5

package-version-create: ## Create a new package version using $PKG
	sf package version create --installation-key-bypass --package $(PKG) --definition-file config/project-scratch-def.json --wait 10

package-version-install: ## Install the latest package version
	@echo "Installing latest package version..."
	@LATEST_VERSION=$$(sf package version list --packages $(PKG) --concise --json | jq -r '.result | sort_by(.CreatedDate) | reverse | .[0].SubscriberPackageVersionId'); \
	echo "Installing latest version: $$LATEST_VERSION"; \
	sf package install --package $$LATEST_VERSION --wait 10 --publish-wait 10

package-version-uninstall: ## Uninstall the latest package version
	@echo "Finding latest package version..."
	@LATEST_VERSION=$$(sf package version list --packages $(PKG) --concise --json | jq -r '.result | sort_by(.CreatedDate) | reverse | .[0].SubscriberPackageVersionId'); \
	echo "Uninstalling latest version: $$LATEST_VERSION"; \
	sf package uninstall --package $$LATEST_VERSION --wait 10

apex-run: ## Run Apex code in scratch org in interactive mode
	sf apex run

apex-run-file: ## Run Apex code in scratch org from file
	sf apex run --file scripts/apex/hello.apex --loglevel debug | grep 'USER_'

apex-list-log: ## List debug logs in scratch org in json format
	sf apex list log --json

apex-run-test: ## Run Apex tests in scratch org
	sf apex run test --wait 1

apex-run-test-file: ## Run Apex tests in scratch org from file
	sf apex run test --file scripts/apex/hello.apex --loglevel debug | grep 'USER_'

data-query: ## Run a data query in scratch org
	sf data query -q "$(QUERY)"

get-setup-urls:
	@URL=$$(sf org display --json | jq -r '.result.instanceUrl'); \
	SETUP_URL=$$(echo "$$URL" | sed 's/salesforce/salesforce-setup/g'); \
	LIGHTNING_URL=$$(echo "$$URL" | sed 's/my.salesforce.com/lightning.force.com/g'); \
	echo "Service Console: $${LIGHTNING_URL}/lightning/page/home"; \
	echo "Apex Classes: $${SETUP_URL}/lightning/setup/ApexClasses/home"; \
	echo "CORS: $${SETUP_URL}/lightning/setup/CorsWhitelistEntries/home"; \
	echo "Debug Mode: $${SETUP_URL}/lightning/setup/UserDebugModeSetup/home"; \
	echo "Digital Experiences: $${SETUP_URL}/lightning/setup/NetworkSettings/home"; \
	echo "External Client App Manager: $${SETUP_URL}/lightning/setup/ManageExternalClientApplication/home"; \
	echo "Installed Packages: $${SETUP_URL}/lightning/setup/ImportedPackage/home"; \
	echo "Lightning Components: $${SETUP_URL}/lightning/setup/LightningComponentBundles/home"; \
	echo "Lightning Experience App Manager: $${SETUP_URL}/lightning/setup/NavigationMenus/home"; \
	echo "Manage Users: $${SETUP_URL}/lightning/setup/ManageUsers/home"; \
	echo "Messaging Settings: $${SETUP_URL}/lightning/setup/LiveMessageSetup/home"; \
	echo "Omni-Channel Settings: $${SETUP_URL}/lightning/setup/OmniChannelSettings/home"; \
	echo "Permission Sets: $${SETUP_URL}/lightning/setup/PermSets/home"; \
	echo "Profiles: $${SETUP_URL}/lightning/setup/EnhancedProfiles/home"; \
	echo "Queues: $${SETUP_URL}/lightning/setup/Queues/home"; \
	echo "Service Cloud Voice Partner Telephony: $${SETUP_URL}/lightning/setup/ServiceCloudVoicePartnerTelephony/home"; \
	echo "Trusted URLs: $${SETUP_URL}/lightning/setup/SecurityCspTrustedSite/home"; \
	echo "Routing Configurations: $${SETUP_URL}/lightning/setup/QueueRoutingConfigSettings/home"; \
	echo "Service Channels: $${SETUP_URL}/lightning/setup/ServiceChannelSettings/home";