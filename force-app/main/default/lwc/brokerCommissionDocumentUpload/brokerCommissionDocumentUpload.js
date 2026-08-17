import { LightningElement, wire, track } from 'lwc';
import uploadBrokerSharedInvoice from '@salesforce/apex/BrokerPortalController.uploadBrokerSharedInvoice';
import isValidInvoiceRecord from '@salesforce/apex/BrokerPortalController.isValidInvoiceRecord';
import { CurrentPageReference } from 'lightning/navigation';

export default class BrokerCommissionDocumentUpload extends LightningElement {
    isUploading = false;
    documentId;
    selectedFile;
    fileName;
    @track isConfirmed = false;
    disableUploadButton = true;
    showForm = false;

    // Get documentId from URL query parameter
    @wire(CurrentPageReference)
    async getStateParameters(currentPageReference) {
        if (currentPageReference) {
            this.documentId = currentPageReference.state?.documentId;
            if (!this.documentId) {
                this.showForm = false;
                return;
            }

            try {
                const isValid = await isValidInvoiceRecord({ documentId: this.documentId });
                if (isValid) {
                    this.showForm = true;
                } else {
                    this.showForm = false;
                }
            } catch (error) {
                console.error('Error validating record:', error);
                this.showForm = false;
                const msg = error?.body?.message || 'Error validating invoice record.';
                alert('Error: ' + msg);
            }
        }
    }

    handleFileChange(event) {
        const files = event.target.files;
        if (files && files.length > 0) {
            this.selectedFile = files[0];
            this.fileName = this.selectedFile.name;
        }
    }

    async handleFileUpload() {
        this.isUploading = true;

        if (!this.selectedFile) {
            alert('Please select a file before uploading!');
            this.isUploading = false;
            return;
        }

        try {

            const base64Data = await this.readFileAsBase64(this.selectedFile);
            await uploadBrokerSharedInvoice({
                documentId: this.documentId,
                fileName: this.selectedFile.name,
                fileBase64Data: base64Data
            });

            alert('File uploaded successfully!');
            this.resetForm();
            window.location.reload();
        } catch (error) {
            console.error('Upload failed:', error);
            const message = error?.body?.message || error?.message || 'An unexpected error occurred.';
             alert('Error : '+message);
        } finally {
            this.isUploading = false;
        }
        
    }

    readFileAsBase64(file) {
        return new Promise((resolve, reject) => {
            const reader = new FileReader();
            reader.onload = () => {
                const base64 = reader.result.split(',')[1];
                resolve(base64);
            };
            reader.onerror = () => reject(new Error('File reading failed.'));
            reader.readAsDataURL(file);
        });
    }

     resetForm() {
        this.fileName = null;
        this.selectedFile = null;
        this.isConfirmed = false;
        const input = this.template.querySelector('input[type="file"]');
        if (input) input.value = null;
    }

    handleCheckboxChange(event) {
        this.disableUploadButton = !event.target.checked;
    }
}