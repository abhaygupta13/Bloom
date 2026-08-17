import { LightningElement, api, track } from 'lwc';
import reassignCase from '@salesforce/apex/ServiceRequestController.reassignCase';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class ChangeOwnerAction extends LightningElement {
    @api recordId;   // Case Id
    @track selectedUserId;

    get isSubmitDisabled() {
        return !this.selectedUserId;
    }

    handleUserChange(event) {
        //const selected = event.detail.recordId;
        const selected = event.detail.recordId;
        this.selectedUserId = selected;
       
    }

    handleSubmit() {
        reassignCase({
            caseId: this.recordId,
            newOwnerId: this.selectedUserId
        })
        .then(() => {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Success',
                    message: 'Case and related Tasks reassigned successfully.',
                    variant: 'success'
                })
            );

            // close quick action
            this.dispatchEvent(new CustomEvent('close'));
        })
        .catch(error => {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: error.body.message,
                    variant: 'error'
                })
            );
        });
    }

    handleCancel() {
        this.dispatchEvent(new CustomEvent('close'));
    }
}