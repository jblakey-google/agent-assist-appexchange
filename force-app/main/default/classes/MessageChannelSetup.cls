public class MessageChannelSetup {

    @AuraEnabled
    public static void install() {
        try {
            // 1. Handle the Queue (Steps 4)
            Group queue = ensureQueueExists('Agent Assist', 'Agent_Assist');
            
            // 2. Ensure Queue supports MessagingSession objects
            ensureQueueSupportsObject(queue.Id, 'MessagingSession');

            // 3. Create the Messaging Channel (Steps 1-3, 5, 6)
            createEnhancedChannel('Messaging Channel', queue.Id);
            
        } catch (Exception e) {
            System.debug('Installation Error: ' + e.getMessage());
            throw e;
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
        // Check if channel already exists to prevent duplicates
        List<MessagingChannel> existingChannels = [SELECT Id FROM MessagingChannel WHERE MasterLabel = :channelName LIMIT 1];
        if (!existingChannels.isEmpty()) {
            return; 
        }

        MessagingChannel channel = new MessagingChannel();
        channel.MasterLabel = channelName;
        channel.DeveloperName = channelName.replaceAll('\\s+', '_'); // e.g., Messaging_Channel
        
        // "Enhanced Chat" corresponds to the 'EmbeddedMessaging' type
        channel.MessageType = 'EmbeddedMessaging';
        
        // For EmbeddedMessaging, we generate a unique Platform Key (UUID)
        // This mimics the backend provisioning that happens in the UI
        channel.MessagingPlatformKey = UUID.randomUUID().toString();
        
        // Routing Configuration (Step 4)
        channel.RoutingType = 'OmniQueue';
        channel.TargetQueueId = queueId; // Links to "Messaging Queue"
        
        // Activation (Step 6)
        channel.IsActive = true; 

        // Additional required fields for context
        channel.Description = 'Created via Package Installer';

        insert channel;
    }
}