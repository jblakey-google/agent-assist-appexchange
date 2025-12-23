/*
TODO:
- Find out how to get siteId
*/
public class EmbeddedServiceSetup {

    @AuraEnabled
    public static void createDeployment(String siteDeveloperName) {
        Map<String, Object> channelConfig = new Map<String, Object>{
            'messagingChannel' => 'Messaging_Channel',
            'isEnabled' => true,
            // API 64.0 often requires these defaults to be explicit
            'shouldShowDeliveryReceipts' => false,
            'shouldShowReadReceipts' => false,
            'shouldShowTypingIndicators' => false,
            'shouldStartNewLineOnEnter' => false,
            'shouldShowEmojiSelection' => false
        };

        // 2. Define the Metadata Structure
        Map<String, Object> metadataContent = new Map<String, Object>{
            'masterLabel' => 'Messaging Embedded Service Deployment',
            'deploymentFeature' => 'EmbeddedMessaging',
            'site' => siteDeveloperName + '1',
            'deploymentType' => 'Web',
            'areGuestUsersAllowed' => false,
            'isEnabled' => true,
            'embeddedServiceMessagingChannel' => channelConfig // NESTED HERE
        };

        // 3. Wrap for Tooling API
        Map<String, Object> payload = new Map<String, Object>{
            'FullName' => 'Messaging_Embedded_Service_Deployment',
            'Metadata' => metadataContent
        };

        // 2. Construct the HTTP Request
        HttpRequest req = new HttpRequest();
        req.setEndpoint(Url.getOrgDomainUrl().toExternalForm() + '/services/data/v60.0/tooling/sobjects/EmbeddedServiceConfig');
        req.setMethod('POST');
        req.setHeader('Authorization', 'OAuth ' + UserInfo.getSessionId()); // Uses current session
        req.setHeader('Content-Type', 'application/json');
        req.setBody(JSON.serialize(payload));

        // 3. Send Request
        Http http = new Http();
        HttpResponse res = http.send(req);

        if (res.getStatusCode() == 201) {
            System.debug('Success! Deployment Created. ID: ' + res.getBody());
        } else {
            System.debug('Error: ' + res.getBody());
            throw new AuraHandledException('Error: ' + res.getBody());
        }
    }
}