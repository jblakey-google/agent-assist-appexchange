/**
 * This class is connected to `sfdx-project.json` under `packageDirectories[0].postInstallScript`.
 * 
 * Is executed on postinstall, so it's intended for bootstrapping org permissions and settings 
 * to support the app's requirements.
 */
global class PostInstallScript implements InstallHandler {

    global void onInstall(InstallContext context) {
        if (context.isUpgrade()) {
            System.debug('Upgrade detected...');
        }
        createSupportQueue();
    }

    private void createSupportQueue() {
        List<Group> supportQueues = [SELECT Id FROM Group WHERE Type = 'Queue' AND Name = 'Agent Assist Support' LIMIT 1];
        
        if (supportQueues.isEmpty()) {
            try {
                Group supportQueue = new Group(Name = 'Agent Assist Support', Type = 'Queue');
                insert supportQueue;

                QueueSobject caseBinding = new QueueSobject(QueueId = supportQueue.Id, SobjectType = 'Case');
                QueueSobject sessionBinding = new QueueSobject(QueueId = supportQueue.Id, SobjectType = 'MessagingSession');
                
                // Use a list insert for efficiency (bulkify DML)
                List<QueueSobject> bindings = new List<QueueSobject>{caseBinding, sessionBinding};
                insert bindings;

                System.debug('Support queue created successfully');
            } catch (DmlException e) {
                // Log or handle the error appropriately
                System.debug('Error creating support queue or bindings: ' + e.getMessage());
            }
        } else {
            System.debug('Support queue already exists');
        }
    }
}