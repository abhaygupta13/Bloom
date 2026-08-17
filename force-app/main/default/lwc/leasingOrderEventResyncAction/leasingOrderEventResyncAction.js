import { LightningElement, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import sendLeasingOrderToSAP from '@salesforce/apex/IntegrationController.sendLeasingOrderToSAP';
import ValidationLeasingOrderSyncWarning from '@salesforce/apex/LeasingOrderController.ValidationLeasingOrderSyncWarning';
import { CloseActionScreenEvent } from 'lightning/actions';
import { notifyRecordUpdateAvailable } from 'lightning/uiRecordApi';
import LightningConfirm from 'lightning/confirm';

export default class LeasingOrderEventResyncAction extends LightningElement {
    @api recordId;
    showLoading = false;

    async handleConfirm() {
        this.showLoading = true;
        try {
            const hasWarning = await ValidationLeasingOrderSyncWarning({ recordId: this.recordId });

            if (hasWarning) {
                this.showLoading = false;

                const proceed = await LightningConfirm.open({
                    label: 'Warning',
                    message: 'One or more Payment Plan/Other Charges/Receipt Acknowledgement records have Due Date in or before the Posting Closure Month. Do you want to proceed?',
                    variant: 'header'
                });

                if (!proceed) {
                    return;
                }

                this.showLoading = true;
            }

            await sendLeasingOrderToSAP({ recordId: this.recordId });

            this.showLoading = false;
            notifyRecordUpdateAvailable([{ recordId: this.recordId }]);
            this.dispatchEvent(new CloseActionScreenEvent());
        }
        catch(error) {
            this.showLoading = false;
            this.dispatchEvent(new CloseActionScreenEvent());
            this.showErrorMessage(error?.body?.message || error.message || JSON.stringify(error));
        }
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