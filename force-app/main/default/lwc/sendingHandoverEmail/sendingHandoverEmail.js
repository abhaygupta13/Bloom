import { LightningElement, api, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import sendEmail from '@salesforce/apex/HandoverEmailController.sendNOCAndDesnaggingReport';
import { CloseActionScreenEvent } from 'lightning/actions';

export default class SendingHandoverEmail extends LightningElement {
    @track handoverId;
    _recordId;

    @api 
    set recordId(value) {
        this._recordId = value;
       // console.log('this.recordId--->', this.recordId);
        if (this._recordId) {
            this.handleSendEmail();
        }
    }

    connectedCallback() {
       // console.log('this.handoverId', this.handoverId);
    }

    handleSendEmail() {
        //console.log('this._recordId--------->>'+this._recordId);
        sendEmail({ recordId: this._recordId })
            .then(result => {
                this.handleSuccess(result);
            })
            .catch(error => {
                this.handleError(error);
            });
    }

    handleSuccess(result) {
        this.dispatchEvent(new CloseActionScreenEvent());
        this.dispatchEvent(
            new ShowToastEvent({
                title: 'Success',
                message: result,
                variant: 'success'
            })
        );
    }

    handleError(error) {
        this.dispatchEvent(new CloseActionScreenEvent());
        //console.error('Error sending email:', error);
        this.dispatchEvent(
            new ShowToastEvent({
                title: 'Error sending email',
                message: error.body.message,
                variant: 'error'
            })
        );
    }

    get recordId() {
        return this._recordId;
    }
}