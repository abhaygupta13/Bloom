import { LightningElement, api, track } from "lwc";
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import modal from "@salesforce/resourceUrl/custommodalcss";
import { CloseActionScreenEvent } from "lightning/actions";
import { loadStyle } from "lightning/platformResourceLoader";
import getProjectRecordDetail from '@salesforce/apex/ProjectController.getProjectRecord';
import updateADMRegUnits from '@salesforce/apex/ProjectController.updateUnitRegistration';
import uploadUnitRegDocument from '@salesforce/apex/ProjectController.uploadUnitRegDocument';

export default class ProjectUnitRegistrationAction extends LightningElement {
    projectRecordId;
    header;
    projectName;
    admRegDate;
    admRegRemark;
    selectedDate;
    @track data = [];
    @track allData = [];
    @track selectedRowKeys = [];
    @track totalRecords = 0;
    @track selectedRecords = 0;
    @track fileData = null;
    dataTableRender = true;
    isLoading = false;
    isModalOpen = true;
    projectHasAttachment = false;
    isConfirm = false;
    isAdmRegDateReadOnly = false;
    isAdmRegRemarkReadOnly = false;
    isAttachmentUpload = true;
    sortBy = 'activeSalesOrderName';
    sortDirection = 'asc';
    isFileUploadModalOpen = false;
    columns = [
        {
            label: 'Sales Order',
            fieldName: 'salesOrderLink',
            type: 'url',
            sortable: true,
            typeAttributes: {
                label: {
                    fieldName: 'activeSalesOrderName'
                },
                target: '_blank'
            }
        },
        {
            label: 'Status',
            fieldName: 'Status__c',
            type: 'text',
            sortable: true
        },
        {
            label: 'Unit Number',
            fieldName: 'unitLink',
            type: 'url',
            sortable: true,
            typeAttributes: {
                label: {
                    fieldName: 'Name'
                },
                target: '_blank'
            }
        },
        {
            label: 'Plot Number',
            fieldName: 'plotNumber',
            type: 'text',
            sortable: true
        },
        {
            label: 'Sold Date',
            fieldName: 'soldDate',
            type: 'date',
            sortable: true
        },
        {
            label: 'Registration Date',
            fieldName: 'registrationDateDisplay',
            type: 'date',
            sortable: true
        }
    ];

    connectedCallback() {
        loadStyle(this, modal);
    }

    @api
    set recordId(value) {
        this.isLoading = true;
        this.projectRecordId = value;
        if (this.projectRecordId) {
            this.doGetProjectDetails();
        }
    }

    get recordId() {
        return this.projectRecordId;
    }

    get acceptedFormats() {
        return ['.pdf'];
    }

    get selectedEditableCount() {
        return this.allData.filter(
            row => row.isChecked && !row.isReadOnly
        ).length;
    }

    get isSaveDisabled() {

        return (
            this.selectedEditableCount === 0 ||
            !this.selectedDate
        );
    }

    get noRecordsFound() {
        return (
            !this.isLoading &&
            this.dataTableRender &&
            this.data.length === 0
        );
    }

    get disabledRowKeys() {
        return this.allData
            .filter(row => row.isReadOnly)
            .map(row => row.Id);
    }

    doGetProjectDetails() {
        getProjectRecordDetail({
            projectRecordId: this.projectRecordId
        })
            .then(res => {
                if (!res) {
                    this.isLoading = false;
                    this.showToast(
                        'Error',
                        'No records found.',
                        'error'
                    );
                    this.closAction();
                    return;
                }
                if (res.Name) {
                    this.header = 'Project Registration';
                    this.projectName = res.Name;
                }
                if (res.ProjectRegistrationRemark__c) {
                    this.isAdmRegRemarkReadOnly = true;
                    this.admRegRemark =
                        res.ProjectRegistrationRemark__c;
                }
                if (res.ProjectRegistrationDate__c) {
                    this.admRegDate = res.ProjectRegistrationDate__c;
                    this.isAdmRegDateReadOnly = true;
                }
                if (res.Documents__r) {
                    res.Documents__r.forEach(e => {
                        if (e.DocumentType__r && e.DocumentType__r.Type__c === 'ADM Registration Document') {
                            this.projectHasAttachment = true;
                            this.isAttachmentUpload = false;
                        }
                    });
                }

                const rows = res.UnitsProject__r || [];
                const processedRows = rows.map(row => {
                    const processedRow = {
                        ...row,
                        isChecked: false,
                        isReadOnly: false,
                        salesOrderLink: row.Active_Sales_Order__c ? window.location.origin + '/' + row.Active_Sales_Order__c : null,
                        unitLink: row.Id ? window.location.origin + '/' + row.Id : null,
                        plotNumber: row.ADMPlotNumber__c ? row.ADMPlotNumber__c : null,
                        activeSalesOrderName: '',
                        soldDate: null,
                        registrationDateDisplay: null
                    };
                    if (row.Active_Sales_Order__r) {
                        if (row.Active_Sales_Order__r.Name) {
                            processedRow.activeSalesOrderName = row.Active_Sales_Order__r.Name;
                        }
                        if (row.Active_Sales_Order__r.SoldDate__c) {
                            processedRow.soldDate = row.Active_Sales_Order__r.SoldDate__c;
                        }
                    }
                    if (row.RegistrationDate__c) {
                        processedRow.registrationDateDisplay = row.RegistrationDate__c;
                        processedRow.isChecked = true;
                        processedRow.isReadOnly = true;
                    }
                    return processedRow;
                });

                this.allData = processedRows;
                this.data = [...processedRows];
                this.totalRecords = processedRows.length;
                this.selectedRowKeys = processedRows.filter(row => row.isChecked).map(row => row.Id);
                this.selectedRecords = this.selectedRowKeys.length;
                this.isLoading = false;
            })
            .catch(err => {
                console.error('Error ==> ', JSON.stringify(err));
                this.isLoading = false;
                this.showToast('Error', 'Error in fetching data.', 'error');
                this.closAction();
            });
    }

    handleDateChange(event) {
        this.selectedDate = event.target.value;
        this.allData = this.allData.map(row => {
            if (row.isChecked && !row.isReadOnly) {
                return { ...row, registrationDateDisplay: this.selectedDate };
            }
            return row;
        });
        this.data = [...this.allData];
    }

    handleRowSelection(event) {
        const selectedRows = event.detail.selectedRows;
        const selectedIds = selectedRows.map(row => row.Id);
        const readOnlyIds = this.allData
            .filter(row => row.isReadOnly)
            .map(row => row.Id);
        this.selectedRowKeys = [
            ...new Set([
                ...selectedIds,
                ...readOnlyIds
            ])
        ];
        this.allData = this.allData.map(row => {
            if (row.isReadOnly) {
                return {
                    ...row,
                    isChecked: true
                };
            }
            const isSelected = selectedIds.includes(row.Id);
            return {
                ...row,
                isChecked: isSelected,
                registrationDateDisplay: isSelected ? this.selectedDate || null : null
            };
        });

        this.selectedRecords = this.allData.filter(row => row.isChecked).length;
        this.data = [...this.allData];
    }

    get isFileUploadSubmitDisabled() {
        return !this.fileData;
    }

    handleFileUploadSubmit() {

        if (!this.fileData) {

            this.showToast(
                'Error',
                'Please upload the registration document.',
                'error'
            );

            return;
        }

        /*
            * Close the upload popup.
            */
        this.isFileUploadModalOpen = false;

        /*
            * Continue with the existing save process.
            */
        this.onSave();
    }

    handleCloseFileUploadModal() {
        this.isFileUploadModalOpen = false;
        this.fileData = null;
        this.isModalOpen = true;
    }

    handleSort(event) {
        this.sortBy = event.detail.fieldName;
        this.sortDirection = event.detail.sortDirection;
        this.data = this.sortData(this.data, this.sortBy, this.sortDirection);
    }


    sortData(data, fieldName, direction) {
        const sortedData = [...data];
        sortedData.sort((a, b) => {
            let valueA = this.getSortValue(a, fieldName);
            let valueB = this.getSortValue(b, fieldName);
            if (
                valueA === null ||
                valueA === undefined
            ) {
                valueA = '';
            }

            if (
                valueB === null ||
                valueB === undefined
            ) {
                valueB = '';
            }

            if (fieldName === 'soldDate' || fieldName === 'registrationDateDisplay') {
                valueA =
                    valueA
                        ? new Date(valueA).getTime()
                        : 0;
                valueB =
                    valueB
                        ? new Date(valueB).getTime()
                        : 0;
            }
            if (typeof valueA === 'string' && typeof valueB === 'string') {
                valueA = valueA.toLowerCase();
                valueB = valueB.toLowerCase();
            }
            let result = 0;
            if (valueA > valueB) {
                result = 1;
            }
            else if (valueA < valueB) {
                result = -1;
            }
            return direction === 'asc'
                ? result
                : -result;
        });
        return sortedData;
    }

    getSortValue(row, fieldName) {
        if (fieldName === 'salesOrderLink') {

            return row.activeSalesOrderName || '';
        }
        if (fieldName === 'unitLink') {
            return row.Name || '';
        }
        return row[fieldName];
    }

    handleSubmitClick() {
        if (!this.selectedDate) {
            this.showToast(
                'Error',
                'Please select a Registration Date.',
                'error'
            );
            return;
        }

        if (this.selectedEditableCount === 0) {
            this.showToast(
                'Error',
                'Please select at least one unit.',
                'error'
            );
            return;
        }

        this.isModalOpen = false;
        this.isFileUploadModalOpen = true;
    }

    handleFileChange(event) {

        const file =
            event.target.files &&
            event.target.files[0];

        if (!file) {
            return;
        }

        if (
            file.type !== 'application/pdf' &&
            !file.name.toLowerCase().endsWith('.pdf')
        ) {
            this.showToast(
                'Error',
                'Please upload a PDF document.',
                'error'
            );

            event.target.value = null;
            return;
        }

        this.isLoading = true;

        const reader = new FileReader();

        reader.onload = () => {

            const base64 =
                reader.result.split(',')[1];

            this.fileData = {
                filename: file.name,
                base64: base64
            };

            this.isLoading = false;
        };

        reader.onerror = () => {

            this.isLoading = false;

            this.showToast(
                'Error',
                'Unable to read the selected file.',
                'error'
            );
        };

        reader.readAsDataURL(file);

        event.target.value = null;
    }

    onSave() {

        if (!this.selectedDate) {
            this.showToast(
                'Error',
                'Please select a Registration Date.',
                'error'
            );
            return;
        }

        if (!this.fileData) {
            this.showToast(
                'Error',
                'Please upload the registration document.',
                'error'
            );
            return;
        }

        const selectedRows = this.allData.filter(
            row => row.isChecked && !row.isReadOnly
        );

        if (selectedRows.length === 0) {
            this.showToast(
                'Error',
                'Please select at least one unit.',
                'error'
            );
            return;
        }

        const unitsWithoutSalesOrder = selectedRows.filter(
            row => !row.Active_Sales_Order__c
        );

        if (unitsWithoutSalesOrder.length > 0) {
            this.showToast(
                'Error',
                'One or more selected Units do not have an Active Sales Order.',
                'error'
            );
            return;
        }

        this.isLoading = true;

        const units = selectedRows.map(row => ({
            Id: row.Id,
            RegistrationDate__c: this.selectedDate
        }));

        const projectDetails = {
            Id: this.projectRecordId,
            Name: this.projectName
        };

        this.doUpdateProjectDetails(
            units,
            projectDetails
        );
    }

    doUpdateProjectDetails(units, projectDetails) {
        updateADMRegUnits({
            selectedUnits: units,
            projectRecord: projectDetails
        })
            .then(() => {

                const salesOrderIds = units
                    .map(unit => {
                        const row = this.allData.find(
                            item => item.Id === unit.Id
                        );

                        return row ? row.Active_Sales_Order__c : null;
                    })
                    .filter(id => id);

                if (salesOrderIds.length === 0) {
                    throw new Error(
                        'No Sales Orders found for the selected Units.'
                    );
                }

                const uniqueSalesOrderIds = [
                    ...new Set(salesOrderIds)
                ];

                const uploadPayload = {
                    recordIds: uniqueSalesOrderIds,
                    base64: this.fileData.base64,
                    fileName: this.fileData.filename
                };

                return uploadUnitRegDocument({
                    unitRegistrationDocument: JSON.stringify(uploadPayload)
                });
            })
            .then(() => {

                this.fileData = null;

                this.showToast(
                    'Success',
                    'Unit Registration is completed.',
                    'success'
                );

                this.isLoading = false;
                this.closAction();
            })
            .catch(error => {

                console.error(
                    'Error ==> ',
                    JSON.stringify(error)
                );

                this.showToast(
                    'Error',
                    this.getErrorMessage(error),
                    'error'
                );

                this.isLoading = false;
            });
    }

    getErrorMessage(error) {

        if (
            error &&
            error.body &&
            error.body.message
        ) {

            return error.body.message;
        }

        return 'An unexpected error occurred.';
    }

    handleCloseModal() {

        this.dispatchEvent(
            new CloseActionScreenEvent()
        );
    }

    closAction() {

        this.dispatchEvent(
            new CloseActionScreenEvent()
        );
    }

    showToast(
        title,
        message,
        variant
    ) {

        const evt =
            new ShowToastEvent({

                title:
                    title,

                message:
                    message,

                variant:
                    variant,

                mode:
                    'dismissable'
            });


        this.dispatchEvent(evt);
    }
}