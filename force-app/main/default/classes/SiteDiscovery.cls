public with sharing class SiteDiscovery {
    @AuraEnabled(cacheable=true)
    public static Map<String, String> getSiteInfo(String siteName) {
        List<Network> networks = [
            SELECT Id, Name 
            FROM Network 
            WHERE Name = :siteName 
            LIMIT 1
        ];

        if (networks.isEmpty()) return null;

        List<Site> sites = [
            SELECT Id, SiteType 
            FROM Site 
            WHERE Name = :networks[0].Name 
            LIMIT 1
        ];

        return new Map<String, String>{
            'siteDeveloperName' => networks[0].Name,
            'siteId' => (sites.isEmpty() ? null : sites[0].Id),
            'siteType' => (sites.isEmpty() ? null : sites[0].SiteType)
        };
    }
}