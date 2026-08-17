import { LightningElement, api, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

import getSalesEntries from '@salesforce/apex/SalesEntriesController.getSalesEntries';
import saveSalesEntries from '@salesforce/apex/SalesEntriesController.saveSalesEntries';

export default class SalesEntries extends LightningElement {

    @api recordId;

    @track masterSalesEntries = [];
@track salesEntries = [];

    @track salesEntries = [];

    originalData = [];
    changedRecords = new Map();

    isLoading = false;
    disableSave = true;

    connectedCallback() {
        this.loadSalesEntries();
    }

loadSalesEntries() {

    this.isLoading = true;

    return getSalesEntries({
        leasingOrderId: this.recordId
    })
   .then(result => {

    this.masterSalesEntries = JSON.parse(
        JSON.stringify(result.masterSalesEntries)
    );

    this.salesEntries = JSON.parse(
        JSON.stringify(result.currentSalesEntries)
    );

    this.salesEntries.forEach(row => {
        row.isActualLocked = row.ActualSalesLock__c;
        row.isAuditedLocked = row.AuditedSalesLock__c;
    });

    this.originalData = JSON.parse(JSON.stringify(this.salesEntries));

    this.changedRecords.clear();
    this.disableSave = true;
})
    .catch(error => {

        this.showToast(
            'Error',
            this.reduceError(error),
            'error'
        );

    })
    .finally(() => {

        this.isLoading = false;

    });

}

    handleChange(event) {

        const recordId = event.target.dataset.id;
        const fieldName = event.target.dataset.field;
        let value;

if (
    fieldName === 'ActualSalesLock__c' ||
    fieldName === 'AuditedSalesLock__c'
) {
    value = event.target.checked;
} else {
    value = event.target.value === '' ? null : Number(event.target.value);
}

        
this.salesEntries = this.salesEntries.map(row => {

    if (row.Id === recordId) {

        return {
            ...row,
            [fieldName]: value
        };
    }

    return row;
});

        const currentRecord = this.salesEntries.find(r => r.Id === recordId);
        const originalRecord = this.originalData.find(r => r.Id === recordId);

        const isChanged =
    currentRecord.ActualSales__c !== originalRecord.ActualSales__c ||
    currentRecord.AuditedSales__c !== originalRecord.AuditedSales__c ||
    currentRecord.ActualSalesLock__c !== originalRecord.ActualSalesLock__c ||
    currentRecord.AuditedSalesLock__c !== originalRecord.AuditedSalesLock__c;

        if (isChanged) {

           this.changedRecords.set(recordId, {
    Id: currentRecord.Id,
    ActualSales__c: currentRecord.ActualSales__c,
    AuditedSales__c: currentRecord.AuditedSales__c,
    ActualSalesLock__c: currentRecord.ActualSalesLock__c,
    AuditedSalesLock__c: currentRecord.AuditedSalesLock__c
});

        } else {

            this.changedRecords.delete(recordId);

        }

        this.disableSave = this.changedRecords.size === 0;

    }

handleSave() {

    if (this.changedRecords.size === 0) {
        this.showToast('Info', 'No changes to save.', 'info');
        return;
    }

    this.isLoading = true;

    saveSalesEntries({
        salesEntries: Array.from(this.changedRecords.values())
    })
    .then(() => this.loadSalesEntries())
    .then(() => {

        this.showToast(
            'Success',
            'Sales Entries updated successfully.',
            'success'
        );

    })
    .finally(() => {
        this.isLoading = false;
    })
    .catch(error => {
        this.showToast(
            'Error',
            this.reduceError(error),
            'error'
        );
    });
}

handleCancel() {

    this.salesEntries = JSON.parse(JSON.stringify(this.originalData));

    this.salesEntries.forEach(row => {
        row.isActualLocked = row.ActualSalesLock__c;
        row.isAuditedLocked = row.AuditedSalesLock__c;
    });

    this.changedRecords.clear();
    this.disableSave = true;
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

    reduceError(error) {

        if (error?.body?.message) {
            return error.body.message;
        }

        if (error?.message) {
            return error.message;
        }

        return 'Unknown Error';

    }

    get totalActualSales() {
    return this.salesEntries.reduce(
        (sum, row) => sum + (Number(row.ActualSales__c) || 0),
        0
    );
}

get totalAuditedSales() {
    return this.salesEntries.reduce(
        (sum, row) => sum + (Number(row.AuditedSales__c) || 0),
        0
    );
}

get masterTotalActualSales() {
    return this.masterSalesEntries.reduce(
        (sum,row)=>sum + (Number(row.ActualSales__c) || 0),
        0
    );
}

get masterTotalAuditedSales() {
    return this.masterSalesEntries.reduce(
        (sum,row)=>sum + (Number(row.AuditedSales__c) || 0),
        0
    );
}

lockAllActual() {
    this.bulkUpdateLock('ActualSalesLock__c', true);
}

unlockAllActual() {
    this.bulkUpdateLock('ActualSalesLock__c', false);
}

lockAllAudited() {
    this.bulkUpdateLock('AuditedSalesLock__c', true);
}

unlockAllAudited() {
    this.bulkUpdateLock('AuditedSalesLock__c', false);
}

bulkUpdateLock(fieldName, value) {

    this.salesEntries = this.salesEntries.map(row => {

        
        if (
            (fieldName === 'ActualSalesLock__c' && row.isActualLocked) ||
            (fieldName === 'AuditedSalesLock__c' && row.isAuditedLocked)
        ) {
            return row;
        }

        const updatedRow = {
            ...row,
            [fieldName]: value
        };

        const originalRecord =
            this.originalData.find(r => r.Id === row.Id);

        const isChanged =
            updatedRow.ActualSales__c !== originalRecord.ActualSales__c ||
            updatedRow.AuditedSales__c !== originalRecord.AuditedSales__c ||
            updatedRow.ActualSalesLock__c !== originalRecord.ActualSalesLock__c ||
            updatedRow.AuditedSalesLock__c !== originalRecord.AuditedSalesLock__c;

        if (isChanged) {

            this.changedRecords.set(updatedRow.Id, {
                Id: updatedRow.Id,
                ActualSales__c: updatedRow.ActualSales__c,
                AuditedSales__c: updatedRow.AuditedSales__c,
                ActualSalesLock__c: updatedRow.ActualSalesLock__c,
                AuditedSalesLock__c: updatedRow.AuditedSalesLock__c
            });

        } else {
            this.changedRecords.delete(updatedRow.Id);
        }

        return updatedRow;
    });

    this.disableSave = this.changedRecords.size === 0;
}

}