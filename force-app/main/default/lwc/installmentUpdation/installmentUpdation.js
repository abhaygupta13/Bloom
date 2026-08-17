import { LightningElement, track, api, wire } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CloseActionScreenEvent } from 'lightning/actions';
import InstallmentUpdationwithmilestone from '@salesforce/apex/installmentMilestoneUpdationCtlr.Installments';
export default class InstallmentUpdation extends LightningElement {
 
 @api recordId;
   
 @track isLoading = false;
 @track callOnce=true;

    @wire(CurrentPageReference)
    getStateParameters(currentPageReference) {

        if (currentPageReference) {
            this.recordId = currentPageReference.state.recordId;
        
        }
    }
    renderedCallback() {
       
        if(this.callOnce)
         this.MilestonesId();
     }
    MilestonesId(){
        this.callOnce= false;
        this.isLoading = true;
        InstallmentUpdationwithmilestone({ MilestoneId : this.recordId})
        .then(result => {
            this.isLoading = false;
            this.dispatchEvent(
               
                                new ShowToastEvent({
                                    title: 'Success',
                                    message: 'Installments Updated Successful',
                                    variant: 'success'
                                })
                            );
                            this.dispatchEvent(new CloseActionScreenEvent());
        })
        .catch(error => {
            this.isLoading = true;
             this.dispatchEvent(
                                new ShowToastEvent({
                                    title: 'error',
                                    message: error.body.message ,
                                    variant: 'error'
                                })
                            );
                            this.isLoading = fasle;
                            this.dispatchEvent(new CloseActionScreenEvent());
        });

    }
   
}