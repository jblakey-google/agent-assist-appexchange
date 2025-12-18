/**
 * @fileoverview A controller for the External Client App `contactEmail` view.
 */

// @ts-check
import { LightningElement } from 'lwc';
import createExternalClientApp from '@salesforce/apex/ExternalClientApp.create';
// @ts-expect-error This is an old deprecated implementation.
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class ExternalClientAppForm extends LightningElement {
    /**
     * @type {string}
     * 
     * @description The email of the contact to create the external client app for.
     * 
     * @default ''
     */
    contactEmail = '';

    doesExternalAppExist = false;

    isLoading = false;

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
