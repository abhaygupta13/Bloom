import { LightningElement, api, track } from "lwc";
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import modal from "@salesforce/resourceUrl/custommodalcss";
import { CloseActionScreenEvent } from "lightning/actions";
import { loadStyle } from "lightning/platformResourceLoader";
import getProjectRecordWithUnits from '@salesforce/apex/ProjectController.getProjectRecordWithUnits';
import updateUnitRegDateOnSalesOrder from '@salesforce/apex/ProjectController.updateUnitRegDateOnSalesOrder';
import getSalesOrderDocuments from '@salesforce/apex/ProjectController.getSalesOrderDocuments';
import getSalesOrderUnitDocument from '@salesforce/apex/ProjectController.getSalesOrderUnitDocument';
import uploadDocument from '@salesforce/apex/ProjectController.uploadUnitRegDocument';
import getSalesOrderRecordWithNoDocuments from '@salesforce/apex/ProjectController.getSalesOrderRecordWithNoDocuments';
import PdfLib from '@salesforce/resourceUrl/PdfLib';


export default class UnitRegistrationAction extends NavigationMixin(LightningElement) {
    projectRecordId;
    projectName;
    admRegDate;
    admRegRemark;
    @track data = [];
    selectedUnitIds;
    @track selectedRowKeys = [];
    dataTableRender = true;
    isLoading = false;
    @track totalRecords = 0; // Total number of records in the table
    @track selectedRecords = 0; // Number of selected records in the table
    @track fileData;
    activeSalesOrderId;
    isSaveButtonDisabled = true;
    filesToDownload;
    isConfirm = false;
    confirmBoxMessage;
    selectedSalesOrderId;
    pdfLibInitialized = false;
    isShowModal = false;
    selectedSalesOrderName;
    @track filesData = [];

    connectedCallback() {
        loadStyle(this, modal);
        if (!this.pdfLibInitialized) {
            const script = document.createElement('script');
            script.src = PdfLib;
            script.onload = () => {
                this.pdfLibInitialized = true;
            };
            document.body.appendChild(script);
        }
    }

    @api set recordId(value) {
        this.isLoading = true;
        this.projectRecordId = value;
        getProjectRecordWithUnits({ projectRecordId: this.projectRecordId })
            .then(res => {
                if (res) {
                    let salesOrderIds = [];
                    if (res.Name) this.projectName = res.Name + ': Unit Registration';
                    var rows = res.UnitsProject__r;
                    for (var i = 0; i < rows.length; i++) {
                        var row = rows[i];
                        row.filePreview = null;
                        row.salesOrderLink = window.location.origin + '/' + row.Active_Sales_Order__c;
                        row.unitLink = window.location.origin + '/' + row.Id;
                        salesOrderIds.push(row.Active_Sales_Order__c);
                        row.plotNumber = row.ADMPlotNumber__c ? row.ADMPlotNumber__c : null;
                        row.isFundMoved = row.Active_Sales_Order__r.FundMovedToGRDate__c ? true : false;
                        row.unitRegistrered = false;
                        row.fileName = null;
                        row.unitRegDate = null;
                        row.isChecked = false;
                        row.fileData = null;
                        if (row.Active_Sales_Order__r) {
                            if (row.Active_Sales_Order__r.Name) row.activeSalesOrderName = row.Active_Sales_Order__r.Name;
                            if (row.Active_Sales_Order__r.Status__c) row.salesOrderStatus = row.Active_Sales_Order__r.Status__c;
                            if (row.Active_Sales_Order__r.SoldDate__c) {
                                row.soldDate = this.formatDate(row.Active_Sales_Order__r.SoldDate__c.toString());
                            }
                            if (row.Active_Sales_Order__r.UnitRegistrationDate__c) {
                                row.unitRegDate = row.Active_Sales_Order__r.UnitRegistrationDate__c;
                                this.selectedRowKeys.push(row.Id);
                                row.isChecked = true;
                                row.unitRegistrered = true;
                            }
                        }
                    }
                    this.data = rows;
                    getSalesOrderRecordWithNoDocuments({ salesOrderIds: salesOrderIds })
                        .then(res => {
                            if (res) {
                                const recordIdSet = new Set(res);
                                this.data = this.data.map(record => ({
                                    ...record, // Spread existing properties
                                    isNoDocument: recordIdSet.has(record.Active_Sales_Order__c) ? true : false // Add `found` property as true/false
                                }));
                            }
                            getSalesOrderUnitDocument({ salesOrderIds: salesOrderIds })
                                .then(result => {
                                    if (result) {
                                        for (var i = 0; i < this.data.length; i++) {
                                            var row = this.data[i];
                                            let document = result[row.Active_Sales_Order__c];
                                            if (document.ContentDocumentId__c) row.filePreview = document.ContentDocumentId__c;
                                        }
                                    }
                                    this.data = this.data;
                                    this.totalRecords = this.data.length;
                                    this.selectedRecords = this.selectedRowKeys.length;
                                    this.isLoading = false;
                                })
                                .catch(error => {
                                    console.error('⛔ Error: ' + JSON.stringify(error));
                                    this.isLoading = false;
                                });
                        }).catch(err => {
                            console.error('⛔ Error: ' + JSON.stringify(err));
                            this.isLoading = false;
                        });
                }
            }).catch(err => {
                console.log('error==>', err);
                this.isLoading = false;
                this.showToast('Error', 'Error in fecthing data.', 'error');

            });
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

    get recordId() {
        return this.projectRecordId;
    }

    get acceptedFormats() {
        return ['.pdf'];
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


    handleDateChange(event) {
        let updatedDate = event.target.value;
        const recordId = event.target.dataset.id;
        this.data = this.data.map(row => {
            //console.log('row.Id==>',row.Id);
            if (row.Id === recordId) {
                return { ...row, unitRegDate: updatedDate };
            }
            return row;
        });
        this.performValidation();
    }

    handleOpenfileUpload(event) {
        this.activeSalesOrderId = event.target.dataset.salesOrderId;
        this.selectedSalesOrderName = event.target.dataset.salesOrderName;
        if (!this.activeSalesOrderId) {
            alert('Active Sales Order Id not found');
            return;
        }
        this.isShowModal = true;
        //this.template.querySelector('input[type="file"]').click();
    }

    openfileUpload(event) {
        //console.log('openfileUpload called');
        /*let files = event.target.files;
        this.filesData = [...this.filesData, ...Array.from(files)];
        event.target.value = null;*/
  
            if(event.target.files.length > 0) {
                let filename = this.selectedSalesOrderName + '.pdf';
                const file = event.target.files[0]
                var reader = new FileReader()
                reader.onload = () => {
                    var base64 = reader.result.split(',')[1]
                    this.fileData = {
                        'filename': filename,
                        'base64': base64,
                        'recordId': this.activeSalesOrderId
                    }
                }
                reader.readAsDataURL(file);
                this.filesData.push(this.fileData);
            }
    }

    handleFileUpload(event) {
        try {
            if (this.filesData.length == 0) {
                this.showToast('Error', 'Please select a file.', 'error');
                return;
            }

            // Merge PDFs
            this.isLoading = true;
            //const merged = await this.mergePdf();
            // Convert merged PDF to Base64
            //const base64Data = await this.arrayBufferToBase64(merged);
            //console.log('base64Data : ', base64Data);
            uploadDocument({ unitRegistrationDocument: JSON.stringify(this.fileData) })
                .then(res => {
                    if (res) {
                        this.data = this.data.map(row => {
                            if (row.Active_Sales_Order__c === this.activeSalesOrderId) {
                                return { ...row, filePreview: res, fileName: this.fileData.filename, fileData: this.fileData };
                            }
                            return row;
                        });
                    }
                    this.showToast('Success', this.fileData.filename + ' document attached.', 'success');
                    this.fileData = null;
                    this.isLoading = false;
                    this.filesData = [];
                    this.isShowModal = false;
                }).catch(err => {
                    this.showToast('Error', JSON.stringify(err), 'error');
                    console.error('⛔ OUTPUT: ', JSON.stringify(err));
                    this.isLoading = false;
                    this.fileData = null;
                    this.filesData = [];
                });
            this.performValidation();
        } catch (err) {
            alert('test-' + err.message);
        }
    }

    async mergePdf() {
        const { PDFDocument } = window.PDFLib;
        const mergedPdf = await PDFDocument.create();
        for (const file of this.filesData) {
            const arrayBuffer = await file.arrayBuffer();
            const pdfDoc = await PDFDocument.load(arrayBuffer);
            const pages = await mergedPdf.copyPages(pdfDoc, pdfDoc.getPageIndices());
            pages.forEach(page => mergedPdf.addPage(page));
        }

        return mergedPdf.save();
    }

    arrayBufferToBase64(buffer) {
        return new Promise((resolve, reject) => {
            const reader = new FileReader();
            reader.onload = () => resolve(reader.result.split(',')[1]);
            reader.onerror = reject;
            reader.readAsDataURL(new Blob([buffer]));
        });
    }


    performValidation() {
        this.isSaveButtonDisabled = !this.data.some(
            record => (record.fileName || record.unitRegDate) && !record.unitRegistrered
        );
    }

    onSave() {
        this.isLoading = true;
        let readyToProcessRecords = false;
        let salesOrderRecordTobeUpdated = [];
        this.data.forEach(e => {
            if (!e.unitRegistrered) {
                if (e.unitRegDate && !e.fileData) {
                    this.showToast('Error', 'Please upload unit ADM registration document on unit: ' + e.Name, 'error');
                    this.isLoading = false;
                    readyToProcessRecords = false;
                    return false;
                } else if (!e.unitRegDate && e.fileData) {
                    this.showToast('Error', 'Please fill-up registration date on unit: ' + e.Name, 'error');
                    this.isLoading = false;
                    readyToProcessRecords = false;
                    return false;
                } else if (e.unitRegDate) {
                    let tempObj = {}
                    tempObj.Id = e.Active_Sales_Order__c;
                    tempObj.ADM_DLD_Pre_Registered_Date__c = e.unitRegDate;
                    tempObj.ADM_DLD_Pre_Registered__c = 'Registered';
                    salesOrderRecordTobeUpdated.push(tempObj);
                    readyToProcessRecords = true;
                    //console.log('tempObj : ' + JSON.stringify(tempObj));
                }
            }

        });
        //console.log('salesOrderRecordTobeUpdated : ', salesOrderRecordTobeUpdated);
        if (readyToProcessRecords && salesOrderRecordTobeUpdated.length != 0) {
            updateUnitRegDateOnSalesOrder({ selectedRecords: salesOrderRecordTobeUpdated })
                .then(res => {
                    this.showToast('Success', 'Records saved successfully.', 'success');
                    this.isLoading = false;
                    this.closAction();
                }).catch(err => {
                    console.error('err-->', err);
                    this.showToast('Error', 'Error occurred, ' + JSON.stringify(err), 'error');
                    this.isLoading = false;
                });
        }
    }

    async downloadDocuments(event) {
        if (!this.pdfLibInitialized) {
            alert('PDF library is not yet initialized.');
            return;
        }
        //console.log('OUTPUT : ', event.target.dataset);
        this.selectedSalesOrderId = event.target.dataset.salesOrderId;
        if (!this.selectedSalesOrderId) {
            alert('Sales Order Id not found.');
            return;
        }
        this.isLoading = true;
        getSalesOrderDocuments({ salesOrderId: this.selectedSalesOrderId })
            .then(res => {
                //console.log('res==>'+JSON.stringify(res));
                if (!res) {
                    this.showToast('Error', 'No documents found.', 'error');
                    this.isLoading = false;
                    return;
                }
                this.filesToDownload = JSON.parse(res);
                this.confirmBoxMessage = 'These are the available documents to download: ';
                this.filesToDownload.map(file =>
                    this.confirmBoxMessage += file.title + ', '
                );
                this.isLoading = false;
                this.downloadFiles();

            }).catch(err => {
                console.error('⛔ error: ' + JSON.stringify(err));
                this.isLoading = false;
            })
    }

    async downloadFiles() {
        this.isLoading = true;
        let pdfBuffers;
        pdfBuffers = this.filesToDownload.map(file =>
            this.base64ToArrayBuffer(file.base64Data)
        );
        let documentName;
        this.data.forEach(e => {
            if (e.Active_Sales_Order__c == this.selectedSalesOrderId) {
                documentName = e.Active_Sales_Order__r.Name + '.pdf';
                return;
            }
        });
        // Merge PDFs
        const mergedPdf = await this.mergePdfs(pdfBuffers);
        this.isLoading = false;
        this.showToast('Downloading...', documentName + ' Downloading...', 'warn');
        this.downloadPdf(mergedPdf, documentName);
        this.closeConfirmBox();
    }

    base64ToArrayBuffer(base64) {
        base64 = base64.replace(/[^A-Za-z0-9+/=]/g, '');
        const binaryString = window.atob ? atob(base64) : Buffer.from(base64, 'base64').toString('binary');
        const len = binaryString.length;
        const bytes = new Uint8Array(len);
        for (let i = 0; i < len; i++) {
            bytes[i] = binaryString.charCodeAt(i);
        }
        return bytes.buffer;
    }

    async mergePdfs(pdfBuffers) {
        const { PDFDocument } = window.PDFLib;
        const mergedPdf = await PDFDocument.create();

        for (const pdfBuffer of pdfBuffers) {
            const pdfDoc = await PDFDocument.load(pdfBuffer);
            const pages = await mergedPdf.copyPages(pdfDoc, pdfDoc.getPageIndices());
            pages.forEach(page => mergedPdf.addPage(page));
        }

        return mergedPdf.save();
    }

    downloadPdf(blobData, fileName) {
        const blob = new Blob([blobData], { type: 'application/pdf' });
        const url = URL.createObjectURL(blob);
        const link = document.createElement('a');
        link.href = url;
        link.download = fileName;
        link.click();
        URL.revokeObjectURL(url);
    }

    closeConfirmBox() {
        this.isConfirm = false;
        this.confirmBoxMessage = '';
        this.filesToDownload = null;
    }
    confirmBoxYes() {
        this.downloadFiles();
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

    removeReceiptImage(event) {
        var index = event.currentTarget.dataset.id;
        this.filesData.splice(index, 1);
    }

    handleCloseModal() {
        this.isShowModal = false;
    }
}