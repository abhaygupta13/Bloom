import { LightningElement, api, track } from 'lwc';
import { CloseActionScreenEvent } from 'lightning/actions';
import createLeadFromAccount from '@salesforce/apex/LeadController.createLeadFromAccount';
import validateBeforeLeadCreation from '@salesforce/apex/LeadController.validateBeforeLeadCreation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';

export default class CreateLeadFromAccountAction extends NavigationMixin(LightningElement) {

    @track _recordId;
    @track message = 'Please wait a moment, Lead creation is in progress.';
    @track showLoading = false;
    @track isEnable = false;
    @track msg;

    @api set recordId(value) {
        this._recordId = value;
        this.doValidateBeforeLeadCreation();
    }

    get recordId() {
        return this._recordId;
    }

    doValidateBeforeLeadCreation() {
        this.showLoading = true;
        validateBeforeLeadCreation({ accountId: this._recordId }).then(result => {
            this.showLoading = false;
            if (result) {
                this.msg = result;
            } else {
                this.isEnable = true;
                this.msg = 'Please confirm if you want to create a lead for the selected account.';
            }
        }).catch(error => {
            this.showLoading = false;
            var message;
            if (Array.isArray(error.body)) {
                message = error.body.map(e => e.message).join(', ');
            } else if (typeof error.body.message === 'string') {
                message = error.body.message;
            }
            this.showErrorMessage(JSON.stringify(message));
        });
    }

    doCreateLeadFromAccount() {
        this.showLoading = true;
        createLeadFromAccount({ accountId: this._recordId }).then(result => {
            this.showLoading = false;
            if (result) {
                this.showSuccessMessage('A new Lead has been created for the selected account');
                this.navigateToOpportunityRecord(result);
            }
        }).catch(error => {
            this.showLoading = false;
            var message;
            if (Array.isArray(error.body)) {
                message = error.body.map(e => e.message).join(', ');
            } else if (typeof error.body.message === 'string') {
                message = error.body.message;
            }
            this.showErrorMessage(JSON.stringify(message));
        });
    }

    handleCancel() {
        this.dispatchEvent(new CloseActionScreenEvent());
    }

    handleConfirm() {
        this.doCreateLeadFromAccount();
    }

    showErrorMessage(msg) {
        const event = new ShowToastEvent({
            title: 'Error',
            message: msg,
            variant: 'error',
            mode: 'dismissable'
        });
        this.dispatchEvent(event);
    }

    showSuccessMessage(msg) {
        const event = new ShowToastEvent({
            title: 'Success',
            message: msg,
            variant: 'success',
            mode: 'dismissable'
        });
        this.dispatchEvent(event);
    }

    navigateToOpportunityRecord(leadId) {
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: leadId,
                actionName: 'view'
            }
        });
    }
}