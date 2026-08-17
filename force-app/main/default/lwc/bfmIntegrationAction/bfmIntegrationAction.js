import { LightningElement, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CloseActionScreenEvent } from 'lightning/actions';
import { notifyRecordUpdateAvailable } from 'lightning/uiRecordApi';
import sendToBFM from '@salesforce/apex/ServiceRequestController.sendToBFM';

export default class BfmIntegrationAction extends LightningElement {

    @api recordId;
    disableSubmit = false;
    showLoading = false;
    msg = 'Are you sure you want to share this service request to BFM System ?';
    handleConfirm(){
        this.showLoading = true;
        sendToBFM({recordId: this.recordId})
        .then(result=>{
            this.showLoading = false;
            if(result){
                this.disableSubmit = true;
                this.msg = result;
                return;
            }
            notifyRecordUpdateAvailable([{ recordId: this.recordId }]);
            this.showSuccessMessage('Request has been submitted to BFM successfully !');
            this.dispatchEvent(new CloseActionScreenEvent());
        })
        .catch(error=>{
            this.showLoading = false;
            this.dispatchEvent(new CloseActionScreenEvent());
            var message;
            if (Array.isArray(error.body)) {
                message = error.body.map(e => e.message).join(', ');
            } else if (typeof error.body.message === 'string') {
                message = error.body.message;
            }
            this.showErrorMessage(JSON.stringify(message));
        })
    }

    handleCancel(){
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