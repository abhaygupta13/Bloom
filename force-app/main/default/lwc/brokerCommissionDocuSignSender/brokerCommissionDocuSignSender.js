import { LightningElement, api, track } from 'lwc';
import { CloseActionScreenEvent } from 'lightning/actions';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getCommissionDocumentTypes from '@salesforce/apex/BrokerCommissionDocuSignHandler.getCommissionDocumentTypes';
import sendForCommissionSignature from '@salesforce/apex/BrokerCommissionDocuSignHandler.sendForCommissionSignature';

export default class BrokerCommissionDocuSignSender extends LightningElement {
    @api recordId;
    @track options = [];
    @track selectedValues = [];
    @track isLoading = false;

    connectedCallback() {
        this.loadDocTypes();
    }

    loadDocTypes() {
        this.isLoading = true;
        getCommissionDocumentTypes()
            .then(result => {
                this.options = result.map(dt => ({
                    label: dt.Type__c,
                    value: dt.Id
                }));
            })
            .catch(error => {
                this.showToast('Error', error.body.message, 'error');
            })
            .finally(() => { this.isLoading = false; });
    }

    handleSelectionChange(event) {
        this.selectedValues = event.detail.value;
    }

    async handleSend() {
        if (!this.selectedValues || this.selectedValues.length === 0) {
            this.showToast('Error', 'Please select at least one document type.', 'error');
            return;
        }
        this.isLoading = true;
        try {
            await sendForCommissionSignature({
                commissionId: this.recordId,
                documentTypeIds: this.selectedValues
            });
            this.showToast('Success', 'Documents sent for signature!', 'success');
            this.dispatchEvent(new CloseActionScreenEvent());
        } catch (error) {
            this.showToast('Error', error.body.message, 'error');
        } finally {
            this.isLoading = false;
        }
    }

    handleCancel() {
        this.dispatchEvent(new CloseActionScreenEvent());
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }
}