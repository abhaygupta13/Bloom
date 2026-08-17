import { LightningElement, api, wire} from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import VERIFIED_FIELD from '@salesforce/schema/ReceiptAcknowledgement__c.Finance_Verified__c';
import BloomResources from '@salesforce/resourceUrl/BloomResources';

export default class ReceiptVerifiedHeaderMsg extends LightningElement {
    verifiedReceiptImage = BloomResources + "/BloomResources/png/VerifiedIcon.png";

    @api recordId;
    @wire(getRecord, { recordId: '$recordId', fields: [VERIFIED_FIELD] })
    account;

    get isVerified() {
        return getFieldValue(this.account.data, VERIFIED_FIELD);
    }
}