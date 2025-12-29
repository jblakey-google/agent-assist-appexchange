public class MessageChannelSetup {

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
        
        channel.RoutingType = 'OmniQueue';
        channel.TargetQueueId = queueId; // Links to "Messaging Queue"
        
        channel.IsActive = true; 

        channel.Description = 'Messaging Channel for Agent Assist';

        insert channel;

        System.debug(LoggingLevel.DEBUG, '[createEnhancedChannel] Channel created!');
    }
}