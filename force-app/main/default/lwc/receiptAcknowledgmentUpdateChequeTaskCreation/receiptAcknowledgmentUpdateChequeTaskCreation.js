import { LightningElement, api, track } from 'lwc';
import LREProcessing from '@salesforce/apex/LeasingReceiptController.createFinanceTask';
import LREfileupload from '@salesforce/apex/LeasingReceiptController.handleFinanceFileUpload';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CloseActionScreenEvent } from 'lightning/actions';

export default class ReceiptAcknowledgmentUpdateChequeTaskCreation extends LightningElement {
    @api recordId;

    @track checkStatus;
    @track financeUser;
    @track proofOfPaymentData;
    @track proofOfPaymentFileName = false;
    @track isLoading = false;
    @track disableSubmitButton = false;

    // Filter only users from Finance department
    financeUserFilter = {
        criteria: [
            {
                fieldPath: 'Department',
                operator: 'eq',
                value: 'Finance'
            }
        ]
    };

    // Picklist options
    checkStatusOptions = [
        { label: 'On Hold', value: 'On Hold' },
        { label: 'Withdrawal', value: 'Withdrawal' },
        { label: 'Replacement', value: 'Replacement' }
    ];

    async handleFieldChange(event) {
        const fieldName = event.target.name;

        switch (fieldName) {
            case 'checkStatus':
                this.checkStatus = event.detail.value;
                break;

            case 'financeUser':
                this.financeUser = event.detail.recordId;
                break;

            case 'proofOfPayment':
                await this.handleFileUpload(event);
                break;

            default:
                break;
        }
    }

    async handleFileUpload(event) {
        const file = event.target.files[0];

        if (!file) {
            return;
        }

        const maxSize = 2.8 * 1024 * 1024; // 2.8 MB

        if (file.size > maxSize) {
            this.showToast('Error', 'File size exceeds 2.8 MB.', 'error');
            return;
        }

        this.isLoading = true;
        this.proofOfPaymentFileName = false;

        try {
            this.proofOfPaymentData = await new Promise((resolve, reject) => {
                const reader = new FileReader();

                reader.onload = () => {
                    const base64 = reader.result.split(',')[1];
                    resolve({
                        filename: 'ProofOfPayment.' + file.name.split('.').pop(),
                        base64: base64
                    });
                };

                reader.onerror = error => reject(error);
                reader.readAsDataURL(file);
            });

            this.proofOfPaymentFileName = true;
        } catch (error) {
            this.showToast('Error', 'Error reading file.', 'error');
        } finally {
            this.isLoading = false;
        }
    }

    validateFields() {
        const fields = this.template.querySelectorAll(
            'lightning-combobox, lightning-record-picker, lightning-input'
        );

        let isValid = true;

        fields.forEach(field => {
            if (field.required && !field.checkValidity()) {
                field.reportValidity();
                isValid = false;
            }
        });

        if (!this.proofOfPaymentData) {
            isValid = false;
            this.showToast(
                'Error',
                'Please upload Proof of Payment.',
                'error'
            );
        }

        return isValid;
    }

    async handleSubmit() {
        if (!this.validateFields()) {
            return;
        }

        this.isLoading = true;
        this.disableSubmitButton = true;

        try {
            // Reuse existing Apex method
            const inputData = {
                receiptAcknowledgementId: this.recordId,
                checkStatus: this.checkStatus,
                financeUser: this.financeUser,
            };

            await LREProcessing({
                inputData: JSON.stringify(inputData)
            });

            // Reuse existing file upload Apex method
            await LREfileupload({
                receiptAcknowledgementId: this.recordId,
                fileName: this.proofOfPaymentData.filename,
                base64Data: this.proofOfPaymentData.base64
            });

            this.showToast(
                'Success',
                'Finance task created successfully.',
                'success'
            );

            setTimeout(() => {
                this.dispatchEvent(new CloseActionScreenEvent());
            }, 1500);

        } catch (error) {
            this.showToast(
                'Error',
                error.body?.message || 'Unexpected error occurred.',
                'error'
            );
            this.disableSubmitButton = false;
        } finally {
            this.isLoading = false;
        }
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