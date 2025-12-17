public class CspTrustedSiteCreator {

    /**
     * Creates a new CspTrustedSite record via the Tooling API.
     * @param siteUrl The URL to trust (e.g., 'https://api.example.com').
     * @param siteName A unique developer name for the site (e.g., 'ExampleApiSite').
     */
    @AuraEnabled
    public static void createTrustedSite(String siteUrl, String siteName) {

        // Use dynamic URL and Session ID
        String baseUrl = URL.getOrgDomainUrl().toExternalForm();
        String apiUrl = '/services/data/v60.0/sobjects/CspTrustedSite';

        HttpRequest req = new HttpRequest();
        req.setEndpoint(baseUrl + apiUrl);
        req.setHeader('Authorization', 'OAuth ' + getSessionId());
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        req.setHeader('Accept', 'application/json');

        // Construct the JSON body with necessary fields
        Map<String, Object> siteData = new Map<String, Object>();
        siteData.put('DeveloperName', siteName);
        siteData.put('MasterLabel', siteName + ' Label');
        siteData.put('EndpointUrl', siteUrl);
        siteData.put('IsActive', true);
        siteData.put('Context', 'All'); // 'All', 'LEX', 'Communities', 'VisualForce', 'Sites'
        
        // Grant access to necessary directives
        siteData.put('IsApplicableToConnectSrc', true); // Essential for API callouts
        siteData.put('IsApplicableToImgSrc', false);
        // Add more directives as needed (StyleSrc, FontSrc, etc.)

        req.setBody(JSON.serialize(siteData));

        Http http = new Http();
        try {
            HttpResponse res = http.send(req);
            
            // Check response status
            if (res.getStatusCode() == 201) {
                System.debug('Successfully created CspTrustedSite: ' + siteName);
            } else {
                System.debug(LoggingLevel.ERROR, 'Failed to create CspTrustedSite. Status: ' + res.getStatusCode() + ', Body: ' + res.getBody());
                String errorMessage = 'Failed to create CspTrustedSite. API returned status: ' + res.getStatusCode() + ' ' + res.getBody();
                AuraHandledException e = new AuraHandledException(errorMessage);
                e.setMessage(errorMessage);
                throw e;
            }
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'HTTP Request failed: ' + e.getMessage());
            String errorMessage = 'Error creating trusted site: ' + e.getMessage();
            AuraHandledException ahe = new AuraHandledException(errorMessage);
            ahe.setMessage(errorMessage);
            throw ahe;
        }
    }

    private static String getSessionId() {
        if (Test.isRunningTest()) {
            return UserInfo.getSessionId();
        }
        String content = Page.SessionIdGetter.getContent().toString();
        String s = 'Start_Of_Session_Id';
        String e = 'End_Of_Session_Id';
        return content.substringBetween(s, e);
    }
}
