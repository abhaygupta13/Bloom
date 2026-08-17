import { LightningElement, api, wire } from 'lwc';
import generateLeasingStatement from '@salesforce/apex/PaymentPlanCreditInvoicePDFHandler.generateAndAttachPdf';
import { CloseActionScreenEvent } from 'lightning/actions';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CurrentPageReference } from 'lightning/navigation';
import { refreshApex } from '@salesforce/apex';

export default class GeneratePaymentCreditInvoice extends LightningElement { 
    
    @api recordId;
    isLoading = false;
    
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
        this.isLoading = true;
        console.log('Leasing Order ID:', this.recordId);
        generateLeasingStatement({ paymentPlanScheduleId: this.recordId })
            .then((fileId) => {
                // Show success message or refresh page
                console.log('PDF Generated & Attached with File ID:', fileId);
                this.isLoading = false;
                this.showToast('Success', 'PDF Generated & Attached successfully!', 'success');
                
                setTimeout(() => this.closeQuickAction(),100);
                return refreshApex(this.recordId );
            })
            .catch((error) => {
                console.error('Error generating PDF:', error);
                this.isLoading = false;
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
        //this.dispatchEvent(new CustomEvent('closequickaction'));
        this.dispatchEvent(new CloseActionScreenEvent());
    }
}