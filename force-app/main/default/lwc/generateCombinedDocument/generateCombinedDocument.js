import { LightningElement, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CloseActionScreenEvent } from 'lightning/actions';
import getBrokerCommissionDocuments from '@salesforce/apex/BrokerCommissionController.getBrokerCommissionDocuments';
import attachCombinedDocument from '@salesforce/apex/BrokerCommissionController.attachCombinedDocument';
import { loadScript } from 'lightning/platformResourceLoader';
import PdfLib from '@salesforce/resourceUrl/PdfLib';
import { notifyRecordUpdateAvailable } from 'lightning/uiRecordApi';


export default class GenerateCombinedDocument extends LightningElement {

    @api recordId;
    filesToMerge;
    pdfLibInitialized = false;
    showLoading = false;
    

    connectedCallback() {
        if (this.pdfLibInitialized) {
            return;
        }

        loadScript(this, PdfLib)
            .then(() => {
                this.pdfLibInitialized = true;
            })
            .catch(error => {
                this.showErrorMessage('Failed to load PDF library');
            });
    }

    handleConfirm(){
        this.showLoading = true;
        getBrokerCommissionDocuments({recordId: this.recordId})
        .then(result=>{
            if (!result) {
                this.showLoading = false;
                this.dispatchEvent(new CloseActionScreenEvent());
                this.showErrorMessage('No documents found.');
                return;
            }
            this.filesToMerge = result;
            // Merge PDFs
            this.convertFile();
        })
        .catch(error=>{
            this.dispatchEvent(new CloseActionScreenEvent());
            this.showErrorMessage(JSON.stringify(error));
        })
    }
    async downloadFiles(mergedPdf){
        let documentName = 'Broker Invoice Combined Document';
        this.showSuccessMessage('Downloading merged PDF');
        this.downloadPdf(mergedPdf, documentName);

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

    async convertFile(){
        try {
            let pdfBuffers = this.filesToMerge.map(file =>
                this.base64ToArrayBuffer(file.base64Data)
            );

            const mergedPdf = await this.mergePdfs(pdfBuffers);

            // Try attaching to Salesforce
            await this.attachCombinedDocument(mergedPdf);               
            
        } catch (error) {
            this.showLoading = false;
            this.dispatchEvent(new CloseActionScreenEvent());
            console.error('Error in convertFile:', error);
            this.showErrorMessage('Failed to merge or attach PDF: ' + (error?.message || JSON.stringify(error)));
        }
    }

    downloadFilesIndividually() {
        this.filesToMerge.forEach(file => {
            const byteArray = this.base64ToArrayBuffer(file.base64Data);
            const blob = new Blob([byteArray], { type: 'application/pdf' });
            const url = URL.createObjectURL(blob);
            const link = document.createElement('a');
            link.href = url;
            link.download = file.fileName + '.pdf';
            link.click();
            URL.revokeObjectURL(url);
        });
    }

    async mergePdfs(pdfBuffers) {
        try {
            const { PDFDocument } = window.PDFLib;
            const mergedPdf = await PDFDocument.create();

            for (let i = 0; i < pdfBuffers.length; i++) {
                const pdfBuffer = pdfBuffers[i];
                const fileName = this.filesToMerge[i]?.fileName;

                try {
                    const pdfDoc = await PDFDocument.load(pdfBuffer);
                    const pages = await mergedPdf.copyPages(pdfDoc, pdfDoc.getPageIndices());
                    pages.forEach(page => mergedPdf.addPage(page));
                } catch (loadError) {
                    const errorMsg = (loadError?.message || '').toLowerCase();

                    if (errorMsg.includes('no pdf header')) {
                        throw new Error(`"${fileName}" is not a valid PDF file.`);
                    } else if (errorMsg.includes('encrypted') || errorMsg.includes('password')) {
                        throw new Error(`"${fileName}" is an encrypted PDF and cannot be merged.`);
                    } else {
                        console.error(`Error loading ${fileName}:`, loadError);
                    }
                }
            }

            return mergedPdf.save();

        } catch (error) {
            console.error('Error in mergePdfs:', error);
            throw error;
        }
    }


    arrayBufferToBase64(buffer) {
        return new Promise((resolve) => {
            const blob = new Blob([buffer], { type: 'application/pdf' });
            const reader = new FileReader();
            reader.readAsDataURL(blob);
            reader.onloadend = () => {
                const base64String = reader.result.split(',')[1];
                resolve(base64String);
            };
        });
    }

    async attachCombinedDocument(mergedPdf){
        try {
            const mergedPdfBase64 = await this.arrayBufferToBase64(mergedPdf);

            const result = await attachCombinedDocument({
                mergedPdf: mergedPdfBase64,
                recordId: this.recordId
            });
            await this.downloadFiles(mergedPdf);
            notifyRecordUpdateAvailable([{ recordId: this.recordId }]);
            this.showLoading = false;
            this.dispatchEvent(new CloseActionScreenEvent());
            this.showSuccessMessage(result);

        } catch (error) {
            this.showLoading = false;

            this.showErrorMessage('File too large to attach. Downloading documents separately.');

            // Download each PDF separately
            this.downloadFilesIndividually();
            this.dispatchEvent(new CloseActionScreenEvent());
        }
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

    handleCancel(){
        this.dispatchEvent(new CloseActionScreenEvent());
    }

    showErrorMessage(msg) {
        const event = new ShowToastEvent({
            title: 'Error',
            message: msg,
            variant: 'error',
            mode: 'dismissable'
        });
        this.dispatchEvent(event);
    }

    showSuccessMessage(msg) {
        const event = new ShowToastEvent({
            title: 'Success',
            message: msg,
            variant: 'success',
            mode: 'dismissable'
        });
        this.dispatchEvent(event);
    }
}