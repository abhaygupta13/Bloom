import { LightningElement, wire } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';

import getReminder from '@salesforce/apex/ReminderController.getReminder';
import saveResponse from '@salesforce/apex/ReminderController.saveResponse';

import BLOOM_LOGO from '@salesforce/resourceUrl/BloomLogo';

export default class LeaseRenewalResponse extends LightningElement {

    token;
    reminder;
    response;
    bloomLogoUrl = BLOOM_LOGO;
    isLoading = false;
    isSaving = false;
    validationMessage = '';

    connectedCallback() {
        console.log('connectedCallback fired');
    }

    renderedCallback() {
        console.log('renderedCallback fired');
    }

    options = [
        {
            label: 'Renew',
            value: 'Renew'
        },
        {
            label: "Don't Renew",
            value: 'Not Renew'
        }
    ];

    get isExpired() {
        return (
            this.reminder?.Stage__c === 'Expired' ||
            this.reminder?.Stage__c === 'Cancelled'
        );
    }

    get recordLoaded() {
        return this.reminder && !this.isResponded && !this.isExpired;
    }

    @wire(CurrentPageReference)
    currentPageReference(pageRef) {

        console.log('CurrentPageReference:', JSON.stringify(pageRef));

        if (pageRef && pageRef.state) {

            console.log('Page State:', JSON.stringify(pageRef.state));

            this.token = pageRef.state.token;

            console.log('Token:', this.token);

            if (this.token) {
                console.log('Calling loadData()');
                this.loadData();
            } else {
                console.log('Token is missing');
            }
        } else {
            console.log('Page reference or state is undefined');
        }
    }

    async loadData() {

        console.log('Entered loadData()');

        this.isLoading = true;

        try {

            console.log('Calling getReminder...');

            this.reminder = await getReminder({
                token: this.token
            });

            console.log('Reminder Response:', JSON.stringify(this.reminder));

        } catch (error) {

            console.error('getReminder Error:', error);
            console.error('getReminder token:', this.token);
            console.error(JSON.stringify(error));

        } finally {

            this.isLoading = false;
            console.log('loadData() completed');
        }
    }

    handleChange(event) {
        this.response = event.detail.value;
        this.validationMessage = '';
        console.log('Selected Response:', this.response);
    }

    async save() {

        console.log('Save button clicked');

        if (!this.response) {
            this.validationMessage = 'Please select a renewal decision.';
            return;
        }

        this.validationMessage = '';
        this.isSaving = true;

        try {

            await saveResponse({
                token: this.token,
                response: this.response
            });

            this.reminder = {
                ...this.reminder,
                Stage__c: 'Responded'
            };

        } catch (error) {
            console.error('Save Error: ', JSON.stringify(error));
        } finally {
            this.isSaving = false;
        }
    }

    get isResponded() {
        return this.reminder?.Stage__c === 'Responded';
    }

    get leasingOrderId() {
        return this.reminder?.LeasingOrder__c;
    }

    get leasingOrderNumber() {
        return this.reminder?.LeasingOrder__r?.LeasingOrderNumber__c || '';
    }

    get startDate() {
        return this.reminder?.LeasingOrder__r?.LeasingStartDate__c;
    }

    get endDate() {
        return this.reminder?.LeasingOrder__r?.LeasingEndDate__c;
    }

    get annualRent() {
        return this.reminder?.LeasingOrder__r?.AppliedAnnualRent__c;
    }
}