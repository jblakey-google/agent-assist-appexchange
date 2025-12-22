public class RestClient {

    public class RestClientException extends Exception {}

/**
     * Executes a query against the Tooling API and returns a strongly typed list.
     * * @param queryStr The SOQL query string.
     * @param returnType The Class Type of the LIST to return (e.g., List<MyWrapper>.class)
     * @return An Object you must cast to your specific List type.
     */
    public static Object query(String queryStr, Type returnType) {
        String endpoint = Url.getOrgDomainUrl().toExternalForm() 
                          + '/services/data/v60.0/tooling/query/?q=' 
                          + EncodingUtil.urlEncode(queryStr, 'UTF-8');

        HttpRequest req = new HttpRequest();
        req.setEndpoint(endpoint);
        req.setMethod('GET');
        req.setHeader('Authorization', 'Bearer ' + UserInfo.getSessionId());
        req.setHeader('Content-Type', 'application/json');

        Http http = new Http();
        HttpResponse res = http.send(req);

        if (res.getStatusCode() == 200) {
            Map<String, Object> root = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
            
            if (root.containsKey('records')) {
                Object recordsObject = root.get('records');
                
                String recordsJson = JSON.serialize(recordsObject);

                System.debug(LoggingLevel.debug, recordsObject);
                
                return JSON.deserialize(recordsJson, returnType);
            }
            
            return returnType.newInstance(); 
        } else {
            throw new RestClientException('[RestClient.query] ' + res.getBody());
        }
    }
}