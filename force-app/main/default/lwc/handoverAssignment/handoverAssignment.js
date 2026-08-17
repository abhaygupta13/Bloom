import { LightningElement, api,wire } from 'lwc';
import updateHandoverOwner from '@salesforce/apex/HandoverController.updateHandoverOwner';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CloseActionScreenEvent } from 'lightning/actions';
import {CurrentPageReference} from 'lightning/navigation';
import { getRecordNotifyChange } from 'lightning/uiRecordApi';


export default class HandoverAssignment extends LightningElement {
    @api recordId; // Handover recordId is passed when the action is invoked
    isLoading = false;

    @wire(CurrentPageReference)
    getStateParameters(currentPageReference) {
        if (currentPageReference) {
            this.recordId = currentPageReference.state.recordId;
        }
    }

    connectedCallback() {
        //this.updateOwner();
    }

    updateOwner() {
        this.isLoading = true;
        updateHandoverOwner({ handoverId: this.recordId })
            .then((result) => {
                // Check if result contains status
                if (result && result.status === 'error') {
                    // Show error message from Apex
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Error',
                            message: result.message || 'Failed to update handover owner',
                            variant: 'error'
                        })
                    );
                } else {
                    // Show success message
                    const successMessage = (result && result.message) ? result.message : 'Handover owner updated successfully';
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Success',
                            message: successMessage,
                            variant: 'success'
                        })
                    );

                    // Refresh the record view
                    getRecordNotifyChange([{ recordId: this.recordId }]);
                }
                // Close the action modal
                this.dispatchEvent(new CloseActionScreenEvent());
            })
            .catch(error => {
                // Extract error message from different error structures
                let errorMessage = 'Failed to update handover owner';
                
                if (error.body) {
                    if (error.body.message) {
                        errorMessage = error.body.message;
                    } else if (error.body.pageErrors && error.body.pageErrors.length > 0) {
                        errorMessage = error.body.pageErrors[0].message;
                    } else if (error.body.fieldErrors) {
                        const fieldErrorMessages = [];
                        Object.values(error.body.fieldErrors).forEach(fieldError => {
                            fieldError.forEach(err => fieldErrorMessages.push(err.message));
                        });
                        if (fieldErrorMessages.length > 0) {
                            errorMessage = fieldErrorMessages.join(', ');
                        }
                    }
                } else if (error.message) {
                    errorMessage = error.message;
                }

                // Show error message
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error',
                        message: errorMessage,
                        variant: 'error'
                    })
                );
            })
            .finally(() => {
                this.isLoading = false;
            });
    }
}