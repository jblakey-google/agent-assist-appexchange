/**
 * A config for managing sobject values. 
 */
public class Config {
    public static final Map<String, String> SERVICE_CHANNEL = new Map<String, String>{
        'PHONE_NAME' => 'sfdc_phone',
        'MESSAGING_NAME' => 'sfdc_livemessage'
    };

    public static final Map<String, String> MESSAGING_QUEUE = new Map<String, String>{
        'NAME' => 'Agent_Assist',
        'LABEL' => 'Agent Assist'   
    };

    public static final Map<String, String> LIVE_MESSAGE_SETTINGS = new Map<String, String>{
        'NAME' => 'LiveMessage'
    };

    public static final Map<String, String> ROUTING_QUEUE_CONFIG = new Map<String, String>{
        'NAME' => 'Agent_Assist',
        'LABEL' => 'Agent Assist'
    };

    public static final Map<String, String> SERVICE_CLOUD_VOICE_SETTINGS = new Map<String, String>{
        'NAME' => 'ServiceCloudVoice'
    };

    public static final Map<String, String> MESSAGING_CHANNEL = new Map<String, String>{
        'LABEL' => 'GCP Messaging Channel',
        'NAME' => 'GCP_Messaging_Channel'
    };

    public static final Map<String, String> SERVICE_PRESENCE = new Map<String, String>{
        'PERMISSION_SET_LABEL' => 'Agent Assist Messaging',
        'PERMISSION_SET_NAME' => 'Agent_Assist_Messaging',
        'STATUS_ONLINE_NAME' => 'Online_Messaging',
        'STATUS_ONLINE_LABEL' => 'Online (Messaging)',
        'STATUS_BUSY_NAME' => 'Busy',
        'STATUS_BUSY_LABEL' => 'Busy'
    };

    public static final Map<String, String> EXTERNAL_CLIENT_APP = new Map<String, String>{
        'NAME' => 'GCP_Agent_Assist',
        'LABEL' => 'GCP Agent Assist'
    };
}