import { LightningElement, track } from 'lwc';
import getOtherCharges from '@salesforce/apex/LeasingOrderController.getOtherCharges';
import updateOtherCharges from '@salesforce/apex/LeasingOrderController.updateOtherCharges';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class OtherChargesPosting extends LightningElement {

    fromDate;
    toDate;
    postingDate = new Date().toISOString().slice(0, 10);
    isPosting = false;
    @track data = [];
    @track selectedIds = [];

    hasSearched = false;

    columns = [
        { label: 'Other Charge Name', fieldName: 'otherChargesLink' , type: 'url', 
            typeAttributes: { 
                label: { fieldName: 'Name' },
                target: '_blank' 
            }
        },
        { label: 'Leasing Order Number', fieldName: 'leasingOrderLink', type: 'url', 
            typeAttributes: { 
                label: { fieldName: 'leasingOrderNumber' },
                target: '_blank' 
            } 
        },
        { label: 'Leasing Order Name', fieldName: 'leasingOrderName' },
        { label: 'Leasing Order Start Date', fieldName: 'leasingStartDate', type: 'date' },
        { label: 'Leasing Order End Date', fieldName: 'leasingEndDate', type: 'date' },
        { label: 'Condition Type', fieldName: 'ConditionType__c' },
        { label: 'Other Charge Type', fieldName: 'Type__c' },
        { label: 'VAT Amount', fieldName: 'VATAmount__c', type: 'currency' },
        { label: 'Gross Amount', fieldName: 'ChargeAmount__c', type: 'currency' },
        { label: 'Posting Date', fieldName: 'PostingDate__c', type: 'date' }
    ];

    handleFromDate(event){ 
        this.fromDate = event.target.value;
        const input = event.target;
        if ((this.toDate && this.toDate < this.fromDate) || this.fromDate > this.maxDate ) {
            this.fromDate = "";
            input.setCustomValidity("'From Date' cannot be in the future or greater than 'To Date'");
        } else {
            input.setCustomValidity(""); 
        }
        input.reportValidity()
    }
    handleToDate(event) {
        this.toDate = event.target.value;
        const input = event.target;
        if ((this.fromDate && this.toDate < this.fromDate) || this.toDate > this.maxDate) {
            this.toDate = "";
            input.setCustomValidity("'To Date' cannot be in the future or less than 'From Date'");
        } else {
            input.setCustomValidity(""); 
        }
        input.reportValidity();
    }

    handlePostingDate(e){ this.postingDate = e.target.value; }

    handleSearch(){

        if(!this.fromDate || !this.toDate){
            this.showToast('Error', 'Enter From & To Date', 'error');
            return;
        }

        getOtherCharges({ fromDate: this.fromDate, toDate: this.toDate })
        .then(result => {

            this.hasSearched = true;

            this.data = result.map(row => ({
                ...row,
                leasingName: row.LeasingOrder__r?.Name
            }));

            console.log('this.data '+  JSON.stringify(this.data))

            this.data = result.map(row => ({
                Id: row.Id,

                leasingOrderNumber: row.LeasingOrder__r?.LeasingOrderNumber__c,
                leasingOrderName: row.LeasingOrder__r?.Name,
                leasingStartDate: row.LeasingOrder__r?.LeasingStartDate__c,
                leasingEndDate: row.LeasingOrder__r?.LeasingEndDate__c,

                Type__c: row.Type__c,
                Name: row.Name,
                ConditionType__c: row.ConditionType__c,
                VATAmount__c: row.VATAmount__c,
                PostingDate__c: row.PostingDate__c,
                ChargeAmount__c: row.ChargeAmount__c,

                otherChargesLink: `/lightning/r/${row.Id}/view`,
                leasingOrderLink: `/lightning/r/${row.LeasingOrder__c}/view`,

            }));

            this.selectedIds = [];
        })
        .catch(error => {
            this.showToast('Error', error.body.message, 'error');
        });
    }

    handleRowSelection(event){
        this.selectedIds = event.detail.selectedRows.map(r => r.Id);
    }

    handleSave(){
        if(!this.postingDate){
            this.showToast('Error', 'Enter Posting Date', 'error');
            return;
        }

        if(this.selectedIds.length === 0){
            this.showToast('Error', 'Select at least one record', 'error');
            return;
        }

        this.isPosting = true;

        updateOtherCharges({
            recordIds: this.selectedIds,
            postingDate: this.postingDate
        })
        .then(() => {
            this.showToast('Success', 'Posted & Sent to SAP', 'success');
            this.handleSearch();
            this.selectedIds = [];
            this.handleSearch();
        })
        .catch(error => {
            this.showToast('Error', error.body.message, 'error');
        }).finally(()=>{
            this.isPosting = false;
        });
    }

    get isPostDisabled(){
        return this.selectedIds.length === 0 || this.isPosting == true;
    }

    get maxDate() {
        return new Date().toISOString().split('T')[0];
    }

    showToast(title, message, variant){
        this.dispatchEvent(
            new ShowToastEvent({ title, message, variant })
        );
    }
}