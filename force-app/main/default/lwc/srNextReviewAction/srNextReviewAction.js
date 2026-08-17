import { LightningElement, api, wire } from 'lwc';
import { CloseActionScreenEvent } from 'lightning/actions';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { getRecordNotifyChange } from 'lightning/uiRecordApi';
import { NavigationMixin } from "lightning/navigation";
import { notifyRecordUpdateAvailable } from 'lightning/uiRecordApi';
import validateForNextReview from '@salesforce/apex/ReviewStepValidatorController.validateForNextReview';

export default class ReviewStepValidator extends NavigationMixin(LightningElement) {
    isLoading = false;
    currentRecordId;

    @api set recordId(value){
        this.currentRecordId = value;
        console.log('✅ Record ID Received via @wire:',  this.currentRecordId);
        //this.checkDeferralStatus();
    }

    get recordId() {
        return this.currentRecordId;
    }

    async checkDeferralStatus() {
        if (!this.currentRecordId) {
            console.error('❌ ERROR: No recordId available.');
            return;
        }

        this.isLoading = true;
        try {
            console.log('🔄 Calling Apex with record ID:', this.currentRecordId);
            const result = await validateForNextReview({ recordId: this.currentRecordId });
            console.log('✅ Apex Response:', result);

            this.showToast(
                result.status === 'success' ? 'Success' : 'Error',
                result.message,
                result.status === 'success' ? 'success' : 'error'
            );

            if (result.status === 'success') {
                console.log('🔄 Refreshing record data...');
                this[NavigationMixin.Navigate]({
                    type: 'standard__recordPage',
                    attributes: { 
                        recordId: this.currentRecordId,
                        actionName: 'view'
                    } 
                });
                notifyRecordUpdateAvailable([{ recordId: this.currentRecordId }]);
               // this.closeComponent();
            }
        } catch (error) {
            console.error('❌ Error in Apex call:', error);
            this.showToast('Error', 'An unexpected error occurred.', 'error');
        } finally {
            this.isLoading = false;
            this.closeComponent();
           /* setTimeout(() => this.closeComponent(), 1500);*/
        }
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

    closeComponent() {
        this.dispatchEvent(new CloseActionScreenEvent());
    }
}