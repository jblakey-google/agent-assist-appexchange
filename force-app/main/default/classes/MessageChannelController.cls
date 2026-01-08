public class MessageChannelController {

    @AuraEnabled
    public static void install() {
        try {
            Group queue = ensureQueueExists(Config.MESSAGING_QUEUE.get('LABEL'), Config.MESSAGING_QUEUE.get('NAME'));
            
            ensureQueueSupportsObject(queue.Id, 'MessagingSession');

            createEnhancedChannel(Config.MESSAGING_CHANNEL.get('LABEL'), queue.Id);
            
        } catch (Exception e) {
            System.debug('Installation Error: ' + e.getMessage());
            throw new AuraHandledException('There was an issue installing MessagingChannel.');
        }
    }

    private static Group ensureQueueExists(String label, String developerName) {
        List<Group> groups = [SELECT Id FROM Group WHERE DeveloperName = :developerName AND Type = 'Queue' LIMIT 1];
        
        if (!groups.isEmpty()) {
            return groups[0];
        }

        Group newQueue = new Group(
            Name = label,
            DeveloperName = developerName,
            Type = 'Queue'
        );

        insert newQueue;

        return newQueue;
    }

    private static void ensureQueueSupportsObject(Id queueId, String objectType) {
        List<QueueSobject> qsos = [SELECT Id FROM QueueSobject WHERE QueueId = :queueId AND SobjectType = :objectType LIMIT 1];
        
        if (qsos.isEmpty()) {
            QueueSobject qso = new QueueSobject(
                QueueId = queueId,
                SobjectType = objectType
            );

            insert qso;
        }
    }

    private static void createEnhancedChannel(String channelName, Id queueId) {
        System.debug(LoggingLevel.DEBUG, '[createEnhancedChannel] Starting with channelName ' + channelName + ' and queueId ' + queueId);

        // Check if channel already exists to prevent duplicates
        List<MessagingChannel> existingChannels = [SELECT Id FROM MessagingChannel WHERE MasterLabel = :channelName LIMIT 1];
        if (!existingChannels.isEmpty()) {
            System.debug(LoggingLevel.DEBUG, '[createEnhancedChannel] Channel already exists.');
            return; 
        }


        MessagingChannel channel = new MessagingChannel();
        channel.MasterLabel = channelName;
        channel.DeveloperName = channelName.replaceAll('\\s+', '_');
        
        channel.MessageType = 'EmbeddedMessaging';
        
        channel.PlatformType = 'Enhanced';
        
        /*
        Keeping this here as a reminder -- I attempted to set these two values programmatically with this and also via REST,
        but neither worked. For the time being, users will have to manually attach the queue to the channel via the UI.
        
        channel.RoutingType = 'OmniQueue';

        channel.TargetQueueId = queueId;
        */
        
        channel.IsActive = true; 

        channel.Description = 'Messaging Channel for Agent Assist';

        insert channel;

        System.debug(LoggingLevel.DEBUG, '[createEnhancedChannel] Channel created!');
    }

    public class MessagingChannelWithUrl {
        @AuraEnabled
        public String name;
        @AuraEnabled
        public Id id;
        @AuraEnabled
        public String routingType;
        @AuraEnabled
        public String url;
        @AuraEnabled
        public Id targetQueueId;

        public MessagingChannelWithUrl(String name, Id id, String routingType, String url, Id targetQueueId) {
            this.name = name;
            this.id = id;
            this.routingType = routingType;
            this.url = url;
            this.targetQueueId = targetQueueId;
        }
    }

    @AuraEnabled(cacheable=true)
    public static MessagingChannelWithUrl getAgentAssistMessageChannel() {
        System.debug(LoggingLevel.DEBUG, '[getAgentAssistMessageChannel] Retrieving MessagingChannel via SOQL.');

        List<MessagingChannel> channels = [SELECT Id, RoutingType, TargetQueueId FROM MessagingChannel WHERE MasterLabel = :Config.MESSAGING_CHANNEL.get('LABEL') LIMIT 1];

        if(channels.isEmpty()) {
            System.debug(LoggingLevel.DEBUG, '[getAgentAssistMessageChannel] SOQL query returned empty.');

            return null;
        }

        MessagingChannel channel = channels[0];

        System.debug(LoggingLevel.DEBUG, '[getAgentAssistMessageChannel] Retrieved channel' + '\n Routing Type:' + channel.RoutingType + '\n Queue ID: ' + channel.TargetQueueId);

        return new MessagingChannelWithUrl(
            Config.MESSAGING_CHANNEL.get('LABEL'),
            channel.Id,
            channel.RoutingType,
            ResourceLinksGenerator.getMessagingChannelUrl(Config.MESSAGING_CHANNEL.get('NAME')),
            channel.TargetQueueId
        );
    }
}