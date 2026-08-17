import { LightningElement, api, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CurrentPageReference } from 'lightning/navigation';
import uploadFiles from '@salesforce/apex/LeasingSiteController.uploadFiles';
import getOpportunity from '@salesforce/apex/LeasingSiteController.getOpportunity';

export default class LeasingDocumentsUploadComponent extends LightningElement {
    @api oppencodeId;
    oppIdFromURL;
    isUploadDisabled = true;
    isUploading = false;
    statusMessage = '';
    showSuccessMessage = false;
    @track isPersonCustomer = false;

    @track potentialTenantDocuments = [
        { label: "Salary Certificate", value: "Salary Certificate", uploadedFile: null },
        { label: "Passport", value: "Passport", uploadedFile: null },
        { label: "Credit Report", value: "Credit Report", uploadedFile: null },
        { label: "Visa", value: "Visa", uploadedFile: null },
        { label: "Emirates Id", value: "Emirates Id", uploadedFile: null }
    ];
    @track potentialOrganizationDocuments = [
        { label: "POA Passport", value: "POA Passport", uploadedFile: null },
        { label: "POA Visa", value: "POA Visa", uploadedFile: null },
        { label: "Trade License", value: "Trade License", uploadedFile: null },
        { label: "POA EID", value: "POA EID", uploadedFile: null }
    ];
    @wire(CurrentPageReference)
    getStateParameters(currentPageReference) {
        if (currentPageReference) {
            this.oppIdFromURL = currentPageReference.state?.oppid || null;
            console.log('AJ- Oppid ::', this.oppIdFromURL);
            if (!this.oppencodeId) {
                this.oppencodeId = this.oppIdFromURL; // Set recordId if not passed directly
            }
            if (this.oppIdFromURL) {
                this.fetchOpportunity(this.oppIdFromURL);
            }
        }
    }

    fetchOpportunity(oppId) {
        getOpportunity({ opportunityId: oppId })
            .then(result => {
                console.log('AJ - Opportunity:', result);
                this.isPersonCustomer = result?.Account?.IsPersonAccount || false;
            })
            .catch(error => {
                console.error('Error fetching opportunity:', error);
            });
    }

    isConfirmed = false;

    handleCheckboxChange(event) {
        this.isConfirmed = event.target.checked;
        // Optional: dispatch event or handle validation
    }

    connectedCallback() {
        console.log('Opportunity IDoppencodeId:::::', this.oppencodeId);
    }


    handleFileUpload(event) {
        const { identifier, filename, base64, type, subidentifier } = event.detail;
        if (identifier === 'Pets') {
            //  this.petDocuments = [...this.petDocuments, { filename, base64, type, uploadedFile: { filename, base64, type }, value: 'Pet_' }];
        } else if (subidentifier) {

        } else {
            this.updateUploadedFile(identifier, { filename, base64, type });
        }
        this.isUploadDisabled = false;
    }

    handleFileRemove(event) {
        const { identifier, subidentifier } = event.detail;

        this.updateUploadedFile(identifier, null);

        this.isUploadDisabled = this.checkIfNoFilesUploaded();
    }



    async handleUpload() {
        this.isUploading = true;
        let allFiles = [...this.potentialTenantDocuments, ...this.potentialOrganizationDocuments]
            .filter(doc => doc.uploadedFile);
        if (allFiles.length === 0) {
            this.statusMessage = 'Please select at least one file to upload.';
            this.showToast('Error', 'Please select at least one file to upload.', 'error');
            this.isUploading = false;
            return;
        }

        this.showToast('Uploading', 'Uploading files, please wait...', 'info');

        try {

        let filesToSend = allFiles.map(doc => ({
            fileName: doc.uploadedFile.filename,
            fileData: doc.uploadedFile.base64,
            category: doc.value
        }));

        await uploadFiles({ recordId: this.oppencodeId, files: filesToSend });


            this.showToast('Success', 'All files uploaded successfully!', 'success');
            this.showSuccessMessage = true;


            this.potentialTenantDocuments = [];
            this.potentialOrganizationDocuments = [];

            this.statusMessage = 'All documents have been successfully uploaded!';
            //this.isUploading = false;

        } catch (error) {
            this.isUploading = false;
            this.statusMessage = 'File upload failed. Please try again.';
            this.showToast('Error', 'File upload failed. Please try again.', 'error');
            console.error(error);
        }
        finally {
        this.isUploading = false;
    }
    }

    // async uploadFileToSalesforce(fileName, base64Data, docType) {
    //     return uploadFile({ recordId: this.oppencodeId, fileName, fileData: base64Data, category: docType });
    // }

    updateUploadedFile(identifier, fileData) {
        if (this.isPersonCustomer) {
            this.potentialTenantDocuments = this.potentialTenantDocuments.map(doc =>
                doc.value === identifier ? { ...doc, uploadedFile: fileData } : doc
            );
        } else {

            this.potentialOrganizationDocuments = this.potentialOrganizationDocuments.map(doc =>
                doc.value === identifier ? { ...doc, uploadedFile: fileData } : doc
            );
        }
    }

    checkIfNoFilesUploaded() {
        if (this.isPersonCustomer) {
            return ![
                ...this.potentialTenantDocuments
            ].some(doc => doc);
        } else {
            return ![
                ...this.potentialOrganizationDocuments
            ].some(doc => doc);
        }
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }
}