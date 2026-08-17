import { LightningElement, api, track, wire } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import { getObjectInfo, getPicklistValues } from 'lightning/uiObjectInfoApi';
import LEASING_RECEIPT_OBJECT from '@salesforce/schema/LeasingReceiptAcknowledgment__c';
import PAYMENT_TYPE_FIELD from '@salesforce/schema/LeasingReceiptAcknowledgment__c.PaymentType__c';
import BEING_TOWARDS_FIELD from '@salesforce/schema/LeasingReceiptAcknowledgment__c.BeingTowards__c';
import BANK_NAME_FIELD from '@salesforce/schema/LeasingReceiptAcknowledgment__c.BankName__c';
import loadData from '@salesforce/apex/LeasingReceiptController.loadData';
import saveReceipt from '@salesforce/apex/LeasingReceiptController.saveReceipt';
import { CloseActionScreenEvent } from 'lightning/actions';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { getRecord } from 'lightning/uiRecordApi';

const FIELDS = [
    'BankAccount__c.Name',
    'BankAccount__c.AccountNumberCorporate__c'
];

export default class LeasingReceipt extends LightningElement {

    @api recordId;
    projectName;
    unitName;
    paymentType;
    paymentTypeOptions = [];
    recordTypeId;
    beingTowardsOptions = [];
    beingTowardsValues = [];
    isIntercompany = false;
    isBankChargesApplicable = false;
    isSaveDisabled = false;
    receivingEntity;
    bankCharges;
    accountName;
    bankName;
    bankNameOptions = [];
    note;

    @track rows = [];
    allRows = [];

    projectId;
    bankAccount;
    sapContract;
    bankAccountName;
    bankAccountNumber;
    leasingStartDate;

    get isReferenceDisabled() {
        return !this.paymentType || this.paymentType.toLowerCase() === 'cheque';
    }

    get isChequeDisabled() {
        return !this.paymentType || this.paymentType.toLowerCase() !== 'cheque';
    }

    @wire(getRecord, { recordId: '$bankAccount', fields: FIELDS })
    wiredBank({ data }) {
        if (data) {
            const name = data.fields.Name.value;
            const accNo = data.fields.AccountNumberCorporate__c.value;

            this.bankAccountName = accNo
                ? `${name} - ${accNo}`
                : name;
        }
    }

    @wire(getPicklistValues, {
        recordTypeId: '$recordTypeId',
        fieldApiName: BANK_NAME_FIELD
    })
    wiredBankNames({ data, error }) {
        if (data) {
            this.bankNameOptions = data.values;
        }
    }

    matchingInfo = {
        primaryField: { fieldPath: 'Name' },
        additionalFields: [{ fieldPath: 'AccountNumberCorporate__c' }]
    };

    displayInfo = {
        primaryField: 'Name',
        additionalFields: ['AccountNumberCorporate__c']
    };

    isAdvance = false;
    amount;
    chequeDate;
    verifyDate;
    receiptDate;
    chequeNumber;
    referenceNumber;
    // sapDocumentNumber;

    @wire(CurrentPageReference)
    getStateParameters(currentPageReference) {
        if (currentPageReference) {
            this.recordId = currentPageReference.state.recordId;
        }
    }

    handleBankName(event) {
        this.bankName = event.detail.value;
    }

    handleNote(event) {
        this.note = event.target.value;
    }

    handleIntercompany(event) {
        this.isIntercompany = event.target.checked;
        if (!this.isIntercompany) {
            this.receivingEntity = null;
        }
    }

    handleReceivingEntity(event) {
        this.receivingEntity = event.target.value;
    }

    handleBankChargesApplicable(event) {
        this.isBankChargesApplicable = event.target.checked;
        if (!this.isBankChargesApplicable) {
            this.bankCharges = null;
        }
    }

    handleBankCharges(event) {
        this.bankCharges = event.target.value;
    }

    @wire(getPicklistValues, {
        recordTypeId: '$recordTypeId',
        fieldApiName: BEING_TOWARDS_FIELD
    })
    wiredBeingTowards({ data, error }) {

        if (data) {
            this.beingTowardsOptions = data.values;
        }
    }

    @wire(getObjectInfo, { objectApiName: LEASING_RECEIPT_OBJECT })
    objectInfo({ data, error }) {
        if (data) {
            this.recordTypeId = data.defaultRecordTypeId;
        }
    }

    @wire(getPicklistValues, {
        recordTypeId: '$recordTypeId',
        fieldApiName: PAYMENT_TYPE_FIELD
    })
    wiredPaymentTypes({ data, error }) {

        if (data) {
            this.paymentTypeOptions = data.values;
        }
    }

    handleBeingTowards(event) {
        this.beingTowardsValues = event.detail.value;
        this.filterRows();
    }

    handleChequeDate(event) {
        this.chequeDate = event.target.value;
        
        // Clear custom validity when user changes the date
        const chequeDateField = this.template.querySelector('.date-field');
        if (chequeDateField) {
            chequeDateField.setCustomValidity('');
            chequeDateField.reportValidity();
        }
    }

    handleVerifyDate(event) {
        this.verifyDate = event.target.value;
        this.receiptDate = this.verifyDate;
        
        // Clear custom validity when user changes the date
        const dateFields = this.template.querySelectorAll('.date-field');
        if (dateFields && dateFields.length > 1) {
            dateFields[1].setCustomValidity('');
            dateFields[1].reportValidity();
        }
    }

    // handleReceiptDate(event){
    //     this.receiptDate = event.target.value;
    // }

    handleChequeNumber(event) {
        this.chequeNumber = event.target.value;
    }

    handleReferenceNumber(event) {
        this.referenceNumber = event.target.value;
    }

    // handleSAPDocumentNumber(event){
    //     this.sapDocumentNumber = event.target.value;
    // }

    connectedCallback() {

        console.log('Leasing Order Record Id:', this.recordId);

        loadData({ leasingOrderId: this.recordId })
            .then(result => {
                console.log('Apex Result:', result);

                this.bankAccountName = result.bankAccountName && result.bankAccountNumber
                    ? `${result.bankAccountName} - ${result.bankAccountNumber}`
                    : result.bankAccountName;

                this.projectId = result.projectId;
                this.projectName = result.projectName;
                this.unitName = result.unitName;
                this.bankAccount = result.bankAccount;
                this.accountName = result.accountName;
                this.bankAccountName = result.bankAccountName && result.bankAccountNumber
                    ? `${result.bankAccountName} - ${result.bankAccountNumber}`
                    : result.bankAccountName;
                this.bankAccountNumber = result.bankAccountNumber;
                this.sapContract = result.sapContract;
                this.leasingStartDate = result.leasingStartDate;

                this.allRows = result?.rows;
                this.filterRows();

                if (!this.rows || this.rows.length === 0) {
                    this.isAdvance = true;
                }

                console.log('Rows:', this.rows);
            })
            .catch(error => {
                console.error(error);
            })
    }

    handleAdvance(event) {
        this.isAdvance = event.target.checked;
    }

    handlePaymentType(event) {
        this.paymentType = event.detail.value;
        
        if (this.paymentType.toLowerCase() === 'cheque') {
            this.referenceNumber = null;
        } else {
            this.chequeNumber = null;
        }

        this.template.querySelectorAll('.conditional-field').forEach(field => {
            field.setCustomValidity('');
            field.reportValidity();
        });
    }

    handleAmount(event) {
        this.amount = event.target.value;
    }

    // handleApply(event){

    //     const index = event.target.dataset.index;
    //     const checked = event.target.checked;

    //     let updatedRows = JSON.parse(JSON.stringify(this.rows));

    //     updatedRows[index].apply = checked;

    //     this.rows = updatedRows;
    // }

    handleAppliedAmount(event) {

        const index = event.target.dataset.index;
        const value = event.target.value;

        let updatedRows = JSON.parse(JSON.stringify(this.rows));

        updatedRows[index] = {
            ...updatedRows[index],
            appliedAmount: value ? Number(value) : null
        };

        this.rows = updatedRows;

    }

    handleBankAccount(event) {
        this.bankAccount = event.detail.recordId;
        this.bankAccountName = event.detail.label;
    }

    handleCancel() {
        this.dispatchEvent(new CloseActionScreenEvent());
    }

    handleSave() {

        if (this.verifyDate && this.leasingStartDate) {

            const postingDate = new Date(this.verifyDate);
            const leasingStart = new Date(this.leasingStartDate);
            console.log('274');
            if (postingDate < leasingStart) {
                console.log('true');

                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Warning!',
                        message: 'Posting Date cannot be before Leasing Order Start Date',
                        variant: 'warning',
                        mode: 'dismissable'
                    }))
            }

            // Prevent multiple clicks
            if (this.isSaveDisabled) {
                return;
            }

            this.isSaveDisabled = true;

            const allValid = [...this.template.querySelectorAll('.req-field')]
                .reduce((validSoFar, field) => {
                    field.reportValidity();
                    return validSoFar && field.checkValidity();
                }, true);

            if (!allValid) {
                this.isSaveDisabled = false;
                return;
            }

            // Validate date fields for advance payment
            let isDateValid = true;
            const dateFields = this.template.querySelectorAll('.date-field');
            const today = new Date();
            today.setHours(0, 0, 0, 0);

            if (this.isAdvance) {
                // Validate Posting Date
                if (this.verifyDate) {
                    const postingDate = new Date(this.verifyDate);
                    postingDate.setHours(0, 0, 0, 0);

                    if (postingDate > today) {
                        isDateValid = false;
                        dateFields[1].setCustomValidity('Posting Date cannot be in future for advance payment');
                    } else {
                        dateFields[1].setCustomValidity('');
                    }
                }

                // Validate Maturity/Value/Cheque Date
                if (this.chequeDate) {
                    const chequeDate = new Date(this.chequeDate);
                    chequeDate.setHours(0, 0, 0, 0);

                    if (chequeDate > today) {
                        isDateValid = false;
                        dateFields[0].setCustomValidity('Maturity/Value/Cheque Date cannot be in future for advance payment');
                    } else {
                        dateFields[0].setCustomValidity('');
                    }

                    
                }
            } else {
                // Clear custom validity when not advance payment
                dateFields[0].setCustomValidity('');
                dateFields[1].setCustomValidity('');
            }

            // Restrict allocation to future due dates when cheque date is today
            if (this.chequeDate) {
                const chequeDate = new Date(this.chequeDate);
                chequeDate.setHours(0, 0, 0, 0);

                if (chequeDate.getTime() === today.getTime()) {

                    const hasFutureDueDate = this.rows.some(row => {
                        if (!row.appliedAmount || row.appliedAmount <= 0) {
                            return false;
                        }

                        const dueDate = new Date(row.dueDate);
                        dueDate.setHours(0, 0, 0, 0);

                        return dueDate > today;
                    });

                    if (hasFutureDueDate) {
                        this.isSaveDisabled = false;

                        this.dispatchEvent(
                            new ShowToastEvent({
                                title: 'Error',
                                message: 'Future invoices cannot be allocated when Maturity/Value/Cheque Date is today.',
                                variant: 'error'
                            })
                        );

                        return;
                    }
                }
            }

                

            // Report validity for date fields
            dateFields.forEach(field => field.reportValidity());

            if (!isDateValid) {
                this.isSaveDisabled = false;
                return;
            }

            let isConditionalValid = true;

            const paymentType = this.paymentType ? this.paymentType.toLowerCase() : '';

            if (paymentType === 'cheque') {
                if (!this.chequeNumber) {
                    isConditionalValid = false;
                    this.template.querySelectorAll('.conditional-field')[1]
                        .setCustomValidity('Cheque Number is required for Cheque payment');
                } else {
                    this.template.querySelectorAll('.conditional-field')[1]
                        .setCustomValidity('');
                }

                this.template.querySelectorAll('.conditional-field')[0]
                    .setCustomValidity('');

            } else {
                if (!this.referenceNumber) {
                    isConditionalValid = false;
                    this.template.querySelectorAll('.conditional-field')[0]
                        .setCustomValidity('Reference Number is required');
                } else {
                    this.template.querySelectorAll('.conditional-field')[0]
                        .setCustomValidity('');
                }

                this.template.querySelectorAll('.conditional-field')[1]
                    .setCustomValidity('');
            }

            this.template.querySelectorAll('.conditional-field')
                .forEach(field => field.reportValidity());

            if (!isConditionalValid) {
                this.isSaveDisabled = false;
                return;
            }

            let receipt = {
                LeasingOrder__c: this.recordId,
                Amount__c: this.amount,
                PaymentType__c: this.paymentType,
                BankName__c: this.bankName,
                BeingTowards__c: this.beingTowardsValues.join(';'),
                ChequeDate__c: this.chequeDate,
                VerifyDate__c: this.verifyDate,
                ReceiptDate__c: this.receiptDate,
                ChequeNumber__c: this.chequeNumber,
                ReferenceNumber__c: this.referenceNumber,
                BankAccount__c: this.bankAccount,
                IsIntercompanyTransaction__c: this.isIntercompany,
                ReceivingEntity__c: this.receivingEntity,
                BankChargesApplicable__c: this.isBankChargesApplicable,
                IsAdvancePayment__c: this.isAdvance,
                BankCharges__c: this.bankCharges,
                Note__c : this.note
            };
            // Validate that if isAdvance is true, at least one row should have appliedAmount
            if (!this.isAdvance) {
                const hasAppliedAmount = this.rows.some(row => row.appliedAmount && row.appliedAmount > 0);
                if (!hasAppliedAmount) {
                    this.isSaveDisabled = false;
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Error',
                            message: 'Atleast one onvoice should have allocation',
                            variant: 'error'
                        })
                    );
                    return;
                }
            }

            let totalAmount = 0;
            for (let row of this.rows) {
                if (row.appliedAmount == 0) {
                    this.isSaveDisabled = false;
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Error',
                            message: 'Applied amount is invalid. It should be blank or contains non-zero value',
                            variant: 'error'
                        }))
                    return;
                }
                if (row?.appliedAmount)
                    totalAmount += row.appliedAmount;
            }
            if (totalAmount > this.amount) {
                this.isSaveDisabled = false;
                this.dispatchEvent(new ShowToastEvent({
                    title: 'Error',
                    message: 'Total applied amount is invalid. It should be less than or equals to Receipt amount',
                    variant: 'error'
                }))
                return;
            }

            saveReceipt({
                leasingOrderId: this.recordId,
                receipt: receipt,
                rowsJson: JSON.stringify(this.rows)
            })
                .then(() => {
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Success',
                            message: 'Receipt created successfully',
                            variant: 'success'
                        })
                    );

                    setTimeout(() => {
                        this.dispatchEvent(new CloseActionScreenEvent());
                        eval("$A.get('e.force:refreshView').fire();");
                    }, 800);
                })
                .catch(error => {

                    // Re-enable on error
                    this.isSaveDisabled = false;

                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Error',
                            message: error.body?.message || 'Error creating receipt',
                            variant: 'error'
                        })
                    );
                });
        }
    }

        filterRows() {
            try {
                console.log(this.beingTowardsValues)
                if (!this.allRows) return;
                this.rows = []
                if (this.beingTowardsValues?.length > 0) {
                    if (this.beingTowardsValues.includes('Rent Installment')) {
                        this.rows = this.allRows.filter(row => row?.type == 'schedule');
                    }

                    this.rows = [
                        ...this.rows,
                        ...this.allRows.filter(row =>
                            row?.type == 'charge' && this.beingTowardsValues.includes(row?.subType)
                        )
                    ];
                }
                this.isAdvance = !this.rows || this.rows.length === 0;
            } catch (e) {
                console.log(e.body.message)
            }
        }

get saveButtonLabel() {
            return this.isSaveDisabled ? 'Saving...' : 'Save';
        }

    }