/**
 * This class is connected to `sfdx-project.json` under `packageDirectories[0].postInstallScript`.
 * 
 * Is executed on postinstall, so it's intended for bootstrapping org permissions and settings 
 * to support the app's requirements.
 */
global class PostInstallScript implements InstallHandler {

    global void onInstall(InstallContext context) {
        
        if (context.isInstall() || context.isUpgrade()) {
            createSupportQueue();
        }
    }

    private void createSupportQueue() {
        List<Group> supportQueues = [SELECT Id FROM Group WHERE Type = 'Queue' AND Name = 'Agent Assist Support' LIMIT 1];
        
        if (supportQueues.isEmpty()) {
            Group supportQueue = new Group(Name = 'Agent Assist Support', Type = 'Queue');
            insert supportQueue;

            QueueSobject caseBinding = new QueueSobject(QueueId = supportQueue.Id, SobjectType = 'Case');
            insert caseBinding;
            
            QueueSobject sessionBinding = new QueueSobject(QueueId = supportQueue.Id, SobjectType = 'MessagingSession');
            insert sessionBinding;

            System.debug('Support queue created');
        } else {
            System.debug('Support queue already exists');
        }
    }
}