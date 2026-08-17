import { LightningElement, wire } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';

import getReminder from '@salesforce/apex/LeaseRenewalEmailController.getReminder';
import saveResponse from '@salesforce/apex/LeaseRenewalEmailController.saveResponse';

import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class RenewalResponseForm extends LightningElement {

    token;
    reminder;
    response;

    isLoading = false;
    isSaving = false;

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

    @wire(CurrentPageReference)
    currentPageReference(pageRef) {

        if (pageRef && pageRef.state) {

           this.token = pageRef.state.token;

            if (this.token) {
                this.loadData();
            }
        }
    }

    async loadData() {

        this.isLoading = true;

        try {

            this.reminder = await getReminder({
                token: this.token
            });

        } catch (error) {

            console.log(JSON.stringify(error));


        } finally {
            this.isLoading = false;
        }
    }

    handleChange(event) {
        this.response = event.detail.value;
    }

    async save() {

        if (!this.response) {
            console.log(JSON.stringify(error));

            return;
        }

        this.isSaving = true;
        console.log('token ' + this.token)
        try {

            await saveResponse({
                token: this.token,
                response: this.response
            });

            // Reload the latest Reminder from Apex
            //await this.loadData();


            this.reminder = {
                ...this.reminder,
                Stage__c: 'Responded'
            };
        } catch (error) {

            console.log(JSON.stringify(error));

        } finally {

            this.isSaving = false;
        }
    }

    get isResponded() {
        return this.reminder?.Stage__c === 'Responded';
    }

    get recordLoaded() {
        return this.reminder && !this.isResponded;
    }

    get leasingOrderId() {
        return this.reminder?.LeasingOrder__c;
    }

    get customerName() {
        return this.reminder?.LeasingOrder__r?.Account__r?.Name || '';
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