import { LightningElement, api,track,wire } from 'lwc';
import updateCaseStatus from '@salesforce/apex/BCAPP_CaseController.updateCaseStatus';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CloseActionScreenEvent } from 'lightning/actions';

export default class CaseRejectionAction extends LightningElement {
    @api recordId;  // The record ID is passed when the action is invoked
    isLoading = false;
    @track comments = '';

        handleCommentsChange(event) {
        this.comments = event.target.value;
    }

showToast(title, message, variant) {
        const event = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant,
        });
        this.dispatchEvent(event);
    }

    handleYes() {

         if (this.comments.trim() === '') {
            this.showToast('Error', 'Please enter comments to update the status', 'error');
        } else {

        this.isLoading = true;
        updateCaseStatus({ caseId: this.recordId,status:'Rejected',comments:this.comments  })
            .then(() => {
                // Show success message
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Success',
                        message: 'Case status updated to Rejected',
                        variant: 'success'
                    })
                );
                // Close the action modal


            setTimeout(() => {
                location.reload();
            }, 2000);

                // Close the action modal
                this.dispatchEvent(new CloseActionScreenEvent());
                            })
            .catch(error => {
                // Show error message
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error',
                        message: 'Failed to update case status',
                        variant: 'error'
                    })
                );
            })
            .finally(() => {
                this.isLoading = false;
            });
        }
    }

    handleNo() {
        // Close the action modal without doing anything
        this.closePopup();
    }

    closePopup() {
        this.dispatchEvent(new CloseActionScreenEvent());
    }
}