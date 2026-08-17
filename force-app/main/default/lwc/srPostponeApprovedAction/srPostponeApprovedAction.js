import { LightningElement, api } from 'lwc';
import getPostponeApprovedPicklistValues from '@salesforce/apex/srPostponeApprovedActionController.getPostponeApprovedPicklistValues';
import updatePostponeApprovedField from '@salesforce/apex/srPostponeApprovedActionController.updatePostponeApprovedField';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CloseActionScreenEvent } from 'lightning/actions';
//import { NavigationMixin } from 'lightning/navigation';
import { notifyRecordUpdateAvailable } from 'lightning/uiRecordApi';

export default class SrPostponeApprovedAction extends LightningElement {
    @api recordId;
    options = [];
    selectedValue = '';
    isLoading = false;

    connectedCallback() {
        this.fetchPicklistValues();
    }

    async fetchPicklistValues() {
        try {
            this.isLoading = true;
            const result = await getPostponeApprovedPicklistValues();
            this.options = result.map(val => ({ label: val, value: val }));
        } catch (error) {
            this.showToast('Error', error.body?.message || error.message, 'error');
        } finally {
            // Whether success or error, stop showing spinner
            this.isLoading = false;
        }
    }

    handleChange(event) {
        this.selectedValue = event.detail.value;
    }

    async handleSubmit() {
        if (!this.selectedValue) {
            this.showToast('Error', 'Please select a value before submitting.', 'error');
            return;
        }

        this.isLoading = true; // Show spinner when submitting

        try {
            const result = await updatePostponeApprovedField({
                caseId: this.recordId,
                selectedValue: this.selectedValue
            });
    
            console.log('✅ Apex Response:', result);
    
            // Normalize status to lowercase
            const status = result.status?.toLowerCase(); // ensures it's safe even if status is undefined
    
            this.showToast(
                status === 'success' ? 'Success' : 'Error',
                result.message,
                status === 'success' ? 'success' : 'error'
            );
    
            if (status === 'success') {
                this.dispatchEvent(new CloseActionScreenEvent());
             // Notify platform to refresh the record wherever it's used
                await notifyRecordUpdateAvailable([{ recordId: this.recordId }]);
            }
    
        } catch (error) {
            console.error('❌ Error updating Case:', error);
            this.showToast('Error', 'An unexpected error occurred.', 'error');
        } finally {
            // Always hide spinner after operation
            this.isLoading = false;
        }
    }

    handleCancel() {
        this.dispatchEvent(new CloseActionScreenEvent());
    }

    showToast(title, message, variant) {
    const evt = new ShowToastEvent({
        title: title,
        message: message,
        variant: variant,
        mode: 'dismissable'
    });
    this.dispatchEvent(evt);
}
}