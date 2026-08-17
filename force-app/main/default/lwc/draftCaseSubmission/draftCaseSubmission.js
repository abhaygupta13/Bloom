import { LightningElement, api,wire } from 'lwc';
import checkDocumentsAndSubmit from '@salesforce/apex/BCAPP_CaseController.checkDocumentsAndSubmit';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CloseActionScreenEvent } from 'lightning/actions';
import {CurrentPageReference} from 'lightning/navigation';


export default class DraftCaseSubmission extends LightningElement {
    @api recordId; // Case recordId is passed when the action is invoked
    isLoading = false;

    @wire(CurrentPageReference)
getStateParameters(currentPageReference) {
    if (currentPageReference) {
        this.recordId = currentPageReference.state.recordId;
    }
}


    connectedCallback() {
        this.updateOwner();
    }

    updateOwner() {
        this.isLoading = true;
        checkDocumentsAndSubmit({ caseId: this.recordId })
            .then((result) => {
                

if(!result){
                         // Show success message
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error',
                        message: 'Please upload all the Customer Documents.',
                        variant: 'error'
                    })
                );
                                // Close the action modal

}else{


                // Show success message
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Success',
                        message: 'Case submittted successfully',
                        variant: 'success'
                    })
                );
                
}

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