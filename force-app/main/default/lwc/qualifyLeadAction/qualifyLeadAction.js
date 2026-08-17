import { LightningElement, api, track } from 'lwc';
import { CloseActionScreenEvent } from 'lightning/actions';
import vaidateLead from '@salesforce/apex/LeadController.vaidateLead';
import qualifyLead from '@salesforce/apex/LeadController.qualifyLead';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';

export default class QualifyLeadAction extends NavigationMixin(LightningElement) {

    @track _recordId;
    @track message = 'Please wait a moment, Lead qualification is in progress.';
    @track missingFields = [];
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
                this.message = 'Please enter all below required fields to mark the lead as Qualified: ';
                this.missingFields = JSON.parse(result);
            } else {
                this.doQualifyLead();
            }
        }).catch(error => {
            this.showLoading = false;
            this.message = ('Error ' + error.body.message);
        });
    }

    doQualifyLead() {
        this.showLoading = true;
        qualifyLead({ leadId: this._recordId }).then(result => {
            this.showLoading = false;
            this.showSuccessMessage('Lead was qualified successfully.');
            this.dispatchEvent(new CloseActionScreenEvent());
        }).catch(error => {
            this.showLoading = false;
            this.message = ('Error ' + error.body.message);
        });
    }

    handleCancel() {
        this.dispatchEvent(new CloseActionScreenEvent());
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
}