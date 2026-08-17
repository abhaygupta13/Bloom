import { LightningElement, track, api, wire } from 'lwc';
import { getRecord, updateRecord,getRecordNotifyChange } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CloseActionScreenEvent } from 'lightning/actions';
import genLpcssalesorder from '@salesforce/apex/LPCGeneration.genLpcssalesorder';



const FIELDS = ['SalesOrder.Name'];

export default class GenerateLPCcmp extends LightningElement {
  @api recordId;
  @track salesordername;
   @track isLoading=false;

  @wire(getRecord, { recordId: '$recordId', fields: FIELDS })
  wiredRecord({ error, data }) {
    if (data) {
      this.salesordername = data.fields.Name.value; // Corrected field API name
     // alert(this.salesordername); // Using console.log instead of alert
      this.handleGenerateLPC();

    } else if (error) {
      // Handle error
    }
  }

 handleGenerateLPC() {
    genLpcssalesorder({ OrderNumber: [this.salesordername] })
      .then(result => {
        // Handle the result from Apex
        console.log('Result:', result);
         getRecordNotifyChange([{recordId: this.recordId}]);
         this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Success',
                            message: 'LPC generated successfully!',
                            variant: 'success'
                        })
                    );
        this.dispatchEvent(new CloseActionScreenEvent());
        this.isLoading=true;
        //alert()
      })
      .catch(error => {
        // Handle error
        console.error('Error:', error);
      });
  }
}