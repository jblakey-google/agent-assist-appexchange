public class ExternalClientApp {

    /**
    * The name of the External Client App.
    */
    private static final String APP_NAME = 'GCP_Agent_Assist_OAuth';

    /**
    * orgScopedExternalApp value, which is orgId:appName.
    */
    private static final String FULLY_QUALIFIED_APP_NAME = UserInfo.getOrganizationId() + ':' + APP_NAME;

    @AuraEnabled
    public static void create(String contactEmail) {

        try {
            SoapService.create(
                createAppMetadataXML(contactEmail)
            );

            System.debug('[ExternalClientApp] Completed setupApp.');
        } catch (Exception e) {

            System.debug(LoggingLevel.ERROR, '[ExternalClientApp] External Client App Setup Failed: ' + e.getMessage());

            throw new AuraHandledException('Error during App Setup: ' + e.getMessage());
        }
    }

    /**
     * Creates an XML string of [ExternalClientApplication](https://developer.salesforce.com/docs/atlas.en-us.api_meta.meta/api_meta/meta_externalclientapplication.htm) metadata.
     *
     * @see https://developer.salesforce.com/docs/atlas.en-us.api_meta.meta/api_meta/meta_externalclientapplication.htm
     */
    private static String createAppMetadataXML(String contactEmail) {

        return '<met:metadata xsi:type="met:ExternalClientApplication" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">' +
            '<met:fullName>' + APP_NAME + '</met:fullName>' +
            '<met:label>GCP Agent Assist Oauth App</met:label>' +
            '<met:contactEmail>' + contactEmail + '</met:contactEmail>' +
            '<met:description>Agent Assist Oauth</met:description>' +
            '<met:distributionState>Local</met:distributionState>' +
            '<met:isProtected>false</met:isProtected>' +
            '<met:orgScopedExternalApp>' + FULLY_QUALIFIED_APP_NAME + '</met:orgScopedExternalApp>' +
            '</met:metadata>';

    }
}