import { LightningElement, wire } from 'lwc';
import { publish, MessageContext } from 'lightning/messageService';
import AGENT_ASSIST_CHANNEL from '@salesforce/messageChannel/Agent_Assist__c';

export default class MessageSender extends LightningElement {
    @wire(MessageContext)
    messageContext;

    handlePostMessage() {
        // Post a message to the window
        const payload = {
            source: 'messageSender',
            message: 'Hello from window.postMessage',
            timestamp: new Date().toISOString()
        };
        window.postMessage(payload, '*');
        console.log('messageSender sent window message');
    }

    handleLMSMessage() {
        const payload = {
            source: 'messageSender',
            message: 'Hello from LMS',
            timestamp: new Date().toISOString()
        };
        publish(this.messageContext, AGENT_ASSIST_CHANNEL, payload);
        console.log('messageSender sent LMS message');
    }
}
