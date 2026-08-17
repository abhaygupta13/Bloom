import { api, LightningElement, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

//import getReceiptAllocationbyReceiptId from '@salesforce/apex/ReceiptAllocationController.getReceiptAllocationbyReceiptId';
import fetchReceiptAlocationByReceiptId from '@salesforce/apex/ReceiptAllocationHandler.fetchReceiptAlocationByReceiptId';
import fetchSalesOrderByAccountId from '@salesforce/apex/ReceiptAllocationHandler.fetchSalesOrderByAccountId';
//import getRelatedSalesOrderbyAccountId from '@salesforce/apex/ReceiptAllocationController.getRelatedSalesOrderbyAccountId';

import fetchInvoiceForSalesorder from '@salesforce/apex/ReceiptAllocationHandler.fetchInvoiceForSalesorder';
//import getInvoicesApplicableForSO from '@salesforce/apex/ReceiptAllocationController.getInvoicesApplicableForSO';
import UpdateReceiptAllocation from '@salesforce/apex/ReceiptAllocationHandler.UpdateReceiptAllocation';
//import saveReceiptAllocation from '@salesforce/apex/ReceiptAllocationController.saveReceiptAllocation';

const COLUMN = [
    { title: 'Account', fieldName: 'account', type: 'picklist-text', style: 'overflow: initial;' },
    { title: 'Unit Number', fieldName: 'unitNumber', type: 'picklist-text', style: 'overflow: initial;' },
    { title: 'Sales Order #', fieldName: 'salesOrder', type: 'text', readonly: true },
    { title: 'Installment # / Other Charges', fieldName: 'installmentNoOtherCharge', type: 'picklist-text', style: 'overflow: initial;' },
    { title: 'Type', fieldName: 'chargeType', type: 'text', readonly: true },
    { title: 'Total Invoice Amount', fieldName: 'totalInvoiceAmount', type: 'currency', readonly: true },
    { title: 'Current Outstanding Amount', fieldName: 'currentOutstandingAmount', type: 'currency', readonly: true },
    { title: 'Currently Amount Applied', fieldName: 'currentAmountApplied', type: 'currency', readonly: true },
    { title: 'Amount Applied', fieldName: 'amountApplied', type: 'currency' },
    { title: 'Final Outstanding Amount', fieldName: 'finalOutstandingAmount', type: 'currency', readonly: true },
    { title: '', fieldName: 'delete', type: 'button' }
];

export default class ReceiptAllocation extends NavigationMixin(LightningElement) {
    @api recordId;
    @track recId = '';
    @track columns = COLUMN;
    @track accountOptions = [];
    @track salesOrderOptions = {};
    @track lineOptions = {};
    @track isLoading = false;

    @track receiptData = {};
    @track totalAmountApplied = 0;
    @track receiptAllocationList = [];
    @track disableSave = true;
    @track refresh = '';
    @track isLoading=false;

    async connectedCallback() {
        this.refresh = Math.floor((Math.random() * 1000000)) + '';
        this.recId = this.recordId ? this.recordId : new URL(window.location.href).searchParams.get("recordId");
        let isOpen = new URL(window.location.href).searchParams.get("c__isOpen");
        if (!isOpen) {
            this.openReceiptAllocation();
            // if (this.receiptAllocationList.length < 1) {
            // location.reload();
            await this.getReceiptData();
            this.refresh = Math.floor((Math.random() * 1000000)) + '';
            // }
        } else {
            this.recId = new URL(window.location.href).searchParams.get("c__rId");
            await this.getReceiptData();
            this.refresh = Math.floor((Math.random() * 1000000)) + '';
        }
    }

    renderedCallback() {
        let recordId = new URL(window.location.href).searchParams.get("c__rId");
        if (recordId != undefined && recordId != null && recordId != '' && recordId != this.recId) {
            this.recId = recordId;
            this.getReceiptData();
        }
    }

    async getReceiptData() {
        this.isLoading = true;
        this.receiptData = {};
        this.receiptAllocationList = [];
       
        await fetchReceiptAlocationByReceiptId({
            receiptId: this.recId
        }).then(result => {
            let tempResult = JSON.parse(result);
            
            this.receiptData = JSON.parse(JSON.stringify(tempResult));
            this.receiptAllocationList = JSON.parse(JSON.stringify(tempResult.rceiptAllocationList));
            this.totalAmountApplied = 0;
            for (let allocation of this.receiptAllocationList) {
                this.totalAmountApplied += allocation.amountApplied;
               
            }

            this.accountOptions = [...this.accountOptions];
            let tempMap = {};
            let tempRelatedAccounts = [];
            for (let acc of tempResult.relatedAccounts) {
                if (tempMap.hasOwnProperty(acc.value)) {
                    tempMap[acc.value] = tempMap[acc.value] + 1;
                    acc.value = acc.value + '_' + tempMap[acc.value];
                    tempRelatedAccounts.push(acc);
                } else {
                    tempMap[acc.value] = 1;
                    acc.value = acc.value + '_' + tempMap[acc.value];
                    tempRelatedAccounts.push(acc);
                }
            }
            this.accountOptions = tempRelatedAccounts;
            this.refresh = Math.floor((Math.random() * 1000000)) + '';
            this.isLoading = false;
        }).catch(error => {
            console.error('error>>>' + error);
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    variant: 'error',
                    message: error,
                })
            );
            this.isLoading = false;
        })
    }

    openReceiptAllocation() {
        /* Commented by Maaz on 31 May below call complete till end of procedure.
        this[NavigationMixin.Navigate]({
            type: 'standard__navItemPage',
            attributes: {
                apiName: 'Receipt_Allocation',
            },
            state: {
                'c__rId': this.recId,
                'c__isOpen': true
            }
        });
        */
    }

    checkValidation(isSave, checkSame) {
        let isError = false;
        let errorMessage = '';

        let uniqueList = [];
        this.totalAmountApplied = 0;
        for (let allocation of this.receiptAllocationList) {
            this.totalAmountApplied = ((this.totalAmountApplied * 100) + (allocation.amountApplied * 100))/100;
            if (checkSame) {
                let unique = allocation.account + '_' + allocation.unitNumber + '_' + allocation.installmentNoOtherCharge;
                if (uniqueList.length > 0 && uniqueList.includes(unique)) {
                    isError = true;
                    errorMessage = 'Please do not select the same Installment number or other changes. Kindly use the existing one.'
                    break;
                } else {
                    uniqueList.push(unique);
                }
            }
            if (checkSame && !isSave) {
                continue;
            }

            if (this.receiptData.amount < this.totalAmountApplied) {
                isError = true;
                errorMessage = "Sum of Receipt Allocation's Amount Applied cannot exceed from Receipt Amount.";
                break;
            } else if (allocation.Id != '' && allocation.totalInvoiceAmount < allocation.amountApplied) {
                isError = true;
                errorMessage = "Receipt Allocation's Amount Applied cannot be exceed from Total Invoice Amount.";
                break;
            } else if (allocation.Id == '' && allocation.currentOutstandingAmount < allocation.amountApplied) {
                isError = true;
                errorMessage = "Receipt Allocation's Amount Applied cannot be exceed from Current Outstanding Amount.";
                break;
            }

            if (isSave) {
                if (!allocation.account || !allocation.unitNumber || !allocation.installmentNoOtherCharge) {
                    isError = true;
                    errorMessage = "Account, Unit Number and Installment # / Other Charges cannot be blank.";
                    break;
                } else if (allocation.amountApplied < 0) {
                    isError = true;
                    errorMessage = "Amount Applied cannot be less than 0";
                    break;
                }

                if (!isError && allocation.amountApplied.toString().includes('.') && allocation.amountApplied.toString().split('.')[1].length > 2) {
                    isError = true;
                    errorMessage = "Please make sure you have added less than 2 digit fraction digit in amount.";
                    break;
                }
            }
        }

        // if (!isError && isSave) {
        //     if (this.totalAmountApplied != this.receiptData.amount) {
        //         isError = true;
        //         errorMessage = 'Please allocate entire "' + this.receiptData.amount +  '" amount.';
        //     }
        // }

        if (isError) {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    variant: 'error',
                    message: errorMessage,
                })
            );
        }
        return isError;
    }

    async handleChange(event) {

        let recordIndex = event.detail.recordIndex;
        let fieldName = event.detail.fieldName;
        let value = event.detail.value;
        this.receiptAllocationList = [...this.receiptAllocationList];
        if (fieldName == 'amountApplied') {
         this.disableSave = false;
            this.receiptAllocationList[recordIndex][fieldName] = parseFloat(value);
            this.receiptAllocationList[recordIndex].finalOutstandingAmount = this.receiptAllocationList[recordIndex].currentOutstandingAmount + this.receiptAllocationList[recordIndex].currentAmountApplied - parseFloat(value);
            this.checkValidation(false, false);
        } else if (fieldName == 'account') {
            this.receiptAllocationList[recordIndex][fieldName] = value;
            for (let acc of this.accountOptions) {
                if (acc.value == value) {
                    this.receiptAllocationList[recordIndex]['accountId'] = acc.accountId;


                    this.receiptAllocationList[recordIndex]['unitNumber'] = '';
                    this.receiptAllocationList[recordIndex]['salesOrderId'] = '';
                    this.receiptAllocationList[recordIndex]['salesOrder'] = '';
                    this.receiptAllocationList[recordIndex]['installmentNoOtherCharge'] = '';
                    this.receiptAllocationList[recordIndex]['isInstallment'] = false;
                    this.receiptAllocationList[recordIndex]['installmentOtherChargeId'] = '';
                    this.receiptAllocationList[recordIndex]['chargeType'] = '';
                    this.receiptAllocationList[recordIndex]['totalInvoiceAmount'] = 0;
                    this.receiptAllocationList[recordIndex]['currentOutstandingAmount'] = 0;
                    this.receiptAllocationList[recordIndex]['currentAmountApplied'] = 0;
                    this.receiptAllocationList[recordIndex]['installmentNoOtherCharge'] = 0;
                    this.receiptAllocationList[recordIndex]['finalOutstandingAmount'] = 0;
                    break;
                }
            }
            await this.getSalesOrder(this.receiptAllocationList[recordIndex]['accountId']);
        } else if (fieldName == 'unitNumber') {
            console.log('inside unit');
            const row = this.receiptAllocationList[recordIndex];
            const selectedSalesOrderId = value;
            const soList = this.salesOrderOptions[row.accountId] || [];
            const selectedSO = soList.find(so => so.value === selectedSalesOrderId);
            if (selectedSO) {
                row.unitNumber = selectedSO.label;          // Unit Name
                row.salesOrderId = selectedSO.value;        // SO Id
                row.salesOrder = selectedSO.salesOrderName; // SO #
            } else {
                row.unitNumber = '';
                row.salesOrderId = '';
                row.salesOrder = '';
            }

            Object.assign(this.receiptAllocationList[recordIndex], {
                installmentNoOtherCharge: '',
                installmentOtherChargeId: '',
                isInstallment: false,
                chargeType: '',
                totalInvoiceAmount: 0,
                currentOutstandingAmount: 0,
                currentAmountApplied: 0,
                amountApplied: 0,
                finalOutstandingAmount: 0
            });
            if (row.salesOrderId) {
                await this.getLines(row.accountId, row.salesOrderId);
            }
            this.receiptAllocationList = [...this.receiptAllocationList];
        } else if (fieldName == 'installmentNoOtherCharge') {
            this.receiptAllocationList[recordIndex][fieldName] = value;
            let isSame = this.checkValidation(false, true);
            for (let line of this.lineOptions[this.receiptAllocationList[recordIndex].accountId + '_' + this.receiptAllocationList[recordIndex].salesOrderId]) {
                if (!isSame && line.value == value) {
                    this.receiptAllocationList[recordIndex]['isInstallment'] = line.chargeType == 'Installment' ? true : false;
                    this.receiptAllocationList[recordIndex]['installmentOtherChargeId'] = line.installmentOtherChargeId;
                    this.receiptAllocationList[recordIndex]['chargeType'] = line.chargeType;
                    this.receiptAllocationList[recordIndex]['totalInvoiceAmount'] = line.totalInvoiceAmount;
                    this.receiptAllocationList[recordIndex]['currentOutstandingAmount'] = line.currentOutstandingAmount;
                    this.receiptAllocationList[recordIndex]['currentAmountApplied'] = 0;
                    const appliedAmount = Math.min(this.remainingAmount, line.currentOutstandingAmount);
                    this.totalAmountApplied = appliedAmount?this.totalAmountApplied +appliedAmount:this.totalAmountApplied;
                    this.receiptAllocationList[recordIndex]['amountApplied'] = appliedAmount;
                   
                    this.receiptAllocationList[recordIndex]['finalOutstandingAmount'] = appliedAmount?line.finalOutstandingAmount-appliedAmount:line.finalOutstandingAmount;
                    
                    break;
                }
            }
             
        }
    }

    async getSalesOrder(accId) {
        this.isLoading = true;
        await fetchSalesOrderByAccountId({
            accountId: accId
        }).then(result => {
            let tempResult = JSON.parse(result);

            this.salesOrderOptions = {
                ...this.salesOrderOptions,
                [accId]: tempResult.map(so => ({label: so.unitName, value: so.salesOrderId, salesOrderName: so.salesOrderName
                }))
            };

             console.log('SalesOrders for account',accId,JSON.stringify(this.salesOrderOptions[accId])); 
            this.isLoading = false;
        }).catch(error => {
            console.error('error>>>' + error);
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    variant: 'error',
                    message: error,
                })
            );
            this.isLoading = false;
        })
    }

    async getLines(accId, salesOrderId) {
        this.isLoading = true;
        await fetchInvoiceForSalesorder({
            SalesOrderId: salesOrderId
        }).then(result => {
            let tempResult = JSON.parse(result);
            tempResult.sort(function(a,b){
                return a.installmentNoOtherCharge-b.installmentNoOtherCharge;
            })
            for (let opt of tempResult) {
                opt.label = opt.installmentNoOtherCharge;
                opt.value = opt.installmentNoOtherCharge + '_'+opt.installmentOtherChargeId;
            }
           

            this.lineOptions[accId + '_' + salesOrderId] = tempResult;
            // for (let line in this.lineOptions) {
            //     this.lineOptions[line] = [...this.lineOptions[line]];
            // }

            this.isLoading = false;
        }).catch(error => {
            console.error('error>>>' + error);
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    variant: 'error',
                    message: error,
                })
            );
            this.isLoading = false;
        })
    }

    addAllocation(event) {
        this.disableSave = false;
        let newRow = {
            Id: '',
            account: '',
            accountId: '',
            salesOrder: '',
            salesOrderId: '',
            unitNumber: '',
            installmentNoOtherCharge: '',
            installmentOtherChargeId: '',
            isInstallment: true,
            chargeType: '',
            totalInvoiceAmount: 0,
            currentOutstandingAmount: 0,
            currentAmountApplied: 0,
            amountApplied: 0,
            finalOutstandingAmount: 0
        }
        this.receiptAllocationList.push(newRow);
    }

    deleteAllocation(event) {
        let rowIndex = event.detail.recordIndex
        if (confirm('Are you sure you want to delete?')) {
            this.receiptAllocationList.splice(rowIndex, 1);
        }
    }

    async handleSave(event) {

        let isError = this.checkValidation(true, true);

        if (!isError) {
            this.isLoading = true;
            let allocation = JSON.stringify(this.receiptAllocationList);
            await UpdateReceiptAllocation({
                receiptAllocations: allocation,
                receiptId: this.recId
            }).then(result => {
                this.getReceiptData();
                this.isLoading = false;
                //Maaz 31-May-2023 commented please see if below line can be done conditionally when Create Receipt with Allocation is clicked or is it not required all together as below line takes you to Receipt Acknowledgement after click on Save
                //this.backToReceiptAcknowledgement();
            }).catch(error => {
                console.error('error>>>' + error);
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error',
                        variant: 'error',
                        message: error,
                    })
                );
                this.isLoading = false;
            })
        }
    }

    backToReceiptAcknowledgement() {
        //let redirectionPageUrl;
        this[NavigationMixin.GenerateUrl]({
            type: 'standard__recordPage',
            attributes: {
                recordId: this.recId,
                objectApiName: 'ReceiptAcknowledgement__c',
                actionName: 'view'
            }
        }).then(url => {
            this.redirectionPageUrl = url;
        });
        setTimeout(() => {
            window.location.href = this.redirectionPageUrl;
        }, 300);
    }

    get remainingAmount() {
        return this.receiptData && this.receiptData.amount != null ? (Math.round(this.receiptData.amount * 100) - Math.round(this.totalAmountApplied * 100))/100 : 0;
    }
}