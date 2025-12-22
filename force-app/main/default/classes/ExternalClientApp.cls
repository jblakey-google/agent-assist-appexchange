public class ExternalClientApp {

    /**
    * The name of the External Client App.
    */
    private static final String APP_NAME = 'GCP_Agent_Assist_OAuth';

    /**
    * orgScopedExternalApp value, which is orgId:appName.
    */
    private static final String FULLY_QUALIFIED_APP_NAME = UserInfo.getOrganizationId() + ':' + APP_NAME;

    public class ECAWrapper {
        @AuraEnabled public String Id;
        @AuraEnabled public String ContactEmail;
    }

    @AuraEnabled
    public static void create(String contactEmail) {
        try {
            String xml = getExternalClientApplicationXml(contactEmail);

            SoapService.create(xml);

            System.debug('[ExternalClientApp] Completed setupApp.');
        } catch (Exception e) {

            System.debug(LoggingLevel.ERROR, '[ExternalClientApp] External Client App Setup Failed: ' + e.getMessage());

            throw new AuraHandledException('Error during App Setup: ' + e.getMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static List<SObject> getExistingECA() {
        try {
            return [SELECT Id, ContactEmail FROM ExternalClientApplication WHERE DeveloperName = :APP_NAME LIMIT 1];
        } catch (Exception e) {
            throw new AuraHandledException('Error: ' + e.getMessage());
        }
    }

    /**
     * Creates an XML string of [ExternalClientApplication](https://developer.salesforce.com/docs/atlas.en-us.api_meta.meta/api_meta/meta_externalclientapplication.htm) metadata.
     *
     * @see https://developer.salesforce.com/docs/atlas.en-us.api_meta.meta/api_meta/meta_externalclientapplication.htm
     */
    private static String getExternalClientApplicationXml(String contactEmail) {
        Map<String, Object> metaData = new Map<String, Object>{
            'fullName' => APP_NAME,
            'label' => 'GCP Agent Assist Oauth App',
            'contactEmail' => contactEmail,
            'description' => 'Agent Assist Oauth',
            'distributionState' => 'Local',
            'isProtected' => false,
            'orgScopedExternalApp' => FULLY_QUALIFIED_APP_NAME
        };

        return XmlMapper.init('ExternalClientApplication', 'met').add(metaData).toXml();
    }
}