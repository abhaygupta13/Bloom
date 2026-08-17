import { LightningElement, wire, track, api } from 'lwc';
import shareCommissionInvoice from '@salesforce/apex/BrokerCommissionController.shareCommissionInvoice';
import getRelatedContacts from '@salesforce/apex/BrokerCommissionController.getRelatedContacts';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CloseActionScreenEvent } from 'lightning/actions';
import { notifyRecordUpdateAvailable } from 'lightning/uiRecordApi';


export default class ShareConfirmAction extends LightningElement {
    @track _recordId;
    @track showLoading = false;
    showConfirmDisabled = true;
    @track contacts = [];
    selectedContactId;
    showMsg = false;
    msg = 'Are you sure you want to share this invoice ?';

    @api set recordId(value) {
        this._recordId = value;
    }

    get recordId() {
        return this._recordId;
    }

    @wire(getRelatedContacts, { recordId: '$recordId' })
    wiredContacts({ error, data }) {
        if (data) {
            this.contacts = data.map(contact => ({
                label: contact.Name,
                value: contact.Id
            }));
        } else if (error) {
            var message;
            if (Array.isArray(error.body)) {
                message = error.body.map(e => e.message).join(', ');
            } else if (typeof error.body.message === 'string') {
                message = error.body.message;
            }
            this.showErrorMessage(JSON.stringify(message));
        }
    }
    handleChange(event) {
        this.selectedContactId = event.detail.value;
        this.showConfirmDisabled = false;
        this.showMsg = true;
    }

    handleCancel() {
        this.dispatchEvent(new CloseActionScreenEvent());
    }

    handleConfirm() {
        this.shareInvoice();
    }

    shareInvoice(){
        this.showLoading = true;
        shareCommissionInvoice({ recordId: this._recordId , contactId: this.selectedContactId})
        .then(result => {
            this.showLoading = false;
            if(result === 'true'){
                this.showSuccessMessage('Invoice has been shared successfully!')
            }
            else if(result === 'false'){
                this.showErrorMessage('Invoice not shared!')
            }
            else if(result === 'The selected contact does not have an email address.'){
                this.msg = 'The selected contact does not have an email address. Please update the contact email before proceeding.';
                this.showConfirmDisabled = true;
                return;
            }
            notifyRecordUpdateAvailable([{ recordId: this._recordId }]);
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