import { LightningElement } from 'lwc';
import setupApp from '@salesforce/apex/ExternalClientAppCreator.setupApp';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class ExternalClientAppForm extends LightningElement {
    contactEmail = '';
    isLoading = false;

    handleEmailChange(event) {
        this.contactEmail = event.target.value;
    }


    async handleCreate() {
        if (!this.contactEmail) {
            this.showToast('Error', 'Please fill in all fields', 'error');
            return;
        }

        this.isLoading = true;

        try {
            await setupApp({ contactEmail: this.contactEmail }).catch(err).

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

    showToast(title, message, variant) {
        const event = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant
        });
        this.dispatchEvent(event);
    }
}
