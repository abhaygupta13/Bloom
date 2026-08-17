import { LightningElement, api, track } from 'lwc';
import verifyRecord from '@salesforce/apex/VerificationController.verifyRecord';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CloseActionScreenEvent } from 'lightning/actions';
import { notifyRecordUpdateAvailable } from 'lightning/uiRecordApi';

export default class VerificationAction extends LightningElement {

    @track _recordId;
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
        this.doVerifyRecord();
    }

    doVerifyRecord() {
        this.showLoading = true;
        verifyRecord({ recordId: this._recordId }).then(result => {
            this.showLoading = false;
            notifyRecordUpdateAvailable([{ recordId: this._recordId }]);
            this.showSuccessMessage('Record has been verified successfully!');
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