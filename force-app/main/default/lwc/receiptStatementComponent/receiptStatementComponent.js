import { LightningElement, track, api, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CurrentPageReference } from 'lightning/navigation';
import generateAndAttachPdf from '@salesforce/apex/SalesOrderController.generateAndAttachPdf';
export default class ReceiptStatementComponent extends LightningElement {
 @api recordId;
    fullUrl ='';
    identifier='SalesReceiptPDFPage';


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
        this.fullUrl = '/apex/SalesReceiptPDFPage?id=' + this.recordId
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