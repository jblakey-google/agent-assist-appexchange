/**
 * This class is connected to `sfdx-project.json` under `packageDirectories[0].postInstallScript`.
 * 
 * Is executed on postinstall, so it's intended for bootstrapping org permissions and settings 
 * to support the app's requirements.
 */
global class PostInstallScript implements InstallHandler {

    global void onInstall(InstallContext context) {
        
        if (context.previousVersion() == null || context.isUpgrade()) {
            createSupportQueue();
        }
    }

    private void createSupportQueue() {}
}