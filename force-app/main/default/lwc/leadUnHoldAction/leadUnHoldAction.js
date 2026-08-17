import { LightningElement, api, track } from 'lwc';
import { CloseActionScreenEvent } from 'lightning/actions';
import handleLeadUnHold from '@salesforce/apex/LeadController.handleLeadUnHold';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { notifyRecordUpdateAvailable } from 'lightning/uiRecordApi';


export default class LeadUnHoldAction extends LightningElement {

    @track _recordId;
    @track message = 'Please confirm to unhold the selected lead.';
    @track showLoading = false;

    @api set recordId(value) {
        this._recordId = value;
    }

    get recordId() {
        return this._recordId;
    }

    handleCancel() {
        this.dispatchEvent(new CloseActionScreenEvent());
    }

    handleConfirm() {
        this.doHandleLeadUnHold();
    }

    async doHandleLeadUnHold() {
        this.showLoading = true;
        handleLeadUnHold({ leadId: this._recordId }).then(result => {
            this.showSuccessMessage('Lead updated successfully!');
            notifyRecordUpdateAvailable([{recordId: this._recordId}]);
            this.dispatchEvent(new CloseActionScreenEvent());
            this.showLoading = false;
        }).catch(error => {
            this.showLoading = false;
        });
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