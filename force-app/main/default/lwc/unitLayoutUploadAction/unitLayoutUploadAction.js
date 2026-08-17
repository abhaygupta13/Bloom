import { LightningElement, api, track } from 'lwc';
import { CloseActionScreenEvent } from 'lightning/actions';
import uploadUnitLayouts from '@salesforce/apex/UnitController.uploadUnitLayouts';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class UnitLayoutUploadAction extends LightningElement {

    @track _recordId;
    @track showLoading = false;
    @track floorPlanDocId;
    @track marketingPlanDocId;
    @track affectionPlanDocId;

    @api set recordId(value) {
        this._recordId = value;
    }

    get recordId() {
        return this._recordId;
    }

    get acceptedFileFormats() {
        return ['.png', '.jpg', '.jpeg', '.pdf'];
    }

    handleCancel() {
        this.dispatchEvent(new CloseActionScreenEvent());
    }

    handleUpload() {
        if (!this.floorPlanDocId || !this.marketingPlanDocId || !this.affectionPlanDocId) {
            this.showErrorMessage('Please upload all documents.');
            return;
        }
        this.doUploadUnitLayouts();
    }

    handleFloorPlanFileUploadChange(event) {
        const uploadedFiles = event.detail.files;
        for(var i = 0; i < uploadedFiles.length; i++){
            this.floorPlanDocId = event.detail.files[i].documentId;
            break;
        }
    }

    handleMarketingPlanFileUploadChange(event) {
        const uploadedFiles = event.detail.files;
        for(var i = 0; i < uploadedFiles.length; i++){
            this.marketingPlanDocId = event.detail.files[i].documentId;
            break;
        }
    }

    handleAfectionPlanFileUploadChange(event) {
        const uploadedFiles = event.detail.files;
        for(var i = 0; i < uploadedFiles.length; i++){
            this.affectionPlanDocId = event.detail.files[i].documentId;
            break;
        }
    }

    doUploadUnitLayouts() {
        this.showLoading = true;
        uploadUnitLayouts({
            recordId: this._recordId,
            floorPlanDocId: this.floorPlanDocId,
            marketingPlanDocId: this.marketingPlanDocId,
            affectionPlanDocId: this.affectionPlanDocId
        }).then(result => {
            this.showLoading = false;
            this.showSuccessMessage('Layouts are uploaded successfully!');
            this.dispatchEvent(new CloseActionScreenEvent());
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
}