import { LightningElement, api, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CloseActionScreenEvent } from 'lightning/actions';
import sendEmailWithChecklist from '@salesforce/apex/ServiceRequestController.sendOriginalDocumentChecklist';
import { NavigationMixin } from 'lightning/navigation';

export default class RequestOriginalDocuments extends NavigationMixin(LightningElement) {
    @api recordId;
    @track selectedValues = [];
    @track message = '';
    @track remarks = '';

    collectionOptions = [
        { label: 'Service Charge Invoices', value: 'Service Charge Invoices' },
        { label: 'Tenancy contract', value: 'Tenancy contract' },
        { label: 'Cheque', value: 'Cheque' },
        { label: 'Other', value: 'Other' }
    ];

    financeOptions = [
        { label: 'Statement of Account', value: 'Statement of Account' },
        { label: 'Broker Invoice - POP', value: 'Broker Invoice - POP' }
    ];

    operationOptions = [
        { label: 'Customer Passport (for all owners)', value: 'Customer Passport (for all owners)' },
        { label: 'Customer EID (for all owners)', value: 'Customer EID (for all owners)' },
        { label: 'Handover Proof Document', value: 'Handover Proof Document' }
    ];

    governmentRelationOptions = [
        { label: 'Unit Registration', value: 'Unit Registration' },
        { label: 'Returned Memo', value: 'Returned Memo' }
    ];

    brokerManagementOptions = [
        { label: 'Broker Invoice', value: 'Broker Invoice' },
        { label: 'Broker Signed Agreement', value: 'Broker Signed Agreement' }
    ];

    handleCheckboxChange(event) {
        const value = event.target.value;
        if (event.target.checked) {
            this.selectedValues = [...this.selectedValues, value];
        } else {
            this.selectedValues = this.selectedValues.filter(item => item !== value);
        }
    }

    handleRemarksChange(event) {
        this.remarks = event.target.value;
    }

    handleSubmit() {
        if (this.selectedValues.length === 0) {
            this.message = 'Please select at least one document.';
            this.showErrorMessage(this.message); // <-- Show toast here
            return;
        }

        sendEmailWithChecklist({ selectedItems: this.selectedValues, caseRecordId : this.recordId, remarks: this.remarks })
            .then(() => {
                this.message = 'Email sent successfully!';
                this.selectedValues = [];
                this.template.querySelectorAll('lightning-input').forEach(input => input.checked = false);
                this.showSuccessMessage(this.message);
            })
            .catch(error => {
                this.message = 'Failed to send email: ' + error.body.message;
                this.showErrorMessage(this.message);
            });

        this.dispatchEvent(new CloseActionScreenEvent());
        // this.navigateToRecord();
    }

    navigateToRecord(){
        console.log('navigate to rec in action', this.recordId);
        this[NavigationMixin.Navigate]( {
            type: 'standard__recordPage',
            attributes: {
                recordId: this.recordId,
                actionName: 'view'
            }
        });
    }

    // Handle the Cancel button click
    handleCancel() {
        this.dispatchEvent(new CloseActionScreenEvent());
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