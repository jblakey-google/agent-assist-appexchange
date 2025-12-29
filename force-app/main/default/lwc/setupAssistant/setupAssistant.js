// @ts-check
'strict'
import { LightningElement, track, wire } from 'lwc';
import deployMetadata from '@salesforce/apex/SetupAssistantController.deployMetadata';
import getResourceUrls from '@salesforce/apex/ResourceLinksGenerator.getResourceUrls';
import installMessageChannel from '@salesforce/apex/MessageChannelSetup.install';
// @ts-expect-error This function does exist: https://developer.salesforce.com/docs/platform/lwc/guide/apex-result-caching.html
import { refreshApex } from "@salesforce/apex";

/**    
 * @typedef {{
 *  url: string;
 *  type: string;
 *  name: string
 * }[]} ResourceItems
 * 
 * @typedef {{
 *  url: string;
 *  type: string;
 *  name: string;
 *  status: string;
 * }[]} TableData
 */ 
const TABLE_COLS = [
    { label: 'Resource name', fieldName: 'name' },
    { label: 'Type', fieldName: 'type' },
    { label: 'URL', fieldName: 'url', type: 'url' },
    { label: 'Status', fieldName: 'status' },
]

export default class SetupAssistant extends LightningElement {
    @track isLoading = false;
    @track isSuccess = false;
    @track error;

    __wiredResult;

    /**
     * Resource information to display in the lightning table.
     * 
     * @type {TableData | undefined}
     */ 
    tableData

    /**
     * A map of column information for the lightning table.
     */
    tableCols = TABLE_COLS

    /**
     * @description Indicates whether all resources contain a link, which translates to whether an SOQL
     * query returned a record for a resource.
     */
    areAllResourcesDeployed = false;

    @wire(getResourceUrls)
    wiredResources(params) {
        this.__wiredResult = params

        const {error, data} = params
        /**
         * @type {ResourceItems}
         */
        const items = data
        if (Array.isArray(items) && items.length) {
            this.areAllResourcesDeployed = items.every(resource => typeof resource.url === 'string' && resource.url.length > 0)

            this.tableData = items.map(resource => ({
                ...resource,
                status: resource.url ? 'Deployed' : 'Not Deployed',
            }));

            this.error = undefined;
        } else if (error) {
            console.error(error);
            this.tableData = undefined
        }
    }

    get resourcesAreNotDeployed () {
        return !this.areAllResourcesDeployed;
    }

    async handleDeploy() {
        this.isLoading = true;
        this.error = null;
        this.isSuccess = false;

        try {
            await deployMetadata()

            await installMessageChannel()

            this.isSuccess = true;

            await refreshApex(this.__wiredResult)
        } catch(error) {
                this.error = error.body ? error.body.message : error.message;
        } finally {
            this.isLoading = false;
        }
    }
}
