import { LightningElement, api,wire } from 'lwc';
import createInstallmentsReceipts from '@salesforce/apex/RecalculateResaleInstallmentsController.createInstallmentsReceipts';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CloseActionScreenEvent } from 'lightning/actions';
import {CurrentPageReference} from 'lightning/navigation';
import { getRecordNotifyChange } from 'lightning/uiRecordApi';
export default class RecalculateResaleInstallmentsCmp extends LightningElement {
@api recordId; 
    isLoading = false;

    @wire(CurrentPageReference)
    getStateParameters(currentPageReference) {
        if (currentPageReference) {
            this.recordId = currentPageReference.state.recordId;
        }
    }

    createInstallmentsReceipts() {
        this.isLoading = true;
        createInstallmentsReceipts({ salesOrderId : this.recordId })
            .then(() => {
                // Show success message
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Success',
                        message: 'Installments and Receipts created successfully',
                        variant: 'success'
                    })
                );
                getRecordNotifyChange([{ recordId: this.recordId }]);
                // Close the action modal
                this.dispatchEvent(new CloseActionScreenEvent());
            })
            .catch(error => {
                // Show error message
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error',
                        message: 'Failed to create Installments and Receipts',
                        variant: 'error'
                    })
                );
            })
            .finally(() => {
                this.isLoading = false;
            });
    }
}