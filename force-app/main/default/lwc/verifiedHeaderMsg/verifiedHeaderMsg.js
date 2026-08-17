import { LightningElement, api, wire, track } from 'lwc';
import BloomResources from '@salesforce/resourceUrl/BloomResources';

export default class VerifiedHeaderMsg extends LightningElement {
    verifiedReceiptImage = BloomResources + "/BloomResources/png/VerifiedIcon.png";
}