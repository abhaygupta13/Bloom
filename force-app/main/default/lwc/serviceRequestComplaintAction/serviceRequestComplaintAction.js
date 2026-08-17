import { LightningElement, api, track, wire } from 'lwc';
import { CloseActionScreenEvent } from 'lightning/actions';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import CASE_OBJECT from "@salesforce/schema/Case";
import SERVICE_CATALOG_OBJECT from "@salesforce/schema/ServiceCatalog__c";
import { getPicklistValues } from 'lightning/uiObjectInfoApi';
import { NavigationMixin } from "lightning/navigation";
import TYPE_FIELD from '@salesforce/schema/ServiceCatalog__c.Type__c';
import CATEGORY_FIELD from '@salesforce/schema/ServiceCatalog__c.Category__c';
import SUB_CATEGORY_FIELD from '@salesforce/schema/ServiceCatalog__c.SubCategory__c';
import BROKER_CONTACT_ROLE_FIELD from '@salesforce/schema/Case.BrokerContactRole__c';
import { getRecordNotifyChange } from 'lightning/uiRecordApi';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import { encodeDefaultFieldValues } from "lightning/pageReferenceUtils";

import convertToRequestComplaint from '@salesforce/apex/ServiceRequestController.convertToRequestComplaint';
import getUnitsByAccount from '@salesforce/apex/UnitService.getUnitsByAccount';
import createCaseRecord from '@salesforce/apex/ServiceRequestController.createCaseRecord';


import TYPE_OF_ESTABLISHMENT_FIELD from '@salesforce/schema/Account.TypeofEstablishment__c';
import getRelatedUnits from '@salesforce/apex/ServiceRequestController.getRelatedUnits';
import validateEligibility from '@salesforce/apex/ServiceRequestController.validateEligibility';
import getContactsByAccount from '@salesforce/apex/ServiceRequestController.getContactsByAccount';
import getTypes from '@salesforce/apex/ServiceRequestController.getTypes';
import getCategories from '@salesforce/apex/ServiceRequestController.getCategories';
import getSubCategories from '@salesforce/apex/ServiceRequestController.getSubCategories';
import getOriginValues from '@salesforce/apex/ServiceRequestController.getOriginValues';
import getSubCategoriesforSubmit from '@salesforce/apex/ServiceRequestController.getSubCategoriesforSubmit';
import getRelatedAccount from '@salesforce/apex/ServiceRequestController.getRelatedAccount';
import getRelatedUnitsbyAccountId from '@salesforce/apex/ServiceRequestController.getRelatedUnitsbyAccountId';

const BROKER_SUB_TYPES = [
    'Broker Agent Details Update',
    'Broker Agency Details Update',
    'Broker New Agent Registration'
];

const REFRESH_SUB_TYPES = [
    'Broker Agent Details Update',
    'Broker Agency Details Update',
    'Broker New Agent Registration',
    'Delayed Commission Payment',
    'Incorrect Commission Amount',
    'Other Service Request'
];

const FIELDS = [TYPE_OF_ESTABLISHMENT_FIELD];

export default class ServiceRequestComplaint extends NavigationMixin(LightningElement) {

    isLoading = false;
    currentRecordId;
    picklistValuesObj;
    typeOptions;
    originOptions;
    categoryFieldData;
    categoryOptions;
    subCategoryFieldData;
    subCategoryOptions;
    unitOptions;
    selectedType;
    selectedOrigin;
    selectedCategory;
    selectedSubCategory;
    selectedAccount;
    selectedUnit;
    disabledCategory = true;
    disabledSubCategory = true;
    disabledAccount = true;
    disabledUnit = true;
    disableNextButton = true;
    isParentVisible = true;
    stopEmailsToCustomer = false;
    salesOrderId;
    result;
    @api requestFrom;
    @api objectApiName
    //  @api recordId;
    @track description = '';
    unitsByAccount;
    isTenantUnit = false;

    selectedBrokerContactRoles = [];
    selectedContact;
    contactOptions = [];
    brokerContactRoleOptions = [];

    get showBrokerFields() {
        return BROKER_SUB_TYPES.includes(this.selectedSubCategory);
    }

    get contactFilter() {
        if (!this.selectedAccount) {
            return null;
        }
        return {
            criteria: [
                {
                    fieldPath: 'AccountId',
                    operator: 'eq',
                    value: this.selectedAccount
                }
            ]
        };
    }

    @wire(getRecord, {
        recordId: '$selectedAccount',
        fields: FIELDS
    })
    accountRecord;

    get typeOfEstablishment() {
        return getFieldValue(
            this.accountRecord.data,
            TYPE_OF_ESTABLISHMENT_FIELD
        );
    }

    get isContactDisabled() {
        return !this.selectedAccount;
    }

    //check to show Next or Submit button
    get showNext() {
        return this.objectApiName != 'Case';
    }
    @api set recordId(value) {
        console.log('recordId received from Salesforce:', value);
        this._recordId = value;
        this.fetchRelatedUnits();

    }

    get recordId() {
        return this._recordId;
    }

    get showBrokerContactRole() {
        return this.selectedSubCategory === 'Broker New Agent Registration';
    }

    get showContact() {
        return this.selectedSubCategory === 'Broker Agent Details Update';
    }

    fetchRelatedUnits() {
        this.isLoading = true;
        getRelatedUnits({ recordId: this._recordId }).then(data => {
            this.isLoading = false;
            if (data) {
                console.log('testing this method');
                if (
                    this.objectApiName === 'SalesOrder__c' ||
                    this.objectApiName === 'Unit__c' ||
                    this.objectApiName === 'Account'
                ) {
                    this.result = data;

                    if (
                        this.objectApiName === 'SalesOrder__c' ||
                        this.objectApiName === 'Unit__c'
                    ) {
                        data.forEach(e => {
                            this.isTenantUnit = e.ActiveTenant__c != null ? true : false;

                            // Safely assign Sales Order ID
                            this.salesOrderId = e.Active_Sales_Order__c || null;

                            // Safely assign Account
                            if (
                                e.Active_Sales_Order__r &&
                                e.Active_Sales_Order__r.Account__c
                            ) {
                                this.selectedAccount = e.Active_Sales_Order__r.Account__c;
                                this.disabledAccount = true;
                            } else {
                                this.selectedAccount = null;
                                this.disabledAccount = false;

                            }
                        });
                    }

                    this.unitOptions = data.map(e => ({
                        label: e.Name,
                        value: e.Id
                    }));

                    if (!this.recordId.startsWith('001')) {
                        this.disabledUnit = true;
                        this.selectedUnit = this.unitOptions[0].value;

                    }

                    if (this.objectApiName === 'Account') {
                        this.selectedAccount = this.recordId;
                        this.fetchUnits(this.selectedAccount);
                    }
                } else if (this.objectApiName === 'Case') {
                    let caseRecord = data[0];
                    if (caseRecord) {
                        this.selectedAccount = caseRecord.AccountId;
                        this.disabledAccount = true;
                        this.fetchUnits(this.selectedAccount);
                    }
                }
            }
            else if (this.selectedAccount == null) {
                this.fetchRelatedAccount(this.recordId);
            }
            else if (error) {
                console.error('Error fetching record:', error);
            }
        })
    }
    fetchRelatedAccount() {
        this.isLoading = true;
        getRelatedAccount({ recordId: this.recordId }).then(data => {
            this.isLoading = false;
            if (data) {
                this.selectedAccount = data;
                this.fetchUnitsfromAccounts(this.selectedAccount);
            }
            else {
                this.selectedAccount = null;
            }
        })
    }

    @wire(getObjectInfo, { objectApiName: SERVICE_CATALOG_OBJECT })
    serviceCatalog;

    @wire(getObjectInfo, { objectApiName: CASE_OBJECT })
    caseObjectSchema;
    subCategoryPicklistData;

    @wire(getPicklistValues, {
        recordTypeId: '$serviceCatalog.data.defaultRecordTypeId',
        fieldApiName: SUB_CATEGORY_FIELD
    })
    wiredSubCategoryPicklist({ data, error }) {
        if (data) {
            this.subCategoryPicklistData = data;
            if (this.selectedCategory) {
                this.updateSubCategoryOptions();
            }
        } else if (error) {
            console.error('Error fetching Sub-Type picklist values:', error);
        }
    }

    @wire(getPicklistValues, {
        recordTypeId: '$caseObjectSchema.data.defaultRecordTypeId',
        fieldApiName: BROKER_CONTACT_ROLE_FIELD
    })
    wiredBrokerContactRolePicklist({ data, error }) {
        if (data) {
            this.brokerContactRoleOptions = data.values.map(item => ({
                label: item.label,
                value: item.value
            }));
        } else if (error) {
            console.error('Error fetching Broker Contact Role picklist values:', error);
        }
    }

    connectedCallback() {
        this.fetchTypes();
        this.fetchOrigins();
        console.log('Component loaded');
        console.log('recordId in connectedCallback:', this.recordId);
    }

    fetchTypes() {
        getTypes()
            .then(result => {
                this.typeOptions = Object.entries(result).map(([value, label]) => ({ label: label, value: value }));
            })
            .catch(error => {
                console.error('Error fetching types:', error);
            });
    }
    fetchOrigins() {
        getOriginValues()
            .then(result => {
                this.originOptions = Object.entries(result).filter(([value, label]) => value !== 'Portal' && label !== 'Portal').map(([value, label]) => ({ label: label, value: value }));
            })
            .catch(error => {
                console.error('Error fetching origin:', error);
            });
    }
    get sourceObject() {
        return this.objectApiName === 'Account' ? 'Account' :
            this.objectApiName === 'Unit__c' ? 'Unit' :
                this.objectApiName === 'SalesOrder__c' ? 'Sales Order' :
                    'Case';
    }

    fetchCategories() {
        if (this.selectedType) {
            getCategories({ type: this.selectedType, recordId: this.recordId })
                .then(result => {

                    const uniqueSortedCategories = [...new Set(result)]
                        .sort((a, b) => a.localeCompare(b));
                    this.categoryOptions = uniqueSortedCategories.map(val => ({ label: val, value: val }));
                })
                .catch(error => {
                    console.error('Error fetching categories:', error);
                });
        }
    }

    getPicklistSubCategoryOptions() {
        if (!this.subCategoryPicklistData || !this.selectedCategory) {
            return [];
        }

        const controllerKey = this.subCategoryPicklistData.controllerValues[this.selectedCategory];
        if (controllerKey === undefined) {
            return [];
        }

        return this.subCategoryPicklistData.values
            .filter(item => item.validFor.includes(controllerKey))
            .map(item => ({ label: item.label, value: item.value }))
            .sort((a, b) => {
                if (a.value === 'Other') return 1;
                if (b.value === 'Other') return -1;
                return a.label.localeCompare(b.label);
            });
    }

    updateSubCategoryOptions() {
        const picklistOptions = this.getPicklistSubCategoryOptions();

        if (!this.selectedType || !this.selectedCategory) {
            this.subCategoryOptions = [];
            return;
        }

        getSubCategories({
            type: this.selectedType,
            category: this.selectedCategory,
            recordId: this.recordId
        })
            .then(result => {
                const optionsMap = new Map();
                picklistOptions.forEach(opt => optionsMap.set(opt.value, opt));

                if (result && result.length > 0) {
                    result.forEach(val => {
                        if (!optionsMap.has(val)) {
                            optionsMap.set(val, { label: val, value: val });
                        }
                    });
                }

                this.subCategoryOptions = [...optionsMap.values()].sort((a, b) => {
                    if (a.value === 'Other') return 1;
                    if (b.value === 'Other') return -1;
                    return a.label.localeCompare(b.label);
                });
            })
            .catch(error => {
                console.error('Error fetching subcategories:', error);
                this.subCategoryOptions = picklistOptions;
            });
    }

    fetchSubCategories() {
        this.updateSubCategoryOptions();
    }

    resetBrokerFields() {
        this.selectedBrokerContactRoles = [];
        this.selectedContact = null;
    }

    onChangeBrokerContactRole(event) {
        this.selectedBrokerContactRoles = event.detail.value;
        this.applyBrokerFieldValidation();
    }

    areBrokerFieldsValid() {
        if (this.selectedSubCategory === 'Broker New Agent Registration') {
            return this.selectedBrokerContactRoles &&
                this.selectedBrokerContactRoles.length > 0;
        }

        if (this.selectedSubCategory === 'Broker Agent Details Update') {
            return !!this.selectedContact;
        }

        return true;
    }

    applyBrokerFieldValidation() {

        if (
            (this.showBrokerContactRole || this.showContact) &&
            !this.areBrokerFieldsValid()
        ) {
            this.disableNextButton = true;
            return;
        }

        if (
            this.showBrokerContactRole || this.showContact
        ) {
            this.disableNextButton = false;
        }
    }


    onChangeType(event) {
        this.selectedType = event.detail.value;
        this.disabledCategory = false;
        this.disabledSubCategory = true;
        this.disabledAccount = true;
        this.disabledUnit = true;
        this.disableNextButton = true;
        this.selectedCategory = '';
        this.selectedSubCategory = '';
        this.resetBrokerFields();
        this.fetchCategories();
    }

    onChangeCategory(event) {
        this.selectedCategory = event.detail.value;
        this.disabledSubCategory = false;
        this.disabledAccount = true;
        this.disabledUnit = true;
        this.disableNextButton = true;
        this.selectedSubCategory = '';
        this.subCategoryOptions = [];
        this.resetBrokerFields();
        this.fetchSubCategories();
    }

    onChangeSubCategory(event) {
        this.selectedSubCategory = event.detail.value;
        this.resetBrokerFields();
        if (this.showContact && this.selectedAccount) {
            this.fetchContactsByAccount(this.selectedAccount);
        }
        getSubCategoriesforSubmit({ subCategory: this.selectedSubCategory })
            .then(result => {
                if (result && result.length > 0) {

                    const enable = result[0];

                    this.isUnitRequired = enable.isUnitChangeRequired__c;
                    this.showUnitAfterAccount = enable.ShowUnitAfterAccount__c;

                    this.disableNextButton = !enable.isNextButtonSelectable__c;

                    if (this.showUnitAfterAccount) {
                        this.disabledUnit = this.selectedAccount ? false : true;
                    }

                    if (this.isUnitRequired) {
                        this.disableNextButton = this.selectedUnit ? false : true;
                    }

                }
                this.applyBrokerFieldValidation();
            });

        this.disabledAccount = this.selectedAccount == undefined ? false : true;

        if (this.selectedAccount && (this.objectApiName === 'Account' || this.objectApiName === 'Case')) {
            this.disabledUnit = false;
        }

        if (this.selectedSubCategory === 'BFM Service Request' || this.selectedSubCategory === 'Common Area Service Request') {

            this.disableNextButton = false;
        }

        this.applyBrokerFieldValidation();
    }

    onChangeContact(event) {
        this.selectedContact = event.detail.value;
        this.applyBrokerFieldValidation();

    }
    onChangeOrigin(event) {
        this.selectedOrigin = event.target.value;
    }

    onChangeAccount(event) {
        this.selectedAccount = event.detail.recordId;
        this.disabledUnit = false;
        if (this.selectedAccount) {
            this.fetchUnits(this.selectedAccount);
            if (this.showContact) {
                this.fetchContactsByAccount(this.selectedAccount);
            }
        } else {
            this.unitOptions = [];
            this.salesOrderId = null;
            this.selectedUnit = null;
            this.disabledUnit = true;
            if (((this.selectedSubCategory != 'BFM Service Request' && this.selectedSubCategory != 'Common Area Service Request') && this.objectApiName != 'Case') || (this.selectedSubCategory != 'General Enquiry')) {
                this.disableNextButton = true;
            }
        }
        this.applyBrokerFieldValidation();
    }

    onChangeUnit(event) {
        this.selectedUnit = event.detail.value;
        this.result.forEach(val => {
            if (val.Id == this.selectedUnit) {
                this.salesOrderId = val.Active_Sales_Order__c;
                this.isTenantUnit = val.ActiveTenant__c != null ? true : false;
            }
        })
        if (this.salesOrderId == null && this.result == null) {
            this.result11.forEach(val => {
                if (val.Unit__c == this.selectedUnit) {
                    this.salesOrderId = val.Id;
                }
            })
        }
        this.disableNextButton = false;
    }

    onChangeStopEmailsToCustomer(event) {
        this.stopEmailsToCustomer = event.target.checked;
    }

    onChangeDescription(event) {
        this.description = event.target.value;
    }

    async handleNext() {
        console.log('--->>>handle next--->>');
        try {
            this.isLoading = true;
            if (this.selectedOrigin == null) {
                this.showToast('Error', 'Origin is required', 'error');
                this.isLoading = false;
                return;
            }
            if (!this.areBrokerFieldsValid()) {
                this.showToast('Error', 'Please fill required broker fields', 'error');
                this.isLoading = false;
                return;
            }

            const message = await validateEligibility({
                recordId: this.salesOrderId,
                subCategory: this.selectedSubCategory,
                accountRecId: this.selectedAccount,
                unitId: this.selectedUnit,
                isTenantUnit: this.isTenantUnit
            });

            if (message) {
                this.showToast('Error', message, 'error');
                return;
            }

            const result = await createCaseRecord({
                recordId: this.objectApiName == 'CommonArea__c' && this.selectedSubCategory == 'Common Area Service Request' ? this._recordId : this.salesOrderId,
                selectedType: this.selectedType,
                selectedCategory: this.selectedCategory,
                selectedSubCategory: this.selectedSubCategory,
                accountId: this.selectedAccount,
                unitId: this.selectedUnit,
                description: this.description,
                origin: this.selectedOrigin,
                brokerContactRole: this.showBrokerContactRole
                    ? this.selectedBrokerContactRoles.join(';')
                    : null,
                contactId: this.showContact
                    ? this.selectedContact
                    : null,
                typeOfEstablishment: this.typeOfEstablishment,
                stopEmailsToCustomer : this.stopEmailsToCustomer
            });


            this.showToast(
                result.status === 'success' ? 'Success' : 'Error',
                result.message,
                result.status === 'success' ? 'success' : 'error'
            );

            /*  getRecordNotifyChange([{ recordId: result.caseId }]);
              if (result.status === 'success') {
  
                  this[NavigationMixin.Navigate]({
                      type: 'standard__recordPage',
                      attributes: {
                          recordId: result.caseId,
                          objectApiName: 'Case',
                          actionName: 'view'
                      }
                  });
              } */

            getRecordNotifyChange([{ recordId: result.caseId }]);

            if (result.status === 'success') {
                this.showToast('Success', result.message, 'success');
                const shouldRefreshAfterNavigate = REFRESH_SUB_TYPES.includes(this.selectedSubCategory);
                this[NavigationMixin.Navigate]({
                    type: 'standard__recordPage',
                    attributes: {
                        recordId: result.caseId,
                        objectApiName: 'Case',
                        actionName: 'view'
                    }
                });

                // Refresh Case page after navigation
                if (shouldRefreshAfterNavigate) {
                    setTimeout(() => {
                        window.location.reload();
                    }, 4000);

                    return;
                }
            }


        } catch (error) {
            console.error('Error creating case:', error);
            this.showToast('Error', error, 'error');
        } finally {
            this.isLoading = false;
            this.closeModal();
        }
    }

    //fetch units based on selected account
    fetchUnits(selectedAccount) {
        getUnitsByAccount({ accId: selectedAccount })
            .then((result) => {
                this.result = result;
                this.unitOptions = result.map(unit => ({
                    label: unit.Name,
                    value: unit.Id
                }));
            })
            .catch((error) => {
                console.error('Error  - fetching units--->>>', error);
                this.unitOptions = [];
            });
    }
    fetchUnitsfromAccounts(selectedAccount) {
        getRelatedUnitsbyAccountId({ recordId: selectedAccount })
            .then((result) => {
                this.result11 = result;
                this.unitOptions = result.map(unit => ({
                    label: unit.Unit__r.Name,
                    value: unit.Unit__c
                }));
                this.selectedUnit = this.unitOptions[0].value;

                this.result11.forEach(val => {
                    if (val.Unit__c == this.selectedUnit) {
                        this.salesOrderId = val.Id;

                    }
                })
            })
            .catch((error) => {
                console.error('Error  - fetching units--->>>', error);
                this.unitOptions = [];
            });
    }

    async handleSubmit() {
        console.log('--->>>handle submit--->>');
        try {

            this.isLoading = true;

            const message = await validateEligibility({ recordId: this.recordId, subCategory: this.selectedSubCategory, isTenantUnit: this.isTenantUnit });
            if (message && !((this.selectedAccount != null && this.selectedSubCategory === 'BFM Service Request') || (this.selectedSubCategory === 'Postpone/Defer payment' && this.selectedAccount != null && this.selectedUnit != null))) {
                this.showToast('Error', message, 'error');
            } else {
                const res = await convertToRequestComplaint({ selectedType: this.selectedType, selectedCategory: this.selectedCategory, selectedSubCategory: this.selectedSubCategory, selectedAccount: this.selectedAccount, selectedUnit: this.selectedUnit, recordID: this.recordId, description: this.description, origin: this.selectedOrigin })
                if (res && res.status == 'success') {
                    getRecordNotifyChange([{ recordId: this.recordId }]);
                    this.showToast('Success', res.message, 'success');
                } else {
                    this.showToast('Error', res.message, 'error');
                }
            }
        } catch (error) {
            console.error('Error updating record type:', error);
        } finally {
            this.closeModal();
            this.isLoading = false;
        }
    }

    fetchContactsByAccount(accountId) {
        this.contactOptions = [];
        this.selectedContact = null;

        if (!accountId) {
            return;
        }

        getContactsByAccount({ accountId: accountId })
            .then(result => {
                this.contactOptions = result.map(contact => ({
                    label: contact.Name,
                    value: contact.Id
                }));
            })
            .catch(error => {
                console.error('Error fetching contacts:', error);
                this.contactOptions = [];
            });
    }

    // Helper function to show toast notifications
    showToast(title, message, variant) {
        const evt = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant,
            mode: 'dismissable'
        });
        this.dispatchEvent(evt);
    }


    handleCancel() {
        this.closeModal();
    }
    closeModal() {
        this.dispatchEvent(new CloseActionScreenEvent());
        if (this.requestFrom === 'homePage') {
            this.dispatchEvent(new CustomEvent('closemodal'));
        }
    }
}