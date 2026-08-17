import { LightningElement, api } from 'lwc';
import sendRenewalEmail from '@salesforce/apex/LeaseRenewalEmailController.sendRenewalEmail';

import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CloseActionScreenEvent } from 'lightning/actions';

export default class RenewalReminderPOC extends LightningElement {

    _recordId;
    isProcessed = false;

    @api
    set recordId(value) {
        this._recordId = value;

        console.log('recordId received => ', value);

        if (value && !this.isProcessed) {
            this.isProcessed = true;
            this.sendMail();
        }
    }

    get recordId() {
        return this._recordId;
    }

    async sendMail() {

        try {

            const result = await sendRenewalEmail({
                leasingOrderId: this.recordId
            });

            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Success',
                    message: result,
                    variant: 'success'
                })
            );

        } catch (error) {

            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: error?.body?.message || error.message,
                    variant: 'error'
                })
            );

        } finally {

            this.dispatchEvent(
                new CloseActionScreenEvent()
            );
        }
    }
}