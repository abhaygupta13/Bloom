import { api, LightningElement, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import callApprovalProcess from "@salesforce/apex/approvalProcessSubmitHandler.callApprovalProcess";
import getCaseRecordTypeDeveloperName from '@salesforce/apex/approvalProcessSubmitHandler.getCaseRecordTypeDeveloperName';
import { updateRecord } from 'lightning/uiRecordApi';
import { CloseActionScreenEvent } from 'lightning/actions';
import { RefreshEvent } from 'lightning/refresh';
export default class ApprovalProcessSubmitComponent extends LightningElement {
    //@api recordId;
    @track isLoaded = true;
    @track isModalOpen = true;
    @track callOnce = true;



    handleSaveClick(event) {
        alert(this.recordId)
        alert(this._recordId)
    }

    recordTypeDeveloperName;
    isLoading = true;
    isBrokerAgentRegistration = false;

    isInitialized = false;

    @api
    set recordId(value) {
        this._recordId = value;

        if (value) {
            console.log('recordId =>', value);
            this.getRecordType();
        }
    }

    get recordId() {
        return this._recordId;
    }

    getRecordType() {

        if (!this.recordId) {
            console.error('recordId is null/undefined');
            return;
        }

        getCaseRecordTypeDeveloperName({
            caseId: this.recordId
        })
            .then(result => {
                console.log('Record Type Developer Name => ', result);

                //this.recordTypeDeveloperName = result;
                this.isBrokerAgentRegistration =
                    result === 'BrokerAgentRegistrationAndUpdate';

                console.log('isBrokerAgentRegistration => ',
                    this.isBrokerAgentRegistration);
            })
            .catch(error => {
                console.error(JSON.stringify(error));
            })
            .finally(() => {
                this.isLoading = false;
            });
    }

    hasSubmitted = false;

get showBrokerSubmitPanel() {
    return this.isBrokerAgentRegistration && !this.hasSubmitted;
}

    submitforCancellation() {
    if (!this.recordId) {
        this.dispatchEvent(
            new ShowToastEvent({
                title: 'Error',
                message: 'Record Id is missing',
                variant: 'error'
            })
        );
        return;
    }

    this.isLoading = true;

    callApprovalProcess({
        recid: this.recordId
    })
    .then(() => {
        this.hasSubmitted = true;
        this.isBrokerAgentRegistration = false;
        this.isModalOpen = false;

        this.dispatchEvent(
            new ShowToastEvent({
                title: 'Submitted',
                message: 'Record has been submitted',
                variant: 'success'
            })
        );

        return updateRecord({
            fields: {
                Id: this.recordId
            }
        });
    })
    .then(() => {
        this.dispatchEvent(new RefreshEvent());

        // Close quick action first
        this.dispatchEvent(new CloseActionScreenEvent());

        // Do NOT use window.location.reload()
        // Redirect to Case record page, so quick action panel will not reopen
        setTimeout(() => {
            window.location.replace('/lightning/r/Case/' + this.recordId + '/view');
        }, 700);
    })
    .catch(error => {
        console.error('Approval submission error:', JSON.stringify(error));

        this.dispatchEvent(
            new ShowToastEvent({
                title: 'Error',
                message: error?.body?.message || 'Something went wrong while submitting the record',
                variant: 'error'
            })
        );

        this.isLoading = false;
    });
}


    updateRecordView(recordId) {
        updateRecord({ fields: { Id: recordId } });
    }

    closeModal() {
        this.isModalOpen = false;
        this.dispatchEvent(new CloseActionScreenEvent());
    }

    showToast(title, message, variant) {
        this.dispatchEvent(
            new ShowToastEvent({
                title,
                message,
                variant
            })
        );
    }
}