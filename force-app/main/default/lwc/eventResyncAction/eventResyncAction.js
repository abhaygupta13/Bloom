import { LightningElement, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import reTriggerPlatformEvent from '@salesforce/apex/IntegrationController.reTriggerPlatformEvent';
import { CloseActionScreenEvent } from 'lightning/actions';
import { notifyRecordUpdateAvailable } from 'lightning/uiRecordApi';

export default class EventResyncAction extends LightningElement {
    @api recordId;
    showLoading = false;
    handleConfirm() {
        this.showLoading = true;
        reTriggerPlatformEvent({ recordId: this.recordId })
            .then(result => {
                this.showLoading = false;
                notifyRecordUpdateAvailable([{ recordId: this.recordId }]);
                this.dispatchEvent(new CloseActionScreenEvent());
            })
            .catch(error => {
                this.showLoading = false;
                console.log('Error:', JSON.stringify(error));

                this.dispatchEvent(new CloseActionScreenEvent());

                let errorMessage = 'Something went wrong.';

                if (error?.body?.message) {
                    const match = error.body.message.match(
                        /FIELD_CUSTOM_VALIDATION_EXCEPTION,\s*(.*?)(?=:\s*\[\]|$)/
                    );

                    errorMessage = match ? match[1].trim() : error.body.message;
                }

                this.showErrorMessage(errorMessage);
            })
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