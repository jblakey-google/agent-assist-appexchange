// Script to revert App Menu changes (make all apps visible)

List<AppMenuItem> allApps = [SELECT Id, Name, Label FROM AppMenuItem];
System.debug('Found ' + allApps.size() + ' apps. setting all to visible.');

for (AppMenuItem app : allApps) {
    try {
        // Set all apps to visible
        AppLauncher.AppMenu.setAppVisibility(app.Id, true);
        System.debug('Set visibility for ' + app.Name + ' (' + app.Label + ') to true');
    } catch (Exception e) {
        System.debug('Failed to set visibility for ' + app.Name + ': ' + e.getMessage());
    }
}
