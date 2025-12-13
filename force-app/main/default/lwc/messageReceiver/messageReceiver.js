import { LightningElement, wire, track } from 'lwc';
import { subscribe, MessageContext, APPLICATION_SCOPE } from 'lightning/messageService';
import AGENT_ASSIST_CHANNEL from '@salesforce/messageChannel/Agent_Assist__c';

export default class MessageReceiver extends LightningElement {
    greeting = 'World';
    @track messages = [];

    @wire(MessageContext)
    messageContext;

    subscription = null;

    connectedCallback() {
        this.subscribeToMessageChannel();
        window.addEventListener('message', this.handleWindowMessage);
    }

    disconnectedCallback() {
        window.removeEventListener('message', this.handleWindowMessage);
        // Subscription is automatically cleaned up by LWC, but good to know.
    }

    subscribeToMessageChannel() {
        if (!this.subscription) {
            this.subscription = subscribe(
                this.messageContext,
                AGENT_ASSIST_CHANNEL,
                (message) => this.handleLMSMessage(message),
                { scope: APPLICATION_SCOPE }
            );
        }
    }

    handleLMSMessage(message) {
        console.log('MessageReceiver LWC received LMS Message:', JSON.stringify(message));
        this.messages.push({
            source: 'LMS',
            message: message.message,
            timestamp: message.timestamp || new Date().toISOString()
        });
    }

    handleWindowMessage = (event) => {
        // Log all messages as requested
        console.log('MessageReceiver LWC received Window Message:', event.data);
        if (event.data && event.data.source === 'messageSender') {
             this.messages.push({
                source: 'Window',
                message: event.data.message,
                timestamp: event.data.timestamp || new Date().toISOString()
            });
        }
    }

    changeHandler(event) {
        this.greeting = event.target.value;
    }
}
