import { LightningElement, api, wire, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

import getRelatedAccount from '@salesforce/apex/ServiceRequestController.getRelatedAccount';
import getRelatedUnits from '@salesforce/apex/ServiceRequestController.getRelatedUnits';
import getTypes from '@salesforce/apex/ServiceRequestController.getTypes';
import getCategories from '@salesforce/apex/ServiceRequestController.getCategories';
import getSubCategories from '@salesforce/apex/ServiceRequestController.getSubCategories';
import getOriginValues from '@salesforce/apex/ServiceRequestController.getOriginValues';
import validateEligibility from '@salesforce/apex/ServiceRequestController.validateEligibility';
import createCaseRecord from '@salesforce/apex/ServiceRequestController.createCaseRecord';

export default class ServiceRequestCreation extends NavigationMixin(LightningElement) {
    @api recordId;
    @api objectApiName;

    @track accountId;
    @track selectedType = '';
    @track selectedCategory = '';
    @track selectedSubCategory = '';
    @track selectedUnit = '';
    @track selectedOrigin = '';
    @track description = '';
    
    @track typeOptions = [];
    @track categoryOptions = [];
    @track subCategoryOptions = [];
    @track unitOptions = [];
    @track originOptions = [];
    
    @track isLoading = false;
    @track errorMessage = '';
    @track eligibilityMessage = '';
    @track isTenantUnit = false;

    // Getters for conditional rendering
    get isCategoryDisabled() {
        return !this.selectedType;
    }

    get isSubCategoryDisabled() {
        return !this.selectedCategory;
    }

    // Load type options, origin options and related account/units on initialization
    connectedCallback() {
        this.isLoading = true;
        this.loadInitialData();
    }

    async loadInitialData() {
        try {
            // Get picklist values for Types
            const typesResult = await getTypes();
            this.typeOptions = Object.keys(typesResult).map(key => ({
                label: key,
                value: typesResult[key]
            }));

            // Get picklist values for Origin
            const originResult = await getOriginValues();
            this.originOptions = Object.keys(originResult).map(key => ({
                label: key,
                value: originResult[key]
            }));

            if (this.recordId) {
                // Get related Account
                this.accountId = await getRelatedAccount({ recordId: this.recordId });

                // Get related Units for dropdown selection
                const unitsResult = await getRelatedUnits({ recordId: this.recordId });
                if (unitsResult) {
                    this.unitOptions = unitsResult.map(unit => {
                        return {
                            label: unit.Name + (unit.Active_Sales_Order__r ? ' (Sales Order: ' + unit.Active_Sales_Order__r.Name + ')' : ''),
                            value: unit.Id,
                            salesOrderId: unit.Active_Sales_Order__c,
                            activeTenantId: unit.ActiveTenant__c
                        };
                    });
                }
            }
        } catch (error) {
            console.error('Error loading initial data: ', error);
            this.showToast('Error', 'Failed to initialize case creation data: ' + (error.body ? error.body.message : error.message), 'error');
        } finally {
            this.isLoading = false;
        }
    }

    // Handle selection changes
    async handleTypeChange(event) {
        this.selectedType = event.detail.value;
        this.selectedCategory = '';
        this.selectedSubCategory = '';
        this.categoryOptions = [];
        this.subCategoryOptions = [];
        this.eligibilityMessage = '';

        if (this.selectedType) {
            this.isLoading = true;
            try {
                const categoriesResult = await getCategories({ type: this.selectedType, recordId: this.recordId });
                this.categoryOptions = categoriesResult.map(cat => ({ label: cat, value: cat }));
            } catch (error) {
                console.error('Error loading categories: ', error);
                this.showToast('Error', 'Error loading categories: ' + (error.body ? error.body.message : error.message), 'error');
            } finally {
                this.isLoading = false;
            }
        }
    }

    async handleCategoryChange(event) {
        this.selectedCategory = event.detail.value;
        this.selectedSubCategory = '';
        this.subCategoryOptions = [];
        this.eligibilityMessage = '';

        if (this.selectedCategory) {
            this.isLoading = true;
            try {
                const subCategoriesResult = await getSubCategories({
                    type: this.selectedType,
                    category: this.selectedCategory,
                    recordId: this.recordId
                });
                this.subCategoryOptions = subCategoriesResult.map(sub => ({ label: sub, value: sub }));
            } catch (error) {
                console.error('Error loading subcategories: ', error);
                this.showToast('Error', 'Error loading subcategories: ' + (error.body ? error.body.message : error.message), 'error');
            } finally {
                this.isLoading = false;
            }
        }
    }

    handleSubCategoryChange(event) {
        this.selectedSubCategory = event.detail.value;
        this.checkEligibility();
    }

    handleUnitChange(event) {
        this.selectedUnit = event.detail.value;
        
        // Find if selected unit is tenant unit
        const selectedUnitOpt = this.unitOptions.find(opt => opt.value === this.selectedUnit);
        if (selectedUnitOpt && selectedUnitOpt.activeTenantId && this.accountId && selectedUnitOpt.activeTenantId === this.accountId) {
            this.isTenantUnit = true;
        } else {
            this.isTenantUnit = false;
        }

        this.checkEligibility();
    }

    handleOriginChange(event) {
        this.selectedOrigin = event.detail.value;
    }

    handleDescriptionChange(event) {
        this.description = event.detail.value;
    }

    // Check case creation eligibility
    async checkEligibility() {
        if (this.selectedSubCategory) {
            this.isLoading = true;
            this.eligibilityMessage = '';
            try {
                const msg = await validateEligibility({
                    recordId: this.recordId,
                    subCategory: this.selectedSubCategory,
                    accountRecId: this.accountId,
                    unitId: this.selectedUnit || null,
                    isTenantUnit: this.isTenantUnit
                });
                
                if (msg) {
                    this.eligibilityMessage = msg;
                }
            } catch (error) {
                console.error('Error checking eligibility: ', error);
                this.showToast('Warning', 'Eligibility validation failed: ' + (error.body ? error.body.message : error.message), 'warning');
            } finally {
                this.isLoading = false;
            }
        }
    }

    // Create Case
    async handleCreate() {
        // Validation checks
        if (!this.selectedType || !this.selectedCategory || !this.selectedSubCategory || !this.selectedOrigin) {
            this.showToast('Validation Error', 'Please complete all required fields.', 'error');
            return;
        }

        if (this.eligibilityMessage) {
            this.showToast('Error', 'Cannot create case: ' + this.eligibilityMessage, 'error');
            return;
        }

        this.isLoading = true;
        try {
            const result = await createCaseRecord({
                recordId: this.recordId,
                selectedType: this.selectedType,
                selectedCategory: this.selectedCategory,
                selectedSubCategory: this.selectedSubCategory,
                accountId: this.accountId,
                unitId: this.selectedUnit || null,
                description: this.description,
                origin: this.selectedOrigin
            });

            if (result && result.status === 'success') {
                this.showToast('Success', 'Service Request Case created successfully!', 'success');
                
                // Navigate to the newly created Case record
                this[NavigationMixin.Navigate]({
                    type: 'standard__recordPage',
                    attributes: {
                        recordId: result.caseId,
                        objectApiName: 'Case',
                        actionName: 'view'
                    }
                });
            } else {
                this.showToast('Error', result.message || 'Failed to create case record.', 'error');
            }
        } catch (error) {
            console.error('Error creating case: ', error);
            this.showToast('Error', 'Failed to create case: ' + (error.body ? error.body.message : error.message), 'error');
        } finally {
            this.isLoading = false;
        }
    }

    handleCancel() {
        // Go back to the record page
        if (this.recordId) {
            this[NavigationMixin.Navigate]({
                type: 'standard__recordPage',
                attributes: {
                    recordId: this.recordId,
                    actionName: 'view'
                }
            });
        } else {
            // Or home page
            this[NavigationMixin.Navigate]({
                type: 'standard__objectPage',
                attributes: {
                    objectApiName: 'Case',
                    actionName: 'list'
                },
                state: {
                    filterName: 'Recent'
                }
            });
        }
    }

    showToast(title, message, variant) {
        this.dispatchEvent(
            new ShowToastEvent({
                title: title,
                message: message,
                variant: variant
            })
        );
    }
}