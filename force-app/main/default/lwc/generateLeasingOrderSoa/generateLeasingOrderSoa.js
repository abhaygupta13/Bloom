import { LightningElement, api, wire } from 'lwc';
//import generateLeasingStatement from '@salesforce/apex/LeasingDocumentsPDFHandler.generateAndAttachPdf';
import generateLeasingStatement from '@salesforce/apex/LeasingSOAPDFHandler.generateAndAttachPdf';
import { CloseActionScreenEvent } from 'lightning/actions';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CurrentPageReference } from 'lightning/navigation';
import { refreshApex } from '@salesforce/apex';

export default class GenerateLeasingOrderSoa extends LightningElement {
     @api recordId;
    
    @wire(CurrentPageReference)
    getStateParameters(currentPageReference) {
        if (currentPageReference) {
            this.recordId = currentPageReference.state?.recordId || this.recordId;
        }
    }
    connectedCallback() {
        this.handleGeneratePDF();
    }

    handleGeneratePDF() {
        generateLeasingStatement({ leasingOrderId: this.recordId })
            .then((fileId) => {
                // Show success message or refresh page
                console.log('PDF Generated & Attached with File ID:', fileId);
                this.showToast('Success', 'PDF Generated & Attached successfully!', 'success');
                
                setTimeout(() => this.closeQuickAction(),100);
                return refreshApex(this.recordId );
            })
            .catch((error) => {
                console.error('Error generating PDF:', error);
                this.showToast('Error', error.body.message, 'error');
            });
    }
    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({
            title,
            message,
            variant
        }));
    }

    closeQuickAction() {
        this.dispatchEvent(new CloseActionScreenEvent());
    }
}