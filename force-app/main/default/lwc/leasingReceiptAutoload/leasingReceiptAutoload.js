import { LightningElement, api, track, wire } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import { getObjectInfo, getPicklistValues } from 'lightning/uiObjectInfoApi';
import LEASING_RECEIPT_OBJECT from '@salesforce/schema/LeasingReceiptAcknowledgment__c';
import PAYMENT_TYPE_FIELD from '@salesforce/schema/LeasingReceiptAcknowledgment__c.PaymentType__c';
import BEING_TOWARDS_FIELD from '@salesforce/schema/LeasingReceiptAcknowledgment__c.BeingTowards__c';
import loadData from '@salesforce/apex/LeasingReceiptController.loadData';
import saveReceiptAllocation from '@salesforce/apex/LeasingReceiptController.saveReceiptAllocation';
import { CloseActionScreenEvent } from 'lightning/actions';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { getRecord } from 'lightning/uiRecordApi';

const RECEIPTFIELDS = [
    'LeasingReceiptAcknowledgment__c.PaymentType__c',
    'LeasingReceiptAcknowledgment__c.BankAccount__c',
    'LeasingReceiptAcknowledgment__c.ReferenceNumber__c',
    'LeasingReceiptAcknowledgment__c.Amount__c',
    'LeasingReceiptAcknowledgment__c.VerifyDate__c',
    'LeasingReceiptAcknowledgment__c.ReceiptDate__c',
    'LeasingReceiptAcknowledgment__c.ChequeNumber__c',
    'LeasingReceiptAcknowledgment__c.ChequeDate__c',
    'LeasingReceiptAcknowledgment__c.LeasingOrder__c',
    'LeasingReceiptAcknowledgment__c.BeingTowards__c'
];

const BACKACCOUNTFIELDS = [
    'BankAccount__c.Name',
    'BankAccount__c.AccountNumberCorporate__c'
];

export default class leasingReceiptAutoload extends LightningElement {

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

@track rows = [];
allRows = [];

projectId;
bankAccount;
sapContract;
bankAccountName;
bankAccountNumber;

@wire(getRecord, { recordId: '$bankAccount', fields: BACKACCOUNTFIELDS })
wiredBank({ data }) {
    if (data) {
        const name = data.fields.Name.value;
        const accNo = data.fields.AccountNumberCorporate__c.value;

        this.bankAccountName = accNo 
            ? `${name} - ${accNo}`
            : name;
    }
}

@wire(getRecord, { recordId: '$recordId', fields: RECEIPTFIELDS })
wiredReceipt({ data }) {
    if (data) {
        this.paymentType = data.fields.PaymentType__c.value;
        this.bankAccount = data.fields.BankAccount__c.value;
        this.referenceNumber = data.fields.ReferenceNumber__c.value;
        this.amount = data.fields.Amount__c.value;
        this.verifyDate = data.fields.VerifyDate__c.value;
        this.receiptDate = data.fields.ReceiptDate__c.value;
        this.chequeNumber = data.fields.ChequeNumber__c.value;
        this.chequeDate = data.fields.ChequeDate__c.value;
        this.leasingOrderRecordId = data.fields.LeasingOrder__c.value;
        this.beingTowardsValues = data.fields.BeingTowards__c.value ? data.fields.BeingTowards__c.value.split(';') : [];
        console.log('Fetched fields:', this.paymentType, this.bankAccount, this.referenceNumber, this.leasingOrderRecordId);
        if(this.leasingOrderRecordId){
            this.loadInitialData();
        }

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
        this.leasingOrderRecordId = currentPageReference.state.leasingOrderRecordId;
    }
}

handleIntercompany(event){
    this.isIntercompany = event.target.checked;
    if(!this.isIntercompany){
        this.receivingEntity = null;
    }
}

handleReceivingEntity(event){
    this.receivingEntity = event.target.value;
}

handleBankChargesApplicable(event){
    this.isBankChargesApplicable = event.target.checked;
    if(!this.isBankChargesApplicable){
        this.bankCharges = null;
    }
}

handleBankCharges(event){
    this.bankCharges = event.target.value;
}

@wire(getPicklistValues, {
    recordTypeId: '$recordTypeId',
    fieldApiName: BEING_TOWARDS_FIELD
})
wiredBeingTowards({data,error}) {

    if(data){
        this.beingTowardsOptions = data.values;
    }
}

@wire(getObjectInfo, { objectApiName: LEASING_RECEIPT_OBJECT })
objectInfo({data,error}) {
    if(data){
        this.recordTypeId = data.defaultRecordTypeId;
    }
}

@wire(getPicklistValues, {
    recordTypeId: '$recordTypeId',
    fieldApiName: PAYMENT_TYPE_FIELD
})
wiredPaymentTypes({data,error}) {

    if(data){
        this.paymentTypeOptions = data.values;
    }
}

handleBeingTowards(event){
    this.beingTowardsValues = event.detail.value;
    this.filterRows();
}

handleChequeDate(event){
    this.chequeDate = event.target.value;
}

handleVerifyDate(event){
    this.verifyDate = event.target.value;
}

handleReceiptDate(event){
    this.receiptDate = event.target.value;
}

handleChequeNumber(event){
    this.chequeNumber = event.target.value;
}

handleReferenceNumber(event){
    this.referenceNumber = event.target.value;
}

// handleSAPDocumentNumber(event){
//     this.sapDocumentNumber = event.target.value;
// }

loadInitialData(){
    console.log('Leasing Order Record Id:', this.leasingOrderRecordId);
    loadData({ leasingOrderId: this.leasingOrderRecordId })
    .then(result=>{
        console.log('Apex Result:', result);

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
        this.allRows = result?.rows;
        this.filterRows();

        //console.log('Rows:', this.rows);
    })
    .catch(error=>{
        console.error(error);
    })
}


filterRows() {
    if (!this.allRows) return;

    if (this.beingTowardsValues.includes('Rent Installment')) {
        this.rows = this.allRows.filter(row => row?.type == 'schedule');
    } else {
        this.rows = this.allRows.filter(row => row?.type == 'charge');
    }

    this.isAdvance = !this.rows || this.rows.length === 0;
}

handleAdvance(event){
this.isAdvance = event.target.checked;
}

handlePaymentType(event){
    this.paymentType = event.detail.value;
}

handleAmount(event){
this.amount = event.target.value;
}

handleApply(event){

    const index = event.target.dataset.index;
    const checked = event.target.checked;

    let updatedRows = JSON.parse(JSON.stringify(this.rows));

    updatedRows[index].apply = checked;

    this.rows = updatedRows;
}

handleAppliedAmount(event){

    const index = event.target.dataset.index;
    const value = event.target.value;

   let updatedRows = JSON.parse(JSON.stringify(this.rows));

    updatedRows[index] = {
        ...updatedRows[index],
        appliedAmount: Number(value)
    };

    this.rows = updatedRows;

}

handleBankAccount(event){
    this.bankAccount = event.detail.leasingOrderRecordId;
    this.bankAccountName = event.detail.label;
}

handleCancel(){
    this.dispatchEvent(new CloseActionScreenEvent());
}

handleSave() {
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
        saveReceiptAllocation({
        leasingOrderId: this.leasingOrderRecordId,
        receiptId: this.recordId,
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

get saveButtonLabel() {
    return this.isSaveDisabled ? 'Saving...' : 'Save';
}

}