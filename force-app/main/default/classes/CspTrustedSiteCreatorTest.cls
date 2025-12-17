@IsTest
private class CspTrustedSiteCreatorTest {

    private class MockHttpResponseGenerator implements HttpCalloutMock {
        private Integer statusCode;
        private String status;
        private String body;

        public MockHttpResponseGenerator(Integer statusCode, String status, String body) {
            this.statusCode = statusCode;
            this.status = status;
            this.body = body;
        }

        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody(this.body);
            res.setStatusCode(this.statusCode);
            res.setStatus(this.status);
            return res;
        }
    }

    @IsTest
    static void testCreateTrustedSiteSuccess() {
        // Mock successful response
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(201, 'Created', '{"id":"someId", "success":true}'));

        Test.startTest();
        CspTrustedSiteCreator.createTrustedSite('https://www.example.com', 'ExampleSite');
        Test.stopTest();

        // No exception should be thrown
    }

    @IsTest
    static void testCreateTrustedSiteFailure() {
        // Mock failure response
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(400, 'Bad Request', '[{"message":"Duplicate value found", "errorCode":"DUPLICATE_VALUE"}]'));

        Test.startTest();
        try {
            CspTrustedSiteCreator.createTrustedSite('https://www.example.com', 'ExampleSite');
            Assert.fail('Expected AuraHandledException was not thrown');
        } catch (AuraHandledException e) {
            // Success: expected exception
            Assert.isTrue(e.getMessage().contains('Failed to create CspTrustedSite'), 'Exception message should contain failure details.');
        } catch (Exception e) {
             Assert.fail('Caught unexpected exception type: ' + e.getTypeName() + '. Message: ' + e.getMessage());
        }
        Test.stopTest();
    }
}
