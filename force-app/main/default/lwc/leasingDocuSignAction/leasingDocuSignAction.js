import { LightningElement, api, track, wire } from 'lwc';
import { CloseActionScreenEvent } from 'lightning/actions';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getLeasingOrderRecord from '@salesforce/apex/LeasingDocGenController.getLeasingOrderRec';
import getDocumentTypeRecords from '@salesforce/apex/LeasingDocGenController.getDocSignSetupRecords';
import sendForSignature from '@salesforce/apex/LeasingDocGenController.sendForSignature';
import { CurrentPageReference } from 'lightning/navigation';

export default class LeasingDocuSignAction extends LightningElement {
    @api recordId;
    @track isLoading = false;
    @track selectedValue = null;
    leasingOrder;
    @track options = [];
    records = [];
    wireRecordId;

    @wire(CurrentPageReference)
    getStateParameters(currentPageReference) {
        if (currentPageReference) {
            this.wireRecordId = currentPageReference.state.recordId;
        }
    }

    connectedCallback() {
        if (this.wireRecordId) {
            this.getDocgenSetDocumentRec();
        }
    }

    getDocgenSetDocumentRec() {
        this.isLoading = true;
        const recId = this.wireRecordId;

        getLeasingOrderRecord({ recordId: recId })
            .then((result) => {
                this.leasingOrder = result;
            })
            .catch((error) => {
                this.showToast('Error retrieving Leasing Order', error.body.message, 'error');
            });

        getDocumentTypeRecords({ recordId: recId })
            .then((result) => {
                this.records = result;
                this.options = result.map((doc) => ({
                    label: doc.Type__c,
                    value: doc.Id,
                    isChecked: false
                }));
            })
            .catch((error) => {
                this.showToast('Error retrieving document types', error.body.message, 'error');
            })
            .finally(() => {
                this.isLoading = false;
            });
    }

    handleCheckboxChange(event) {
        const selectedValue = event.target.value;
        this.selectedValue = selectedValue;

        // Update options — ensure only one stays checked
        this.options = this.options.map(option => ({
            ...option,
            isChecked: option.value === selectedValue
        }));

        // Force re-render and update UI immediately
        this.refreshCheckboxes(selectedValue);
    }

    refreshCheckboxes(selectedValue) {
        // Ensure all DOM inputs reflect the state
        this.template.querySelectorAll('lightning-input[type="checkbox"]').forEach(input => {
            input.checked = input.value === selectedValue;
        });
    }

    async handleGenerate() {
        if (!this.selectedValue) {
            this.showToast('Error', 'Please select one document type before proceeding.', 'error');
            return;
        }

        this.isLoading = true;

        try {
            const selectedRecord = this.records.find(rec => rec.Id === this.selectedValue);
            await sendForSignature({
                leasingOrderRec: this.leasingOrder,
                documentTypeRecord: selectedRecord
            });

            this.dispatchEvent(new CloseActionScreenEvent());
            this.showToast('Success', 'Documents processed successfully!', 'success');
        } catch (error) {
            this.showToast('Error processing documents', error.message, 'error');
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