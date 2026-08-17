import { LightningElement, api, track } from 'lwc';
import getDocuments from '@salesforce/apex/DocumentController.getDocuments';
import shareDocument from '@salesforce/apex/DocumentController.shareDocument';
import getArchiveDocuments from '@salesforce/apex/DocumentController.getArchiveDocuments';
/* import addFile from '@salesforce/apex/DocumentController.addFile'; */
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { notifyRecordUpdateAvailable } from 'lightning/uiRecordApi';
import { RefreshEvent } from 'lightning/refresh';

export default class DocumentManagement extends NavigationMixin(LightningElement) {

    @track _recordId;
    @track documents = [];
    @track archiveDocuments = [];
    @track fileData;
    @track documentId;
    @track isShowModal = false;
    @track showLoading = false;
    @track isShowShareModal = false;
    @track showArchiveModal = false;
    @track isDocumentScreenRender = false;
    @track isFirstDocumentUpload = false;
    get acceptedFormats() {
        return ['.pdf', '.png', '.jpg', '.jpeg', '.gif', '.doc', '.docx'];
    }


    @api set recordId(value) {
        this._recordId = value;
        this.doGetDocuments();
    }

    get recordId() {
        return this._recordId;
    }

    /*doGetDocuments() {
        getDocuments({ recordId: this._recordId }).then(result => {
            if (result) {
                //console.log('this.documents==>'+JSON.stringify(result));
                this.documents = result;
                this.isDocumentScreenRender = true;
            }
        }).catch(error => {
            console.log('error==>',error);
        });
    } */

    doGetDocuments() {
        return getDocuments({ recordId: this._recordId })
            .then(result => {
                if (result) {
                    console.log('OUTPUT : ',this._recordId );
                    console.log('OUTPUT : ',result);
                    this.documents = result;
                    this.isDocumentScreenRender = true;
                }
            })
            .catch(error => {
                console.log('error==>', error);
            });
    }

    doGetArchiveDocuments() {
        this.showLoading = true;
        getArchiveDocuments({ documentId: this.documentId }).then(result => {
            this.showLoading = false;
            if (result) {
                this.archiveDocuments = result;
                this.showArchiveModal = true;
            }
        }).catch(error => {
            this.showLoading = false;
            console.log('error==>', error);
        });
    }

    handleFilePreview(event) {
        this[NavigationMixin.Navigate]({
            type: 'standard__namedPage',
            attributes: {
                pageName: 'filePreview'
            },
            state: {
                selectedRecordId: event.target.dataset.id
            }
        })
    }

    handleCloseModal(event) {
        this.isShowModal = false;
        this.documentId = null;
    }

    /*handleOpenModal(event) {
        this.isShowModal = true;
        this.documentId = event.target.dataset.id;
    } */

    handleOpenModal(event) {
        this.isShowModal = true;
        this.documentId = event.target.dataset.id;

        const selectedDoc = this.documents.find(doc => doc.Id === this.documentId);

        // true only when this Document__c has no file before upload
        this.isFirstDocumentUpload = selectedDoc && !selectedDoc.ContentDocumentId__c;
    }

    handleShareCloseModal(event) {
        this.isShowShareModal = false;
        this.documentId = null;
    }
    handleFileArchive(event) {
        this.documentId = event.target.dataset.id;
        this.doGetArchiveDocuments();
    }

    handleArchiveCloseModal() {
        this.showArchiveModal = false;
        this.archiveDocuments = [];
        this.documentId = null;
    }

    handleOpenShareModal(event) {
        this.isShowShareModal = true;
        this.documentId = event.target.dataset.id;
    }
/* 
    handleFileUpload(event) {
        if (!this.fileData) {
            this.showErrorMessage('Please upload document');
            return;
        }
        this.doAddFile();
    }

    handleFileUploadChange(event) {
        const file = event.target.files[0];
        var reader = new FileReader()
        reader.onload = () => {
            var base64 = reader.result.split(',')[1]
            this.fileData = {
                'filename': file.name,
                'base64': base64,
                'filetype': file.type
            }
        }
        reader.readAsDataURL(file)
    }

    doAddFile() {
        this.showLoading = true;
        addFile({
            base64: this.fileData.base64,
            filename: this.fileData.filename,
            documentId: this.documentId,
        }).then(result => {
            this.showLoading = false;
            this.isShowModal = false;
            this.fileData = null;
            this.documentId = null;
            notifyRecordUpdateAvailable([{ recordId: this._recordId }]);
            this.doGetDocuments();
            this.showSuccessMessage('File uploaded successfully!');
        }).catch(error => {
            this.showLoading = false;
            var message;
            if (Array.isArray(error.body)) {
                message = error.body.map(e => e.message).join(', ');
            } else if (typeof error.body.message === 'string') {
                message = error.body.message;
            }
            this.showErrorMessage(JSON.stringify(message));
        });
    }

 */    showSuccessMessage(msg) {
        const event = new ShowToastEvent({
            title: 'Success',
            message: msg,
            variant: 'success',
            mode: 'dismissable'
        });
        this.dispatchEvent(event);
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

    handleShareConfirm() {
        this.doShareDocument();
    }


    /* handleUploadFinished(event) {
         // Get the list of uploaded files
         const uploadedFiles = event.detail.files;
       this.doGetDocuments();
     } */


    async handleUploadFinished(event) {
        const shouldRefreshCasePage = this.isFirstDocumentUpload;

        this.showLoading = true;

        // Wait because Document trigger updates Case after file upload
        setTimeout(async () => {
            try {
                await this.doGetDocuments();

                await notifyRecordUpdateAvailable([
                    { recordId: this._recordId },   // Case Id
                    { recordId: this.documentId }   // Document__c Id
                ]);

                this.showSuccessMessage('File uploaded successfully!');

                this.isShowModal = false;

                if (shouldRefreshCasePage) {
                    this.dispatchEvent(new RefreshEvent());

                    // Use this only if RefreshEvent does not reload all Case page data
                    // window.location.reload();
                }

            } catch (error) {
                console.log('Upload refresh error ==>', error);
                this.showErrorMessage('File uploaded, but page refresh failed.');
            } finally {
                this.showLoading = false;
                this.documentId = null;
                this.isFirstDocumentUpload = false;
            }
        }, 1500);
    }

    doShareDocument() {
        this.showLoading = true;
        shareDocument({ recordId: this.documentId }).then(result => {
            this.showLoading = false;
            this.isShowShareModal = false;
            this.showSuccessMessage('Document has been shared successfully!');
        }).catch(error => {
            this.showLoading = false;
            var message;
            if (Array.isArray(error.body)) {
                message = error.body.map(e => e.message).join(', ');
            } else if (typeof error.body.message === 'string') {
                message = error.body.message;
            }
            this.showErrorMessage(JSON.stringify(message));
        });
    }
}