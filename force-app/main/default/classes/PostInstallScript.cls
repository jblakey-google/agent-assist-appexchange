global class PostInstallScript implements InstallHandler {
    global void onInstall(InstallContext context) {
        if (context.previousVersion() == null) {
            createAndAssignPermissionSet(context.installerId());
        }
    }

    private void createAndAssignPermissionSet(Id installerId) {
        try {
            String psName = Config.SERVICE_PRESENCE.get('PERMISSION_SET_NAME');
            String psLabel = Config.SERVICE_PRESENCE.get('PERMISSION_SET_LABEL');
            
            // 1. Check/Create PermissionSet
            List<PermissionSet> psList = [SELECT Id FROM PermissionSet WHERE Name = :psName LIMIT 1];
            PermissionSet ps;
            
            if (psList.isEmpty()) {
                ps = new PermissionSet(
                    Name = psName,
                    Label = psLabel
                );
                insert ps;
                System.debug('Created Permission Set: ' + psName);
            } else {
                ps = psList[0];
            }
            
            // 2. Grant App Visibility
            String appName = Config.EXTERNAL_CLIENT_APP.get('NAME');
            Id appId = null;
            
            // Try AppMenuItem first (Most reliable for finding App IDs)
            try {
                List<SObject> items = Database.query('SELECT ApplicationId FROM AppMenuItem WHERE Name = :appName LIMIT 1');
                if (!items.isEmpty()) {
                    appId = (Id) items[0].get('ApplicationId');
                }
            } catch (Exception e) {
                System.debug('AppMenuItem query failed: ' + e.getMessage());
            }

            if (appId == null) {
                // Fallback to TabSet dynamic query
                try {
                     List<SObject> tabSets = Database.query('SELECT Id FROM TabSet WHERE Name = :appName LIMIT 1');
                     if (!tabSets.isEmpty()) {
                         appId = (Id) tabSets[0].get('Id');
                     }
                } catch (Exception e) {
                     System.debug('TabSet query failed: ' + e.getMessage());
                }
            }
            
            if (appId != null) {
                 List<SetupEntityAccess> seas = [SELECT Id FROM SetupEntityAccess WHERE ParentId = :ps.Id AND SetupEntityId = :appId LIMIT 1];
                 if (seas.isEmpty()) {
                     insert new SetupEntityAccess(
                         ParentId = ps.Id,
                         SetupEntityId = appId
                     );
                     System.debug('Granted App Visibility to: ' + appName);
                 }
            }

            // 3. Assign Users
            Set<Id> userIdsToAssign = new Set<Id>();
            if (installerId != null) userIdsToAssign.add(installerId);
            
            for (User u : [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' AND IsActive = true]) {
                userIdsToAssign.add(u.Id);
            }
            
            if (!userIdsToAssign.isEmpty()) {
                 List<PermissionSetAssignment> newAssignments = new List<PermissionSetAssignment>();
                 Set<Id> existingAssignees = new Set<Id>();
                 
                 for (PermissionSetAssignment psa : [SELECT AssigneeId FROM PermissionSetAssignment WHERE PermissionSetId = :ps.Id AND AssigneeId IN :userIdsToAssign]) {
                     existingAssignees.add(psa.AssigneeId);
                 }
                 
                 for (Id uid : userIdsToAssign) {
                     if (!existingAssignees.contains(uid)) {
                         newAssignments.add(new PermissionSetAssignment(
                             AssigneeId = uid,
                             PermissionSetId = ps.Id
                         ));
                     }
                 }
                 
                 if (!newAssignments.isEmpty()) {
                     insert newAssignments;
                 }
            }
        } catch (Exception e) {
            System.debug('Failed to create/assign permission set in PostInstall: ' + e.getMessage());
        }
    }
}