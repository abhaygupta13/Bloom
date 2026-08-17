import { LightningElement, api, wire, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import sendEmail from '@salesforce/apex/ServiceRequestController.sendDefaultNoticeEmail';
import fetchEmailTemplate from '@salesforce/apex/ServiceRequestController.fetchDefaultNoticeEmailTemplate';
import { CloseActionScreenEvent } from 'lightning/actions';

export default class SendDefaultNotice extends LightningElement {
    @api recordId;
    template;
    showFileUpload = false;
    showLoading = true;
    fileData = [];
    isModalOpen = true;
    uploadedFiles;
    showErrorMsg = false;
    errorMsg = '';
    showEmailAction = false;

    
    get uploadedFileNames(){
        return this.uploadedFiles.map(file => file.filename).join(', ');
    }

    handleCancel() {
        this.dispatchEvent(new CloseActionScreenEvent());
    }

    handleAttach() {
        this.showFileUpload = true;
        this.uploadedFiles = [];
    }

    handleSend() {
        this.showLoading = true;
        sendEmail({ recordId: this.recordId, fileList : JSON.stringify(this.fileData)})
        .then(result => {
            if(result === 'true'){
                this.dispatchEvent(new CloseActionScreenEvent());
                this.showSuccessMessage('Email Sent Successfully');
            }
            else if(result === 'false'){
                this.dispatchEvent(new CloseActionScreenEvent());
                this.showErrorMessage('Send Email Fail!');
            } 
            else if(result === 'Customer email not found'){
                // this.dispatchEvent(new CloseActionScreenEvent());
                // this.showErrorMessage('Customer email not found');
                this.errorMsg = 'Customer email not found';
                this.showErrorMsg = true;
                this.showEmailAction = false; 
            }   
            else if(result === 'Primary contact not found'){
                // this.dispatchEvent(new CloseActionScreenEvent());
                this.errorMsg = 'Primary contact not found';
                this.showErrorMsg = true;
                this.showEmailAction = false;
            }
            else if(result === 'Default Notice not found'){
                // this.dispatchEvent(new CloseActionScreenEvent());
                this.errorMsg = 'Default Notice not found. Please generate Default Notice from Generate Document button.';
                this.showErrorMsg = true;
                this.showEmailAction = false;
            } 
            else if(result === 'Statement of Account not found'){
                // this.dispatchEvent(new CloseActionScreenEvent());
                this.errorMsg = 'Statement of Account not found. Please upload Statement of Account.';
                this.showErrorMsg = true;
                this.showEmailAction = false;
            }     
            this.showLoading = false;
             
        })
        .catch(error => {
            var message;
            if (Array.isArray(error.body)) {
                message = error.body.map(e => e.message).join(', ');
            } else if (typeof error.body.message === 'string') {
                message = error.body.message;
            }
            this.dispatchEvent(new CloseActionScreenEvent());
            this.showErrorMessage(JSON.stringify(message));
        })
    }
    // fetch the email template body
    @wire(fetchEmailTemplate, { recordId: '$recordId' })
    emailTemplate({ error, data }) {
        console.log('data ::::: '+ data);
        debugger;
        if (data) {
            if(data === 'Email template not found'){
                this.errorMsg = 'Email template not found.';
                this.showErrorMsg = true;
                return;
            }
            else if(data === 'Customer Email not found'){
                this.errorMsg = 'Customer Email not found.';
                this.showErrorMsg = true;
                return;
            }
            else if(data === 'Primary contact not found'){
                this.errorMsg = 'Primary contact not found.';
                this.showErrorMsg = true;
                return;
            }
            this.showEmailAction = true;
            console.log('data'+data);
            this.template = data; 
        } else if (error) {
            var message;
            if (Array.isArray(error.body)) {
                message = error.body.map(e => e.message).join(', ');
            } else if (typeof error.body.message === 'string') {
                message = error.body.message;
            }
            this.showErrorMessage(JSON.stringify(message));
        }
        this.showLoading = false;
    }

    async handleFileUploadChange(event) {
        const files = event.target.files;
        const fileDataArray = [];
        // Create an array of promises to read each file
        const promises = Array.from(files).map(file => {
            return new Promise((resolve, reject) => {
                const reader = new FileReader();
                reader.onload = () => {
                    const base64 = reader.result.split(',')[1];
                    fileDataArray.push({
                        filename: file.name,
                        base64: base64,
                        filetype: file.type
                    });
                    resolve();
                };
    
                reader.onerror = (error) => {
                    reject(error);
                };
                reader.readAsDataURL(file);
            });
        });
    
        // Wait for all files to be read
        try {
            await Promise.all(promises);
            this.fileData = [...this.fileData, ...fileDataArray];
            this.uploadedFiles = fileDataArray;
        } catch (error) {
            console.error('Error reading files:', error);
        }
    
    }
    //remove file from array on click of cross icon
    handleRemoveFile(event) {
        const index = event.currentTarget.getAttribute('data-index');
        this.fileData = this.fileData.filter((a,b) => b !== parseInt(index));
    }

    handleFileUpload(event) {
        if (!this.fileData) {
            this.showErrorMessage('Please upload document');
            return;
        }
        this.showFileUpload = false;
    }

    handleCloseModal(event) {
        this.showFileUpload = false;
    }
    closeModal(){
        this.isModalOpen = false;
    }

    showErrorMessage(msg) {
        const event = new ShowToastEvent({
            title: 'Error',
            message: msg,
            variant: 'error',
            mode: 'dismissable'
        });
        this.dispatchEvent(event);
    }

    showSuccessMessage(msg) {
        const event = new ShowToastEvent({
            title: 'Success',
            message: msg,
            variant: 'success',
            mode: 'dismissable'
        });
        this.dispatchEvent(event);
    }
}