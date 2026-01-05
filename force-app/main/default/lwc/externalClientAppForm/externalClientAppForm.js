/**
 * @fileoverview A controller for the External Client App `contactEmail` view.
 */

// @ts-check
import { LightningElement, wire } from 'lwc';
import createExternalClientApp from '@salesforce/apex/ExternalClientApp.create';
import getExistingECA from '@salesforce/apex/ExternalClientApp.getExistingECA';
// @ts-expect-error This is an old deprecated implementation.
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
// @ts-expect-error This function does exist: https://developer.salesforce.com/docs/platform/lwc/guide/apex-result-caching.html
import { refreshApex } from "@salesforce/apex";

export default class ExternalClientAppForm extends LightningElement {
    /**
     * @description Retrieves the ECA's record via Apex DML.
     */
    @wire(getExistingECA)
    wiredResources(params) {
        this.__wiredResult = params;

        const {data, error} = params;

        if (error) {
            console.error('Error checking if external client app exists:', error);  
        }

        /**
         * @type {{
         *  Id: string;
         *  ContactEmail: string;
         * }[] | undefined}
         */
        const ecaList = data;

        if (Array.isArray(ecaList) && ecaList.length > 0) {
            const eca = ecaList[0];

            this.doesExternalAppExist = true;
            this.contactEmail  = eca.ContactEmail;
            this.ecaId = eca.Id
        }
    }

    __wiredResult = null;
    /**
     * @type {string}
     * 
     * @description The email of the contact to create the external client app for.
     * 
     * @default ''
     */
    contactEmail = '';

    /**
     * The External Client App Id for the record found via `getExistingECA`.
     */
    ecaId = ''

    /**
     * Indicates whether a record for the ECA's developer name was found in Salesforce. 
     */
    doesExternalAppExist = false;

    isLoading = false;

    /**
     * @description Opens the GCP AA Client App's page in a new tab. The URL requires a truncated Id, hence `slice`.
     */
    handleNavigateToEcaSettings() {
        window.open(`/lightning/setup/ManageExternalClientApplication/${this.ecaId.slice(0, -3)}/detail/`, '_blank');
    }

    /**
     * @description Updates the contactEmail on change.
     * 
     * @param {InputEvent} event 
     */
    handleEmailChange(event) {
        if("value" in event.target && typeof event.target.value === "string") {
            this.contactEmail = event.target.value;
        }
    }


    /**
     * @description A click handler that creates the external client app.
     */
    async handleCreate() {
        if (!this.contactEmail) {
            this.showToast('Error', 'Please fill in all fields', 'error');
            return;
        }

        try {
            this.isLoading = true;

            await createExternalClientApp({ contactEmail: this.contactEmail })

            this.showToast('Success', 'External Client App created successfully', 'success');
            
            await refreshApex(this.__wiredResult)
        
            this.contactEmail = '';
        } catch(error) {
                let message = 'Unknown error';

                if (Array.isArray(error.body)) {
                    message = error.body.map(e => e.message).join(', ');
                } else if (typeof error.body.message === 'string') {
                    message = error.body.message;
                }

                this.showToast('Error', 'Error creating external client app: ' + message, 'error');

                console.error('Error creating external client app:', error);
        } finally {
            this.isLoading = false;
        }
    }

    /**
     * @description Shows a toast message.
     * 
     * @param {string} title 
     * @param {string} message 
     * @param {string} variant 
     */
    showToast(title, message, variant) {
        const event = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant
        });
        this.dispatchEvent(event);
    }
}
