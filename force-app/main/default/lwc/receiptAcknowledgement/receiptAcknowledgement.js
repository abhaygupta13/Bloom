import { LightningElement, wire, track, api } from 'lwc';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import { getPicklistValues } from 'lightning/uiObjectInfoApi';
import RECEIPT_ACKOWLEDGEMENT_OBJECT from '@salesforce/schema/ReceiptAcknowledgement__c';
import PAYMENT_MODE from '@salesforce/schema/ReceiptAcknowledgement__c.PaymentType__c';
import CURRENCY from '@salesforce/schema/ReceiptAcknowledgement__c.CurrencyIsoCode';
import getAllAccountsMap from '@salesforce/apex/ReceiptAcknowledgementHandler.getBankDetails';
import fetcholdReceiptRecord from "@salesforce/apex/ReceiptAcknowledgementHandler.getDetailOfReceiptAcknowledgement";
import getDetailOfInstallmentRecord from "@salesforce/apex/ReceiptAcknowledgementHandler.getDetailOfInstallmentRecord";
import getRemitterNames from '@salesforce/apex/ReceiptAcknowledgementHandler.getRemitterNames';
import getBankDetails from "@salesforce/apex/ReceiptAcknowledgementHandler.getDetailOfInstallmentRecord";
import getPicklistvalue from "@salesforce/apex/Utilities.getPicklistValues";
import fetchUserProfileName from "@salesforce/apex/ReceiptAcknowledgementHandler.fetchUserProfileName";
import InsertReceiptAcknowledgement from "@salesforce/apex/ReceiptAcknowledgementHandler.insertReceiptAcknowledgement";
import insertAllocatedReceiptWthAmt from "@salesforce/apex/ReceiptAcknowledgementHandler.insertAllocatedReceiptWthAmt";
import { CloseActionScreenEvent } from 'lightning/actions';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';
import resourcesPath from '@salesforce/resourceUrl/BloomResources';
import PaymentModeLabel from '@salesforce/label/c.PaymentModes';
import fileUploadCustomCss from '@salesforce/resourceUrl/fileUploadCustomCss';
import { loadStyle, loadScript } from 'lightning/platformResourceLoader';
import { refreshApex } from '@salesforce/apex';
import LightningConfirm from 'lightning/confirm';

export default class ReceiptAcknowledgement extends NavigationMixin(LightningElement) {

    disableSave = true;
    @track disableAllocationButton = true;
    @track paymentModes;
    @track currency;
    @track bankNames;
    @track profileName;
    @track paymentMode = 'Cheque';
    @track amount = '';
    @track updatedAmount = '';
    @track currencyISO = 'AED';
    @track referenceNumber = '';
    @track customerBankName = '';
    @track customerBankNumber = '';
    @track remarks = '';
    @api mortgageCheque = false;
    @track maturityDate = '';
    @track postingDate = '';
    @track holdDate = '';
    @api recordId;
    @track installmentRecord = [];
    @track uploadedFiles = [];
    @track openModal = false;
    @track salesOrderId = '';
    @track parentRecord = [];
    @track payFrom = '';
    @track relatedObject = '';
    @track accountList = [];
    @track payFromAccountId = '';
    @track payFromAccountName = '';
    @track sendForAllocation = false;
    @track bankNameRequired = false;
    @track receiptAckRecordId = [];
    @track maturityDateRequired = true;
    @track postingDateRequired = true;
    @track doNotCreateAllocation = false;
    @track disableDoNotCreateAllocation = false;
    @track docR
    @track isLoading = true;
    @track selectedPaidBy;
    @track imageDocumentId;
    @track imgData;
    @track cameraImg;
    isModalOpen = false;
    @track showLoading = false;
    showUploadfile = true;
    showCamperaUpload = true;
    showOrPart = true;
    @track selectedPaidByLabel;
    bankAccount;
    @track totalDue = 0;
    @track totalAllocated = 0;
    showAllinstallments = false;
    acrossUnitsChecked = false;
    @track installmentdetailItem = [];
    @track salesorderOtherDetailItem = [];
    installmetntype;
    overdueInDays;
    installmentAccount;
    @track selectedInstallments = [];
    @track selectedSalesorderOther = [];
    timer;
    installmentsInfo;
    salesorderOOtherinfo;
    disableAllocateOutStanding = true;
    disableTotalDue = true;
    disableTotalAllocated = true;
    isNegativeAmount;
    isTotalAllocatedAmountvalid;
    @track installmentRecords = [];
    @track salesorderOtherchargeRecord = [];
    showSalesorderOthercharge = false;
    @track totalInstAllocAmount = 0;
    @track totalOtherChAllocAmount = 0;
    @track chequeLeftOverAmt = 0;
    @track totalInstDueAmt = 0;
    @track totalSaleOthDueAmt = 0;
    @track invoiceTypes;
    @track allocatedValues;
    @track allocationValue;
    @track bankAccounts = [];
    @track remitterOptions = [];
    @track selectedRemitter;
    @track otherRemitterName;
    @track showOtherRemitter = false;
    @track accountId;
    remitterLoaded = false;
    showRestrictionMessage = false;
    restrictionMessage = '';

    @track invoiceTypeOptions = [
        { label: 'None', value: null },
        { label: 'Installment', value: 'Installment' },
        { label: 'Tax', value: 'Tax' },
        { label: 'ADM Fee', value: 'ADM Fee' },
        { label: 'Service Charge', value: 'Service Charge' },
        { label: 'ADM Admin Fee', value: 'ADM Admin Fee' },
        { label: 'Late Payment Charges', value: 'Late Payment Charges' },
        { label: 'Transfer Fee', value: 'Transfer Fee' },
        { label: 'Admin Charges', value: 'Admin Charges' }
    ];

    @track acceptFileTypeList = [];
    connectedCallback() {

        console.log(this.maturityDate + '- Installment Record - ' + this.recordId);
        this.openModal = true;
        this.isLoading = true;
        //this.paymentModes = PaymentModeLabel.split(',');
        if (PaymentModeLabel) {
            const options = PaymentModeLabel.split(';').map((elem) => {
                const option = {
                    label: elem,
                    value: elem
                };
                return option;
                // this.paymentModes = [ ...this.paymentModes, option ];  
            });
            this.paymentModes = options;
        }
        console.log(PaymentModeLabel + '**Payment Modes**' + this.paymentModes);


        fetchUserProfileName()
            .then(result => {
                this.profileName = result;
            })
            .catch(error => {
                console.log('Error in retriving current user profile name');
            });
    }

    get isBankAccountEmpty() {
        return !this.bankAccount; // Check if the bankAccount is empty or null
    }

    renderedCallback() {


        Promise.all([
            loadStyle(this, fileUploadCustomCss)
        ]).then(() => {
            console.log('Files loaded');
        })
            .catch(error => {
                console.log(error.body.message);
            });
    }


    getFilterInstallmentRecord() {
        if (this.overdueInDays || this.invoiceTypes) {
            this.installmentRecord = [];
            this.salesorderOOtherinfo = [];
            this.installmentdetailItem = [];
            this.salesorderOtherchargeRecord = [];
            this.selectedInstallments = [];
            this.selectedSalesorderOther = [];
            this.totalOtherChAllocAmount = 0;
            this.chequeLeftOverAmt = this.amount;
            this.totalInstDueAmt = 0;
            this.totalSaleOthDueAmt = 0;
            this.totalDue = 0;
            this.totalAllocated = 0
            this.totalInstAllocAmount = 0;


            getDetailOfInstallmentRecord({ recordId: this.salesOrderId, overdueInDays: this.overdueInDays, invoiceTypes: this.invoiceTypes, acrossUnitsChecked: this.acrossUnitsChecked, installmentAccount: this.installmentAccount })
                .then(result => {
                    console.log(result);
                    let instData = [];
                    let salesOtherData = [];
                    result.forEach(item => {
                        if (item.InstallmentLines__r)
                            item.InstallmentLines__r.forEach(inst => {
                                instData.push(inst);
                            })
                        if (item.SalesOrdersOtherCharges__r)
                            item.SalesOrdersOtherCharges__r.forEach(sooc => {

                                salesOtherData.push(sooc);
                            })
                    })
                    this.installmentRecords = instData;
                    console.log(this.installmentRecords);
                    this.salesorderOtherchargeRecord = salesOtherData;
                    this.installmentsInfo = this.installmentRecords;
                    this.salesorderOOtherinfo = this.salesorderOtherchargeRecord;

                    const cloneResult = JSON.parse(JSON.stringify(this.installmentRecords));
                    const cloneResultSalesorderOther = JSON.parse(JSON.stringify(this.salesorderOtherchargeRecord));

                    cloneResult.forEach(item => {
                        item.allocatedAmount = 0;
                    });
                    cloneResultSalesorderOther.forEach(item => {
                        item.allocatedAmountSalesother = 0;
                    });
                    this.installmentdetailItem = cloneResult;
                    this.salesorderOtherchargeRecord = cloneResultSalesorderOther;

                    if (this.installmentdetailItem.length > 0) {
                        this.showAllinstallments = true;
                    }
                    if (this.salesorderOtherchargeRecord.length > 0) {
                        this.showSalesorderOthercharge = true;
                    }

                }).catch(error => {
                    this.error = error;
                })
        } else {
            this.showAllinstallments = false;
        }
    }

    handleAllSelect(event) {
        try {

            const isChecked = event.target.checked;
            if (isChecked) {
                let totalDueAmt = 0;
                let totalAllocAmt = 0;
                let totalAllocOther = 0
                let totalDueOtherCha = 0;
                let chequeAmt = Number(this.chequeLeftOverAmt);

                this.installmentdetailItem.forEach(item => {
                    console.log(typeof (chequeAmt))
                    item.isSelected = true;

                    if (chequeAmt > item.PendingAmount__c) {

                        item.allocatedAmount = item.PendingAmount__c;
                        chequeAmt = chequeAmt - item.PendingAmount__c;
                        item.PendingAmount__c = item.PendingAmount__c - item.allocatedAmount;
                    } else if (chequeAmt <= item.PendingAmount__c) {

                        item.allocatedAmount = chequeAmt;
                        item.PendingAmount__c = item.PendingAmount__c - item.allocatedAmount;
                        chequeAmt = 0;
                    }

                    totalDueAmt += item.PendingAmount__c;
                    totalAllocAmt += item.allocatedAmount;

                });

                this.selectedInstallments = this.installmentdetailItem;

                this.salesorderOtherchargeRecord.forEach(item => {
                    item.isSelected = true;
                    if (chequeAmt > item.PendingAmount__c) {
                        item.allocatedAmountSalesother = item.PendingAmount__c;
                        chequeAmt = chequeAmt - item.PendingAmount__c;
                        item.PendingAmount__c = item.PendingAmount__c - item.allocatedAmountSalesother;
                    } else if (chequeAmt <= item.PendingAmount__c) {
                        item.allocatedAmountSalesother = chequeAmt;
                        item.PendingAmount__c = item.PendingAmount__c - item.allocatedAmountSalesother;
                        chequeAmt = 0;
                    }
                    totalDueOtherCha += item.PendingAmount__c;
                    totalAllocOther = +item.allocatedAmountSalesother;
                });
                this.totalDue = totalDueAmt + totalDueOtherCha;
                this.totalAllocated = totalAllocAmt + totalAllocOther;
                this.totalInstAllocAmount = totalAllocAmt;
                this.totalOtherChAllocAmount = totalAllocOther;
                this.totalInstDueAmt = totalDueAmt;
                this.totalSaleOthDueAmt = totalDueOtherCha;
                this.selectedSalesorderOther = this.salesorderOtherchargeRecord;
                this.chequeLeftOverAmt = chequeAmt;
            } else {

                this.installmentdetailItem.forEach(item => {
                    item.isSelected = false;
                    item.PendingAmount__c = this.installmentsInfo.filter(filt => filt.Id == item.Id)[0].PendingAmount__c;
                    item.allocatedAmount = 0;
                });
                this.salesorderOtherchargeRecord.forEach(item => {
                    item.isSelected = false;
                    item.PendingAmount__c = this.salesorderOOtherinfo.filter(filt => filt.Id == item.Id)[0].PendingAmount__c;
                    item.allocatedAmountSalesother = 0;
                });
                this.selectedInstallments = [];
                this.selectedSalesorderOther = [];
                this.totalDue = 0;
                this.totalAllocated = 0;
                this.totalOtherChAllocAmount = 0;
                this.chequeLeftOverAmt = this.amount;
                this.totalInstDueAmt = 0;
                this.totalSaleOthDueAmt = 0;
                this.totalInstAllocAmount = 0;

            }
        } catch (e) {
            console.log(e.message);
        }
    }


    handleOverdueChange(event) {

        this.overdueInDays = event.target.value;
        this.validateInputs();
        window.clearTimeout(this.timer)

        this.timer = setTimeout(() => {

            this.getFilterInstallmentRecord()
        }, 1000)


    }
    handleInvoiceTypeChange(event) {
        this.invoiceTypes = event.target.value;

        this.timer = setTimeout(() => {

            this.getFilterInstallmentRecord()
        }, 1000)

    }

    handleAcrossUnitCheckbox(event) {
        this.acrossUnitsChecked = event.target.checked;
        this.getFilterInstallmentRecord();

    }

    handleCheckboxinstallment(event) {
        const index = event.target.dataset.index;
        console.log('index' + index + '---' + event.target.checked);
        if (event.target.checked) {
            this.selectedInstallments.push(this.installmentdetailItem[index]);
            let currentInst = this.installmentdetailItem[index];
            if (this.chequeLeftOverAmt > currentInst.PendingAmount__c) {
                currentInst.allocatedAmount = currentInst.PendingAmount__c;
                this.chequeLeftOverAmt = this.chequeLeftOverAmt - currentInst.PendingAmount__c;
                currentInst.PendingAmount__c = 0;
            } else if (this.chequeLeftOverAmt <= currentInst.PendingAmount__c) {
                currentInst.allocatedAmount = this.chequeLeftOverAmt;
                this.chequeLeftOverAmt = 0;
                currentInst.PendingAmount__c = currentInst.PendingAmount__c - currentInst.allocatedAmount;
            }
        } else if (!event.target.checked) {

            this.selectedInstallments = this.selectedInstallments.filter((item) => item.Id !== this.installmentdetailItem[index].Id);
            this.chequeLeftOverAmt = this.chequeLeftOverAmt + this.installmentdetailItem[index].allocatedAmount;
            this.installmentdetailItem[index].allocatedAmount = 0;
            this.installmentdetailItem[index].PendingAmount__c = this.installmentsInfo.filter(filt => filt.Id == this.installmentdetailItem[index].Id)[0].PendingAmount__c;

        }
        let allocateAmt = 0;
        let totalDueAmt = 0;
        this.selectedInstallments.forEach(item => {
            allocateAmt += Number(item.allocatedAmount);
            totalDueAmt += Number(item.PendingAmount__c);
        })
        this.totalInstAllocAmount = allocateAmt;
        this.totalInstDueAmt = totalDueAmt;
        this.totalAllocated = allocateAmt + this.totalOtherChAllocAmount;
        this.totalDue = totalDueAmt + this.totalSaleOthDueAmt;


        if (this.totalAllocated > this.amount) {
            this.isTotalAllocatedAmountvalid = true;
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    variant: 'error',
                    message: 'Allocated amount should not be greater than applied amount.'
                }),
            );
        } else {
            this.isTotalAllocatedAmountvalid = false;
        }

        console.log('receiptitem' + JSON.stringify(this.selectedInstallments));



    }

    handleCheckboxSalesorderOther(event) {
        try {
            const index = event.target.dataset.index;
            console.log('index' + index + '---' + event.target.checked);
            if (event.target.checked) {
                this.selectedSalesorderOther.push(this.salesorderOtherchargeRecord[index]);
                let currentInst = this.salesorderOtherchargeRecord[index];
                if (this.chequeLeftOverAmt > currentInst.PendingAmount__c) {
                    currentInst.allocatedAmountSalesother = currentInst.PendingAmount__c;
                    this.chequeLeftOverAmt = this.chequeLeftOverAmt - currentInst.PendingAmount__c;
                    currentInst.PendingAmount__c = 0;
                } else if (this.chequeLeftOverAmt <= currentInst.PendingAmount__c) {
                    currentInst.allocatedAmountSalesother = this.chequeLeftOverAmt;
                    this.chequeLeftOverAmt = 0;
                    currentInst.PendingAmount__c = currentInst.PendingAmount__c - currentInst.allocatedAmountSalesother;
                }


            } else if (!event.target.checked) {
                this.chequeLeftOverAmt = this.chequeLeftOverAmt + this.salesorderOtherchargeRecord[index].allocatedAmountSalesother;

                this.selectedSalesorderOther = this.selectedSalesorderOther.filter((item) => item.Id !== this.salesorderOtherchargeRecord[index].Id);
                this.salesorderOtherchargeRecord[index].allocatedAmountSalesother = 0;
                this.salesorderOtherchargeRecord[index].PendingAmount__c = this.salesorderOOtherinfo.filter(filt => filt.Id == this.salesorderOtherchargeRecord[index].Id)[0].PendingAmount__c;


                console.log(JSON.stringify(this.selectedSalesorderOther));

            }
            let SalesOOtherallocateAmt = 0;
            let SalesOOthertotalDueAmt = 0;
            this.selectedSalesorderOther.forEach(item => {
                SalesOOtherallocateAmt += Number(item.allocatedAmountSalesother);
                SalesOOthertotalDueAmt += Number(item.PendingAmount__c);
            })
            this.totalSaleOthDueAmt = SalesOOthertotalDueAmt;
            this.totalOtherChAllocAmount = SalesOOtherallocateAmt;
            this.totalAllocated = SalesOOtherallocateAmt + this.totalInstAllocAmount;
            this.totalDue = SalesOOthertotalDueAmt + this.totalInstDueAmt;

            if (this.totalAllocated > this.amount) {
                this.isTotalAllocatedAmountvalid = true;
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error',
                        variant: 'error',
                        message: 'Allocated amount should not be greater than applied amount.'
                    }),
                );
            } else {
                this.isTotalAllocatedAmountvalid = false;
            }
        }
        catch (e) {
            console.log(e.message);
            console.log(e);
            console.log(e.stack);
            console.log(e.linenumber);
        }


    }

    allocateAmountChange(event) {
        const index = event.target.dataset.index;
        this.installmentdetailItem[index].PendingAmount__c = this.installmentsInfo[index].PendingAmount__c - event.target.value;
        if (this.installmentdetailItem[index].PendingAmount__c < 0) {
            this.isNegativeAmount = true;
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    variant: 'error',
                    message: 'Pending Amount Can Not Be Less Then Zero.'
                }),
            );

        } else {
            this.isNegativeAmount = false;
        }


        if (event.target.value) {
            this.installmentdetailItem[index].allocatedAmount = event.target.value;
            this.selectedInstallments.forEach(item => {
                if (item.Id == this.installmentdetailItem[index].Id) {
                    item.allocatedAmount = event.target.value;
                }
            })

        }
        let allocateAmt = 0;
        this.selectedInstallments.forEach(item => {
            allocateAmt += Number(item.allocatedAmount);
        })

        this.totalInstAllocAmount = allocateAmt;
        this.totalAllocated = allocateAmt + this.totalOtherChAllocAmount;


    }

    allocateSalesOOtherAmountChange(event) {
        const index = event.target.dataset.index;
        this.salesorderOtherchargeRecord[index].PendingAmount__c = this.salesorderOOtherinfo[index].PendingAmount__c - event.target.value;

        if (this.salesorderOtherchargeRecord[index].PendingAmount__c < 0) {
            this.isNegativeAmount = true;
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    variant: 'error',
                    message: 'Pending Amount Can Not Be Less Then Zero.'
                }),
            );

        } else {
            this.isNegativeAmount = false;
        }
        if (event.target.value) {
            this.salesorderOtherchargeRecord[index].allocatedAmountSalesother = event.target.value;
            this.selectedSalesorderOther.forEach(item => {
                if (item.Id == this.salesorderOtherchargeRecord[index].Id) {
                    item.allocatedAmountSalesother = event.target.value;
                }
            })

        }
        console.log(this.salesorderOtherchargeRecord);
        let SalesOOallocateAmt = 0;
        this.selectedSalesorderOther.forEach(item => {
            SalesOOallocateAmt += Number(item.allocatedAmountSalesother);
        })
        console.log('SalesOOallocateAmt' + this.SalesOOallocateAmt);
        this.totalOtherChAllocAmount = SalesOOallocateAmt;
        this.totalAllocated = SalesOOallocateAmt + this.totalInstAllocAmount;
        console.log('totalAllocated' + this.totalAllocated);


    }

    @wire(getAllAccountsMap, { recordId: '$recordId' })
    wiredMap({ error, data }) {
        if (data) {
            // Convert map { Id: Name } → array [{ label, value }]
            this.bankAccounts = Object.entries(data).map(([key, value]) => ({
                label: value,
                value: key
            }));
            console.log('BankAccounts' + this.bankAccounts);
            console.log(JSON.stringify(this.bankAccounts));
        } else if (error) {
            console.error('Error fetching bank account map: ', error);
        }
    }

    handleBankAccountChange(event) {
        this.bankAccount = event.detail.value;
        console.log('this.bankAccount' + this.bankAccount);
    }

    //---- To get installment details
    @wire(fetcholdReceiptRecord, { recordId: '$recordId' })
    parentRecords({ data, error }) {
        if (data) {
            // Handle restricted case FIRST
            if (data.isRestricted === true) {

                this.showRestrictionMessage = true;
                this.restrictionMessage =
                    this.parentRecord.restrictionMessage;

                // Auto close after 3 sec
                setTimeout(() => {
                    window.history.back();
                }, 3000);

                return;
            }
            this.parentRecord = data;
            this.amount = this.parentRecord.amount;
            this.chequeLeftOverAmt = this.parentRecord.amount;
            this.relatedObject = this.parentRecord.objectName;
            console.log(this.relatedObject + ' - Sales Order Number - ' + JSON.stringify(this.parentRecord));
            this.salesOrderId = this.parentRecord.salesOrderId;
            this.maturityDate = this.parentRecord.paymentDate;
            this.postingDate = this.parentRecord.ReceiptPostingDate__c;
            this.installmentAccount = this.parentRecord.salesOrderRecord.Account__c;
            // alert('accountname'+this.installmentAccount);
            if (this.relatedObject == 'InstallmentLines__r') {
                if (data.installmentRec.SalesOrder__r.Cheque_from_Bank__c)
                    this.customerBankName = data.installmentRec.SalesOrder__r.Cheque_from_Bank__c;
                if (data.installmentRec.Type__c == 'Installment' && data.installmentRec.SalesOrder__r.Unit__r.BuildingSectionName__r.Primary_Account_Installment__c) {
                    this.bankAccount = data.installmentRec.SalesOrder__r.Unit__r.BuildingSectionName__r.Primary_Account_Installment__c;
                } else if (data.installmentRec.Type__c == 'Handover' && data.installmentRec.SalesOrder__r.Unit__r.BuildingSectionName__r.HandoverAccountInstallment__c) {
                    this.bankAccount = data.installmentRec.SalesOrder__r.Unit__r.BuildingSectionName__r.HandoverAccountInstallment__c;
                } else if (data.installmentRec.Type__c == 'Post Handover Installment' && data.installmentRec.SalesOrder__r.Unit__r.BuildingSectionName__r.PHPPAccountInstallment__c) {
                    this.bankAccount = data.installmentRec.SalesOrder__r.Unit__r.BuildingSectionName__r.PHPPAccountInstallment__c;
                } else {
                    this.bankAccount = data.installmentRec.SalesOrder__r.Unit__r.BuildingSectionName__r.Primary_Account_Installment__c;
                }
            } else if (this.relatedObject == 'SalesOrdersOtherCharges__r') {
                if (data.salesOrderOtherChargesRec.SalesOrder__r.Cheque_from_Bank__c)
                    this.customerBankName = data.salesOrderOtherChargesRec.SalesOrder__r.Cheque_from_Bank__c;
                if (data.salesOrderOtherChargesRec.TypeOfCharge__c == 'ADM Fee' && data.salesOrderOtherChargesRec.SalesOrder__r.Unit__r.BuildingSectionName__r.Primary_Account_ADM_Charges__c) {
                    this.bankAccount = data.salesOrderOtherChargesRec.SalesOrder__r.Unit__r.BuildingSectionName__r.Primary_Account_ADM_Charges__c;
                }
                else if (data.salesOrderOtherChargesRec.TypeOfCharge__c != 'ADM Fee' && data.salesOrderOtherChargesRec.SalesOrder__r.Unit__r.BuildingSectionName__r.BounceChequeAccount__c) {
                    this.bankAccount = data.salesOrderOtherChargesRec.SalesOrder__r.Unit__r.BuildingSectionName__r.BounceChequeAccount__c;
                }
            }

            if (this.parentRecord.relatedAccounts) {
                for (const list of this.parentRecord.relatedAccounts) {
                    const option = {
                        label: list.Name,
                        value: list.Id
                    };
                    this.accountList = [...this.accountList, option];
                }
                console.log(JSON.stringify(this.accountList) + ' - Account List');
            }
            console.log(this.salesOrderId + ' - Sales Order - ' + JSON.stringify(this.parentRecord.salesOrderRecord));

            if (this.parentRecord.salesOrderRecord.Account__c != null && !this.remitterLoaded) {
                this.accountId = this.parentRecord.salesOrderRecord.Account__c;
                this.remitterLoaded = true;
                this.fetchRemitterNames();
            }
        } else if (error) {
            console.log(error);
        }
    };

    fetchRemitterNames() {
        console.log('this.accountId' + this.accountId);
        getRemitterNames({ accountId: this.accountId })
            .then(data => {
                if (!data || data.length === 0) {
                    this.remitterOptions = [{ label: 'Other', value: 'Other' }];
                    this.selectedRemitter = 'Other';
                    this.showOtherRemitter = true;
                    return;
                }
                let options = [];

                data.forEach(name => {
                    options.push({
                        label: name,
                        value: name
                    });
                });

                options.push({
                    label: 'Other',
                    value: 'Other'
                });

                this.remitterOptions = options;

                if (!this.selectedRemitter && options.length) {
                    this.selectedRemitter = options[0].value;
                }
            })
            .catch(error => {
                console.error('Error fetching remitter names', error);
            });
    }

    handleRemitterChange(event) {
        this.selectedRemitter = event.detail.value;
        this.showOtherRemitter = this.selectedRemitter === 'Other';

        if (!this.showOtherRemitter) {
            this.otherRemitterName = null;
        }

        this.validateInputs();
    }

    handleOtherRemitterChange(event) {
        this.otherRemitterName = event.target.value;
        this.validateInputs();
    }

    get finalRemitterName() {
        return this.selectedRemitter === 'Other' ? this.otherRemitterName : this.selectedRemitter;
    }

    //---- To get receipt acknowledgement records
    @wire(getObjectInfo, { objectApiName: RECEIPT_ACKOWLEDGEMENT_OBJECT })
    receiptObject;



    /*
    //------ To get paymentmode dropdown
    @wire(getPicklistValues,{
            recordTypeId: '$receiptObject.data.defaultRecordTypeId', 
            fieldApiName: PAYMENT_MODE
        })
    paymentModes;
    */

    @wire(getPicklistvalue, {
        objName: 'ReceiptAcknowledgement__c',
        fieldName: 'BankName__c'
    })
    wiredBankNameValues({ data, error }) {
        if (data) {
            let temp = [];

            for (var key in data) {
                temp.push({ label: key, value: data[key] });
            }
            this.bankNames = temp;
            console.log(JSON.stringify(this.bankNames));
        } else if (error) {
            console.log('error' + JSON.stringify(error));
            this.error = error;
            this.bankNames = undefined;
        }
    }


    @wire(getPicklistvalue, {
        objName: 'ReceiptAcknowledgement__c',
        fieldName: 'CurrencyIsoCode'
    })
    wiredCurrencyIsoCodeValues({ data, error }) {
        if (data) {
            let temp = [];

            for (var key in data) {
                temp.push({ label: key, value: data[key] });
            }
            this.currency = temp;
            console.log(JSON.stringify(this.currency));
        } else if (error) {
            this.error = error;
            this.bankNames = undefined;
        }
    }

    @wire(getPicklistvalue, {
        objName: 'ReceiptAcknowledgement__c',
        fieldName: 'Allocate__c'
    })
    wiredAllocateValues({ data, error }) {
        if (data) {
            let temp = [];

            for (var key in data) {
                temp.push({ label: key, value: data[key] });
            }
            this.allocateValues = temp;
            console.log(JSON.stringify(this.currency));
        } else if (error) {
            this.error = error;
            this.allocateValues = undefined;
        }
    }

    @wire(getPicklistvalue, {
        objName: 'ReceiptAcknowledgement__c',
        fieldName: 'Allocation__c'
    })
    wiredallocationValues({ data, error }) {
        if (data) {
            let temp = [];

            for (var key in data) {
                temp.push({ label: key, value: data[key] });
            }
            this.allocationValues = temp;
            console.log(JSON.stringify(this.currency));
        } else if (error) {
            this.error = error;
            this.allocationValues = undefined;
        }
    }
    //--- On select of payment mode picklist value
    handleChangePaymentMode(event) {
        this.paymentMode = event.detail.value;
        if (this.paymentMode == 'Cheque') {
            this.bankNameRequired = true;
            //this.maturityDateRequired = true ; 
        }
        else {
            this.bankNameRequired = false;
            //this.maturityDateRequired = false ; 
        }

        if (this.paymentMode == 'Wire Transfer') {
            this.doNotCreateAllocation = true;
            this.disableDoNotCreateAllocation = true;
        }
        else {
            this.doNotCreateAllocation = false;
            this.disableDoNotCreateAllocation = false;

        }

        this.validateInputs();
    }

    //--- On select of currency iso picklist value
    handleChangeCurrency(event) {
        this.currencyISO = event.detail.value;
    }

    //--- On select of Customer Bank Name value
    handleChangeCustomerBankName(event) {
        this.customerBankName = event.detail.value;
        this.validateInputs();
    }

    handleChangeallocateValues(event) {
        this.allocatedValues = event.target.value;
    }

    handleChangeallocationValues(event) {
        this.allocationValue = event.target.value;

    }

    handleChange(event) {
        const field = event.target.dataset.name;
        const value = event.target.value;
        console.log('value' + value);
        if (field === 'amount') {
            this.chequeLeftOverAmt = value;
            this.updatedAmount = value;
        } else if (field === 'postingDate') {
            this.postingDate = value;
        } else {
            this[field] = value;
        }

        console.log('updatedAmount:', this.updatedAmount);
        this.validateInputs();
    }

    validatePostingDate(inputCmp) {
        if (!this.postingDate) {
            inputCmp.setCustomValidity('');
            inputCmp.reportValidity();
            return;
        }

        const selectedDate = new Date(this.postingDate);
        const today = new Date();

        selectedDate.setHours(0, 0, 0, 0);
        today.setHours(0, 0, 0, 0);

        const firstDayOfMonth = new Date(
            today.getFullYear(),
            today.getMonth(),
            1
        );

        let errorMessage = '';

        if (selectedDate < today && selectedDate < firstDayOfMonth) {
            errorMessage =
                'For past dates, Posting Date must be within the current month.';
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    variant: 'error',
                    message: 'For past dates, Posting Date must be within the current month.',
                }),
            );
        }

    }


    handleCheckboxChange(event) {
        this.doNotCreateAllocation = event.target.checked;
        console.log('doNotCreateAllocation' + this.doNotCreateAllocation);
    }

    validateInputs() {
        const remitterInvalid = this.showOtherRemitter && !this.otherRemitterName;
        this.disableSave = [this.paymentMode, this.amount, this.referenceNumber, this.bankAccount, this.postingDate].some(value => !value) || remitterInvalid;
        if (this.paymentMode == 'Cheque') {
            this.disableSave = [this.paymentMode, this.amount, this.referenceNumber, this.customerBankName, this.maturityDate, this.bankAccount, this.postingDate].some(value => !value) || remitterInvalid;
        }
        if (this.referenceNumber.length < 6) {
            this.disableSave = true;
        }
        this.disableAllocateOutStanding = [this.amount, this.overdueInDays].some(value => !value);
        this.disableAllocationButton = this.disableSave;
        console.log('Current user profileName -' + this.profileName);
        if (this.paymentMode == 'Wire Transfer' && (this.profileName == 'Finance Team' || this.profileName == 'Operations Team')) {
            //this.disableAllocationButton = false;
        }
        else if (this.paymentMode == 'Wire Transfer' && (this.profileName != 'Finance Team' || this.profileName != 'Operations Team')) {
            //this.disableAllocationButton = true;
        }
        console.log('doNotCreateAllocation' + this.doNotCreateAllocation);

    }

    navigateToObjectRecord() {
        console.log('navigating record-' + this.recordId);
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: this.recordId,
                objectApiName: 'InstallmentLines__c',
                actionName: 'view'
            }
        });
    }

    navigateToSOListView() {
        this[NavigationMixin.GenerateUrl]({
            type: 'standard__recordRelationshipPage',
            attributes: {
                recordId: this.salesOrderId,
                objectApiName: 'SalesOrder__c',
                relationshipApiName: this.relatedObject,
                actionName: 'view'
            },
        }).then(url => {

            this.redirectionPageUrl = url;

        });
    }

    navigateToSOView() {
        this[NavigationMixin.GenerateUrl]({
            type: 'standard__recordPage',
            attributes: {
                recordId: this.salesOrderId,
                objectApiName: 'SalesOrder__c',
                actionName: 'view'
            },
        }).then(url => {

            this.redirectionPageUrl = url;

        });

    }

    onFileUpload(event) {

        //---- Get the list of uploaded files
        const uploadedFiles = event.detail.files;
        // alert(event.target.files[0].name + ' No. of files uploaded : ' + uploadedFiles.length);
        console.log('uploadedFiles ' + JSON.stringify(uploadedFiles));

        function getBase64(file) {
            return new Promise((resolve, reject) => {
                const reader = new FileReader();
                reader.readAsDataURL(file);
                reader.onload = () => resolve(reader.result);
                reader.onerror = error => reject(error);
            });
        }

        Array.from(event.target.files).forEach(file => {
            let filePieces = file.name.split('.');
            let fileType = filePieces[filePieces.length - 1].trim();

            //if (this.acceptFileTypeList.includes(fileType)) {
            var base64;
            getBase64(file).then(
                data => {
                    base64 = data.split(',')[1];
                }
            );
            var reader = new FileReader();
            if (event.target.dataset.id === 'paymentFiles') {
                reader.onload = () => {
                    let result = this.uploadedFiles.filter(obj => {

                        return obj.Title === file.name;
                    });
                    this.uploadedFiles.push({
                        'Title': result?.length > 0 ? file.name + `(${this.uploadedFiles.length})` : file.name,
                        'FileContent': base64,
                    });
                }
                reader.readAsDataURL(file);
            } else {
                console.log('else');
            }
            // }
        });

    }

    get acceptedFormats() {
        var acceptFormatList = [];
        for (let i = 0; i < this.acceptFileTypeList.length; i++) {
            acceptFormatList[i] = '.' + this.acceptFileTypeList[i];
        }

        return acceptFormatList;
    }

    removeFile(event) {
        let listName = event.currentTarget.dataset.listname;
        let fileName = event.currentTarget.dataset.id;

        this.uploadedFiles = this.uploadedFiles?.filter(function (obj) {
            return obj.Title != fileName;
        });
        this.uploadedFiles = [...this.uploadedFiles];

    }

    handleSaveAllocation() {
        this.sendForAllocation = true;
        this.handleSave();
    }

    async handleSave() {
        this.showLoading = true;
        try {
            const posting = new Date(this.postingDate);
            const maturity = new Date(this.maturityDate);
            if (posting < maturity) {
                const result = await LightningConfirm.open({
                    message: 'Posting Date is earlier than Maturity Date. Do you want to continue?',
                    variant: 'header',
                    label: 'Confirmation Required',
                    variant: 'header',
                    theme: 'warning'
                });

                // If user clicks Cancel
                if (!result) {
                    this.showLoading = false;
                    return; // STOP execution
                }
            }

            this.disableSave = true;
            this.disableAllocationButton = true;
            console.log('Sales Order - ' + this.salesOrderId + '- Account - ' + this.parentRecord.salesOrderRecord.Account__c);
            console.log('paymentMode - ' + this.paymentMode + ' amount - ' + this.amount);
            console.log('this.updatedAmount' + this.updatedAmount);
            console.log('referenceNumber - ' + this.referenceNumber + '- remarks - ' + this.remarks);
            console.log('customerBankName - ' + this.customerBankName + '- customerBankNumber - ' + this.customerBankNumber);
            //alert(this.parentRecord.salesOrderRecord.Opportunity__c+'File Uploaded - '+this.uploadedFiles);
            let receiptAcknowledgementRec = { 'sobjectType': 'ReceiptAcknowledgement__c' };
            receiptAcknowledgementRec.PaymentType__c = this.paymentMode;
            receiptAcknowledgementRec.Amount__c = (this.updatedAmount !== null && this.updatedAmount !== '') ? this.updatedAmount : this.amount;
            receiptAcknowledgementRec.SalesOrder__c = this.salesOrderId;
            receiptAcknowledgementRec.Opportunity__c = this.parentRecord.salesOrderRecord.Opportunity__c;
            receiptAcknowledgementRec.Account__c = this.parentRecord.salesOrderRecord.Account__c;
            receiptAcknowledgementRec.Remarks__c = this.remarks;
            receiptAcknowledgementRec.BankName__c = this.customerBankName;
            receiptAcknowledgementRec.CustomerBankAccount__c = this.customerBankNumber;
            receiptAcknowledgementRec.ReferenceNumber__c = this.referenceNumber;
            //Added by Jana - 09/08/2023
            receiptAcknowledgementRec.Unit__c = this.parentRecord.salesOrderRecord.Unit__c;
            receiptAcknowledgementRec.Account_Name__c = this.parentRecord.salesOrderRecord.AccountName__c;

            receiptAcknowledgementRec.Allocate__c = this.allocatedValues;
            receiptAcknowledgementRec.Allocation__c = this.allocationValue;
            if (this.paymentMode == 'Wire Transfer') {
                receiptAcknowledgementRec.Customer_Transfer_Reference__c = this.referenceNumber;
            }
            receiptAcknowledgementRec.MortgageCheque__c = this.mortgageCheque;
            receiptAcknowledgementRec.MaturityDate__c = this.maturityDate;
            receiptAcknowledgementRec.ReceiptPostingDate__c = this.postingDate;
            receiptAcknowledgementRec.HoldDate__c = this.holdDate;

            receiptAcknowledgementRec.CurrencyIsoCode = this.currencyISO;
            receiptAcknowledgementRec.IsCreatedFromLink__c = true;
            receiptAcknowledgementRec.RecievedFromAccount__c = this.payFromAccountId;
            receiptAcknowledgementRec.PaidBy__c = this.selectedPaidByLabel;
            receiptAcknowledgementRec.RecievedFromAccount__c = this.selectedPaidBy;
            receiptAcknowledgementRec.RemitterName__c = this.finalRemitterName;
            console.log('receiptAcknowledgementRec - ' + JSON.stringify(receiptAcknowledgementRec));


            if (this.relatedObject == 'InstallmentLines__r') {
                if (this.parentRecord.installmentRec.Installment_Type__c == 'Installment' && this.parentRecord.installmentRec.SalesOrder__r.Unit__r.BuildingSectionName__r.Primary_Account_Installment__c) {
                    receiptAcknowledgementRec.Bank_Account__c = this.bankAccount;
                    receiptAcknowledgementRec.SAP_Special_GL_Indicator__c = 'X';
                } else if (this.parentRecord.installmentRec.Installment_Type__c == 'Tax' && this.parentRecord.installmentRec.SalesOrder__r.Unit__r.BuildingSectionName__r.Primary_Account_ADM_Charges__c) {
                    receiptAcknowledgementRec.Bank_Account__c = this.bankAccount;
                    receiptAcknowledgementRec.SAP_Special_GL_Indicator__c = 'X';
                }

            } else if (this.relatedObject == 'SalesOrdersOtherCharges__r') {
                receiptAcknowledgementRec.Bank_Account__c = this.bankAccount;
                receiptAcknowledgementRec.SAP_Special_GL_Indicator__c = this.parentRecord.salesOrderOtherChargesRec.TypeOfCharge__c == 'ADM Fee' ? 'V' : '';
            }


            let { base64, filename } = this.fileData;
            base64 = base64 ? base64 : (this.imgData ? this.imgData.split(',')[1] : '');

            filename = filename ? filename : 'CameraImage.png';


            let obj = new Object();
            obj.sobjectType = 'Document__c';
            obj.Document_Name__c = 'Receipt Acknowledge';
            // obj.Receipt_Acknowledgement__c =this.receiptAckRecordId.Id;

            InsertReceiptAcknowledgement({ base64: base64, filename: filename, docRec: obj, recieptRecord: receiptAcknowledgementRec, parentRecord: this.recordId, filesToInsert: this.uploadedFiles, wrapperString: JSON.stringify(this.parentRecord), noAllocation: this.doNotCreateAllocation })
                .then(result => {

                    this.receiptAckRecordId = result;
                    this.isLoading = true;
                    if (this.sendForAllocation) {
                        const acknowledgementId = this.receiptAckRecordId;
                        this.dispatchEvent(
                            new ShowToastEvent({
                                title: 'Success',
                                variant: 'success',
                                message: 'Receipt Acknowledgement has been Created.',
                            }),
                        );

                        this[NavigationMixin.Navigate]({
                            type: 'standard__recordPage',
                            attributes: {
                                recordId: this.receiptAckRecordId.Id,
                                objectApiName: 'ReceiptAcknowledgement__c',
                                actionName: 'view'
                            }
                        });

                    } else {
                        this.sendForAllocation = false;
                        this.dispatchEvent(
                            new ShowToastEvent({
                                title: 'Success',
                                variant: 'success',
                                message: 'Receipt Acknowledgement has been Created.',
                            }),
                        );

                        this[NavigationMixin.Navigate]({
                            type: 'standard__recordPage',
                            attributes: {
                                recordId: this.receiptAckRecordId.Id,
                                objectApiName: 'ReceiptAcknowledgement__c',
                                actionName: 'view'
                            }
                        });

                        setTimeout(() => {
                            this.isLoading = false;
                        }, 2000);
                        this.closeModal(false);
                    }


                })
                .catch(error => {
                    this.sendForAllocation = false;
                    this.showLoading = false;
                    let errorMessage = 'An unexpected error occurred. Please try again.';
                    console.log(JSON.stringify(error));
                    if (error?.body?.message) {
                        errorMessage = error.body.message;
                        if (errorMessage.includes('FIELD_CUSTOM_VALIDATION_EXCEPTION')) {
                            errorMessage = errorMessage
                                .split('FIELD_CUSTOM_VALIDATION_EXCEPTION,')[1]
                                .split(':')[0]
                                .trim();
                        }
                    }
                    else if (error?.body?.output?.errors?.length) {
                        errorMessage = error.body.output.errors[0].message;
                    }
                    else if (error?.body?.fieldErrors) {
                        const fieldErrors = Object.values(error.body.fieldErrors);
                        if (fieldErrors.length && fieldErrors[0].length) {
                            errorMessage = fieldErrors[0][0].message;
                        }
                    }
                    this.error = error;
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Error',
                            variant: 'error',
                            message: errorMessage
                        }),
                    );
                    this.disableSave = false;
                    if (this.paymentMode == 'Wire Transfer') {
                        this.disableAllocationButton = true;
                    }
                    else {
                        this.disableAllocationButton = false;
                    }
                });
        } catch (e) {
            console.log(e.message);
        }
    }


    navigateToReceiptAllocation(receiptAllocationId) {
        this[NavigationMixin.GenerateUrl]({
            type: 'standard__recordPage',
            attributes: {
                //apiName: 'ReceiptAcknowledgement__c',
                recordId: this.recId,
                objectApiName: 'ReceiptAcknowledgement__c',
                actionName: 'view',
            },
            //state: {
            //'c__rId': receiptAllocationId,
            //'c__isOpen': true
            //}
        }).then(url => {

            this.redirectionPageUrl = url;

        });
    }


    validateSalesOtherAllBeforeAllocateOutStanding() {
        let isValid = true;


        this.selectedSalesorderOther.forEach(item => {
            /*   console.log(typeof(item.allocateSalesOOtherAmountChange));
              console.log(Number(item.allocateSalesOOtherAmountChange));
              console.log(typeof(this.salesorderOOtherinfo.filter(val=>val.Id==item.Id)[0].PendingAmount__c));
              console.log(this.salesorderOOtherinfo.filter(val=>val.Id==item.Id)[0].PendingAmount__c);
       */
            if (Number(item.allocatedAmountSalesother) > this.salesorderOOtherinfo.filter(val => val.Id == item.Id)[0].PendingAmount__c) {
                isValid = false;
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error',
                        variant: 'error',
                        message: 'Pending Amount Can Not Be Less Then Zero.'
                    }),
                );

            }



            if (Number(item.allocatedAmountSalesother) > this.amount) {
                isValid = false;
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error',
                        variant: 'error',
                        message: 'Allocated amount should not be greater than applied amount.'
                    }),
                );

            }
            if (Number(item.allocatedAmountSalesother) === 0) {
                isValid = false;
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error',
                        variant: 'error',
                        message: 'Allocated Amound Should Not Be Zero.'
                    }),
                );

            }


        })

        this.selectedInstallments.forEach(item => {
            /*  console.log(item);
             console.log(typeof(item.allocatedAmount));
             console.log(item.allocatedAmount);
             console.log(typeof(this.installmentsInfo.filter(val=>val.Id==item.Id)[0].PendingAmount__c));
             console.log(this.installmentsInfo.filter(val=>val.Id==item.Id)[0].PendingAmount__c);
      */
            if (Number(item.allocatedAmount) > this.installmentsInfo.filter(val => val.Id == item.Id)[0].PendingAmount__c) {
                isValid = false;
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error',
                        variant: 'error',
                        message: 'Pending Amount Can Not Be Less Then Zero.'
                    }),
                );

            }

            if (Number(item.allocatedAmount) > this.amount) {
                isValid = false;
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error',
                        variant: 'error',
                        message: 'Allocated amount should not be greater than applied amount.'
                    }),
                );

            }
            if (Number(item.allocatedAmount) === 0) {
                isValid = false;
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error',
                        variant: 'error',
                        message: 'Allocated Amound Should Not Be Zero.'
                    }),
                );

            }



        })



        return isValid;
    }


    handleAllocateOUtStanding(event) {
        if ((this.selectedInstallments.length > 0 && this.selectedInstallments.length != '') || (this.selectedSalesorderOther.length > 0 && this.selectedSalesorderOther.length != '')) {
            console.log('selectedamount' + JSON.stringify(this.selectedInstallments));


            let recpAckObj = { 'sobjectType': 'ReceiptAcknowledgement__c' };
            recpAckObj.PaymentType__c = this.paymentMode;
            recpAckObj.Amount__c = this.amount;
            recpAckObj.SalesOrder__c = this.salesOrderId;
            recpAckObj.Opportunity__c = this.parentRecord.salesOrderRecord.Opportunity__c;
            recpAckObj.Account__c = this.parentRecord.salesOrderRecord.Account__c;
            recpAckObj.Remarks__c = this.remarks;
            recpAckObj.BankName__c = this.customerBankName;
            recpAckObj.CustomerBankAccount__c = this.customerBankNumber;
            recpAckObj.ReferenceNumber__c = this.referenceNumber;


            recpAckObj.Unit__c = this.parentRecord.salesOrderRecord.Unit__c;
            recpAckObj.Account_Name__c = this.parentRecord.salesOrderRecord.AccountName__c;

            if (this.paymentMode == 'Wire Transfer') {
                recpAckObj.Customer_Transfer_Reference__c = this.referenceNumber;
            }
            recpAckObj.MortgageCheque__c = this.mortgageCheque;
            recpAckObj.MaturityDate__c = this.maturityDate;
            recpAckObj.ReceiptPostingDate__c = this.postingDate;
            recpAckObj.HoldDate__c = this.holdDate;


            recpAckObj.CurrencyIsoCode = this.currencyISO;
            recpAckObj.IsCreatedFromLink__c = true;
            recpAckObj.RecievedFromAccount__c = this.payFromAccountId;
            recpAckObj.PaidBy__c = this.selectedPaidByLabel;
            recpAckObj.RecievedFromAccount__c = this.selectedPaidBy;
            recpAckObj.RemitterName__c = this.finalRemitterName;
            let updateInstallments = [];
            let updateSalesorderOOther = [];
            this.selectedInstallments.forEach(item => {
                let insObj = { 'sobjectType': 'InstallmentLines__c' };
                insObj.Id = item.Id;
                insObj.AmountReceived__c = item.allocatedAmount;
                insObj.PendingAmount__c = item.PendingAmount__c;
                updateInstallments.push(insObj);

            })
            this.salesorderOtherchargeRecord.forEach(item => {
                let sooObj = { 'sobjectType': 'SalesOrderOtherCharges__c' };
                sooObj.Id = item.Id;
                sooObj.AmountReceived__c = item.allocatedAmountSalesother;
                sooObj.PendingAmount__c = item.PendingAmount__c;
                updateSalesorderOOther.push(sooObj);

            })
            //  if(this.isTotalAllocatedAmountvalid==false && this.isNegativeAmount){

            // alert('updateSalesorderOOther'+updateSalesorderOOther);



            if (this.validateSalesOtherAllBeforeAllocateOutStanding()) {


                this.showLoading = true;
                insertAllocatedReceiptWthAmt({ updateInstallment: updateInstallments, recpAck: recpAckObj, updateSalesorderOOther: updateSalesorderOOther })
                    .then(result => {


                        this.dispatchEvent(
                            new ShowToastEvent({
                                title: 'Success',
                                message: 'ReceiptAcknowledgement Created Successfully',
                                variant: 'success'
                            }))
                        this.isLoading = false;
                        this.closeModal();

                    })
                    .catch(error => {
                        this.error = error;
                        this.isLoading = false;
                        this.dispatchEvent(
                            new ShowToastEvent({
                                title: 'Error',
                                message: error.body.message,
                                variant: 'error'
                            }))
                    })
            }
        }


        else {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: 'Please select atleast one installment to proceed.',
                    variant: 'error'
                }))
        }




    }

    closeModal(redirectToSO = false) {
        this.openModal = false;

        if (redirectToSO) {
            this.navigateToSOListView();
            setTimeout(() => {
                window.location.href = this.redirectionPageUrl;
            }, 300);
        }
    }


    //new file upload method
    @track fileData = { 'filename': '', 'base64': '' };
    @track fileName;
    @track hasFile = false;
    handleFileUploaded(event) {
        const file = event.target.files[0];
        if (!file) {
            alert("Please select a file.");
            return;
        }
        else {
            this.fileName = file.name;
            this.showCamperaUpload = false;
        }

        var reader = new FileReader()
        reader.onload = () => {
            var base64 = reader.result.split(',')[1]
            this.fileData.filename = file.name;
            this.fileData.base64 = base64;

            console.log(this.fileData)
        }
        reader.readAsDataURL(file)
    }


    onFileRemove(event) {
        let selfile = event.target.name;
        this.showCamperaUpload = true;

        this.fileData = [];
        this.fileName = null;
    }
    onCameraImageRemove(event) {
        this.showUploadfile = true;
        this.showOrPart = true;
        this.cameraImg = null;
        this.imageData = null;
    }

    handlePaidByChange(event) {
        this.selectedPaidBy = event.target.value;
        this.selectedPaidByLabel = this.accountList.find(option => option.value == this.selectedPaidBy).label;
    }



    capureViewHandler() {
        this.imageDocumentId = event.target.dataset.id;
        this.isModalOpen = true;
        setTimeout(() => {
            this.initCamera();
        }, 1000);

    }

    async initCamera() {

        if (navigator.mediaDevices && navigator.mediaDevices.getUserMedia) {
            try {
                this.template.querySelector('.videoElement').srcObject = await navigator.mediaDevices.getUserMedia({ video: true, audio: false });
            } catch (error) {
                console.error('Error accessing the camera: ', JSON.stringify(error));
            }
        } else {
            console.error('getUserMedia is not supported in this browser');
        }
    }

    captureImage() {
        let videoElement = this.template.querySelector('.videoElement');
        let canvasElement = this.template.querySelector('.canvas');
        if (videoElement && videoElement.srcObject !== null) {

            canvasElement.height = videoElement.videoHeight;
            canvasElement.width = videoElement.videoWidth;
            const context = canvasElement.getContext('2d');
            context.drawImage(videoElement, 0, 0, canvasElement.width, canvasElement.height);
            const imageData = canvasElement.toDataURL('image/png');
            this.imgData = imageData;

            const saveBtn = this.template.querySelector('.saveBtn');
            saveBtn.classList.remove('slds-hide');
            saveBtn.classList.add('slds-show');

            const imageElement = this.template.querySelector('.imageElement');
            imageElement.setAttribute('src', imageData);
            imageElement.classList.add('slds-show');
            imageElement.classList.remove('slds-hide');
            this.cameraImg = 'cameraImage.png';
            // console.log(this.imgData);
            this.showUploadfile = false;
            this.showOrPart = false;
        }
    }


    @api stopCamera() {
        const video = this.template.querySelector(".videoElement");
        video.srcObject.getTracks().forEach((track) => track.stop());
        video.srcObject = null;
        this.hideImageElement();
    }

    hideImageElement() {
        const imageElement = this.template.querySelector('.imageElement');
        imageElement.setAttribute('src', "");
        imageElement.classList.add('slds-hide');
        imageElement.classList.remove('slds-show');
    }

    handleCaputeOnSuccess(event) {

        this.isModalOpen = false;
    }
    closePopupWindow(event) {
        this.stopCamera();
        this.isModalOpen = false;
    }

}