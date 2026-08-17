import { LightningElement,api, track } from 'lwc';
import sendApproval from '@salesforce/apex/ApprovalController.sendApproval';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CloseActionScreenEvent } from 'lightning/actions';
import { notifyRecordUpdateAvailable } from 'lightning/uiRecordApi';

export default class ConfirmAction extends LightningElement {
    @track _recordId;
    @track showLoading = false;
    showComments = true;
    errorMsg;
    comment = '';
    @api set recordId(value) {
        this._recordId = value;
    }

    get recordId() {
        return this._recordId;
    }

    handleCancel() {
        this.dispatchEvent(new CloseActionScreenEvent());
    }

    handleSubmit() {
        this.sendForApproval();
    }
    handleCommentChange(event){
        this.comment = event.target.value;
        console.log('comment-->>'+this.comment);
    }

    sendForApproval() {
        
        this.showLoading = true;
        sendApproval({ recordId: this._recordId, comment: this.comment })
        .then(result => {
            this.showLoading = false;
            //result ? this.showSuccessMessage('Record has been send for approval successfully!') : this.showErrorMessage('Request for approval failed!');
            if (result === 'Record has been send for approval successfully!') {
                // refresh the page
                notifyRecordUpdateAvailable([{ recordId: this._recordId }]);

                this.showSuccessMessage(result);
                this.dispatchEvent(new CloseActionScreenEvent());
            } else if(result === 'Request for approval failed!'){
                this.showErrorMessage(result);
                this.dispatchEvent(new CloseActionScreenEvent());
            }
            else{
                this.showComments = false;
                this.showErrorMsg = true;
                this.errorMsg = result;
            }
            
            //this.dispatchEvent(new CloseActionScreenEvent());
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