import { LightningElement, api,track } from 'lwc';
import updateCaseStatus from '@salesforce/apex/BCAPP_CaseController.updateCaseStatus';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CloseActionScreenEvent } from 'lightning/actions';

export default class CaseApprovalAction extends LightningElement {
    @api recordId;  // The record ID is passed when the action is invoked
    isLoading = false;
    @track comments;

   handleCommentsChange(event) {
        this.comments = event.target.value;
    }

    handleYes() {
        this.isLoading = true;
        updateCaseStatus({ caseId: this.recordId,status:'Approved',comments:this.comments })
            .then((result) => {

                if(result){
                // Show Error message
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error',
                        message: result,
                        variant: 'error'
                    })
                );
//return;
                }
                else{
                    this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'success',
                        message: 'Request Approved Successfully. ',
                        variant: 'success'
                    })
                );
//return;
                }

            setTimeout(() => {
                location.reload(); 
            }, 2000);

                // Close the action modal
                this.dispatchEvent(new CloseActionScreenEvent());
                // Close the action modal
            })
            .catch(error => {
                console.log('errorerror'+JSON.stringify(error));
                // Show error message
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error',
                        message: error,
                        variant: 'error'
                    })
                );
            })
            .finally(() => {
                this.isLoading = false;
            });
    }

    handleNo() {
        // Close the action modal without doing anything
        this.closePopup();
    }

    closePopup() {
        this.dispatchEvent(new CloseActionScreenEvent());
    }
}