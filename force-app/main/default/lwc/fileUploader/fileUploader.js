import { LightningElement, api } from 'lwc';

export default class FileUploader extends LightningElement {
    @api label = 'Upload File'; // Custom label
    @api acceptedFormats = '.png,.jpg,.jpeg,.pdf'; // Allowed formats
    @api identifier; // Unique identifier for multiple instances
    @api subidentifier; // Unique subidentifier for multiple instances
    fileName = ''; // Store uploaded file name
    fileData = null; // Store file data

    handleFileChange(event) {
        const file = event.target.files[0];
        if (file) {
            this.fileName = file.name;
            const reader = new FileReader();
            console.log('this.identifier:::',this.identifier);
            console.log('file.name:::',file.name);
            console.log('file.type:::',file.type);
            reader.onload = () => {
                this.fileData = {
                    identifier: this.identifier, // Include identifier in event
                    filename: file.name,
                    base64: reader.result.split(',')[1], // Extract base64
                    type: file.type,
                    subidentifier: this.subidentifier
                };
               console.log('AJ:::', this.fileData);
                // Dispatch event to parent with identifier
                this.dispatchEvent(new CustomEvent('fileuploaded', { 
                    detail: this.fileData 
                }));
            };
            reader.readAsDataURL(file);
        }
    }

    handleRemoveFile() {
        this.fileName = '';
        this.fileData = null;

        // Reset file input (for lightning-input)
        const fileInput = this.template.querySelector('.file-input');
        if (fileInput) {
            fileInput.value = null;
        }

        // Dispatch event to notify parent with identifier
        this.dispatchEvent(new CustomEvent('fileremoved', {
            detail: { identifier: this.identifier }
        }));
    }
}