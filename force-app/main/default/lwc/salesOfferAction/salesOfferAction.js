import { LightningElement, track, api, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';
import { getObjectInfo, getPicklistValues } from 'lightning/uiObjectInfoApi';
import SALES_OFFER_OBJECT from '@salesforce/schema/OffersPromotions__c'; 
import DIRECT_TYPE_FIELD from '@salesforce/schema/OffersPromotions__c.Direct_Indirect__c';
import getProjects from '@salesforce/apex/SalesOfferController.getProjects';
import getUnitModelsByProjectId from '@salesforce/apex/SalesOfferController.getUnitModelsByProjectId';
import getUnits from '@salesforce/apex/SalesOfferController.getUnits';
import getPaymentPlans from '@salesforce/apex/SalesOfferController.getPaymentPlans';
import generateSalesOffer from '@salesforce/apex/SalesOfferController.generateSalesOffer';
import getOfferTypes from '@salesforce/apex/SalesOfferController.getOfferTypes';

export default class SalesOfferAction extends NavigationMixin(LightningElement) {
    isShowModal = false;
    showLoading = false;
    selectedProject;
    selectedUnitModel;
    selectedUnit;
    selectedDirectType;
    selectedOfferType;
    selectedPriceType;
    selectedCustomerType;
    firstName;
    lastName;
    email;
    remarks;
    @api autoOpen = false; 
    @track unitList = [];
    @track projectList = [];
    @track unitModelList = [];
    @track paymentPlanList = [];
    @track offerTypeList = [];
    @track selectedPaymentPlans = [];
    @track isUnitTab = true;
    @track isCustomerTab = false;
    @track isMobile = false;
    @track directTypeList = [];

    @wire(getObjectInfo, { objectApiName: SALES_OFFER_OBJECT })
    objectInfo;

    @wire(getPicklistValues, {
        recordTypeId: '$objectInfo.data.defaultRecordTypeId',
        fieldApiName: DIRECT_TYPE_FIELD
    })
    wiredDirectType({ data, error }) {
        if (data) {
            this.directTypeList = data.values.map(item => ({
                label: item.label,
                value: item.value
            }));
        } else if (error) {
            console.error('Error fetching Direct Type picklist:', error);
        }
}

    get priceTypeList() {
        return [
            { label: 'Standard Price', value: 'Standard Price' },
            { label: 'Premium Price', value: 'Premium Price' }
        ];
    }

    connectedCallback() {
        console.log('autoOpen flag => ', this.autoOpen);
        const ua = navigator.userAgent;
        this.isMobile = /sfdcapp/i.test(ua);
        if (this.autoOpen === true || this.autoOpen === 'true') {
            this.isShowModal = true;
        }
        this.doGetProjects(); 
    }

    get columnSize() {
        return this.isMobile ? '12' : '6';
    }

    get customerTypeList() {
        return [
            { label: 'CORPORATE', value: 'CORPORATE' },
            { label: 'STAFF', value: 'STAFF' },
            { label: 'BULK', value: 'BULK' },
            { label: 'NORMAL', value: 'NORMAL' },
            { label: 'BULK SPECIAL', value: 'BULK SPECIAL' },
            { label: 'CORPORATE ADIB', value: 'CORPORATE ADIB' }
        ];
    }

    get isOfferTypeDisabled() {
        return !this.selectedDirectType;
    }
    
    resetModal() {
        this.selectedProject = null;
        this.selectedUnitModel = null;
        this.selectedCustomerType = null;
        this.selectedUnit = null;
        this.selectedOfferType = null;
        this.selectedPriceType = null;
        this.selectedPaymentPlans = [];
        this.firstName = '';
        this.lastName = '';
        this.email = '';
        this.remarks = '';

        // reset tab flags
        this.isUnitTab = true;
        this.isCustomerTab = false;
    }

    handleOpenModal() {
        this.resetModal();
        this.isUnitTab = true;          
        this.isCustomerTab = false;
        this.doGetProjects();
        this.isShowModal = true;
    }

    handleCloseModal() {
         this.resetModal();              
        this.isUnitTab = true;
        this.isCustomerTab = false;
        this.isShowModal = false;
    }

    goToCustomerTab() {
        if (!this.selectedUnit || this.selectedPaymentPlans.length === 0 || !this.selectedPriceType) {
            this.showErrorMessage('Please select Unit, Payment Plan(s) and Price Type.');
            return;
        }
        this.isUnitTab = false;
        this.isCustomerTab = true;
    }

    goToUnitTab() {
        this.isUnitTab = true;
        this.isCustomerTab = false;
    }

    handleProjectOnChange(event) {
        this.selectedProject = event.target.value;
        this.selectedUnitModel = null;
        this.selectedUnit = null;
        this.selectedOfferType = null;
        this.selectedPriceType = null;
        this.selectedPaymentPlans = [];
        this.doGetUnitModelsByProjectId();
        this.doGetUnits();
        this.doGetOfferTypes();
        this.doGetPaymentPlans();
    }

    handleUnitModelOnChange(event) {
        this.selectedUnitModel = event.target.value;
        this.selectedUnit = null;
        this.selectedOfferType = null;
        this.selectedPriceType = null;
        this.selectedPaymentPlans = [];
        this.doGetUnits();
    }

    handleRadioSelect(event) {
        const selectedUnitId = event.target.dataset.id;
        this.unitList = this.unitList.map(unit => ({
            ...unit,
            isSelected: unit.Id === selectedUnitId
        }));
        this.selectedUnit = selectedUnitId;
        console.log('this.selectedUnit'+this.selectedUnit);
    }

    handleUnitOnChange(event) {
        this.selectedUnit = event.target.value;
        this.selectedOfferType = null;
        this.selectedPriceType = null;
        this.selectedPaymentPlans = [];
    }

    handleCustomerTypeOnChange(event) {
        this.selectedCustomerType = event.target.value;
        this.selectedOfferType = null;
        this.selectedPaymentPlans = [];
        this.doGetPaymentPlans();
        this.doGetOfferTypes();
    }

    handlePaymentPlanSelect(event) {
        const selectedValue = event.target.value;
        if (!selectedValue) return;

        let exists = this.selectedPaymentPlans.find(p => p.value === selectedValue);
        if (exists) {
            this.showErrorMessage('This payment plan is already added.');
            event.target.value = null;
            return;
        }

        let planLabel = this.paymentPlanList.find(p => p.value === selectedValue)?.label;

        this.selectedPaymentPlans = [
            ...this.selectedPaymentPlans,
            { value: selectedValue, label: planLabel }
        ];

        event.target.value = null;
    }

    handleRemovePaymentPlan(event) {
        const planId = event.detail.name;
        this.selectedPaymentPlans = this.selectedPaymentPlans.filter(p => p.value !== planId);
    }

    handleDirectTypeOnChange(event) {
        this.selectedDirectType = event.target.value;

        // reset dependent fields
        this.selectedOfferType = null;

        // reload offer types based on selection
        //this.doGetOfferTypes();
    }

    handleOfferTypeOnChange(event) {
        this.selectedOfferType = event.target.value;
    }

    handlePriceOnChange(event) {
        this.selectedPriceType = event.target.value;
    }

    handleFirstNameChange(event) {
        this.firstName = event.target.value;
    }

    handleLastNameChange(event) {
        this.lastName = event.target.value;
    }

    handleEmailChange(event) {
        this.email = event.target.value;
    }

    handleRemarksChange(event) {
        this.remarks = event.target.value;
    }

    doGetProjects() {
        this.showLoading = true;
        getProjects({})
            .then(result => {
                this.showLoading = false;
                if (result) {
                    this.projectList = result.map(r => ({ value: r.Id, label: r.Name }));
                }
            })
            .catch(() => { this.showLoading = false; });
    }

    doGetUnitModelsByProjectId() {
        this.showLoading = true;
        this.unitModelList = [];
        getUnitModelsByProjectId({ projectId: this.selectedProject })
            .then(result => {
                this.showLoading = false;
                if (result) {
                    let options = [{ value: 'All', label: 'All' }];
                    options = [...options, ...result.map(r => ({ value: r, label: r }))];
                    this.unitModelList = options;
                }
            })
            .catch(() => { this.showLoading = false; });
    }

    doGetUnits() {
        this.unitList = [];
        this.showLoading = true;

        getUnits({ projectId: this.selectedProject, unitModel: this.selectedUnitModel, directType: this.selectedDirectType })
            .then(result => {
                this.showLoading = false;
                if (result) {
                    // Keep all fields from Apex, and add `isSelected` for the radio
                    this.unitList = result.map(r => ({
                        ...r,
                        isSelected: false
                    }));
                }
            })
            .catch(error => {
                this.showLoading = false;
                console.error('Error fetching units:', error);
            });
    }

    doGetPaymentPlans() {
        this.paymentPlanList = [];
        this.showLoading = true;
        getPaymentPlans({ projectId: this.selectedProject, customerType: this.selectedCustomerType })
            .then(result => {
                this.showLoading = false;
                if (result) {
                    this.paymentPlanList = result.map(r => ({ value: r.Id, label: r.Name }));
                }
            })
            .catch(() => { this.showLoading = false; });
    }

    doGetOfferTypes() {
        this.offerTypeList = [];
        this.showLoading = true;
        getOfferTypes({ projectId: this.selectedProject, customerType: this.selectedCustomerType, directType: this.selectedDirectType })
            .then(result => {
                this.showLoading = false;
                if (result) {
                    this.offerTypeList = result.map(r => ({ value: r.Id, label: r.Name }));
                }
            })
            .catch(() => { this.showLoading = false; });
    }

    handleGenerateSalesOffer() {
        /*if (!this.firstName || !this.lastName || !this.email) {
            this.showErrorMessage('Please enter customer details.');
            return;
        }*/

        if (!this.selectedUnit || this.selectedPaymentPlans.length === 0 || !this.selectedPriceType) {
            this.showErrorMessage('Please select Unit, Payment Plan(s) and Price Type.');
            return;
        }

        const unitData = {
            unitId: this.selectedUnit,
            paymentPlanIds: this.selectedPaymentPlans.map(p => p.value),
            offerTypeId: this.selectedOfferType,
            priceType: this.selectedPriceType
        };

        this.showLoading = true;
        generateSalesOffer({
            projectId: this.selectedProject,
            selectedUnit: unitData,
            firstName: this.firstName,
            lastName: this.lastName,
            email: this.email,
            remarks: this.remarks,
            customerType: this.selectedCustomerType
        })
            .then(result => {
                this.showLoading = false;
                if (result) {
                    this.navigateToSORecord(result);
                }
            })
            .catch(error => {
                this.showLoading = false;
                let message;
                if (Array.isArray(error.body)) {
                    message = error.body.map(e => e.message).join(', ');
                } else if (typeof error.body.message === 'string') {
                    message = error.body.message;
                }
                this.showErrorMessage(JSON.stringify(message));
            });
    }

    showErrorMessage(msg) {
        this.dispatchEvent(
            new ShowToastEvent({
                title: 'Error',
                message: msg,
                variant: 'error',
                mode: 'dismissable'
            })
        );
    }

    showSuccessMessage(msg) {
        this.dispatchEvent(
            new ShowToastEvent({
                title: 'Success',
                message: msg,
                variant: 'success',
                mode: 'dismissable'
            })
        );
    }

    navigateToSORecord(recordId) {
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: recordId,
                actionName: 'view'
            }
        });
    }
}