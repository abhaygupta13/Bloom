import { api,LightningElement,track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import callApprovalProcess from "@salesforce/apex/approvalProcessSubmitHandler.callApprovalProcess";
import { updateRecord } from 'lightning/uiRecordApi';
import { CloseActionScreenEvent } from 'lightning/actions';
export default class ApprovalProcessSubmitComponent extends LightningElement {
    @api recordId;
    @track isLoaded=true;
    @track isModalOpen=true;
    @track callOnce=true;
  
 
      
    handleSaveClick(event){
        alert(this.recordId)
        alert(this._recordId)
    }

    
    submitforCancellation(){
        alert(this.recordId);
        callApprovalProcess({
            recid: this.recordId
        }).then(result => {
            
            if(result=='Success'){
                const events = new ShowToastEvent({
                        title: "Submitted",
                        message: "Sales Order has been submitted for Cancellation",
                        variant: 'Success'
                    });
                    this.dispatchEvent(events);
                    this.isLoaded=true;
                    this.cancel();
                    this.updateRecordView(this.recordId);
            }

             else{
                const events = new ShowToastEvent({
                        title: "Error",
                        message: JSON.stringify(result),
                        variant: 'Error'
                    });
                    this.dispatchEvent(events);
                    this.cancel();
                    this.updateRecordView(this.recordId);
            } 

            //updateRecord({fields: { Id: this.recordId }});
        }).catch(error => {
            this.cancel();
             /* const events = new ShowToastEvent({
                        title: "Error",
                        message: error.getMessage(),
                        variant: 'Error'
                    });
                    this.dispatchEvent(events); */
        });
    }

    updateRecordView(recordId) {
       updateRecord({fields: { Id: recordId }});
   }

   closeModal(){
       this.isModalOpen=false;
       this.dispatchEvent(new CloseActionScreenEvent());
   }
}