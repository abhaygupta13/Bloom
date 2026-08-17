import { LightningElement, api, track } from 'lwc';
import { CloseActionScreenEvent } from 'lightning/actions';
import vaidateLead from '@salesforce/apex/LeadConversionController.vaidateLead';
import convertLead from '@salesforce/apex/LeadConversionController.convertLead';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';

export default class LeadConvertAction extends NavigationMixin(LightningElement) {

    @track _recordId;
    @track accountId;
    @track leadRecord;
    @track accountRecord;
    @track message = 'Please wait a moment, Lead conversion is in progress.';
    @track missingFields = [];
    @track hasDuplicateAccount = false;
    @track isIndividualLead = false;
    @track showLoading = false;
    @track showConfirmDialog = false;

    @track isDisabled = true;

    @api set recordId(value) {
        this._recordId = value;
        this.doVaidateLead();
    }

    get recordId() {
        return this._recordId;
    }

    doVaidateLead() {
        this.showLoading = true;
        vaidateLead({ leadId: this._recordId }).then(result => {
            this.showLoading = false;
            if (result) {
                var resultData = JSON.parse(result);
                this.leadRecord = resultData.objLead;
                this.accountRecord = resultData.objAccount;
                this.message = resultData.message;
                this.isIndividualLead = resultData.isIndividualLead;
                this.hasDuplicateAccount = resultData.hasDuplicateAccount;
                this.missingFields = resultData.missingFields;
                if (this.hasDuplicateAccount) {

                    if (this.accountRecord) {
                        this.accountId = this.accountRecord.Id;
                    }
                }
                if (resultData.isEligibleToConvert) {
                    this.doConvertLead();
                }
            }
        }).catch(error => {
            this.showLoading = false;
            this.message = ('Error ' + error.body.message);
        });
    }

    doConvertLead() {
        this.showLoading = true;
        convertLead({ leadId: this._recordId, accountId: this.accountId }).then(result => {
            this.showLoading = false;
            if (result) {
                var resultData = JSON.parse(result);
                if (resultData.opportunityId) {
                    this.showSuccessMessage('Lead was converted successfully.');
                    this.navigateToOpportunityRecord(resultData.opportunityId);
                    this.dispatchEvent(new CloseActionScreenEvent());
                } else {
                    this.message = 'Lead conversion failed due to some technical error, please contact your administrator. \n' + resultData.message;
                }
            }
        }).catch(error => {
            this.showLoading = false;
            this.message = ('Error ' + error.body.message);
        });
    }

    handleCancel() {
        this.dispatchEvent(new CloseActionScreenEvent());
    }

    handleConfirm() {
        this.doConvertLead();
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

    navigateToOpportunityRecord(opportunityId) {
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: opportunityId,
                actionName: 'view'
            }
        });
    }
}