import { LightningElement, api,wire } from 'lwc';
import updateCaseOwner from '@salesforce/apex/BCAPP_CaseController.updateCaseOwner';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CloseActionScreenEvent } from 'lightning/actions';
import {CurrentPageReference} from 'lightning/navigation';
import { getRecordNotifyChange } from 'lightning/uiRecordApi';


export default class CaseAssignment extends LightningElement {
    @api recordId; // Case recordId is passed when the action is invoked
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
handleCancel() {
    this.dispatchEvent(new CloseActionScreenEvent());
}
    updateOwner() {
        this.isLoading = true;
        updateCaseOwner({ caseId: this.recordId })
            .then(() => {
                // Show success message
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Success',
                        message: 'Case owner updated successfully',
                        variant: 'success'
                    })
                );


           /* setTimeout(() => {
                location.reload();
            }, 2000);*/
            
           
            
                getRecordNotifyChange([{ recordId: this.recordId }]);
            
             //getRecordNotifyChange([{ recordId: this.currentRecordId }]);

                // Close the action modal
                this.dispatchEvent(new CloseActionScreenEvent());
            })
            .catch(error => {
                // Show error message
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error',
                        message: 'Failed to update case owner',
                        variant: 'error'
                    })
                );
            })
            .finally(() => {
                this.isLoading = false;
            });
    }
}