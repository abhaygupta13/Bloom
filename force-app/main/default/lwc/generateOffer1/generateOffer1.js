import { LightningElement, api, wire } from 'lwc';
import generatePDF from '@salesforce/apex/generateOffer1Controller.generatePDF';
import { CloseActionScreenEvent } from 'lightning/actions';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CurrentPageReference } from 'lightning/navigation';
import { refreshApex } from '@salesforce/apex';
export default class GenerateOffer1 extends LightningElement {
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
        generatePDF({ contractId: this.recordId })
            .then((fileId) => {
                // Show success message or refresh page
                console.log('PDF Generated & Attached with File ID:', fileId);
                this.showToast('Success', 'PDF Generated & Attached successfully!', 'success');

                this.closeQuickAction();
                return refreshApex(this.recordId);
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