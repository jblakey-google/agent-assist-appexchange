public with sharing class SoapService {
    /**
    * Base URL for soap requests.
    */
    private static final String BASE_PATH = URL.getOrgDomainUrl().toExternalForm();

    /**
    * The API URL for the Metadata API.
    */
    private static final String METADATA_API_URL = '/services/Soap/m/64.0';

    public static void create(String metadataXml) {

        String soapEnvelope = buildSoapEnvelope(metadataXml, 'create');

        HttpRequest req = new HttpRequest();

        req.setEndpoint(BASE_PATH + METADATA_API_URL);
        req.setMethod('POST');
        req.setHeader('Content-Type', 'text/xml;charset=UTF-8');
        req.setHeader('SOAPAction', '""');
        req.setBody(soapEnvelope);
        req.setTimeout(120000);

        Http http = new Http();

        HttpResponse res = http.send(req);

        if (res.getStatusCode() != 200 || res.getBody().contains('<success>false</success>')) {

            throw new CalloutException('Metadata Deployment Failed: ' + res.getBody());

        }

    }

    private static String getSessionIdFromVF() {
        if (Test.isRunningTest()) return 'TEST_SESSION_ID';

        PageReference pageRef = Page.SessionIdGetter;

        String content = pageRef.getContent().toString();
        Integer s = content.indexOf('Start_Of_Session_Id') + 'Start_Of_Session_Id'.length();
        Integer e = content.indexOf('End_Of_Session_Id');

        return content.substring(s, e);
    }

    private static String buildSoapEnvelope(String metadataXml, String method) {
        String sessionId = getSessionIdFromVF();

        return '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" ' +
            'xmlns:met="http://soap.sforce.com/2006/04/metadata">' +
            '<soapenv:Header>' +
            '<met:SessionHeader>' +
            '<met:sessionId>' + sessionId + '</met:sessionId>' +
            '</met:SessionHeader>' +
            '</soapenv:Header>' +
            '<soapenv:Body>' +
            '<met:' + method + 'Metadata>' +
            metadataXml +
            '</met:createMetadata>' +
            '</soapenv:Body>' +
            '</soapenv:Envelope>';
    }
}