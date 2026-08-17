import { LightningElement, track } from 'lwc';
import EmailTemplates from '@salesforce/apex/BulkEmailController.getEmailTemplatesDefault';
import OrgWideEmailAddress from '@salesforce/apex/BulkEmailController.getOrgWideEmailAddress';
import FetchReportDetails from '@salesforce/apex/BulkEmailController.getReportDetailsDefault';
import sendBulkEmails from '@salesforce/apex/BulkEmailController.sendBulkEmails';
import sampleCSVFileId from '@salesforce/apex/BulkEmailController.getSampleCSVFile';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class BulkEmailLwc extends LightningElement {
    @track isShowModal = false;
    @track showLoading = false;
    @track showReport = false;
    @track showfileUpload = false;
    @track fileName;
    @track selectedEmailBody;
    @track selectedEmailTemplate;
    @track emailFolderList = [];
    @track emailTemplatesList = [];
    @track reportFolderList = [];
    @track reportsList = [];
    @track orgWideAddressList = [];
    @track typeofEmailvalue;
    @track selectedEmailFolder;
    @track EmailTemplateDetails = [];
    @track ReportDetails = [];
    @track ReportList = [];
    uploadedFileId = '';
    @track selectedEmailSubject = '';
    @track selectedFromEmail = '';
    @track selectedReportId = '';
    @track isPreviewMode = false;
    fileContentBase64 = '';
    isFileUploaded = false;
    @track attachments = [];
    @track sampleCsvDownloadlink;
   // sampleCsvDownloadlink = '/sfc/servlet.shepherd/document/download/'+this.sampleFileUrl;
    get radioOptions() {
        return [
            { label: 'Report', value: 'Report' },
            { label: 'Bulk Email File', value: 'BulkEmailFile' },
        ];
    }
    get acceptedFormats() {
        return ['.csv', '.xlsx'];
    }
    connectedCallback() {
    }

    handleOpenModal() {
        this.isShowModal = true;
        this.showReport = false;
        this.showfileUpload = false;
        this.getEmailTemplates();
        this.getOrgWideEmailAddresses();
        this.getSampleFileUrl();
        this.selectedEmailSubject = '';
        this.selectedFromEmail = '';
        this.selectedReportId = '';
        this.isFileUploaded = false;
        this.selectedEmailBody = '';
        this.typeofEmailvalue = null;

    }

    getSampleFileUrl(){
        this.showLoading = true;
        sampleCSVFileId({}).then(result => {
            this.showLoading = false;
            if (result) {
                let fileId;
                console.log('result--' + result);
                for (var key in result) {
                     fileId = result[key];
                    console.log(key + '---' + result[key]);
                }
               this.sampleCsvDownloadlink =  '/sfc/servlet.shepherd/document/download/'+fileId;
            }
        }).catch(error => {
            this.showLoading = false;
        });
    }

    handleCloseModal() {
        this.isShowModal = false;
    }
    handleFromEmailChange(event) {
        this.selectedFromEmail = event.target.value;
    }
    handleEmailTemplateChange(event) {
        this.selectedEmailTemplate = event.target.value;
        console.log('this.selectedEmailTemplate'+this.selectedEmailTemplate);
        const templateDetails = this.EmailTemplateDetails[this.selectedEmailTemplate];
        if (templateDetails) {
            console.log(this.EmailTemplateDetails[this.selectedEmailTemplate].Body);
            console.log(this.EmailTemplateDetails[this.selectedEmailTemplate].HtmlValue);
            //this.selectedEmailBody = this.EmailTemplateDetails[this.selectedEmailTemplate].HtmlValue;
            this.selectedEmailBody = templateDetails.HtmlValue;
            this.template.querySelector('lightning-input-rich-text').value = templateDetails.HtmlValue;
            this.selectedEmailSubject = templateDetails.Subject;
        }
    }

    handlePreview() {
        if (this.validateForm('preview')) {
            const editor = this.template.querySelector('lightning-input-rich-text');
            console.log(editor.value);
            this.isPreviewMode = true;
        }
    }
    get richTextValue() {
        var richtext = '';
        const emailBodyElement = this.template.querySelector('[data-id="emailBody"]');
        if (emailBodyElement) {
            richtext = emailBodyElement.value;
            console.log('Updated Email Body:', this.selectedEmailBody);
        }
        return richtext;
    }

    handleAttachmentChange(event) {
        const files = event.target.files;
        this.attachments = Array.from(files).map((file) => ({
            name: file.name,
            size: file.size,
            fileData: file,
        }));
    }

    closePreview() {
        this.isPreviewMode = false;
    }
    get previewStyle() {
        return this.isPreviewMode ? 'display: block;' : 'display: none;';
    }

    get editStyle() {
        return this.isPreviewMode ? 'display: none;' : 'display: block;';
    }
    handleBodyChange(event) {
        const emailBodyElement = this.template.querySelector('[data-id="emailBody"]');
        if (emailBodyElement) {
            this.selectedEmailBody = emailBodyElement.value;
            console.log('Updated Email Body:', this.selectedEmailBody);
        } else {
            console.log('Unable to fetch the latest Email Body.');
        }
    }

    handleTypeOfEmailChange(event) {
        console.log(event.target.value);
        this.typeofEmailvalue = event.target.value;
        if (event.target.value == 'Report') {
            this.showReport = true;
            this.showfileUpload = false;
            this.getReportFolders();
        }
        else if (event.target.value == 'BulkEmailFile') {
            this.showReport = false;
            this.showfileUpload = true;
        }
        else {
            this.showReport = false;
            this.showfileUpload = false;
        }
    }

    handleUploadFinished(event) {
        const uploadedFiles = event.detail.files;
        if (uploadedFiles.length > 0) {
            console.log('Name of file uploaded : ' + uploadedFiles[0].documentId);
            const fileId = uploadedFiles[0].documentId;
            this.fileName = 'File uploaded: ' + uploadedFiles[0].name;
            this.uploadedFileId = fileId; // Store the ContentDocumentId
        } else {
            this.fileName = '';
        }
    }

    handleFileChange(event) {
        const file = event.target.files[0];
        if (file) {
            this.fileName = file.name;
            const reader = new FileReader();

            reader.onload = () => {
                const fileContent = reader.result.split(',')[1]; // Get base64 part
                this.fileContentBase64 = fileContent;
                this.isFileUploaded = true;
            };

            reader.readAsDataURL(file);
        }
    }

    handleSubjectChange(event) {
        this.selectedEmailSubject = event.target.value;
    }
    handleReportChange(event) {
        const selectedReportId = event.target.value;
        this.selectedReportId = selectedReportId;
    }
    getEmailTemplates() {
         this.showLoading = true;
        EmailTemplates().then(result => {
            this.showLoading = false;
            if (result) {
                console.log('result--' + result);
                this.EmailTemplateDetails = result;
                var emailTemps = [];
                for (var key in result) {
                    emailTemps.push({ value: key, label: result[key].Name });
                    console.log(key + '---' + result[key].Name);
                }
                this.emailTemplatesList = emailTemps;
            }
        }).catch(error => {
            this.showErrorMessage(error.body.message);
            this.showLoading = false;
        });
    }

    getOrgWideEmailAddresses() {
        this.showLoading = true;
        OrgWideEmailAddress({}).then(result => {
            this.showLoading = false;
            if (result) {
                console.log('result--' + result);
                var emailaddress = [];
                for (var key in result) {
                    emailaddress.push({ value: key, label: result[key] });
                    console.log(key + '---' + result[key]);
                }
                this.orgWideAddressList = emailaddress;
            }
        }).catch(error => {
            this.showLoading = false;
        });
    }

    getReportFolders() {
       this.showLoading = true;
        FetchReportDetails().then(result => {
            this.showLoading = false;
            if (result) {
                console.log('result--' + result);
                this.ReportDetails = result;
                var reportTemps = [];
                for (var key in result) {
                    reportTemps.push({ value: key, label: result[key].Name });
                }
                this.reportsList = reportTemps;
            }
        }).catch(error => {
            this.showErrorMessage(error.body.message);
            this.showLoading = false;
        });
    }

    handleSave() {
        if (this.validateForm('send')) {
            this.showLoading = true;

            const attachments = this.attachments.map((file) => {
                return new Promise((resolve) => {
                    const reader = new FileReader();
                    reader.onload = () => {
                        resolve({
                            fileName: file.name,
                            fileContent: btoa(reader.result) // Convert file content to base64
                        });
                    };
                    reader.readAsBinaryString(file.fileData);
                });
            });
            Promise.all(attachments).then((attachmentData) => {
                const attachmentNames = attachmentData.map((file) => file.fileName);
                const attachmentContents = attachmentData.map((file) => file.fileContent);

                let params = {
                    fileContentBase64: this.fileContentBase64,
                    emailBody: this.richTextValue,
                    emailSubject: this.selectedEmailSubject,
                    fromEmailAddress: this.selectedFromEmail,
                    reportId: null,
                    attachmentNames: attachmentNames,
                    attachmentContents: attachmentContents,
                    emailTemplateId: this.selectedEmailTemplate
                };

                if (this.typeofEmailvalue === 'Report') {
                    params.reportId = this.selectedReportId;
                }

                sendBulkEmails(params)
                    .then(() => {
                        this.showSuccessMessage('Emails sent successfully.');
                        this.showLoading = false;
                        this.handleCloseModal();
                    })
                    .catch(error => {
                        this.showErrorMessage(error.body.message);
                        this.showLoading = false;
                    });

            });
        }
    }

    validateForm(action) {
        if (action == 'send' || action == 'preview') {
            if (!this.selectedEmailSubject) {
                this.showErrorMessage('Subject is required.');
                return false;
            }
            if (!this.selectedEmailBody) {
                this.showErrorMessage('Email body is required.');
                return false;
            }
        }
        if (action == 'send') {
            if (!this.selectedReportId && !this.isFileUploaded) {
                this.showErrorMessage('Recipients not found');
                return false;
            }
            if (this.typeofEmailvalue === 'Report' && !this.selectedReportId) {
                this.showErrorMessage('Report is required when the email type is "Report".');
                return false;
            }
            if (this.typeofEmailvalue === 'BulkEmailFile' && !this.isFileUploaded) {
                this.showErrorMessage('A file is required when the email type is "BulkEmailFile".');
                return false;
            }

            if (!this.selectedFromEmail) {
                this.showErrorMessage('From Email address is required.');
                return false;
            }
        }

        return true;
    }


    showSuccessMessage(message) {
        const evt = new ShowToastEvent({
            title: 'Success',
            message: message,
            variant: 'success',
        });
        this.dispatchEvent(evt);
    }

    showErrorMessage(message) {
        const evt = new ShowToastEvent({
            title: 'Error',
            message: message,
            variant: 'error',
        });
        this.dispatchEvent(evt);
    }
}