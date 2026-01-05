// @ts-check
import { LightningElement } from "lwc";

export default class Wizard extends LightningElement {
    selectedTab = "1";

    onNext() {
        this.selectedTab = (parseInt(this.selectedTab, 10) + 1).toString();
    }

    onSelect(ev) {
        console.log('ON SELECT', ev)
    }
}