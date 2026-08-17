import { LightningElement, wire, api, track } from "lwc";
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CloseActionScreenEvent } from "lightning/actions";
import modal from "@salesforce/resourceUrl/custommodalcss";
import { loadStyle } from "lightning/platformResourceLoader";
import getProjectRecordDetail from '@salesforce/apex/ProjectController.getProjectAndSoldUnits';
import updateSalesOrderRecords from '@salesforce/apex/ProjectController.updateSalesOrderRecords';

export default class UnitRegPreRequisitesActionFinance extends LightningElement {
    projectRecordId;
    header = 'Unit Registration - Fund Status Confirmation';
    projectName;
    admRegDate;
    @track data = []; // table data
    selectedUnitIds;
    @track selectedRowKeys = [];
    isLoading = false;
    isConfirm = false;
    isAdmRegDateReadOnly = false;
    isSaveButtonDisabled = true;

    connectedCallback() {
        loadStyle(this, modal);
    }

    @api set recordId(value) {
        this.isLoading = true;
        this.projectRecordId = value;
        if (this.projectRecordId) {
            this.doGetProjectDetails();
        }
    }

    get recordId() {
        return this.projectRecordId;
    }

    // get acceptedFormats() {
    //     return ['.pdf'];
    // }

    // get selectedEditableCount() {
    //     // Count only selected editable checkboxes (rows without a pre-existing date)
    //     return this.data.filter(row => row.Active_Sales_Order__r.RegistrationDocumentUploadedDate__c && row.isChecked && !row.isReadOnly).length;
    // }

    // get options() {
    //     return [
    //         { label: 'Yes', value: 'Yes' },
    //         { label: 'No', value: 'No' },
    //     ];
    // }

    doGetProjectDetails() {
        getProjectRecordDetail({ projectRecordId: this.projectRecordId })
            .then(res => {
                if (res && res.UnitsProject__r && res.UnitsProject__r.length > 0) {
                    if (res.Name) {
                        this.projectName = res.Name;
                    }
                    var salesOrders = [];
                    var rows = res.UnitsProject__r;
                    for (var i = 0; i < rows.length; i++) {
                        var row = rows[i];
                        salesOrders.push(row.Active_Sales_Order__c);
                        row.salesOrderLink = window.location.origin + '/' + row.Active_Sales_Order__c;
                        row.unitLink = window.location.origin + '/' + row.Id;
                        row.mandatoryDocumentsAvailable = false;
                        row.fundMovedToGRDate = null;
                        row.isChecked = false;
                        row.isReadOnly = false;
                        //console.log('row.ADM_Fee_Included__c : ',row.ADM_Fee_Included__c);
                        if (row.ADMPlotNumber__c) row.plotNumber = row.ADMPlotNumber__c;
                        if (row.Active_Sales_Order__r) {
                            row.admFeeIncluded = row.Active_Sales_Order__r.ADM_Fee_Included__c === true || (row.Active_Sales_Order__r.ADMFeeWaivedAmount__c > 0);
                            row.admFee = new Intl.NumberFormat('en-US', {style: 'currency', currency: 'AED'}).format((row.Active_Sales_Order__r.ADM_Fee_Cleared_Amount__c > 0) ? row.Active_Sales_Order__r.ADM_Fee_Cleared_Amount__c : (row.Active_Sales_Order__r.ADMFeeWaivedAmount__c || 0));
                            if (row.Active_Sales_Order__r.Name) row.activeSalesOrderName = row.Active_Sales_Order__r.Name;
                            if (row.Active_Sales_Order__r.Status__c) row.salesOrderStatus = row.Active_Sales_Order__r.Status__c;
                            if (row.Active_Sales_Order__r.SoldDate__c) {
                                row.soldDate = this.formatDate(row.Active_Sales_Order__r.SoldDate__c.toString());
                            }
                            if (row.Active_Sales_Order__r.FundMovedToGRDate__c) {
                                row.fundMovedToGRDate = this.formatDate(row.Active_Sales_Order__r.FundMovedToGRDate__c.toString());
                                this.selectedRowKeys.push(row.Id);
                                row.isChecked = true;
                                row.isReadOnly = true;
                            }
                        }
                    }
                    this.data = rows;
                    this.isLoading = false;
                    // getSalesOrdersWithMandatoryDocuments({ salesOrderIds: salesOrders }).then(res => {
                    //     if (res.length != 0) {
                    //         for (var j = 0; j < rows.length; j++) {
                    //             var row = rows[j];
                    //             res.forEach(e => {
                    //                 if (row.Active_Sales_Order__c == e) row.mandatoryDocumentsAvailable = true;
                    //             });
                    //         }
                    //     }
                    //     this.data = rows;
                    //     this.isLoading = false;
                    // }).catch(err => {
                    //     this.isLoading = false;
                    //     console.error('⛔ OUTPUT: ', JSON.stringify(err));
                    //     this.showToast('Error', JSON.stringify(err), 'error');
                    // });

                } else {
                    this.isLoading = false;
                    this.data = [];
                    this.showToast('Info', 'No records found.', 'info');
                    this.closAction();
                }
            }).catch(err => {
                console.log('error==>' + JSON.stringify(err));
                this.isLoading = false;
                this.showToast('Error', 'Error Occured, ' + JSON.stringify(err), 'error');
                this.closAction();

            });
    }

    // handleSelectChange(event){
    //     let selectedValue = event.target.value;
    //     const recordId = event.target.dataset.id;
    //     let regDateToUpdate = this.getCurrentDate();
    //     regDateToUpdate = this.getFormattedDate(regDateToUpdate);
    //     // Update the tableData with the new date value
    //     this.data = this.data.map(row => {
    //         if (row.Id == recordId && row.selectedValue == 'Yes') {
    //             return { ...row, dropDownValue: selectedValue, regDocUplodedDate: regDateToUpdate };
    //         } else if (!row.isReadOnly && !row.dropDownValue) {
    //             return { ...row, dropDownValue: null, regDocUplodedDate: null };
    //         }
    //         return row;
    //     });
    //     this.saveButtonValidation();
    // }

    // onSelecAllCheckbox(event) {
    //     const checked = event.target.checked;
    //     let regDateToUpdate = this.getCurrentDate();
    //     regDateToUpdate = this.getFormattedDate(regDateToUpdate);
    //     // Update the tableData with the new date value
    //     this.data = this.data.map(row => {
    //         if (!row.isReadOnly && checked && row.mandatoryDocumentsAvailable) {
    //             return { ...row, isChecked: true, regDocUplodedDate: regDateToUpdate };
    //         } else if (!row.isReadOnly && !checked) {
    //             return { ...row, isChecked: false, regDocUplodedDate: null };
    //         }
    //         return row;
    //     });
    //     this.getSelectedRecordsCount();
    //     this.saveButtonValidation();
    // }

    onCheckboxClick(event) {
        const checked = event.target.checked;
        const recordId = event.target.dataset.id;
        let dateToUpdate = this.getCurrentDate();
        dateToUpdate = this.formatDate(dateToUpdate);
        // Update the tableData with the new date value
        this.data = this.data.map(row => {
            if (row.Id === recordId && !row.isReadOnly && checked) {
                return { ...row, isChecked: true, fundMovedToGRDate: dateToUpdate };
            } else if (row.Id === recordId && !checked) {
                return { ...row, isChecked: false, fundMovedToGRDate: null };
            }
            return row;
        });
        //console.log('this.data===>'+JSON.stringify(this.data[0]));
        this.saveButtonValidation();
    }

    // getSelectedRecordsCount() {
    //     let count = 0;
    //     this.data.forEach(e => {
    //         if (e.isChecked) count += 1;
    //     })
    //     this.selectedRecords = count;
    // }

    handleDateChange(event) {
        const recordId = event.target.dataset.id;
        const selectedDate = event.target.value;

        // Find row and update value locally
        let updatedData = [...this.data];
        updatedData = updatedData.map(row => {
            if (row.Id === recordId) {
                return { ...row, fundMovedToGRDate: selectedDate, hasChanges: true};
            }
            return row;
        });
        this.data = updatedData;
        this.saveButtonValidation();
    }

    //Do date format dd-mm-year
    getFormattedDate(stringDate) {
        const year = stringDate.split('-')[0];
        const month = stringDate.split('-')[1];
        const date = stringDate.split('-')[2];
        return date + '-' + month + '-' + year;
    }

    formatDate(dateString) {
        if (!dateString) return '';
        try {
            const dateObj = new Date(dateString); // Convert string to Date
            return new Intl.DateTimeFormat(navigator.language, {
                year: 'numeric',
                month: 'numeric', // Full month name
                day: '2-digit'
            }).format(dateObj);
        } catch (error) {
            console.error('Error formatting date:', error);
            return dateString; // Fallback to raw value
        }
    }

    saveButtonValidation() {
        this.isSaveButtonDisabled = !this.data.some(record => record.hasChanges);
    }

    getCurrentDate() {
        const currentDate = new Date();
        const year = currentDate.getFullYear();
        const month = currentDate.getMonth() + 1; // Months are zero-based
        let day = currentDate.getDate();
        day = day.toString();
        if (day.length == 1) day = '0' + day;
        const regDateToUpdate = year + '-' + month + '-' + day;
        return regDateToUpdate;
    }

    async handleSaveClick() {
        this.isConfirm = true;
    }

    onSave() {
        this.isLoading = true;
        let salesOrders = [];

        this.data.forEach(element => {
            if (element.hasChanges) {
                let so = {}
                so.Id = element.Active_Sales_Order__c;
                so.FundMovedToGRDate__c = element.fundMovedToGRDate;
                salesOrders.push(so);
            }
        });

        if (salesOrders.length === 0) {
            this.showToast('Info', 'No changes to save.', 'info');
            this.isLoading = false;
            return;
        }
        this.updateSalesOrderRecords(salesOrders);
    }

    //Update project and unit records
    updateSalesOrderRecords(salesOrders) {
        updateSalesOrderRecords({ selectedRecords: salesOrders })
            .then(res => {
                this.showToast('Success', 'Records updated successfully.', 'success');
                this.isLoading = false;
                this.closAction();
            }).catch(err => {
                console.error('err-->', err);
                this.showToast('Error', 'Error occurred, ' + JSON.stringify(err), 'error');
                this.isLoading = false;
            });
    }

    closeConfirmBox(event) {
        this.isConfirm = false;
    }
    confirmBoxYes() {
        this.onSave();
    }

    closAction() {
        this.dispatchEvent(new CloseActionScreenEvent());
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
}