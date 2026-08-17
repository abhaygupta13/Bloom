import { LightningElement,api,track } from 'lwc';
import saveDetails from '@salesforce/apex/SearchControllerFmApp.saveCheckoutDetails';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
export default class AccessDetailCheckout extends LightningElement {
     @api caseId;
     @track checkouttimeValue='';
     @track showSuccessMessage = false;
     @track isDisabled = false;

handleSubmit() {
       saveDetails({ caseId: this.caseId, checkoutTime: this.checkouttimeValue })
            .then(() => {
                //this.showToast('Success', 'Checkout details saved successfully', 'success');
                this.checkoutTime = '';  // Clear the input field after success
                this.handleBack();
            })
            .catch(error => {
                this.showToast('Error', 'Error saving checkout details: ' + error.body.message, 'error');
            });
       
}

   
handleInputChange(event) {
        const field = event.target.label;
        if (field === 'CheckOut Time') {
         this.checkouttimeValue = event.target.value;
        }
}
showToast(title, message, variant) {
        const evt = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant
        });
        this.dispatchEvent(evt);
}
handleBack() {
        // Toggle visibility between components
        this.showSuccessMessage = true; 
        this.isDisabled = true;
    }

}