import { LightningElement, track, api, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';
import InsertReceiptAcknowledgement from "@salesforce/apex/ReceiptAcknowledgementHandler.insertReceiptAcknowledgement";
import fetcholdReceiptRecord from "@salesforce/apex/ReceiptAcknowledgementHandler.getDetailOfReceiptAcknowledgement";
import getAllAccountsMap from '@salesforce/apex/ReceiptAcknowledgementHandler.getBankDetails';
import getRemitterNames from '@salesforce/apex/ReceiptAcknowledgementHandler.getRemitterNames';
import fetchUserProfileName from "@salesforce/apex/ReceiptAcknowledgementHandler.fetchUserProfileName";
import getPicklistvalue from "@salesforce/apex/Utilities.getPicklistValues";
import PaymentModeLabel from '@salesforce/label/c.PaymentModes';
import LightningConfirm from 'lightning/confirm';
import { loadStyle } from 'lightning/platformResourceLoader';
import fileUploadCustomCss from '@salesforce/resourceUrl/fileUploadCustomCss'; 

export default class ReceiptAcknowledgementSalesOrder extends NavigationMixin(LightningElement) {

    @api recordId;
    @track openModal = true;
    @track paymentModes = [];
    @track paymentMode = 'Cheque';
    @track amount;
    @track updatedAmount;
    @track referenceNumber = '';
    @track customerBankName = '';
    @track customerBankNumber = '';
    @track remarks = '';
    @track maturityDate = '';
    @track postingDate = '';
    @track holdDate = '';
    @track currency;
    @track currencyISO = 'AED';
    @track bankAccounts = [];
    @track remitterOptions = [];
    @track selectedRemitter;
    @track otherRemitterName;
    @track showOtherRemitter = false;
    @track uploadedFiles = [];
    @track bankAccount;
    @track disableSave = true;
    @track showLoading = false;
    @track profileName;
    @track accountId;
    @track accountName;
    @track unit;

    @track fileData = { filename: '', base64: '' };
    @track fileName;
    @track imgData;
    @track allocateTo = 'Installment';
    @track sapSpecialGLIndicator = 'X';

    cssLoaded = false;
    remitterLoaded = false;

    // ---- SINGLE connectedCallback ----
    connectedCallback() {
        if (PaymentModeLabel) {
            this.paymentModes = PaymentModeLabel.split(';').map(item => ({
                label: item,
                value: item
            }));
        }

        fetchUserProfileName()
            .then(res => this.profileName = res)
            .catch(() => {});
    }

    // ---- SINGLE renderedCallback ----
    renderedCallback() {
        if (!this.cssLoaded) {
            this.cssLoaded = true;
            loadStyle(this, fileUploadCustomCss)
                .then(() => {
                    console.log('Styles loaded successfully');
                })
                .catch(error => {
                    console.error('Error loading styles', error);
                });
        }

        if (!this.remitterLoaded && this.accountId) {
            this.remitterLoaded = true;
            this.fetchRemitterNames();
        }
    }

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
        } else if (error) {
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
        } else if (error) {
            this.error = error;
        }
    }

    @wire(getAllAccountsMap, { recordId: '$recordId' })
    wiredAccounts({ data, error }) {
        if (data) {
            this.bankAccounts = Object.entries(data).map(([key, value]) => ({
                label: value,
                value: key
            }));
        }
    }

    @wire(fetcholdReceiptRecord, { recordId: '$recordId' })
    wiredParent({ data, error }) {
        if (data) {
            this.accountId = data.salesOrderRecord.Account__c;
            this.opportunityId = data.salesOrderRecord.Opportunity__c;
            this.accountName = data.salesOrderRecord.AccountName__c;
            this.unit = data.salesOrderRecord.Unit__c;
        }
    }

    get allocateToOptions() {
        return [
            { label: 'Installment', value: 'Installment' },
            { label: 'Other Charges', value: 'Other Charges' }
        ];
    }

    handleAllocateToChange(event) {
        this.allocateTo = event.detail.value;
        if (this.allocateTo === 'Installment') {
            this.sapSpecialGLIndicator = 'X';
        } else {
            this.sapSpecialGLIndicator = '';
        }
        this.validateInputs();
    }

    handleBankAccountChange(event) {
        this.bankAccount = event.detail.value;
        this.validateInputs();
    }

    // ---- SINGLE fetchRemitterNames ----
    fetchRemitterNames() {
        getRemitterNames({ accountId: this.accountId })
            .then(data => {
                if (!data || data.length === 0) {
                    this.remitterOptions = [{ label: 'Other', value: 'Other' }];
                    this.selectedRemitter = 'Other';
                    this.showOtherRemitter = true;
                    return;
                }
                let options = data.map(name => ({ label: name, value: name }));
                options.push({ label: 'Other', value: 'Other' });
                this.remitterOptions = options;

                if (!this.selectedRemitter && options.length) {
                    this.selectedRemitter = options[0].value;
                }
            })
            .catch(error => {
                console.error('Error fetching remitter names', error);
            });
    }

    // ---- SINGLE handleRemitterChange ----
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

    handleChangeCustomerBankName(event) {
        this.customerBankName = event.detail.value;
        this.validateInputs();
    }

    handleChangeCurrency(event) {
        this.currencyISO = event.detail.value;
    }

    handleChange(event) {
        const field = event.target.dataset.name;
        let value = event.target.value;

        if (field === 'amount') {
            value = value ? Number(value) : null;
            this.updatedAmount = value;
        }

        this[field] = value;
        this.validateInputs();
    }

    handleChangePaymentMode(event) {
        this.paymentMode = event.detail.value;
        this.validateInputs();
    }

    // ---- SINGLE get finalRemitterName ----
    get finalRemitterName() {
        return this.selectedRemitter === 'Other' ? this.otherRemitterName : this.selectedRemitter;
    }

    validateInputs() {
        const isEmpty = (val) => val === null || val === undefined || val === '';
        const remitterInvalid = this.showOtherRemitter && isEmpty(this.otherRemitterName);

        let requiredFields = [
            this.paymentMode,
            this.amount,
            this.referenceNumber,
            this.bankAccount,
            this.postingDate
        ];

        if (this.paymentMode === 'Cheque') {
            requiredFields.push(this.customerBankName, this.maturityDate);
        }

        const hasEmptyField = requiredFields.some(field => isEmpty(field));
        this.disableSave = hasEmptyField || remitterInvalid;

        if (this.referenceNumber && this.referenceNumber.length < 6) {
            this.disableSave = true;
        }
    }

    handleFileUploaded(event) {
        const file = event.target.files[0];
        if (!file) return;
        this.fileName = file.name;
        const reader = new FileReader();
        reader.onload = () => {
            this.fileData = {
                filename: file.name,
                base64: reader.result.split(',')[1]
            };
        };
        reader.readAsDataURL(file);
    }

    async handleSave() {
        this.showLoading = true;
        try {
            const posting = new Date(this.postingDate);
            const maturity = new Date(this.maturityDate);

            if (posting < maturity) {
                const confirm = await LightningConfirm.open({
                    message: 'Posting Date is earlier than Maturity Date. Do you want to continue?',
                    label: 'Confirmation Required',
                    variant: 'header',
                    theme: 'warning'
                });
                if (!confirm) {
                    this.showLoading = false;
                    return;
                }
            }

            let receipt = {
                sobjectType: 'ReceiptAcknowledgement__c',
                PaymentType__c: this.paymentMode,
                Opportunity__c: this.opportunityId || null,
                Account__c: this.accountId || null,
                Amount__c: this.updatedAmount || this.amount,
                SalesOrder__c: this.recordId,
                Remarks__c: this.remarks,
                BankName__c: this.customerBankName,
                CustomerBankAccount__c: this.customerBankNumber,
                ReferenceNumber__c: this.referenceNumber,
                CurrencyIsoCode: this.currencyISO,
                ReceiptPostingDate__c: this.postingDate,
                MaturityDate__c: this.maturityDate,
                HoldDate__c: this.holdDate,
                Bank_Account__c: this.bankAccount || null,
                RemitterName__c: this.finalRemitterName,
                SAP_Special_GL_Indicator__c: this.sapSpecialGLIndicator,
                IsCreatedFromLink__c: true,
                Unit__c : this.unit || null,
                Account_Name__c : this.accountName
            };

            console.log('RECEIPT =>', JSON.stringify(receipt));
            Object.keys(receipt).forEach(key => {
                if (receipt[key] === undefined || receipt[key] === '') {
                    delete receipt[key];
                }
            });
            console.log('FINAL RECEIPT =>', JSON.stringify(receipt));
            let { base64, filename } = this.fileData;
            base64 = base64 || (this.imgData ? this.imgData.split(',')[1] : '');
            filename = filename || 'Receipt.png';

            let doc = {
                sobjectType: 'Document__c',
                Document_Name__c: 'Receipt'
            };

            const result = await InsertReceiptAcknowledgement({
                base64,
                filename,
                docRec: doc,
                recieptRecord: receipt,
                parentRecord: this.recordId,
                filesToInsert: this.uploadedFiles,
                wrapperString: '',
                noAllocation: true
            });

            const receiptId = result.Id;

            this.dispatchEvent(new ShowToastEvent({
                title: 'Success',
                message: 'Receipt created successfully',
                variant: 'success'
            }));

            this.closeModal();

            this[NavigationMixin.Navigate]({
                type: 'standard__recordPage',
                attributes: {
                    recordId: receiptId,
                    objectApiName: 'ReceiptAcknowledgement__c',
                    actionName: 'view'
                }
            });

        } catch (error) {
            this.showLoading = false;
            this.dispatchEvent(new ShowToastEvent({
                title: 'Error',
                message: error?.body?.message || 'Error occurred',
                variant: 'error'
            }));
        }
    }

    closeModal() {
        this.openModal = false;
        this.dispatchEvent(new CustomEvent('close'));

        // Force close the Quick Action wrapper
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: this.recordId,
                actionName: 'view'
            }
        });
    }
}