import { LightningElement, track, api, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CurrentPageReference } from 'lightning/navigation';
import generateAndAttachPdf from '@salesforce/apex/InstallmentLineController.generateAndAttachPdf';
import { CloseActionScreenEvent } from 'lightning/actions';
export default class GenerateProformaInvoice extends LightningElement {
@api recordId;
    fullUrl ='';
    identifier='salesProformaPDF';

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
        this.fullUrl = '/apex/SalesProformaInvoicePDF?id=' + this.recordId  + '&docName=ProformaInvoice';
        this. attachedGeneratedFile();
    }

    attachedGeneratedFile(){
      
        generateAndAttachPdf({installmentId:this.recordId,identifier:this.identifier})
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