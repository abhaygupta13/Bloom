import { LightningElement, api, track } from 'lwc';
import verifyReceiptAcknowledgement from '@salesforce/apex/ReceiptAcknowledgementController.verifyReceiptAcknowledgement';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CloseActionScreenEvent } from 'lightning/actions';
import { notifyRecordUpdateAvailable } from 'lightning/uiRecordApi';
import hasReceiptAllocation from '@salesforce/apex/ReceiptAcknowledgementController.hasReceiptAllocation';
import LightningConfirm from 'lightning/confirm';


export default class ReceiptVerificationAction extends LightningElement {

    @track _recordId;
    @track showLoading = false;
    @track allocationMissing = false;
    @track allocationMessage = '';
    isChecked = false;

    @api set recordId(value) {
        this._recordId = value;

        if (value && !this.isChecked) {
            this.isChecked = true;
            this.checkAllocationOnLoad();
        }
    }

    get recordId() {
        return this._recordId;
    }

    async checkAllocationOnLoad() {
    this.showLoading = true;

    try {
        const hasAllocation = await hasReceiptAllocation({ recordId: this._recordId });

        this.showLoading = false;

        if (!hasAllocation) {
            this.allocationMissing = true;
            this.allocationMessage = 'No Receipt Allocation found. Do you want to proceed with adding the receipt as On Account.';
        } else {
            this.allocationMissing = false;
        }

    } catch (error) {
        this.showLoading = false;
        this.showErrorMessage('Error checking allocation');
    }
}

    handleCancel() {
        this.dispatchEvent(new CloseActionScreenEvent());
    }

    handleConfirm() {
        this.doVerifyReceiptAcknowledgement();
    }

    doVerifyReceiptAcknowledgement() {
        this.showLoading = true;
        verifyReceiptAcknowledgement({ recordId: this._recordId }).then(result => {
            this.showLoading = false;
            notifyRecordUpdateAvailable([{ recordId: this._recordId }]);
            this.showSuccessMessage('Receipt Acknowledgement has been verified successfully!');
            this.dispatchEvent(new CloseActionScreenEvent());
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