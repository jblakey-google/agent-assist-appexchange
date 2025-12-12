// Debug script to list all visible apps
List<AppMenuItem> visibleApps = [SELECT Name, Label, IsVisible FROM AppMenuItem WHERE IsVisible = true];
System.debug('--- Visible Apps (' + visibleApps.size() + ') ---');
for (AppMenuItem app : visibleApps) {
    System.debug('Name: ' + app.Name + ', Label: ' + app.Label + ', Visible: ' + app.IsVisible);
}
