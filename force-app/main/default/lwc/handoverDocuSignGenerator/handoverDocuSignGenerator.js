import { LightningElement, api, track, wire } from 'lwc';
    import { CloseActionScreenEvent } from 'lightning/actions';
    import { getRecord, getFieldValue } from 'lightning/uiRecordApi'; // Add getFieldValue import
    import getHandoverRecord from '@salesforce/apex/DocGenController.getHandoverRecord';
    import getBrokerApplicationRecord from '@salesforce/apex/DocGenController.getBrokerApplicationRecord';
    import { ShowToastEvent } from 'lightning/platformShowToastEvent';
    import { CurrentPageReference } from 'lightning/navigation';
    import generateDocument from '@salesforce/apex/DocGenController.generateDocument';
    import getDocgenSetupRecords from '@salesforce/apex/DocGenController.getDocgenSetupRecords';
    import getDocumentTypeRecords from '@salesforce/apex/DocGenController.getDocumentTypeRecords';
    import sendHandoverDocForSignature from '@salesforce/apex/DocGenController.sendHandoverDocForSignature';

    export default class HandoverDocuSignGenerator extends LightningElement {
        @api recordId;
        @track selectedValues = [];
        @track isRunAllChecked = false; // To track "Run All" checkbox state
        @track isLoading = false; // To track spinner visibility
        directIndirectValue = '';
        documentList = [''];
        displayOptions = [];
        handoverRecord;
        options = [];
        records = [];
    
        connectedCallback() {
            setTimeout(() => {
                if (this.recordId) {
                    console.log(' recordId available:', this.recordId);
                    this.getHandoverDocumentTypeRecords();
                } else {
                    console.error(' recordId is still undefined after delay');
                }
            }, 0);
        }

        getHandoverDocumentTypeRecords() {
            this.isLoading = true;
            console.log('this.recordId ;;;;' +this.recordId);

            getHandoverRecord({ recordId: this.recordId })
                .then((result) => {
                    this.handoverRecord = result;
                    console.log('this.handoverRecord ::::: ' + JSON.stringify(this.handoverRecord));
                })
                .catch((error) => { 
                    console.error(error);
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Error retrieving Broker Application',
                            message: error.body.message,
                            variant: 'error',
                        })
                    );
                });

            getDocumentTypeRecords({ recordId: this.recordId })
                .then((result) => {
                    console.log('getDocumentTypeRecords result:', JSON.stringify(result));
                    this.records = result;

                    // Add Options from Document Type records (No filtering anymore)
                    this.options = [
                        ...result.map((doc) => ({
                            label: doc.Type__c, // Use Type__c as label
                            value: doc.Id,      // Use Id as value
                        })),
                        { label: 'Send for Customer Signature (last generated)', value: 'Send for Customer Signature (last generated)' }
                    ];
                })
                .catch((error) => {
                    console.error(error);
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Error retrieving document types',
                            message: error.body.message,
                            variant: 'error',
                        })
                    );
                })
                .finally(() => {
                    this.isLoading = false;
                });
        }


        filterOptions() {
            this.displayOptions = []; // Clear existing options
            if (this.options) {
                this.options.forEach(option => {
                });
            }
        }

        handleCheckboxChange(event) {
            const selectedValue = event.target.value;

                // Handle individual checkbox selection
                if (event.target.checked) {
                    this.selectedValues = [...this.selectedValues, selectedValue];
                } else {
                    this.selectedValues = this.selectedValues.filter((value) => value !== selectedValue);
                }
        }



        async handleGenerate() {
            if (!this.selectedValues.length || (this.selectedValues.length === 1 && this.isRunAllChecked)) {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error',
                        message: 'Please select a document type to generate the document.',
                        variant: 'error',
                    })
                );
                return;
            }

            //const selectedIds = this.selectedValues.filter((value) => value !== 'RunAll');
            const selectedIds = this.selectedValues.filter((value) => value !== 'Send for Customer Signature (last generated)');
            let sendForCustomerSignatureString = this.selectedValues.filter((value) => value === 'Send for Customer Signature (last generated)');
            //let isSendForCustomerSignature = false;
            console.log('testttt ::::: '+ sendForCustomerSignatureString);
        
            this.isLoading = true;

            // Delay function that returns a promise, resolves after a specified time (in ms)
            const delay = (ms) => new Promise(resolve => setTimeout(resolve, ms));

            try {
                if(sendForCustomerSignatureString.length > 0){
                    // Filtering the records
                    const selectedRecords = this.records.filter(record => selectedIds.includes(record.Id));
                    
                    await sendHandoverDocForSignature({handoverId: this.recordId, documentTypeRecords: selectedRecords});
                        this.dispatchEvent(
                            new ShowToastEvent({
                                title: 'Success',
                                message: 'Documents processed successfully!',
                                variant: 'success',
                            })
                        );
                        this.dispatchEvent(new CloseActionScreenEvent());
                        
            
                } else {
                    for (const selectedId of selectedIds) {
                        const selectedRecord = this.records.find((record) => record.Id === selectedId);
                        if (selectedRecord) {
                            console.log('Inside FORR ::::: ');
                            // Sequential document generation with await
                            await generateDocument({
                                deliveryOptionId: selectedRecord.DeliveryOption__c,
                                templateId: selectedRecord.DocGenPackage__c,
                                recordId: this.recordId,
                                documentName: selectedRecord.Type__c
                            });

                            // Add a 200ms delay between each callout
                            await delay(200);  // 200ms delay
                        }
                    }
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Success',
                            message: 'Documents processed successfully!',
                            variant: 'success',
                        })
                    );
                    this.dispatchEvent(new CloseActionScreenEvent());
                }
            }catch (error) {
                console.error('Error processing documents:', JSON.stringify(error));
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error processing documents',
                        message: error.body && error.body.message ? error.body.message : error.message || 'An error occurred while processing documents.',
                        variant: 'error',
                    })
                );
            }finally {
                this.isLoading = false;
            }
        }

        
        // Handle the Cancel button click
        handleCancel() {
            this.dispatchEvent(new CloseActionScreenEvent());
        }

        callSendForSignatureMethod() {
            console.log('Document sent for signature:', result);
            return new Promise((resolve, reject) => {
                sendDocumentForSignature({ recordId: this.recordId }) // Replace with your actual Apex method name
                    .then(result => {
                        console.log('Document sent for signature:', result);
                        resolve(result); // Resolve with the result from Apex
                    })
                    .catch(error => {
                        console.error('Error sending document for signature:', error);
                        reject(error); // Reject with the error from Apex
                    });
            });
        }
    }