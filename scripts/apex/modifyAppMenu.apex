// Script to hide specific App Menu items

Set<String> appsToHide = new Set<String>{
    'Sales',
    'Marketing',
    'Community',
    'Sites',
    'Chatter',
    'Content',
    'LightningSales',
    'LightningBolt',
    'SalesforceCMS',
    'SalesCloudMobile',
    'Approvals',
    'MSJApp',
    'CPQIntegrationUserApp'
};

List<AppMenuItem> allApps = [SELECT Id, Name, Label FROM AppMenuItem];
System.debug('Found ' + allApps.size() + ' apps.');

for (AppMenuItem app : allApps) {
    Boolean makeVisible = true; // Default to visible
    
    // If in the hide list, set to false
    if (appsToHide.contains(app.Name)) {
        makeVisible = false;
    }
    
    try {
        AppLauncher.AppMenu.setAppVisibility(app.Id, makeVisible);
        String status = makeVisible ? 'Visible' : 'Hidden';
        System.debug('Set ' + app.Name + ' (' + app.Label + ') to ' + status);
    } catch (Exception e) {
        System.debug('Failed to set visibility for ' + app.Name + ': ' + e.getMessage());
    }
}
