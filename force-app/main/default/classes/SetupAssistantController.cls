public with sharing class SetupAssistantController {

    private static final String QUEUE_DEVELOPER_NAME = 'Agent_Assist';

    @AuraEnabled
    public static String deployMetadata() {
        try {
            String sessionId = getSessionIdFromVF();
            String userId = UserInfo.getUserId();
            
            // --- PHASE 1: Callouts (Metadata API) ---
            // Must happen BEFORE any DML to avoid "Uncommitted Work" errors
            
            // 1. Enable Features (Make MessagingSession/VoiceCall available)
            deploySettings(sessionId); 
            
            // 2. Create Routing Config & Channels
            deployQueueRoutingConfig(sessionId);
            deployServiceChannel(sessionId); 
            
            // 3. Create Statuses & Perm Set (But don't assign yet)
            deployServicePresenceStatus(sessionId); 
            deployPresencePermissionSet(sessionId); 
            
            // --- PHASE 2: DML (Database Operations) ---
            // 4. Create the Queue (Group) record
            createAgentAssistQueue();

            assignCurrentUserToQueue(userId);
            
            // 5. Link the Queue to the Routing Config
            linkQueueToConfig();

            // 6. Assign the Permission Set to the Current User (The Final Step)
            assignPermissionSetToCurrentUser(userId);
            
            return 'Success';
        } catch (Exception e) {
            System.debug('Setup Failed: ' + e.getMessage() + '\n' + e.getStackTraceString());
            throw new AuraHandledException('Error: ' + e.getMessage());
        }
    }

    // --- NEW: Auto-Assign the Perm Set ---
    private static void assignPermissionSetToCurrentUser(String currentUserId) {
        try {
            // 1. Find the Perm Set we just created
            List<PermissionSet> ps = [SELECT Id FROM PermissionSet WHERE Name = 'Agent_Assist_Messaging' LIMIT 1];
            if (ps.isEmpty()) return;
            
            // 2. Check if already assigned
            List<PermissionSetAssignment> existing = [
                SELECT Id FROM PermissionSetAssignment 
                WHERE AssigneeId = :currentUserId AND PermissionSetId = :ps[0].Id
            ];
            
            // 3. Assign if missing
            if (existing.isEmpty()) {
                PermissionSetAssignment psa = new PermissionSetAssignment();
                psa.AssigneeId = currentUserId;
                psa.PermissionSetId = ps[0].Id;
                insert psa;
            }
        } catch (Exception e) {
            System.debug('Failed to assign permission set: ' + e.getMessage());
        }
    }

    private static void createAgentAssistQueue() {
        List<Group> existingQueues = [SELECT Id FROM Group WHERE Type = 'Queue' AND DeveloperName = :QUEUE_DEVELOPER_NAME LIMIT 1];
        if (!existingQueues.isEmpty()) {
            return;
        }

        Group agentAssistQueue = new Group();
        agentAssistQueue.Name = 'Agent Assist';
        agentAssistQueue.DeveloperName = QUEUE_DEVELOPER_NAME;
        agentAssistQueue.Type = 'Queue';
        agentAssistQueue.DoesSendEmailToMembers = false;
        insert agentAssistQueue;

        // Note: GlobalDescribe might catch the new objects immediately after metadata enable, 
        // but in some edge cases, it might require a page refresh. 
        // For a setup script, this is the best we can do in one transaction.
        List<QueueSobject> queueSobjects = new List<QueueSobject>();
        Map<String, Schema.SObjectType> globalDesc = Schema.getGlobalDescribe();

        if (globalDesc.containsKey('MessagingSession')) {
            QueueSobject msgSessionQ = new QueueSobject();
            msgSessionQ.QueueId = agentAssistQueue.Id;
            msgSessionQ.SobjectType = 'MessagingSession';
            queueSobjects.add(msgSessionQ);
        }

        if (globalDesc.containsKey('VoiceCall')) {
            QueueSobject voiceCallQ = new QueueSobject();
            voiceCallQ.QueueId = agentAssistQueue.Id;
            voiceCallQ.SobjectType = 'VoiceCall';
            queueSobjects.add(voiceCallQ);
        }

        if (!queueSobjects.isEmpty()) {
            insert queueSobjects;
        }
    }

    private static void assignCurrentUserToQueue(Id userId) {
        try {
            Group queue = [SELECT Id FROM Group WHERE Type = 'Queue' AND DeveloperName = :QUEUE_DEVELOPER_NAME LIMIT 1];
            
            Integer existing = [SELECT Count() FROM GroupMember 
                                WHERE GroupId = :queue.Id AND UserOrGroupId = :userId];
            
            if (existing == 0) {
                GroupMember assignment = new GroupMember(
                    GroupId = queue.Id,
                    UserOrGroupId = userId
                );
                insert assignment;
                System.debug('User assigned to queue: ' + QUEUE_DEVELOPER_NAME);
            }
        } catch (QueryException e) {
            System.debug(LoggingLevel.ERROR, '[assignCurrentUserToQueue] Queue not found: ' + QUEUE_DEVELOPER_NAME + '\n ' + e.getMessage());
            throw new CalloutException('[assignCurrentUserToQueue] Queue not found: ' + QUEUE_DEVELOPER_NAME + '\n ' + e.getMessage());
        } catch (Exception e) {
            System.debug('[assignCurrentUserToQueue] Failed to assign user to queue.');
            throw new CalloutException('[assignCurrentUserToQueue] Error when assigning user to queue: ' + QUEUE_DEVELOPER_NAME + '\n ' + e.getMessage());
        }
    }

    private static void deploySettings(String sessionId) {
        String body = 
            '<met:updateMetadata xmlns:met="http://soap.sforce.com/2006/04/metadata">' +
                '<met:metadata xsi:type="met:LiveMessageSettings" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">' +
                    '<met:fullName>LiveMessage</met:fullName>' + 
                    '<met:enableLiveMessage>true</met:enableLiveMessage>' +
                '</met:metadata>' +
                '<met:metadata xsi:type="met:ServiceCloudVoiceSettings" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">' +
                    '<met:fullName>ServiceCloudVoice</met:fullName>' +
                    '<met:enableSCVExternalTelephony>true</met:enableSCVExternalTelephony>' +
                    '<met:enableServiceCloudVoice>true</met:enableServiceCloudVoice>' +
                '</met:metadata>' +
            '</met:updateMetadata>';
        sendMetadataRequest(body, sessionId);
    }

    private static void deployServiceChannel(String sessionId) {
        String metadataItems = '';
        if ([SELECT Count() FROM ServiceChannel WHERE DeveloperName = 'sfdc_livemessage'] == 0) {
            metadataItems += 
                '<met:metadata xsi:type="met:ServiceChannel" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">' +
                    '<met:fullName>sfdc_livemessage</met:fullName>' + 
                    '<met:label>Messaging</met:label>' +              
                    '<met:relatedEntityType>MessagingSession</met:relatedEntityType>' +
                '</met:metadata>';
        }
        if ([SELECT Count() FROM ServiceChannel WHERE DeveloperName = 'sfdc_phone'] == 0) {
            metadataItems += 
                '<met:metadata xsi:type="met:ServiceChannel" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">' +
                    '<met:fullName>sfdc_phone</met:fullName>' +       
                    '<met:label>Phone</met:label>' +                  
                    '<met:relatedEntityType>VoiceCall</met:relatedEntityType>' +
                '</met:metadata>';
        }
        if (String.isNotBlank(metadataItems)) {
            String soapBody = '<met:createMetadata xmlns:met="http://soap.sforce.com/2006/04/metadata">' + metadataItems + '</met:createMetadata>';
            sendMetadataRequest(soapBody, sessionId);
        }
    }

    private static void deployServicePresenceStatus(String sessionId) {
        if ([SELECT Count() FROM ServicePresenceStatus WHERE DeveloperName = 'Busy'] == 0) {
            String busyBody = '<met:createMetadata xmlns:met="http://soap.sforce.com/2006/04/metadata"><met:metadata xsi:type="met:ServicePresenceStatus" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"><met:fullName>Busy</met:fullName><met:label>Busy</met:label></met:metadata></met:createMetadata>';
            sendMetadataRequest(busyBody, sessionId);
        }
        if ([SELECT Count() FROM ServicePresenceStatus WHERE DeveloperName = 'Online_Messaging'] == 0) {
            String channelDevName = 'Messaging'; 
            List<ServiceChannel> channels = [SELECT DeveloperName FROM ServiceChannel WHERE RelatedEntity = 'MessagingSession' LIMIT 1];
            if (!channels.isEmpty()) channelDevName = channels[0].DeveloperName;

            String onlineBody = '<met:createMetadata xmlns:met="http://soap.sforce.com/2006/04/metadata"><met:metadata xsi:type="met:ServicePresenceStatus" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"><met:fullName>Online_Messaging</met:fullName><met:label>Online (Messaging)</met:label><met:channels><met:channel>' + channelDevName + '</met:channel></met:channels></met:metadata></met:createMetadata>';
            sendMetadataRequest(onlineBody, sessionId);
        }
    }

    private static void deployQueueRoutingConfig(String sessionId) {
        if ([SELECT Count() FROM QueueRoutingConfig WHERE DeveloperName = 'Agent_Assist'] > 0) return;
        String soapBody = '<met:createMetadata xmlns:met="http://soap.sforce.com/2006/04/metadata"><met:metadata xsi:type="met:QueueRoutingConfig" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"><met:fullName>Agent_Assist</met:fullName><met:label>Agent Assist</met:label><met:capacityPercentage>25</met:capacityPercentage><met:capacityType>INHERITED</met:capacityType><met:isAttributeBased>false</met:isAttributeBased><met:routingModel>LEAST_ACTIVE</met:routingModel><met:routingPriority>1</met:routingPriority></met:metadata></met:createMetadata>';
        sendMetadataRequest(soapBody, sessionId);
    }

    private static void linkQueueToConfig() {
        try {
            List<QueueRoutingConfig> qrcs = [SELECT Id FROM QueueRoutingConfig WHERE DeveloperName = 'Agent_Assist' LIMIT 1];
            if (qrcs.isEmpty()) return;
            List<Group> queues = [SELECT Id, QueueRoutingConfigId FROM Group WHERE Type = 'Queue' AND DeveloperName = 'Agent_Assist' LIMIT 1];
            if (!queues.isEmpty()) {
                Group g = queues[0];
                if (g.QueueRoutingConfigId != qrcs[0].Id) {
                    g.QueueRoutingConfigId = qrcs[0].Id;
                    update g;
                }
            }
        } catch (Exception e) { System.debug('Failed to link Queue: ' + e.getMessage()); }
    }

    private static void deployPresencePermissionSet(String sessionId) {
        String accessXml = '';
        for (String statusName : new List<String>{'Busy', 'Online_Messaging'}) {
            accessXml += '<met:servicePresenceStatusAccesses><met:enabled>true</met:enabled><met:servicePresenceStatus>' + statusName + '</met:servicePresenceStatus></met:servicePresenceStatusAccesses>';
        }
        String permSetBody = '<met:upsertMetadata xmlns:met="http://soap.sforce.com/2006/04/metadata"><met:metadata xsi:type="met:PermissionSet" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"><met:fullName>Agent_Assist_Messaging</met:fullName><met:label>Agent Assist Messaging</met:label><met:hasActivationRequired>false</met:hasActivationRequired>' + accessXml + '</met:metadata></met:upsertMetadata>';
        sendMetadataRequest(permSetBody, sessionId); 
    }

    private static String getSessionIdFromVF() {
        if (Test.isRunningTest()) return 'TEST_SESSION_ID';
        PageReference pageRef = Page.SessionIdGetter;
        String content = pageRef.getContent().toString();
        Integer s = content.indexOf('Start_Of_Session_Id') + 'Start_Of_Session_Id'.length();
        Integer e = content.indexOf('End_Of_Session_Id');
        return content.substring(s, e);
    }

    private static void sendMetadataRequest(String body, String sessionId) {
        String endpoint = URL.getOrgDomainUrl().toExternalForm() + '/services/Soap/m/64.0';
        String envelope = '<?xml version="1.0" encoding="UTF-8"?><env:Envelope xmlns:env="http://schemas.xmlsoap.org/soap/envelope/" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"><env:Header><met:SessionHeader xmlns:met="http://soap.sforce.com/2006/04/metadata"><met:sessionId>' + sessionId + '</met:sessionId></met:SessionHeader></env:Header><env:Body>' + body + '</env:Body></env:Envelope>';
        HttpRequest req = new HttpRequest();
        req.setEndpoint(endpoint);
        req.setMethod('POST');
        req.setHeader('Content-Type', 'text/xml; charset=utf-8');
        req.setHeader('SOAPAction', '""');
        req.setBody(envelope);
        Http http = new Http();
        HttpResponse res = http.send(req);
        if (res.getStatusCode() != 200 || res.getBody().contains('<success>false</success>')) {
             throw new CalloutException('Metadata Deployment Failed: ' + res.getBody());
        }
    }
}