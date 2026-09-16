import { LightningElement, api, track } from 'lwc';
import getDocuments from '@salesforce/apex/DocumentController.getDocuments';
import shareDocument from '@salesforce/apex/DocumentController.shareDocument';
import getArchiveDocuments from '@salesforce/apex/DocumentController.getArchiveDocuments';
/* import addFile from '@salesforce/apex/DocumentController.addFile'; */
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { notifyRecordUpdateAvailable } from 'lightning/uiRecordApi';

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
     get acceptedFormats() {
        return ['.pdf', '.png','.jpg', '.jpeg', '.gif', '.doc', '.docx'];
    }


    @api set recordId(value) {
        this._recordId = value;
        this.doGetDocuments();
    }

    get recordId() {
        return this._recordId;
    }
    
    doGetDocuments() {
        getDocuments({ recordId: this._recordId }).then(result => {
            if (result) {
                //console.log('this.documents==>'+JSON.stringify(result));
                this.documents = result;
                this.isDocumentScreenRender = true;
            }
        }).catch(error => {
            console.log('error==>',error);
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

    handleOpenModal(event) {
        this.isShowModal = true;
        this.documentId = event.target.dataset.id;
    }

    handleShareCloseModal(event) {
        this.isShowShareModal = false;
        this.documentId = null;
    }

    handleOpenShareModal(event) {
        this.isShowShareModal = true;
        this.documentId = event.target.dataset.id;
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
    showSuccessMessage(msg) {
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


    handleUploadFinished(event) {
        // Get the list of uploaded files
        const uploadedFiles = event.detail.files;
      this.doGetDocuments();
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