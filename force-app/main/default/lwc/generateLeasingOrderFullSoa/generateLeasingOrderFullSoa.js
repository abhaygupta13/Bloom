import { LightningElement, api, wire } from 'lwc';
//import generateLeasingStatement from '@salesforce/apex/LeasingDocumentsPDFHandler.generateAndAttachPdf';
import generateLeasingStatement from '@salesforce/apex/LeasingSOAPDFHandler.generateAndAttachPdfSOA_FULL';
import { CloseActionScreenEvent } from 'lightning/actions';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CurrentPageReference } from 'lightning/navigation';
import { refreshApex } from '@salesforce/apex';

export default class GenerateLeasingOrderFullSoa extends LightningElement {
    @api recordId;
    isLoading = false;
    pdc = false;
    sd = false;
    sd1 = false;
    
    @wire(CurrentPageReference)
    getStateParameters(currentPageReference) {
        if (currentPageReference) {
            this.recordId = currentPageReference.state?.recordId || this.recordId;
        }
    }

    handleChange(event) {
        const checkboxType = event.target.dataset.id;

        if (checkboxType === 'pdc') {
            this.pdc = event.target.checked;
        }
        if (checkboxType === 'sd') {
            this.sd = event.target.checked;
        }
        if (checkboxType === 'sd1') {
            this.sd1 = event.target.checked;
        }
    }

    connectedCallback() {
        //this.handleGeneratePDF();
    }
    handleProceed(){
        this.isLoading = true;
        generateLeasingStatement({ leasingOrderId: this.recordId, isPDC : this.pdc, isSecurity : this.sd, Details : this.sd1 })
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

    handleGeneratePDF() {
        this.isLoading = true;
        generateLeasingStatement({ leasingOrderId: this.recordId })
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
        this.dispatchEvent(new CustomEvent('closequickaction'));
    }

    handleCancel() {
        this.dispatchEvent(new CloseActionScreenEvent());
    }
}