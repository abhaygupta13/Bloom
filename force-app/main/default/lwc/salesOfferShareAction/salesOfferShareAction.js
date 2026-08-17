import { LightningElement, api, track } from 'lwc';
import shareSalesOffer from '@salesforce/apex/SalesOfferController.shareSalesOffer';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CloseActionScreenEvent } from 'lightning/actions';

export default class SalesOfferShareAction extends LightningElement {

    @track _recordId;

    @api set recordId(value) {
        this._recordId = value;
    }

    get recordId() {
        return this._recordId;
    }

    handleCancel() {
        this.dispatchEvent(new CloseActionScreenEvent());
    }

    handleConfirm() {
        this.doShareSalesOffer();
    }

    doShareSalesOffer() {
        shareSalesOffer({ salesOfferId: this._recordId }).then(result => {
            this.dispatchEvent(new CloseActionScreenEvent());
            this.showSuccessMessage('Sales offer has been shared successfully!');
        }).catch(error => {
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