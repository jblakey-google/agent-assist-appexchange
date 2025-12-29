public class ResourceLinksGenerator {

    /**
     * Retrieves a list of resource data, like link to the resource in the SF UI, SObject type, and developer name.
     */
    @AuraEnabled(cacheable=true)
    public static List<ResourceItem> getResourceUrls() {
        return new List<ResourceItem>{
            new ResourceItem(
                getServiceChannelUrl(Config.SERVICE_CHANNEL.get('MESSAGING_NAME')),
                'ServiceChannel',
                Config.SERVICE_CHANNEL.get('MESSAGING_NAME')
            ),
            new ResourceItem(
                getServiceChannelUrl(Config.SERVICE_CHANNEL.get('PHONE_NAME')),
                'ServiceChannel',
                Config.SERVICE_CHANNEL.get('PHONE_NAME')
            ),
            new ResourceItem(
                getQueueUrl(Config.MESSAGING_QUEUE.get('NAME')),
                'Queue',
                Config.MESSAGING_QUEUE.get('NAME')
            ),
            new ResourceItem(
                getQueueRoutingConfigUrl(Config.ROUTING_QUEUE_CONFIG.get('NAME')),
                'QueueRoutingConfig',
                Config.ROUTING_QUEUE_CONFIG.get('NAME')
            ),
            new ResourceItem(
                getExternalClientAppUrl(),
                'ExternalClientApplication',
                Config.EXTERNAL_CLIENT_APP.get('NAME')
            ),
            new ResourceItem(
                getServicePresenceStatusUrl(Config.SERVICE_PRESENCE.get('STATUS_ONLINE_NAME')),
                'ServicePresenceStatus',
                Config.SERVICE_PRESENCE.get('STATUS_ONLINE_NAME')
            ),
            new ResourceItem(
                getPermissionSetUrl(Config.SERVICE_PRESENCE.get('PERMISSION_SET_NAME')),
                'PermissionSet',
                Config.SERVICE_PRESENCE.get('PERMISSION_SET_NAME')
            ),
            new ResourceItem(
                getMessagingChannelUrl(Config.MESSAGING_CHANNEL.get('NAME')),
                'MessagingChannel',
                Config.MESSAGING_CHANNEL.get('NAME')
            )
        };
    }

    public static String getMessagingChannelUrl(String developerName) {
        try {
            MessagingChannel channel = [SELECT Id FROM MessagingChannel WHERE DeveloperName = :developerName LIMIT 1];
            
            return Url.getOrgDomainUrl().toExternalForm() + '/lightning/setup/LiveMessageSetup/' + channel.Id + '/view';
        } catch (Exception e) {
            return null;
        }
    }

    public static String getServiceChannelUrl(String developerName) {
        ServiceChannel channel = [SELECT Id FROM ServiceChannel WHERE DeveloperName = :developerName LIMIT 1];

        return Url.getOrgDomainUrl().toExternalForm() + generateSetupPageLinkByResourceAndId('ServiceChannel', channel.Id);
    }

    public static String getQueueUrl(String developerName) {
        try {
            Group queue = [SELECT Id FROM Group WHERE DeveloperName = :developerName AND Type = 'Queue' LIMIT 1];
            return Url.getOrgDomainUrl().toExternalForm() + 
                   '/lightning/setup/Queues/page?address=%2Fp%2Fown%2FQueue%2Fd%3Fid%3D' + queue.Id;
        } catch (Exception e) {
            return null;
        }
    }

    public static String getServicePresenceStatusUrl(String developerName) {
        try {
            ServicePresenceStatus status = [SELECT Id FROM ServicePresenceStatus WHERE DeveloperName = :developerName LIMIT 1];

            return Url.getOrgDomainUrl().toExternalForm() + generateSetupPageLinkByResourceAndId('ServicePresenceStatus', status.Id);
        } catch(Exception e) {
            return null;
        }
    }

    public static String getPermissionSetUrl(String developerName) {
        try {
            PermissionSet permSet = [SELECT Id FROM PermissionSet WHERE Name = :developerName LIMIT 1];

            return Url.getOrgDomainUrl().toExternalForm() + generateSetupPageLinkByResourceAndId('PermSets', permSet.Id);
        } catch(Exception e) {
            return null;
        }
    }

    public static String getQueueRoutingConfigUrl(String developerName) {
        try {
            QueueRoutingConfig config = [SELECT Id FROM QueueRoutingConfig WHERE DeveloperName = :developerName LIMIT 1];

            return Url.getOrgDomainUrl().toExternalForm() + generateSetupPageLinkByResourceAndId('QueueRoutingConfig', config.Id);
        } catch(Exception e) {
            return null;
        }
    }

    public static String getExternalClientAppUrl() {
        return Url.getOrgDomainUrl().toExternalForm() + '/lightning/setup/ExternalClientApp/home';
    }

    private static String generateSetupPageLinkByResourceAndId(String resourceName, Id resourceId) {
        return '/lightning/setup/'+ resourceName + '/page?address=%2F' + resourceId;
    }
}