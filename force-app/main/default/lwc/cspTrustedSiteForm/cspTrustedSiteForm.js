// @ts-check
/**
 * @fileoverview A controller that updates CSP/Trusted URLs in the GCP flexipage. Here's the page flow:
 *
 * - On load, calls verifySalesforceDomainCSP, which checks if the user's SF domain has been added to a trust policy. If not, it adds it.
 * - On load, calls getCSPs, which returns a list of all existing CSPs.
 *
 * @note There isn't a way to update existing Trusted URLs programmatically as of 2025/12/27, so instead a link is added to the table that
 * directs to each Trusted URL's settings page.
 */
import { LightningElement, wire } from "lwc";
import createTrustedSite from "@salesforce/apex/CspTrustedSiteCreator.createTrustedSite";
import getCSPs from "@salesforce/apex/CspTrustedSiteCreator.getCSPs";
import verifySalesforceDomainCSP from "@salesforce/apex/CspTrustedSiteCreator.verifySalesforceDomainCSP";
// @ts-expect-error Legacy toast, but still works. Just doesn't have module typings.
import { ShowToastEvent } from "lightning/platformShowToastEvent";
// @ts-expect-error This function does exist: https://developer.salesforce.com/docs/platform/lwc/guide/apex-result-caching.html
import { refreshApex } from "@salesforce/apex";

/**
 * @typedef {{
 *  Id: string;
 *  DeveloperName: string;
 *  EndpointUrl: string;
 *  IsActive: string;
 * }[] | undefined} CSPList
 *
 * @typedef {{
 *  value: string,
 *  label: string,
 * }[]} CheckboxGroupOptions
 */

const UI_CONNECTOR = "ui_connector";

const UI_CONNECTOR_WSS = "ui_connector_wss";

const TWILIO_FLEX = "twilio_flex";

const COLS = [
  { label: "Label", fieldName: "developerName" },
  { label: "URL", fieldName: "endpoint" },
  { label: "Active", fieldName: "isActive", type: "boolean" },
  { label: "Settings URL", fieldName: "settingsUrl", type: "url" }
];

export default class CspTrustedSiteForm extends LightningElement {
  isLoading = false;

  datatableColumns = COLS;

  uiConnector = "";
  uiConnectorWss = "";

  /**
   * Trusted URLs where IsActive === false. This is used to trigger a warning status message in the UI.
   */
  inactiveTrustedUrlNames = [];
  /**
   * @type {CSPList}
   */
  csps = [];
  checkboxGroupValue = [];

  isUIConnectorFieldVisible = true;
  isUIConnectorWSFieldVisible = true;
  isTwilioFlexFieldVisible = true;
  isDataTableVisible = false;
  isApplyBtnDisabled = false;

  /**
   * A reference used in `apexRefresh` to force apex to pull fresh data.
   * 
   * @see https://developer.salesforce.com/docs/platform/lwc/guide/apex-result-caching.html
   */
  __wiredResult;

  @wire(getCSPs)
  wiredResources(result) {
    this.__wiredResult = result;

    const { data, error } = result;

    if (error) {
      console.error("Error checking if external client app exists:", error);
    }
    if (!Array.isArray(data) || !data.length) {
      return;
    }
    /**
     * @type {CSPList}
     */
    this.csps = data;
    const initialFields = [];
    /**
     * Applies defaults to form fields.
     */
    this.csps.forEach((csp) => {
      if (!csp.IsActive) {
        this.inactiveTrustedUrlNames.push(csp.DeveloperName);
      }
      if (csp.DeveloperName === UI_CONNECTOR) {
        initialFields.push(UI_CONNECTOR);
        this.isUIConnectorFieldVisible = false;
      } else if (csp.DeveloperName === UI_CONNECTOR_WSS) {
        initialFields.push(UI_CONNECTOR_WSS);
        this.isUIConnectorWSFieldVisible = false;
      } else if (csp.DeveloperName === TWILIO_FLEX) {
        initialFields.push(TWILIO_FLEX);
        this.isTwilioFlexFieldVisible = false;
      }
    });

    /**
     * If some Trusted URLs have been created, display DataTable.
     */
    this.isDataTableVisible = [
      UI_CONNECTOR_WSS,
      UI_CONNECTOR,
      TWILIO_FLEX
    ].some((field) => initialFields.includes(field));

    /**
     * If all Trusted URLs have been created, disable `Apply` button.
     */
    this.isApplyBtnDisabled = [
      UI_CONNECTOR_WSS,
      UI_CONNECTOR,
      TWILIO_FLEX
    ].every((field) => initialFields.includes(field));
  }

  /**
   * Options for the Voice checkbox group.
   *
   * @returns {CheckboxGroupOptions}
   */
  get options() {
    return [{ value: TWILIO_FLEX, label: "Add Twilio Flex to Trusted URLs" }];
  }

  get dataTableData() {
    return this.csps.map((csp) => ({
      developerName: csp.DeveloperName,
      endpoint: csp.EndpointUrl,
      isActive: csp.IsActive,
      settingsUrl: `/lightning/setup/SecurityCspTrustedSite/page?address=%2F${csp.Id.slice(0, -3)}`
    }));
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

  handleCheckbox(event) {
    this.checkboxGroupValue = event.detail.value;
  }

  async onCreateTrustedUrls() {
    const creators = [];

    if (this.uiConnector) {
      creators.push(
        createTrustedSite({
          siteUrl: this.uiConnector,
          siteName: UI_CONNECTOR
        })
      );
    }

    if (this.uiConnectorWss) {
      creators.push(
        createTrustedSite({
          siteUrl: this.uiConnectorWss,
          siteName: UI_CONNECTOR_WSS
        })
      );
    }

    if (this.checkboxGroupValue.includes(TWILIO_FLEX)) {
      creators.push(
        createTrustedSite({
          siteUrl: "https://flex.twilio.com",
          siteName: TWILIO_FLEX
        })
      );
    }

    return Promise.all(creators);
  }

  /**
   * @description Handles Trusted URL form submissions, updating or creating trusted URLs.
   *
   * @param {SubmitEvent} event
   */
  async handleSubmit(event) {
    event.preventDefault();

    if (!(event.target instanceof HTMLFormElement)) {
      console.error(`Event target must be instanceof HTMLFormElement.`);
      return;
    }

    if (!event.target.checkValidity()) {
      this.showToast(
        "Error",
        "Form cannot be submitted due to errors. Please check your Trusted URL fields and try again."
      );
      return;
    }

    this.isLoading = true;

    this.isApplyBtnDisabled = true

    try {
      await this.onCreateTrustedUrls();

      this.showToast("Success", "Trusted Site created successfully", "success");

      /**
       * Forces wired apex methods to re-fetch.
       * 
       * @see https://developer.salesforce.com/docs/platform/lwc/guide/apex-result-caching.html
       */
      await refreshApex(this.__wiredResult);

      /**
       * Falsey's the values so that those created on a first form submit aren't carried over if the
       * user decides to create additional Trusted URLs with subsequent form submits.
       */
      this.uiConnectorWss = "";
      this.uiConnector = "";
      this.checkboxGroupValue = [];

    } catch (error) {
      let message = "Unknown error";

      if (Array.isArray(error.body)) {
        message = error.body.map((e) => e.message).join(", ");
      } else if (typeof error.body.message === "string") {
        message = error.body.message;
      }

      this.showToast("Error", "Error creating site: " + message, "error");
      console.error("Error creating site:", error);

      this.isApplyBtnDisabled = false
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
