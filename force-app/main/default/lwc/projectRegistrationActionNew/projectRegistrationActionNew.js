import { LightningElement, api, track } from "lwc";
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import modal from "@salesforce/resourceUrl/custommodalcss";
import { CloseActionScreenEvent } from "lightning/actions";
import { loadStyle } from "lightning/platformResourceLoader";
import getProjectRecordDetail from '@salesforce/apex/ProjectController.getProjectRecord';
import updateADMRegUnits from '@salesforce/apex/ProjectController.updateProjectRegistration';
import uploadFile from '@salesforce/apex/ProjectController.uploadFile';
const FILE_NAME = 'Project Registration Document.pdf';

export default class ProjectRegistrationActionNew extends NavigationMixin(LightningElement) {
    isLoading = false;
    isConfirm = false;
    header = 'Project Registration';
    projectName;
    admRegDate;
    projectRegNumber;
    admRegRemark;
    fileData;
    isAdmRegDateReadOnly = false;
    isProjectRegNumberReadOnly = false;
    isAdmRegRemarkReadOnly = false;
    isAttachmentUpload = true;
    projectHasAttachment = false;
    @track data = [];
    selectedRowKeys = [];

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
                    this.isLoading = false;
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

    getCurrentDate() {
        const currentDate = new Date();
        return this.formatDate(currentDate.toString());
    }

    async handleSaveClick() {
        if (!this.admRegDate) {
            this.showToast('Error', 'Please fill up Project registration date field', 'error');
            return;
        }
        if (!this.projectRegNumber) {
            this.showToast('Error','Please fill up Project registration number field','error');
            return;
        }
        if (!this.admRegRemark) {
            this.showToast('Error', 'Please fill up Project registration remark field', 'error');
            return;
        }
        if (!this.projectHasAttachment) {
            this.showToast('Error', 'Please upload a document.', 'error');
            return;
        }

        this.isConfirm = true;
    }

    onSave() {
        this.isLoading = true;

        let projectDetails = {};
        let projectAlreadyRegistered = true;

        if (this.admRegDate && !this.isAdmRegDateReadOnly && !this.isProjectRegNumberReadOnly) {
            projectDetails = {
                Id: this.projectRecordId,
                ProjectRegistrationRemark__c: this.admRegRemark,
                ProjectRegistrationNumber__c : this.projectRegNumber,
                ProjectRegistrationDate__c: this.admRegDate,
                LastProjectRegEmailReminder__c: this.admRegDate
            };
            projectAlreadyRegistered = false;

        } else if (this.admRegDate && this.isAdmRegDateReadOnly) {
            projectDetails = {
                Id: this.projectRecordId,
                Name: this.projectName,
                ProjectRegistrationDate__c: this.admRegDate
            };
        }
        if (this.projectRegNumber) {
            projectDetails.ProjectRegistrationNumber__c = this.projectRegNumber;
        }
        if (this.admRegRemark) {
            projectDetails.ProjectRegistrationRemark__c = this.admRegRemark;
        }

        this.doUpdateProjectDetails(projectDetails, projectAlreadyRegistered);
    }

    //Update project and unit records
    doUpdateProjectDetails(projectDetails, projectAlreadyRegistered) {
        updateADMRegUnits({
            updateProjectRecord: projectDetails,
            isProjectAlreadyRegistered: projectAlreadyRegistered
        })
        .then(() => {

            if (this.fileData) {
                const { base64, filename, recordId } = this.fileData;

                uploadFile({ base64, filename, recordId })
                    .catch(error => {
                        console.error('File upload error:', error);
                    });
            }

            this.showToast('Success', 'Project Registration is completed.', 'success');
            this.isLoading = false;
            this.closAction();

        })
        .catch(err => {
            console.error(err);
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