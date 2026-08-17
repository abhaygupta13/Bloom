import { LightningElement, api, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';
import sendNOCAndDesnaggingReport from '@salesforce/apex/HandoverEmailController.sendNOCAndDesnaggingReport';
import { CloseActionScreenEvent } from 'lightning/actions';
export default class SendNOCtoCustomer extends NavigationMixin(LightningElement) {
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
        //this.dispatchEvent(new RefreshEvent());
        //console.log('this._recordId--------->>'+this._recordId);
        sendNOCAndDesnaggingReport({ recordId: this._recordId })
            .then(result => {
                if (result == 'Success') {
                    this.handleSuccess('Notice of Completion sent successful');
                }
                else {
                    this.fileValidation(result);

                }
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
         if (this._recordId) {
            this[NavigationMixin.GenerateUrl]({
                type: "standard__webPage",
                attributes: {
                    url: window.location.origin+'/lightning/r/Handover__c/'+this._recordId+'/view'
                }
            }).then(url => {
                window.open(url, "_self");
            });
        }

    }

    fileValidation(result) {
        this.dispatchEvent(new CloseActionScreenEvent());
        this.dispatchEvent(
            new ShowToastEvent({
                title: 'Required',
                message: result,
                variant: 'error'
            })
        );
    }
    handleError(error) {
        this.dispatchEvent(new CloseActionScreenEvent());
        this.dispatchEvent(
            new ShowToastEvent({
                title: 'Error sending email',
                message: error.body.message,
                variant: 'error'
            })
        );
       // window.location.reload();

    }

    get recordId() {
        return this._recordId;
    }

}