// @ts-check
'strict'
import { LightningElement, wire } from 'lwc';
import installMessageChannel from '@salesforce/apex/MessageChannelController.install';
import getAgentAssistMessageChannel from '@salesforce/apex/MessageChannelController.getAgentAssistMessageChannel';
// @ts-expect-error This function does exist: https://developer.salesforce.com/docs/platform/lwc/guide/apex-result-caching.html
import { refreshApex } from "@salesforce/apex";

/**    
 * @typedef {{
 *  name: string;
 *  id: string;
 *  routingType: string;
 *  targetQueueId: string;
 *  url: string;
 * } | null} MessagingChannelWithUrl
 * 
 * @typedef {{
 *  name: string;
 *  url: string;
 *  routingType: string;
 *  targetQueueId: string;
 *  status: string;
 * }[]} TableData
 */ 
const TABLE_COLS = [
    { label: 'Resource name', fieldName: 'name' },
    // { label: 'Routing Type', fieldName: 'routingType' },
    // { label: 'Queue ID', fieldName: 'targetQueueId' },
    { label: 'URL', fieldName: 'url', type: 'url' },
]

export default class SetupAssistant extends LightningElement {
    isLoading = false;
    isSuccess = false;
    error;

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

    shouldDisplayInstallBtn = true;

    channelUrl = ''

    @wire(getAgentAssistMessageChannel)
    wiredResources(params) {
        this.__wiredResult = params

        const {error, data} = params

        const errors = []

        if (error) {
            console.error(error);
            this.tableData = undefined
            errors.push(error)
        }

        /**
         * @type {MessagingChannelWithUrl}
         */
        const item = data

        if(!item) {
            this.shouldDisplayInstallBtn = true;
            return;
        }

        this.channelUrl = item.url

        this.tableData = [{
            ...item,
            status: item.url ? 'Deployed' : 'Not Deployed',
        }]

        if(errors.length) {
            this.error = errors.join('\n')
            this.shouldDisplayInstallBtn = false
        } else {
            this.error = undefined;
            this.isSuccess = true
            this.shouldDisplayInstallBtn = false
        }
    }

    async handleDeploy() {
        this.isLoading = true;
        this.error = null;
        this.isSuccess = false;

        try {

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
