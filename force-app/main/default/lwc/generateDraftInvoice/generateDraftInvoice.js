import { LightningElement,api,wire,track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import Updateinvoice from '@salesforce/apex/ServiceChargeDraftInvoiceHandler.Generatedraftinvoicesexcecution';
import {CurrentPageReference} from 'lightning/navigation';
import { getRecord, getFieldValue, getRecordNotifyChange } from 'lightning/uiRecordApi';
import { CloseActionScreenEvent } from 'lightning/actions';
export default class GenerateDraftInvoice extends LightningElement {
@api recordId;
hasPartialErrors =false;
errorDetails;
@track callOnce=true;
isLoading = false;

@wire(CurrentPageReference)
getStateParameters(currentPageReference) {
    if (currentPageReference) {
        this.recordId = currentPageReference.state.recordId;
       
    }
}
    renderedCallback() {
       
       if(this.callOnce)
        this.handleClick();
    }

  handleClick() {
         
        this.callOnce= false;
        this.isLoading = true;
        if (this.recordId) {
              const method = "Generate";
            Updateinvoice({ Servicecongid:this.recordId, Method: method })

             .then(result => {
                // Handle the result from the Apex method
                console.log(result);

                if(result.length > 0){
                    this.isLoading = false;
                    this.hasPartialErrors = true;
                    this.errorDetails = result;
                    this.dispatchEvent(
                                new ShowToastEvent({
                                    title: 'Parital Success',
                                    message: 'Generated Invoice has been partially Successful',
                                    variant: 'Warning'
                                })
                            );
                }else{
                    this.dispatchEvent(
                                new ShowToastEvent({
                                    title: 'Success',
                                    message: 'Generated Invoice has been successfully processed',
                                    variant: 'success'
                                })
                            );
                        this.dispatchEvent(new CloseActionScreenEvent());
                }
                           
                           
            })
            .catch(error => {
               
                if (error) {
             
                var message = error.body.message;
                console.error(error);
                    this.dispatchEvent(
                                new ShowToastEvent({
                                    title: 'Error',
                                    message: message,
                                    variant: 'Error'
                                })
                            );
                }
                       this.dispatchEvent(new CloseActionScreenEvent());
                            getRecordNotifyChange([{ recordId: this.recordId }]); 
         
                        
            });
         
                
}
  }
 
}