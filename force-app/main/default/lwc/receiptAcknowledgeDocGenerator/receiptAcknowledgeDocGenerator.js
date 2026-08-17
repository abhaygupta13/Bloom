import { LightningElement, track, api, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CurrentPageReference } from 'lightning/navigation';
import generateAndAttachPdf from '@salesforce/apex/ReceiptAcknowledgementController.generateAndAttachPdf';
import { CloseActionScreenEvent } from 'lightning/actions';
export default class ReceiptAcknowledgeDocGenerator extends LightningElement {
     @api recordId;
    fullUrl ='';
    identifier='generateReceipt';


    @wire(CurrentPageReference)
    getStateParameters(currentPageReference) {

        if (currentPageReference) {
            this.recordId = currentPageReference.state.recordId;
        }
    }
    closeTheAction(event) {

       // this.dispatchEvent(new CloseActionScreenEvent());

    }

    connectedCallback() {
        this.fullUrl = '/apex/ReceiptAcknowledgementPDF?id=' + this.recordId
        this. attachedGeneratedFile();
    }

    attachedGeneratedFile(){
      
        generateAndAttachPdf({salesOrderId:this.recordId,identifier:this.identifier})
        .then(result=>{
            this.result = result;
         
          this.dispatchEvent(
            new ShowToastEvent({
              title: 'success',
              message: 'Document Generated Successfully!',
              variant: 'success'
            })
          );

        }).catch(error=>{
          this.error = error;
          this.dispatchEvent(
            new ShowToastEvent({
              title: 'error',
              message: this.error,
              variant: 'error'
            })
          );


        })
    }



}