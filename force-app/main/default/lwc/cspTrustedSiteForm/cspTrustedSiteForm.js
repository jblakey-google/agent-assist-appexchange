// @ts-check
/**
 * @fileoverview A controller that updates CSP/Trusted URLs in the GCP flexipage. Here's the page flow:
 * 
 * - On load, calls verifySalesforceDomainCSP, which checks if the user's SF domain has been added to a trust policy. If not, it adds it.
 * - On load, calls getCSPs, which returns a list of all existing CSPs.
 * 
 * @TODO Consider adding an update feature rather than setting fields to readonly.
 */
import { LightningElement, wire } from "lwc";
import createTrustedSite from "@salesforce/apex/CspTrustedSiteCreator.createTrustedSite";
import getCSPs from "@salesforce/apex/CspTrustedSiteCreator.getCSPs";
import verifySalesforceDomainCSP from "@salesforce/apex/CspTrustedSiteCreator.verifySalesforceDomainCSP";
import { ShowToastEvent } from "lightning/platformShowToastEvent";

/**
 * @typedef {{
 *  Id: string;
 *  DeveloperName: string;
 *  EndpointUrl: string;
 *  IsActive: string;
 * }[] | undefined} CSPList
 */

const UI_CONNECTOR = "ui_connector";

const UI_CONNECTOR_WSS = "ui_connector_wss";

const TWILIO_FLEX = "twilio_flex";

export default class CspTrustedSiteForm extends LightningElement {
  isLoading = false;

  uiConnector = "";
  uiConnectorWss = "";
  provider = [];

  /**
   * If values are already created, all form fields are placed in a readOnly state.
   */
  showReadonlyState = false;

  inactiveTrustedUrlNames = [];

  /**
   * @type {CSPList}
   */
  csps = []

  @wire(getCSPs)
  wiredResources({ error, data }) {
    if (error) {
      console.error("Error checking if external client app exists:", error);
    }
    if (!Array.isArray(data) || !data.length) {
      return;
    }
        console.log(JSON.stringify(data))
    /**
     * @type {CSPList}
     */
    this.csps = data;
    /**
     * Applies defaults to form fields.
     */
    this.csps.forEach((csp) => {
      if (!csp.IsActive) {
        this.inactiveTrustedUrlNames.push(csp.DeveloperName);
      }
      if (csp.DeveloperName === UI_CONNECTOR) {
        this.uiConnector = csp.EndpointUrl;
      } else if (csp.DeveloperName === UI_CONNECTOR_WSS) {
        this.uiConnectorWss = csp.EndpointUrl;
      } else if (csp.DeveloperName === TWILIO_FLEX) {
        this.provider = [TWILIO_FLEX];
      }

      if([UI_CONNECTOR, UI_CONNECTOR_WSS].includes(csp.DeveloperName)) {
        this.showReadonlyState = true;
      }
    });
  }

  /**
   * Options for the checkbox group.
   * 
   * @returns {{
   *  value: string,
   *  label: string,
   * }[]}
   */
  get options() {
    return [{ value: TWILIO_FLEX, label: "Enable Twilio Flex CSP" }];
  }

  /**
   * Indicates whether the create/apply button should be displayed.
   */
  get displayCreateBtn() {
    return !this.showReadonlyState
  }

  /**
   * Populates the number of CSP policies that are inactive for a status banner that appears
   * if this number is greater than zero.
   */
  get numberOfInactiveUrls() {
    return this.inactiveTrustedUrlNames.length;
  }

  /**
   * A comma separated string of inactive CSP policy names.
   * 
   * @returns {`${string}, ${string}` | string}
   * 
   */
  get inactiveUrlNames() {
    return this.inactiveTrustedUrlNames.join(", ");
  }

  connectedCallback() {
    /**
     * Check if the Salesforce domain is in the CSP list.
     * If not, add it.
     */
    verifySalesforceDomainCSP();
  }

  handleUrlChange(event) {
    if (event.target.name === UI_CONNECTOR) {
      this.uiConnector = event.target.value;
    } else if (event.target.name === UI_CONNECTOR_WSS) {
      this.uiConnectorWss = event.target.value;
    }
  }

  handleProviderCheckbox(event) {
    this.provider = event.detail.value;
  }

  async handleCreate() {
    if (!this.uiConnector || !this.uiConnectorWss) {
      this.showToast("Error", "Please fill in all fields", "error");
      return;
    }

    this.isLoading = true;

    const creators = [
        createTrustedSite({
          siteUrl: this.uiConnector,
          siteName: UI_CONNECTOR
        }),
        createTrustedSite({
          siteUrl: this.uiConnectorWss,
          siteName: UI_CONNECTOR_WSS
        })
    ];

    if (this.provider[0] === TWILIO_FLEX) {
      creators.push(createTrustedSite({
          siteUrl: "https://flex.twilio.com",
          siteName: TWILIO_FLEX
        })
      );
    }

    try {
      await Promise.all(creators);

      this.showToast("Success", "Trusted Site created successfully", "success");
    } catch (error) {
      let message = "Unknown error";

      if (Array.isArray(error.body)) {
        message = error.body.map((e) => e.message).join(", ");
      } else if (typeof error.body.message === "string") {
        message = error.body.message;
      }

      this.showToast("Error", "Error creating site: " + message, "error");
      console.error("Error creating site:", error);
    } finally {
      this.isLoading = false;
    }
  }

  showToast(title, message, variant) {
    const event = new ShowToastEvent({
      title: title,
      message: message,
      variant: variant
    });
    this.dispatchEvent(event);
  }
}
