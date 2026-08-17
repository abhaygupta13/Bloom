import { LightningElement, api, track, wire } from 'lwc';
import getProjectClassifications from '@salesforce/apex/ProjectController.getProjectClassifications';
import getPaymentPlans from '@salesforce/apex/ProjectController.getPaymentPlans';
import getActiveSalesOrderCount from '@salesforce/apex/ProjectController.getActiveSalesOrderCount';
import getInstallmentsByPlan from '@salesforce/apex/ProjectController.getInstallmentsByPlan';
import isPaymentPlanPendingApproval from '@salesforce/apex/ProjectController.isPaymentPlanPendingApproval';
import updateInstallments from '@salesforce/apex/ProjectController.updateInstallmentLineRecords';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import modal from "@salesforce/resourceUrl/custommodalcss";
import { CloseActionScreenEvent } from "lightning/actions";
import { loadStyle } from "lightning/platformResourceLoader";
import { getObjectInfo, getPicklistValues } from 'lightning/uiObjectInfoApi';
import PAYMENT_PLAN_OBJECT from '@salesforce/schema/PaymentPlan__c';
import CLASSIFICATION_FIELD from '@salesforce/schema/PaymentPlan__c.Classification__c';
import { NavigationMixin } from 'lightning/navigation';

export default class ProjectPaymentplanAction extends NavigationMixin(LightningElement) {
    // @api recordId;
    isModalOpen = true;
    isLoading = false;
    classificationOptions = [];
    paymentPlanOptions = [];
    selectedClassification;
    selectedPaymentPlan;
    selectedPaymentPlanCreatedDate = '';
    recordTypeId;
    lstInstallmentLine = [];
    noOfActiveSalesOrder = 0;

    connectedCallback() {
        loadStyle(this, modal);
    }

    _recordId;

    @api
    set recordId(value) {

        this._recordId = value;

        if (value) {
            this.loadClassifications();
        }
    }

    get recordId() {
        return this._recordId;
    }

    @wire(getObjectInfo, { objectApiName: PAYMENT_PLAN_OBJECT })
    objectInfo({ data, error }) {
        if (data) {
            this.recordTypeId = data.defaultRecordTypeId;
        }
    }

    loadClassifications() {

        getProjectClassifications({
            projectId: this.recordId
        })
            .then(result => {
                this.classificationOptions =
                    result.map(item => ({
                        label: item,
                        value: item
                    }));
            })
            .catch(error => {
                console.error(error);
                this.showToast(
                    'Error',
                    'Failed to load classifications',
                    'error'
                );
            });
    }

    get hasInstallments() {
        return this.lstInstallmentLine && this.lstInstallmentLine.length > 0;
    }

    get isPaymentPlanDisabled() {
        return !this.selectedClassification;
    }

    get isNextDisabled() {
        return !this.selectedClassification || !this.selectedPaymentPlan;
    }

    get showSalesOrder() {
        return !!this.selectedPaymentPlan;
    }

    getActiveSalesOrderCount() {
        getActiveSalesOrderCount({
            paymentPlanId: this.selectedPaymentPlan
        })
            .then(result => {
                this.noOfActiveSalesOrder = result;
            })
            .catch(error => {
                console.error('Error fetching active Sales Order count', error);
                this.noOfActiveSalesOrder = 0;
            });
    }

    handleNext() {

        

        this.showUpdateScreen = false;

        this.showDocumentScreen = true;
    }

    handleBack() {

        this.showUpdateScreen = true;

        this.showDocumentScreen = false;
    }

    handleClassificationChange(event) {
        this.selectedClassification = event.detail.value;
        this.selectedPaymentPlan = null;
        this.noOfActiveSalesOrder = 0;
        this.selectedPaymentPlanCreatedDate = '';
        this.paymentPlanOptions = [];
        this.lstInstallmentLine = [];
        this.isLoading = true;
        getPaymentPlans({
            projectId: this.recordId,
            classification: this.selectedClassification
        })
            .then(result => {
                const data = Array.isArray(result) ? result : [];
                this.paymentPlanOptions = data.map(plan => ({
                    label: plan.Name,
                    value: plan.Id,
                    createdDate: plan.CreatedDate
                }));
                this.isLoading = false;
            })
            .catch(error => {
                console.error(error);
                this.showToast(
                    'Error',
                    'Failed to fetch payment plans',
                    'error'
                );
                this.isLoading = false;
            });
    }

    get formattedPaymentPlanCreatedDate() {
        if (!this.selectedPaymentPlanCreatedDate) {
            return '';
        }

        return this.formatDate(this.selectedPaymentPlanCreatedDate);
    }

    get showCreatedDate() {
        return !!this.selectedPaymentPlan;
    }

    handlePaymentPlanChange(event) {
        this.selectedPaymentPlan = event.detail.value;
        const selectedPlan = this.paymentPlanOptions.find(
            plan => plan.value === this.selectedPaymentPlan
        );

        this.selectedPaymentPlanCreatedDate = selectedPlan?.createdDate || '';
        this.getActiveSalesOrderCount();
        this.isLoading = true;
        getInstallmentsByPlan({
            paymentPlanId: this.selectedPaymentPlan
        })
            .then(result => {
                const data = Array.isArray(result) ? result : [];
                this.lstInstallmentLine =
                    data.map(rec => {
                        const today = new Date();
                        today.setHours(0, 0, 0, 0);
                        const installmentDate = rec.InstallmentDate__c ? new Date(rec.InstallmentDate__c) : null;
                        const revisedDate = rec.RevisedDate__c ? new Date(rec.RevisedDate__c) : null;
                        const dueDate = rec.DueDate__c ? new Date(rec.DueDate__c) : null;
                        const isReadOnly = dueDate && dueDate < today;

                        return {
                            Id: rec.Id,
                            Name: rec.Name,
                            Description__c: rec.Description__c,
                            InstallmentNumber__c: rec.InstallmentNumber__c,
                            InstallmentPercentage__c: rec.InstallmentPercentage__c,
                            InstallmentDate__c: this.formatDate(rec.InstallmentDate__c),
                            rawInstallmentDate: rec.InstallmentDate__c,
                            Milestone__c: rec.Milestone__c,
                            RevisedDate__c: this.formatDate(rec.RevisedDate__c),
                            NewRevisedDate__c: null,
                            originalRevisedDate__c: rec.RevisedDate__c,
                            ChequeReplacement__c: rec.ChequeReplacement__c,
                            DueDate: rec.DueDate__c,
                            Type__c: rec.InstallmentType__c,
                            isReadOnly: isReadOnly
                        };
                    });

                this.isLoading = false;
            })
            .catch(error => {
                console.error(error);
                this.showToast(
                    'Error',
                    'Error fetching installments',
                    'error'
                );
                this.isLoading = false;
            });
    }

    handleChequeReplacementChange(event) {
        const recordId = event.target.dataset.id;
        const checked = event.target.checked;

        this.lstInstallmentLine = this.lstInstallmentLine.map(row => {
            if (row.Id === recordId) {
                return {
                    ...row,
                    ChequeReplacement__c: checked
                };
            }
            return row;
        });

        // If user unchecks Cheque Replacement, validate existing Revised Date
        if ( !checked && row.Type__c !== 'Handover' && row.Type__c !== 'Post Handover Installment') {
            const row = this.lstInstallmentLine.find(item => item.Id === recordId);
            if (row && row.NewRevisedDate__c) {
                const selectedDate = new Date(row.NewRevisedDate__c);
                const dueDate = new Date(row.DueDate);

                const maxAllowedDate = new Date(dueDate);
                maxAllowedDate.setDate(maxAllowedDate.getDate() + 180);

                if (selectedDate > maxAllowedDate) {

                    this.showToast(
                        'Error',
                        'Revised Date cannot exceed 180 days from the Due Date.',
                        'error'
                    );

                    this.lstInstallmentLine = this.lstInstallmentLine.map(item => {
                        if (item.Id === recordId) {
                            return {
                                ...item,
                                NewRevisedDate__c: null
                            };
                        }
                        return item;
                    });
                }
            }
        }
    }

    handleRowDateChange(event) {
        const recordId = event.target.dataset.id;
        const value = event.target.value;
        const selectedDate = new Date(value);
        const row = this.lstInstallmentLine.find(
            item => item.Id === recordId
        );
        const dueDate = new Date(row.DueDate);
        const today = new Date();
        today.setHours(0, 0, 0, 0);
        // Past date validation
        if (selectedDate < today) {
            this.showToast(
                'Error',
                'Past dates are not allowed.',
                'error'
            );
            event.target.value = null;
            return;
        }

        // 180 day validation
        if ( !row.ChequeReplacement__c && row.Type__c !== 'Handover' && row.Type__c !== 'Post Handover Installment') {
            const maxAllowedDate = new Date(dueDate);
            maxAllowedDate.setDate(maxAllowedDate.getDate() + 180);
            console.log('selectedDate' + selectedDate);
            console.log('maxAllowedDate' + maxAllowedDate);
            if (selectedDate > maxAllowedDate) {
                this.showToast(
                    'Error',
                    'Revised Date cannot exceed 180 days from Original Installment Date.',
                    'error'
                );
                event.target.value = null;
                this.lstInstallmentLine = this.lstInstallmentLine.map(item => {
                    if (item.Id === recordId) {
                        return {
                            ...item,
                            NewRevisedDate__c: null
                        };
                    }
                    return item;
                });

                return;
            }
        }

        this.lstInstallmentLine = this.lstInstallmentLine.map(row => {
            if (row.Id === recordId) {
                return {
                    ...row,
                    NewRevisedDate__c: value
                };
            }
            return row;
        });
    }

    handleSubmit() {
        const today = new Date();
        today.setHours(0, 0, 0, 0);

        for (let row of this.lstInstallmentLine) {

            if (!row.NewRevisedDate__c) {
                continue;
            }

            // Skip validation for cheque replacement and type
            if (row.ChequeReplacement__c || row.Type__c === 'Handover' || row.Type__c === 'Post Handover Installment') {
                continue;
            }

            const selectedDate = new Date(row.NewRevisedDate__c);
            const installmentDate = new Date(row.rawInstallmentDate);
            const dueDate = new Date(row.DueDate);
            const maxAllowedDate = new Date(dueDate);
            maxAllowedDate.setDate(maxAllowedDate.getDate() + 180);

            if (selectedDate > maxAllowedDate) {

                this.showToast(
                    'Error',
                    `Revised Date for Installment ${row.InstallmentNumber__c} cannot exceed 180 days from the Due Date.`,
                    'error'
                );

                return;
            }
        }
        let modifiedRecords =
            this.lstInstallmentLine.filter(
                row =>
                    row.NewRevisedDate__c &&
                    row.NewRevisedDate__c !==
                    row.originalRevisedDate__c
            );

        if (modifiedRecords.length === 0) {

            this.showToast(
                'Error',
                'Please update at least one revised date.',
                'error'
            );

            return;
        }

        this.isLoading = true;

        isPaymentPlanPendingApproval({
            paymentPlanId: this.selectedPaymentPlan
        })
            .then(result => {
                console.log('Approval Check Result:', result);
                if (result) {
                    this.showToast('Error', 'This Payment Plan is already submitted for approval.', 'error');
                    this.isLoading = false;
                    return;
                }

                let recordsToUpdate = this.lstInstallmentLine
                    .filter(row =>
                        row.NewRevisedDate__c &&
                        row.NewRevisedDate__c !==
                        row.originalRevisedDate__c
                    )
                    .map(row => ({ Id: row.Id, RevisedDate__c: row.NewRevisedDate__c, ChequeReplacement__c: row.ChequeReplacement__c }));

                console.log('Records To Update:', JSON.stringify(recordsToUpdate));

                if (recordsToUpdate.length === 0) {
                    this.showToast(
                        'Error',
                        'No records modified.',
                        'error'
                    );
                    this.isLoading = false;
                    return;
                }

                updateInstallments({ selectedRecords: recordsToUpdate, paymentPlanId: this.selectedPaymentPlan })
                    .then(() => {
                        console.log('Update successful');
                        this.showToast(
                            'Success',
                            'Records updated successfully.',
                            'success'
                        );

                        this[NavigationMixin.Navigate]({
                            type:
                                'standard__recordPage',
                            attributes: {
                                recordId:
                                    this.selectedPaymentPlan,
                                objectApiName:
                                    'PaymentPlan__c',
                                actionName:
                                    'view'
                            }
                        });

                        setTimeout(() => {
                            this.closeAction();
                        }, 500);

                        this.isLoading = false;
                    })
                    .catch(error => {
                        console.error('Update Installments Error:', error);
                        let message = 'Update failed.';
                        if (error?.body?.message) {
                            message = error.body.message;
                        }

                        this.showToast('Error', message, 'error');
                        this.isLoading = false;
                    });
            })
            .catch(error => {

                let message = 'Error checking approval status.';

                if (error?.body?.message) {
                    message = error.body.message;
                }

                this.showToast(
                    'Error',
                    message,
                    'error'
                );

                this.isLoading = false;
            });
    }

    formatDate(dateValue) {
        if (!dateValue) {
            return '';
        }
        const date = new Date(dateValue);
        return new Intl.DateTimeFormat('en-GB', {
            day: '2-digit',
            month: 'short',
            year: 'numeric'
        }).format(date);
    }

    closeAction() {
        this.dispatchEvent(new CloseActionScreenEvent());
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({
            title,
            message,
            variant
        }));
    }
}