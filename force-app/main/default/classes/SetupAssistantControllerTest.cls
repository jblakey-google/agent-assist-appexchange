@isTest
private class SetupAssistantControllerTest {

    // 1. SUCCESS MOCK: Simulates a successful API response
    private class MetadataServiceMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'text/xml');
            res.setStatusCode(200);
            String successBody = 
                '<?xml version="1.0" encoding="UTF-8"?>' +
                '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/">' +
                    '<soapenv:Body>' +
                        '<createMetadataResponse>' +
                            '<result><success>true</success></result>' +
                        '</createMetadataResponse>' +
                    '</soapenv:Body>' +
                '</soapenv:Envelope>';
            res.setBody(successBody);
            return res;
        }
    }

    // 2. FAILURE MOCK: Simulates a crash (THIS WAS MISSING)
    private class MetadataServiceFailureMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'text/xml');
            res.setStatusCode(500); // Simulate Server Error
            res.setBody('<soapenv:Envelope><soapenv:Body><faultstring>Internal Error</faultstring></soapenv:Body></soapenv:Envelope>');
            return res;
        }
    }
    
    @TestSetup
    static void makeData() {
        // Setup Objects (like PermissionSet) are visible in tests.
        // If you already ran the setup in this org, the record exists.
        // We only insert if it is MISSING.
        if ([SELECT Count() FROM PermissionSet WHERE Name = 'Agent_Assist_Messaging'] == 0) {
            PermissionSet ps = new PermissionSet(
                Name = 'Agent_Assist_Messaging',
                Label = 'Agent Assist Messaging Test' // Use a distinct label just in case
            );
            insert ps;
        }
    }

    @isTest
    static void testDeployMetadata_Success() {
        Test.setMock(HttpCalloutMock.class, new MetadataServiceMock());

        Test.startTest();
        String result = SetupAssistantController.deployMetadata();
        Test.stopTest();

        System.assertEquals('Success', result, 'The deployment should return Success');

        // Verify Queue Creation
        List<Group> queues = [SELECT Id, DeveloperName FROM Group WHERE DeveloperName = 'Agent_Assist' AND Type = 'Queue'];
        System.assert(!queues.isEmpty(), 'The Agent Assist Queue should have been created');
        
        // Verify Permission Set Assignment
        List<PermissionSetAssignment> psa = [
            SELECT Id 
            FROM PermissionSetAssignment 
            WHERE PermissionSet.Name = 'Agent_Assist_Messaging' 
            AND AssigneeId = :UserInfo.getUserId()
        ];
        System.assert(!psa.isEmpty(), 'The Permission Set should have been assigned to the running user');
    }

@isTest
    static void testDeployMetadata_Idempotency() {
        Test.setMock(HttpCalloutMock.class, new MetadataServiceMock());

        // FIX: Check if the Queue exists before trying to create it.
        // If it's visible (from real data), we use it. If not, we create it.
        if ([SELECT Count() FROM Group WHERE DeveloperName = 'Agent_Assist' AND Type = 'Queue'] == 0) {
            Group existingQueue = new Group(
                Name = 'Agent Assist',
                DeveloperName = 'Agent_Assist',
                Type = 'Queue'
            );
            insert existingQueue;
            
            insert new GroupMember(
                GroupId = existingQueue.Id,
                UserOrGroupId = UserInfo.getUserId()
            );
        }

        PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name = 'Agent_Assist_Messaging' LIMIT 1];
        if ([SELECT Count() FROM PermissionSetAssignment WHERE AssigneeId = :UserInfo.getUserId() AND PermissionSetId = :ps.Id] == 0) {
            insert new PermissionSetAssignment(
                AssigneeId = UserInfo.getUserId(),
                PermissionSetId = ps.Id
            );
        }

        Test.startTest();
        // Run Setup (Should detect the queue and SKIP creation)
        SetupAssistantController.deployMetadata();
        
        // Run Setup AGAIN (Should still skip)
        String result = SetupAssistantController.deployMetadata();
        Test.stopTest();

        System.assertEquals('Success', result, 'Subsequent runs should still succeed');
        
        // Verify we still have exactly 1 queue (no duplicates created)
        Integer count = [SELECT Count() FROM Group WHERE DeveloperName = 'Agent_Assist' AND Type = 'Queue'];
        System.assertEquals(1, count, 'There should be exactly one queue');
    }

    @isTest
    static void testDeployMetadata_CalloutFailure() {
        // Now this class exists!
        Test.setMock(HttpCalloutMock.class, new MetadataServiceFailureMock());

        Test.startTest();
        try {
            SetupAssistantController.deployMetadata();
            System.assert(false, 'Should have thrown an exception');
        } catch (AuraHandledException e) {
            System.assert(true, 'Caught expected exception');
        } catch (Exception e) {
            System.assert(true, 'Caught generic exception');
        }
        Test.stopTest();
    }
}