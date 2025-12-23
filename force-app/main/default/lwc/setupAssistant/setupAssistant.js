import { LightningElement, track } from 'lwc';
import deployMetadata from '@salesforce/apex/SetupAssistantController.deployMetadata';
import setupEmbeddedServiceDeploy from '@salesforce/apex/EmbeddedServiceSetup.createDeployment';
import setupMessageChannel from '@salesforce/apex/MessageChannelSetup.install';
import getSiteInfo from '@salesforce/apex/SiteDiscovery.getSiteInfo';

export default class SetupAssistant extends LightningElement {
    @track isLoading = false;
    @track isSuccess = false;
    @track error;
    siteName = '';

    handleNameChange(event) {
        this.siteName = event.target.value;
    }

    get isDeployButtonDisabled() {
        return this.isLoading || !this.siteName;
    }
    
    async handleDeploy() {
        this.isLoading = true;
        this.error = null;
        this.isSuccess = false;

        try {
            
            await deployMetadata()
            
            /**
             * @type {{
             *  siteDeveloperName: string;
             *  siteId: string
             * }}
             */
            const siteInfo = await getSiteInfo({ siteName: this.siteName })
    
            await setupMessageChannel()
            
            await setupEmbeddedServiceDeploy({ siteDeveloperName: siteInfo.siteDeveloperName })

            this.isSuccess = true;

        } catch(error ){
                this.error = error.body ? error.body.message : error.message;
        } finally {
                this.isLoading = false;
        }
    }
}
