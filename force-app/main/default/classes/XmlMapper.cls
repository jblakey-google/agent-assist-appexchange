/**
 * Converts a Map into Xml for a soap request..
 * 
 * @usage
 * Map<String, Object> channelData = new Map<String, Object>{
 *      'fullName' => 'Agent_Assist_Channel',
 *      'label' => 'Agent Assist Channel',
 *      'type' => 'EmbeddedMessaging', // Some APIs might require 'messageType'
 *      'isProtected' => false
 *  };
 *
 *  // "met" is the prefix used in your main SOAP Envelope for http://soap.sforce.com/2006/04/metadata
 *  String metadataXml = XmlUtils.init('MessagingChannel', 'met')
 *     .add(channelData)
 *     .toXml();
 */
public class XmlMapper {
    
    private String sobjectType;
    private String prefix;
    private String innerXmlContent = '';

    private XmlMapper(String sobjectType, String prefix) {
        this.sobjectType = sobjectType;
        this.prefix = prefix;
    }

    /**
     * @param sobjectType Name of sobject, which you'd ordinarily add to xsi:type="<sobject>" in XML.
     * @param prefix This is typically "met" (e.g. <met:fullName>), but I made it flexible just in case.
     */
    public static XmlMapper init(String sobjectType, String prefix) {
        return new XmlMapper(sobjectType, prefix);
    }

    /**
     * Automatically applies the prefix to keys (e.g., 'fullName' -> 'met:fullName')
     * 
     * @param attributes A map of key/values intended to be mapped to XML property/value pairs.
     */
    public XmlMapper add(Map<String, Object> attributes) {
        this.innerXmlContent += mapToXml(attributes, this.prefix);
        return this; // Chainable
    }

    /**
     * Generates the Metadata Wrapper with the correct xsi:type and injects Map data that was converted to XML.
     */
    public String toXml() {
        return '<' + this.prefix + ':metadata xsi:type="' + this.prefix + ':' + this.sobjectType + '" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">' + 
                    this.innerXmlContent + 
               '</' + this.prefix + ':metadata>';
    }
    
    public override String toString() {
        return this.toXml();
    }

    private static String mapToXml(Map<String, Object> data, String ns) {
        String xml = '';
        for (String key : data.keySet()) {
            Object value = data.get(key);
            if (value == null) continue;
            
            String fullTagName = key.contains(':') ? key : ns + ':' + key;

            if (value instanceof List<Object>) {
                for (Object listItem : (List<Object>)value) {
                    xml += buildElement(fullTagName, listItem, ns);
                }
            } else {
                xml += buildElement(fullTagName, value, ns);
            }
        }
        return xml;
    }

    private static String buildElement(String tagName, Object value, String ns) {
        if (value instanceof Map<String, Object>) {
            return '<' + tagName + '>' + mapToXml((Map<String, Object>)value, ns) + '</' + tagName + '>';
        } else {
            String textContent = String.valueOf(value).escapeXml();
            return '<' + tagName + '>' + textContent + '</' + tagName + '>';
        }
    }
}