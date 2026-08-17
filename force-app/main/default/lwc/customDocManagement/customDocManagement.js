import { LightningElement, api, track, wire } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getApplicableDocument from '@salesforce/apex/CustomDocManageController.getDocMetaDataInfo';
import addFilesonRecord from '@salesforce/apex/CustomDocManageController.addFilesonRecord';
import getDocumentRecordList from '@salesforce/apex/CustomDocManageController.getDocumentList';
import getHandoverTeamUsersList from '@salesforce/apex/CustomDocManageController.getHandoverTeamUsersList';
import getHandoverLeasingDocName from '@salesforce/apex/CustomDocManageController.getHandoverLeasingDocName';
import getFiles from '@salesforce/apex/CustomDocManageController.getFiles';
import downloadDocument from '@salesforce/apex/CustomDocManageController.downloadDocument';
import deleteUploadedFile from '@salesforce/apex/CustomDocManageController.deleteFile'
import { NavigationMixin } from 'lightning/navigation';
import { loadStyle, loadScript } from 'lightning/platformResourceLoader';
import fileUploadCustomCss from '@salesforce/resourceUrl/fileUploadCustomCss';
import LightningConfirm from 'lightning/confirm';
import userId from '@salesforce/user/Id';
const fields = ['Id'];
import PROFILE_NAME_FIELD from '@salesforce/schema/User.Profile.Name';
const USER_FIELDS = [PROFILE_NAME_FIELD];
import hasPermission from '@salesforce/customPermission/Document_Download_Button';

import pdflib from "@salesforce/resourceUrl/pdflic"; // Adjust this if needed



export default class CustomDocManagement extends NavigationMixin(LightningElement) {
    @api recordId;
    @track documentType;
    @track isLoading = false;
    @track record;
    @track fileData;
    @track sObjectLookupApiname;
    @track docRecords = [];
    @track callOnce = true;
    @track error;
    @track showDownAndPrev = false;
    @track contentDocumentId;
    @track isModalOpen = false;
    @track imageDocumentId;
    @track showCreateBtn;
    @track docName = '';
    @track showButton = false;
    showDocRecModal;
    sObjectName;
    handoverTeamUsersList = [];
    currentUserId = userId;
    docListContainsName;
    userListContainsUserId;
    profileName;
    cameraCaptureRef;

    // for preview files in single pdf
    isLibLoaded = false;
    mergedPdfUrl;
    pdfLibInstance;
    mimeTypeMap = {
    pdf: 'application/pdf',
    png: 'image/png',
    jpg: 'image/jpeg',
    jpeg: 'image/jpeg',
    gif: 'image/gif',
    bmp: 'image/bmp',
    svg: 'image/svg+xml',
    webp: 'image/webp',
    tif: 'image/tiff',
    tiff: 'image/tiff',
};


    // constructor(){
    //     // to load library for merge file and download

    // }

    // connectedCallback() {
    //     //super();
    //     if (this.isLibLoaded) {
    //             return;
    //         }
    //         console.log('pdfLib - ', pdfLib);
    //     loadScript(this, pdfLib)
    //         .then(() => {
    //             if (window['pdfLib'] || window['PDFLib']) {
    //                 this.isLibLoaded = true;
    //                 this.pdfLibInstance = window['pdfLib'] || window['PDFLib'];

    //                // this.loadPdfs();
    //             } else {
    //                 console.error('PDF-LIB not loaded correctly.');
    //             }
    //         })
    //         .catch(error => {
    //             console.error('Error loading PDF-LIB:', error);
    //         });
    // }
    renderedCallback() {
        if (hasPermission) {
            this.showButton = true;
        } else {
            this.showButton = false;
        }

        if (this.callOnce)
            this.fetchMetaDoc();

        Promise.all([
            loadStyle(this, fileUploadCustomCss)
        ]).then(() => {
            console.log('Files loaded');
        })
            .catch(error => {
                console.log(error.body.message);
            });

        loadScript(this, pdflib).then(() => {
        });
        console.log('pdflib lib is loaded sucessfully');
    }


    @wire(getRecord, { recordId: userId, fields: USER_FIELDS })
    wiredUser({ error, data }) {
        if (data) {
            this.profileName = data.fields.Profile.displayValue || data.fields.Profile.value;
        } else if (error) {
            console.error('Error fetching user record:', error);
        }
    }

    @wire(getRecord, { recordId: '$recordId', fields })
    wiredRecord({ error, data }) {
        if (data) {
            this.sObjectName = data.apiName;
            if (this.sObjectName == 'Handover__c') {
                this.fetchHandoverUserList();
            }
        } else if (error) {
            console.error('Error fetching record:', error);
        }
    }

    fetchMetaDoc() {

        getApplicableDocument({ recordId: this.recordId })
            .then(result => {
                this.documentType = result?.map(
                    ({ Id, MasterLabel }) => ({ value: MasterLabel, label: MasterLabel })
                );

                result.forEach(item => {
                    this.sObjectLookupApiname = item.Sobject_lkup_Api_Name__c;
                    this.showCreateBtn = item.Show_Create_Btn__c;

                });
                let obj = new Object();
                obj.sobjectType = 'Document__c';

                obj[this.sObjectLookupApiname] = this.recordId;
                obj.Document_Name__c = '';
                this.record = obj;
                //console.log('record' + JSON.stringify(this.record));
                this.getDocumentRecord();
                this.callOnce = false;
            }).catch(error => {
                this.error = error;

            })
    }

    getDocumentRecord() {
        try {
            getDocumentRecordList({ recordId: this.recordId, sObjectLookupApiname: this.sObjectLookupApiname })
                .then(result => {
                    console.log(JSON.stringify(result));
                    this.docRecords = result.map(item => ({
                        "Id": item.Id,
                        "Name": item.Document_Name__c,
                        "url": `/sfc/servlet.shepherd/document/download/${item.ContentDocumentId__c}`,
                        "contentDocId": item.ContentDocumentId__c
                    }));



                }).catch(error => {
                    this.error = error;
                    this.docRecords = undefined;

                })
        } catch (e) {
            console.log(e.message)
        }

    }

    handleDocumentType(event) {
        this.record.Document_Name__c = event.detail.value;
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


    openfileUpload(event) {
        const rowElement = event.target.closest('tr'); // Get the closest <tr> element containing the lightning-input
        const name = rowElement.querySelector('td[data-label=""]').textContent.trim();
        console.log('handoverTeamUsersList-->', this.handoverTeamUsersList);
        console.log('name---->', name);
        if (this.sObjectName == 'Handover__c') {
            let matchFound = false;
            this.handoverTeamUsersList.forEach((item, index) => {
                const docListContainsName = item?.docList?.some(doc => doc === name);
                const userListContainsUserId = item?.userList?.some(userId => userId === this.currentUserId);
                console.log('docListContainsName-->', docListContainsName);
                console.log('userListContainsUserId-->', userListContainsUserId);
                if (docListContainsName && userListContainsUserId) {
                    console.log('matchFound+matchFound');
                    matchFound = true;
                }
            });
            console.log('matchFound---->', matchFound);
            if (matchFound) {
                this.onfileUpload(event);
            }
            else {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'error',
                        message: 'You can not Upload this doc',
                        variant: 'error'
                    })
                );
            }
        } else {
            this.onfileUpload(event);
        }
    }

    onfileUpload(event) {
        const dataId = event.target.dataset.id;

        const rowElement = event.target.closest('tr'); // Get the closest <tr> element containing the lightning-input
        const name = rowElement.querySelector('td[data-label=""]').textContent.trim();

        this.record.Id = dataId;
        this.record.Document_Name__c = name;


        const file = event.target.files[0];
        if (!file) {
            alert("Please select a file.");
            return;
        }

        var reader = new FileReader()
        reader.onload = () => {
            var base64 = reader.result.split(',')[1]
            this.fileData = {

                'filename': file.name,
                'base64': base64,
                'recordId': this.fileId

            }
            console.log('filedata----->', this.fileData)
            this.handleFileSubmit();
        }
        reader.readAsDataURL(file)

    }

    handleFileSubmit() {
        const { base64, filename, recordId } = this.fileData
        this.isLoading = true;
        console.log('base64 - ', base64);
        addFilesonRecord({ base64: base64, filename: filename, documentObj: this.record })
            .then(result => {

                this.fileData = null
                this.isLoading = false;
                let title = `File uploaded successfully!!`
                this.toast(title)
                this.showDownAndPrev = true;
                this.getDocumentRecord();

            }).catch(error => {
                console.log('error - ', error);
                this.error = error;
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'error',
                        message: 'this.error!',
                        variant: 'error'
                    })
                );
            })


    }
    async handleDeleteFile(event) {
        const documentId = event.target.dataset.id;
        const rowElement = event.target.closest('tr'); // Get the closest <tr> element containing the lightning-input
        const name = rowElement.querySelector('td[data-label=""]').textContent.trim();
        console.log('name---.', name);
        console.log('handoverTeamUsersList-->', this.handoverTeamUsersList);
        console.log('currentUserId-->', this.currentUserId);
        if (this.sObjectName == 'Handover__c') {
            let matchFound = false;
            this.handoverTeamUsersList.forEach((item, index) => {
                const docListContainsName = item?.docList?.some(doc => doc === name);
                const userListContainsUserId = item?.userList?.some(userId => userId === this.currentUserId);
                if (docListContainsName && userListContainsUserId) {
                    matchFound = true;
                }
            });
            if (matchFound) {
                this.deleteDoc(documentId);
            }
            else {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'error',
                        message: 'You can not delete this doc',
                        variant: 'error'
                    })
                );
            }
        } else {
            this.deleteDoc(documentId);
        }
    }
    async deleteDoc(documentId) {
        console.log('documentId-->' + documentId);
        const result = await LightningConfirm.open({
            message: 'Are you sure you want to delete this file.',
            variant: 'header',
            label: 'Delete file',
            theme: 'warning',
        });
        if (result) {
            console.log('event-->')
            this.isLoading = true;
            deleteUploadedFile({ documentId: documentId })
                .then(result => {
                    this.isLoading = false;
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Success',
                            message: 'File Deleted successfully!',
                            variant: 'success'
                        })
                    );
                    this.getDocumentRecord();
                })
        }
    }

    fetchHandoverUserList() {
        getHandoverTeamUsersList({ recordId: this.recordId })
            .then(data => {
                if (data) {
                    console.log('data - ', data);
                    this.handoverTeamUsersList = data;
                }
            })
            .catch(error => {
                console.error('Error fetching record:', error);
            });
    }

    toast(title) {
        const toastEvent = new ShowToastEvent({
            title,
            variant: "success"
        })
        this.dispatchEvent(toastEvent)
    }
    handleClosePopup(event) {
        this.isModalOpen = false;
    }

    capureViewHandler() {
        this.imageDocumentId = event.target.dataset.id;
        this.isModalOpen = true;
    }

    handleCaputeOnSuccess(event) {
        this.getDocumentRecord();
        this.isModalOpen = false;
    }

    showRecordEditForm(event) {
        console.log('this.profileName', this.profileName);
        if (this.profileName === 'Leasing' && this.sObjectName == 'Handover__c') {
            getHandoverLeasingDocName({ recordId: this.recordId })
                .then(data => {
                    if (data) {
                        console.log('data - ', data);
                        let baseName = data.replace(/\d+$/, '').trim(); // Get the base name without the number
                        let number = parseInt(data.match(/\d+$/)) || 0; // Extract the number or default to 0
                        console.log('number', number);
                        console.log('baseName', baseName);
                        let newDocumentName = `${baseName} ${number + 1}`;
                        this.docName = newDocumentName;
                        console.log('Updated document name - ', newDocumentName);
                    }
                })
                .catch(error => {
                    console.error('Error fetching detail:', error);
                });

        }
        this.showDocRecModal = true;
    }
    closeDocRecModal(event) {
        this.showDocRecModal = false;
    }
    handleDocRecSuccess(event) {
        let recId = event.detail.id;
        console.log(recId);
        this.showDocRecModal = false;
        this.toast('Document record has been created.')
        if (this.profileName === 'Leasing' && this.sObjectName == 'Handover__c') {
            this.fetchHandoverUserList();
        }
        try {
            this.getDocumentRecord();
        } catch (e) {
            console.log(e.message)
        }

    }
    handleDocRecSubmit(event) {

    }

getMimeType(fileName) {
        const extension = fileName.split('.').pop().toLowerCase();
        return this.mimeTypeMap[extension] || 'application/octet-stream';
    }
   
   async handleDownload() {
        try {
            const files = await getFiles({ recordId: this.recordId });
            this.files = files.map(file => ({
                id: file.id,
                title: file.title,
                fileType: this.getMimeType(file.title),
                arrayBuffer: () => Uint8Array.from(atob(file.base64Data), c => c.charCodeAt(0)).buffer
            }));
            this.isDownloadDisabled = this.files.length === 0;
            console.log('this.files',this.files);
            this.downloadMergedPdf();
        } catch (error) {
            console.error('Error fetching files:', error);
        }
    }
    @track files = [];
    //isDownloadDisabled = true;
    pdfLibLoaded = false;





    async downloadMergedPdf() {
        if (!window.PDFLib) {
            console.error('PDF-lib is not loaded');
            return;
        }

        try {
            const pdfDoc = await window.PDFLib.PDFDocument.create();

            for (const file of this.files) {
                const fileArrayBuffer = file.arrayBuffer();

                if (file.fileType === 'application/pdf') {
                    const loadedPdf = await window.PDFLib.PDFDocument.load(fileArrayBuffer);
                    const copiedPages = await pdfDoc.copyPages(loadedPdf, loadedPdf.getPageIndices());
                    copiedPages.forEach(page => pdfDoc.addPage(page));
                } else if (file.fileType.startsWith('image/')) {
                    const imageBytes = new Uint8Array(fileArrayBuffer);
                    const image = await this.addImageToPdf(pdfDoc, imageBytes, file.fileType);
                    const page = pdfDoc.addPage([image.width, image.height]);
                    page.drawImage(image, {
                        x: 0,
                        y: 0,
                        width: image.width,
                        height: image.height
                    });
                }
            }

            const mergedPdfBytes = await pdfDoc.save();
            this.downloadBlob(new Blob([mergedPdfBytes], { type: 'application/pdf' }), 'Handover-Doc.pdf');
        } catch (error) {
            console.error('Error merging files:', error);
        }
    }

    async addImageToPdf(pdfDoc, imageBytes, fileType) {
        if (fileType === 'image/jpeg') {
            return pdfDoc.embedJpg(imageBytes);
        } else if (fileType === 'image/png') {
            return pdfDoc.embedPng(imageBytes);
        }
        throw new Error('Unsupported image format');
    }

    downloadBlob(blob, filename) {
        const link = document.createElement('a');
        link.href = URL.createObjectURL(blob);
        link.download = filename;
        link.click();
        URL.revokeObjectURL(link.href);
    }
}