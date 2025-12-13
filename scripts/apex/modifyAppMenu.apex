// Script to hide everything EXCEPT specific App Menu items

Set<String> appsToKeep = new Set<String>{
    'LightningService', // Standard Service Console
    'Service',          // Standard Service App
    'GCP_Agent_Assist',           // GCP Agent Assist (Local name)
    'agent_assist__GCP_Agent_Assist' // GCP Agent Assist (Namespaced name, just in case)
};

List<AppMenuItem> allApps = [SELECT Id, Name, Label FROM AppMenuItem];
System.debug('Found ' + allApps.size() + ' apps.');

for (AppMenuItem app : allApps) {
    // Default to hidden unless it's in the keep list
    Boolean makeVisible = false;
    
    if (appsToKeep.contains(app.Name)) {
        makeVisible = true;
    }
    
    try {
        AppLauncher.AppMenu.setAppVisibility(app.Id, makeVisible);
        String status = makeVisible ? 'Visible' : 'Hidden';
        System.debug('Set ' + app.Name + ' (' + app.Label + ') to ' + status);
    } catch (Exception e) {
        System.debug('Failed to set visibility for ' + app.Name + ': ' + e.getMessage());
    }
}
