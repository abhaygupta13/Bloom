import { LightningElement, api, track } from "lwc";
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import modal from "@salesforce/resourceUrl/custommodalcss";
import { CloseActionScreenEvent } from "lightning/actions";
import { loadStyle } from "lightning/platformResourceLoader";
import getProjectRecordDetail from '@salesforce/apex/ProjectController.getProjectRecord';
import updateADMRegUnits from '@salesforce/apex/ProjectController.updateADMRegDateOnUnits';
import uploadFile from '@salesforce/apex/ProjectController.uploadFile';
import uploadDocument from '@salesforce/apex/ProjectController.uploadUnitRegDocument';
import getUnitdocuments from '@salesforce/apex/ProjectController.getUnitDocuments';
const FILE_NAME = 'Project Registration Document.pdf';

export default class ProjectRegistrationAction extends NavigationMixin(LightningElement) {
    projectRecordId;
    header;
    projectName;
    admRegDate;
    projectRegNumber;
    admRegRemark;
    fileData;
    @track data = []; // table data
    selectedUnitIds;
    @track selectedRowKeys = [];
    dataTableRender = true;
    isLoading = false;
    @track totalRecords = 0; // Total number of records in the table
    @track selectedRecords = 0; // Number of selected records in the table
    projectHasAttachment = false;
    isConfirm = false;
    isAdmRegDateReadOnly = false;
    isProjectRegNumberReadOnly = false;
    isAdmRegRemarkReadOnly = false;
    isAttachmentUpload = true;
    atLeastOneUnitRecordSelected = false;
    selectedUnitId;

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

    get acceptedFormats() {
        return ['.pdf'];
    }

    get selectedEditableCount() {
        // Count only selected editable checkboxes (rows without a pre-existing date)
        return this.data.filter(row => row.RegistrationDate__c && row.isChecked && !row.isReadOnly).length;
    }

    doGetProjectDetails() {
        getProjectRecordDetail({ projectRecordId: this.projectRecordId })
            .then(res => {
                //console.log('res==>' + JSON.stringify(res));
                if (res) {
                    if (res.Name) {
                        this.header = 'Project Registration';
                        this.projectName = res.Name;
                    }
                    if (res.ProjectRegistrationRemark__c) {
                        this.isAdmRegRemarkReadOnly = true;
                        this.admRegRemark = res.ProjectRegistrationRemark__c;
                    }
                    if (res.ProjectRegistrationDate__c) {
                        this.admRegDate = res.ProjectRegistrationDate__c;
                        this.isAdmRegDateReadOnly = true;
                    }
                    if (res.ProjectRegistrationNumber__c) {
                        this.projectRegNumber = res.ProjectRegistrationNumber__c;
                        this.isProjectRegNumberReadOnly = true;
                    }
                    //console.log('res.Documents__r==>',res.Documents__r);
                    //console.log('.isAttachmentUpload==>',this.isAttachmentUpload);
                    if (res.Documents__r) {
                        res.Documents__r.forEach(e => {
                            if (e.DocumentType__r) {
                                if (e.DocumentType__r.Type__c == 'ADM Registration Document') {
                                    this.projectHasAttachment = true;
                                    this.isAttachmentUpload = false;
                                }
                            }
                        });
                    }
                    //console.log('.isAttachmentUpload==>',this.isAttachmentUpload);
                    var rows = res.UnitsProject__r;
                    let unitIds = [];
                    for (var i = 0; i < rows.length; i++) {
                        var row = rows[i];
                        unitIds.push(row.Id);
                        row.filePreview = null;
                        row.isChecked = false;
                        row.isReadOnly = false;
                        row.salesOrderLink = window.location.origin + '/' + row.Active_Sales_Order__c;
                        row.unitLink = window.location.origin + '/' + row.Id;
                        row.plotNumber = row.ADMPlotNumber__c ? row.ADMPlotNumber__c : null;
                        if (row.Active_Sales_Order__r) {
                            if (row.Active_Sales_Order__r.Name) row.activeSalesOrderName = row.Active_Sales_Order__r.Name;
                            if (row.Active_Sales_Order__r.SoldDate__c) row.soldDate = this.formatDate(row.Active_Sales_Order__r.SoldDate__c.toString());
                            if (row.Active_Sales_Order__r.Status__c) row.salesOrderStatus = row.Active_Sales_Order__r.Status__c;
                        }   
                        if (row.RegistrationDate__c) {
                            row.RegistrationDate__c = this.formatDate(row.RegistrationDate__c.toString());
                            this.selectedRowKeys.push(row.Id);
                            row.isChecked = true;
                            row.isReadOnly = true;
                        }
                    }
                    this.data = rows;
                    this.totalRecords = this.data.length;
                    this.selectedRecords = this.selectedRowKeys.length;
                    getUnitdocuments({ unitIds: unitIds })
                        .then(result => {
                            if (result) {
                                for (var i = 0; i < this.data.length; i++) {
                                    var row = this.data[i];
                                    let document = result[row.Id];
                                    if (document.ContentDocumentId__c) row.filePreview = document.ContentDocumentId__c;
                                }
                            }
                            this.data = this.data;
                        })
                        .catch(error => {
                            console.error('⛔ Error: ' + JSON.stringify(error));
                        }).finally(fin=>{
                            this.isLoading = false;
                        });
                } else {
                    this.isLoading = false;
                    this.showToast('Error', 'No records found.', 'error');
                    this.closAction();
                }
            }).catch(err => {
                console.log('error==>' + JSON.stringify(err));
                this.isLoading = false;
                this.showToast('Error', 'Error in fecthing data.', 'error');
                this.closAction();

            });
    }

    admRegDateChange(event) {
        //console.log('adm date-->', event.target.value);
        this.admRegDate = event.target.value;
    }

    projectRegNumberChange(event) {
        //console.log('adm date-->', event.target.value);
        this.projectRegNumber = event.target.value;
    }

    admRemarkChange(event) {
        //console.log('remakr---.', event.target.value);
        this.admRegRemark = event.target.value;
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

    handleOpenfileUpload(event) {
        this.selectedUnitId = event.target.dataset.id;
        if (!this.selectedUnitId) {
            alert('Unit record id not found');
            return;
        }
        this.template.querySelector('input[name="unitFileUpload"]').click();
    }

    openUnitFileUpload(event) {
        this.isLoading = true;
        const file = event.target.files[0];
        var reader = new FileReader()
        reader.onload = () => {
            var base64 = reader.result.split(',')[1]
            this.fileData = {
                'filename': file.name,
                'base64': base64,
                'recordId': this.selectedUnitId
            }
            uploadDocument({ unitRegistrationDocument: JSON.stringify(this.fileData) })
                .then(res => {
                    //console.log('res===> : ', res);
                    if (res) {
                        this.data = this.data.map(row => {
                            if (row.Id === this.selectedUnitId) {
                                return { ...row, filePreview: res, fileName: this.fileData.filename, fileData: this.fileData };
                            }
                            return row;
                        });
                    }
                    this.showToast('Success', file.name + ' document attached.', 'success');
                    this.fileData = null;
                    this.isLoading = false;
                    this.template.querySelector('input[name="unitFileUpload"]').value = '';
                }).catch(err => {
                    this.showToast('Error', JSON.stringify(err), 'error');
                    this.fileData = null;
                    console.error('⛔ OUTPUT: ', JSON.stringify(err));
                    this.isLoading = false;
                    this.template.querySelector('input[name="unitFileUpload"]').value = '';
                });
        }
        reader.readAsDataURL(file)
        //event.target.files = null;
    }


    openfileUpload(event) {
        const file = event.target.files[0];
        let filename = this.projectName + '.pdf';
        var reader = new FileReader()
        reader.onload = () => {
            var base64 = reader.result.split(',')[1]
            this.fileData = {
                'filename': filename,
                'base64': base64,
                'recordId': this.projectRecordId
            }
            this.projectHasAttachment = true;
        }
        reader.readAsDataURL(file)
        event.target.value = null;
    }

    handleFilePreview(event) {
        this[NavigationMixin.Navigate]({
            type: 'standard__namedPage',
            attributes: {
                pageName: 'filePreview'
            },
            state: {
                selectedRecordId: event.target.dataset.id
            }
        })
    }

    onSelecAllCheckbox(event) {
        const checked = event.target.checked;
        const regDateToUpdate = this.getCurrentDate();
        // Update the tableData with the new date value
        this.data = this.data.map(row => {
            if (!row.isReadOnly && checked) {
                return { ...row, isChecked: true, RegistrationDate__c: regDateToUpdate };
            } else if (!row.isReadOnly && !checked) {
                return { ...row, isChecked: false, RegistrationDate__c: null };
            }
            return row;
        });
        this.getSelectedRecordsCount();
    }

    onCheckboxClick(event) {
        const checked = event.target.checked;
        const recordId = event.target.dataset.id;
        const regDateToUpdate = this.getCurrentDate();
        // Update the tableData with the new date value
        this.data = this.data.map(row => {
            if (row.Id === recordId && !row.isReadOnly && checked) {
                return { ...row, isChecked: true, RegistrationDate__c: regDateToUpdate };
            } else if (row.Id === recordId && !checked) {
                return { ...row, isChecked: false, RegistrationDate__c: null };
            }
            return row;
        });
        this.getSelectedRecordsCount();
    }

    getCurrentDate() {
        const currentDate = new Date();
        return this.formatDate(currentDate.toString());
    }

    getSelectedRecordsCount() {
        let count = 0;
        this.data.forEach(e => {
            if (e.isChecked) count += 1;
        })
        this.selectedRecords = count;
    }

    async handleSaveClick() {
        if (!this.admRegDate) {
            this.showToast('Error', 'Please fill up Project registration date field', 'error');
            return;
        } else if (!this.projectRegNumber) {
            this.showToast('Error','Please fill up Project registration number field','error');
            return;
        } else if (this.admRegDate && !this.admRegRemark) {
            this.showToast('Error', 'Please fill up Project registration remark field', 'error');
            return;
        } else if (!this.projectHasAttachment) {
            this.showToast('Error', 'Please upload a document.', 'error');
            return;
        }
        if (this.admRegDate && this.admRegRemark) this.isConfirm = true;

    }

    onSave() {
        this.isLoading = true;
        let units = [];
        this.data.forEach(element => {
            if (element.isChecked && !element.isReadOnly) {
                let unitObj = {}
                unitObj.Id = element.Id;
                unitObj.RegistrationDate__c = element.RegistrationDate__c;
                units.push(unitObj);
            }
        })
        console.log('this.projectRecordId'+this.projectRecordId);
        console.log(
            'admRegDate=', this.admRegDate,
            'projectnumber', this.projectRegNumber,
            'isAdmRegDateReadOnly=', this.isAdmRegDateReadOnly,
            'isProjectRegNumberReadOnly=', this.isProjectRegNumberReadOnly
        );
        let projectDetails = {
            Id: this.projectRecordId
        };
        let projectAlreadyResgistered = true;
        if (this.admRegDate && !this.isAdmRegDateReadOnly && !this.isProjectRegNumberReadOnly) {
            console.log('If Block');
            projectDetails.ProjectRegistrationRemark__c = this.admRegRemark;
            projectDetails.ProjectRegistrationNumber__c = this.projectRegNumber;
            projectDetails.ProjectRegistrationDate__c = this.admRegDate;
            projectDetails.LastProjectRegEmailReminder__c = projectDetails.ProjectRegistrationDate__c;
            projectAlreadyResgistered = false;
        } 
        if (this.projectRegNumber) {
            projectDetails.ProjectRegistrationNumber__c = this.projectRegNumber;
        }
        if (this.admRegRemark) {
            projectDetails.ProjectRegistrationRemark__c = this.admRegRemark;
        }
        this.doUpdateProjectDetails(units, projectDetails, projectAlreadyResgistered);
    }

    //Update project and unit records
    doUpdateProjectDetails(units, projectDetails, projectAlreadyResgistered) {
        updateADMRegUnits({ selectedUnits: units, updateProjectRecord: projectDetails, isProjectAlreadyRegistered: projectAlreadyResgistered })
            .then(res => {
                //console.log('res==>', res);
                if (this.fileData) {
                    const { base64, filename, recordId } = this.fileData
                    uploadFile({ base64, filename, recordId }).then(result => {
                        this.fileData = null;
                    }).catch(error => {
                        console.error('Error in upload file==>' + JSON.stringify(error))
                    })
                }
                this.showToast('Success', 'Project Registration is completed.', 'success');
                this.isLoading = false;
                this.closAction();
            }).catch(err => {
                console.error('err-->', err);
                this.showToast('Error', 'Error occurred: ' + JSON.stringify(err), 'error');
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