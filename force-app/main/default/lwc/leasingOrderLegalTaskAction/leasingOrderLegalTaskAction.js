import { LightningElement, track, api } from 'lwc';
import createTask from '@salesforce/apex/LeasingOrderController.createLegalTask';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CloseActionScreenEvent } from 'lightning/actions';

export default class LeasingOrderLegalTaskAction extends LightningElement {
    @track selectedCaseType = '';
    @track assignedToName = '';
    @track showUserLookup = false;
    @api recordId;
    @track legalUser;
    disableSubmitButton = false;
    @track isLoading = false;

    get caseOptions() {
        return [
            { label: 'Legal Case', value: 'Legal Case' },
            { label: 'Cheque Bounce Case', value: 'Cheque Bounce Case' }
        ];
    }

    connectedCallback(){
        this.filter = {
            criteria: [
                {
                    fieldPath: 'Department',
                    operator: 'eq',
                    value: 'Legal'
                },
            ],
        };
    }

    validateFields() {
        const inputFields = this.template.querySelectorAll(
            'lightning-input, lightning-record-picker,lightning-combobox'
        );

        let allValid = true;

        inputFields.forEach(field => {
            // Only validate visible fields
            if (!field.classList.contains('slds-hide') && field.required) {
                if (field.tagName === 'LIGHTNING-INPUT' || field.tagName === 'LIGHTNING-COMBOBOX') {
                    if (!field.value) {
                        allValid = false;
                        field.reportValidity();
                    }
                } else if (field.tagName === 'LIGHTNING-RECORD-PICKER') {
                    if (!field.value) {   // value is recordId
                        allValid = false;
                        // record picker doesn’t have reportValidity, so show error manually
                        field.setCustomValidity('This field is required');
                        field.reportValidity();
                    } else {
                        field.setCustomValidity('');
                    }
                }
            }
        });

        return allValid;
    }

    async handleFieldChange(event) {

        const fieldName = event.target.name;

        switch (fieldName) {
            case 'legalUser':
                this.legalUser = event.detail.recordId;
                console.log(`legalUser : `,this.legalUser);
                break;
            default:
                this[fieldName] = event.detail.value;
        }

    }

    handleCaseChange(event) {
        this.selectedCaseType = event.detail.value;
    }

    // handleUserSearch(event) {
    //     this.assignedToName = event.detail.value;
    //     this.showUserLookup = true;
    // }

    // handleUserSelect(event) {
    //     this.assignedToId = event.detail.id;
    // }

    handleCancel() {
        // const closeEvent = new CustomEvent('close');
        // this.dispatchEvent(closeEvent);
        console.log(`Close action called`);
        // closeModal();
        setTimeout(() => this.closeModal(), 100);
    }

    async handleSubmit() {
        if (this.validateFields()) {
            this.isLoading = true;
            this.disableSubmitButton = true;
            const data = {
                caseType : this.selectedCaseType,
                legalUserId : this.legalUser
            }
            //createTask({ caseType: this.selectedCaseType, assignedTo: this.assignedToId })
            await createTask({ leasingOrdrId: this.recordId, inputData: JSON.stringify(data) })
                .then(() => {
                    this.isLoading = false;
                    this.showToast('Success', 'Task created successfully!', 'success');
                    
                    setTimeout(() => this.closeModal(), 1000);
                })
                .catch(error => {
                    this.isLoading = false;
                    this.showToast('Error', error.body.message, 'error');
                });
            
        } else{
            console.log('Validation failed, please fill all required fields.');
        }
    }

    showToast(title, message, variant) {
        this.dispatchEvent(
            new ShowToastEvent({
                title: title,
                message: message,
                variant: variant,
            })
        );
    }

    closeModal() {
        console.log('in close modal')
        this.dispatchEvent(new CloseActionScreenEvent());
    }
}
``