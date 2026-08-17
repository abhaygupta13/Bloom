import { LightningElement, api, track, wire } from 'lwc';
import { CloseActionScreenEvent } from 'lightning/actions';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi'; // Add getFieldValue import
import getSalesOrderRecord from '@salesforce/apex/DocGenController.getSalesOrderRecord';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';
import generateDocument from '@salesforce/apex/DocGenController.generateDocument';
import getDocgenSetupRecords from '@salesforce/apex/DocGenController.getDocgenSetupRecords';
import getDocumentTypeRecords from '@salesforce/apex/DocGenController.getDocumentTypeRecords';
//import updateWordsandArabicField from '@salesforce/apex/DocGenController.updateWordsandArabicField';
import sendForSignature from '@salesforce/apex/DocGenController.sendForSignature';

// Import the field
const DIRECT_INDIRECT_FIELD = 'SalesOrder__c.Direct_Indirect__c';
export default class DocuSignDocGenerator extends NavigationMixin(LightningElement) {
    @api recordId;
    @track selectedValues = [];
    @track isRunAllChecked = false; // To track "Run All" checkbox state
    @track isLoading = false; // To track spinner visibility
    directIndirectValue = '';
    documentList = [''];
    displayOptions = [];
    salesOrder;
    options = [];
    records = [];

    // Fetch the SalesOrder's Direct_Indirect__c field value
    @wire(getRecord, { recordId: '$recordId', fields: [DIRECT_INDIRECT_FIELD] })
    salesOrder({ error, data }) {
        if (data) {
            this.directIndirectValue = getFieldValue(data, DIRECT_INDIRECT_FIELD);
            // Trigger fetching DocGen setup records once the field value is available
            this.getDocgenSetDocumentRec(); 
        } else if (error) {
            console.error('Error fetching SalesOrder:', error);
        }
    }

    // Fetch DocGen record and prepare options for checkboxes
    getDocgenSetDocumentRec() {
        this.isLoading = true;
        getSalesOrderRecord({ recordId: this.recordId })
        .then((result) => {
            this.salesOrder = result;
            console.log('this.salesOrder ::::: '+JSON.stringify(this.salesOrder));
        })
        .catch((error) => {
            console.error(error);
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error retrieving Sales Order',
                    message: error.body.message,
                    variant: 'error',
                })
            );
        });
        /*.finally(() => {
            this.isLoading = false;
        });*/

        getDocumentTypeRecords({ recordId: this.recordId })
            .then((result) => {
                this.records = result;

                // Add Otions from Document Type records
                this.options = [ 
                    ...result
                        .filter((doc) => {
                            // Exclude "Broker Acknowledgement Form" if Direct_Indirect__c is "Direct"
                            return !(doc.Type__c === 'Signature Broker Acknowledgement Form' && this.directIndirectValue === 'Direct');
                        })
                        .map((doc) => ({
                            label: doc.Type__c, // Use Type__c as label
                            value: doc.Id, // Use Id as values
                        })),
                    { label: 'Send for Signature (last generated)', value: 'Send for Customer Signature (last generated)' }/*,
                    { label: 'Send Email to Customer (cc to you)', value: 'Send Email to Customer (cc to you)' },
                    { label: 'Send Email to Me', value: 'Send Email to Me'}*/
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
                /*if (option.label == 'Book, CIS, Disclosure and MCD Arabic')) {
                    this.displayOptions.push({ ...option });
                }*/
            });
        }
    }

    handleCheckboxChange(event) {
        const selectedValue = event.target.value;

        /*if (selectedValue === 'RunAll' && event.target.checked) {
            // Select all values, including Run All
            this.selectedValues = [             
                'RunAll',
                ...this.options.filter((opt) => opt.value !== 'RunAll').map((opt) => opt.value),
            ];
            this.isRunAllChecked = true;

            // Programmatically check all checkboxes in the DOM
            const checkboxes = this.template.querySelectorAll('lightning-input');
            checkboxes.forEach((checkbox) => {
                checkbox.checked = true;
            });
        } else if (selectedValue === 'RunAll' && !event.target.checked) {
            // Deselect all values, including Run All
            this.selectedValues = [];
            this.isRunAllChecked = false;

            // Programmatically uncheck all checkboxes in the DOM
            const checkboxes = this.template.querySelectorAll('lightning-input');
            checkboxes.forEach((checkbox) => {
                checkbox.checked = false;
            });
        } else {*/
            // Handle individual checkbox selection
            if (event.target.checked) {
                this.selectedValues = [...this.selectedValues, selectedValue];
            } else {
                this.selectedValues = this.selectedValues.filter((value) => value !== selectedValue);
            }

            // If any checkbox other than "Run All" is unchecked, uncheck "Run All"
            /*if (!this.options.every((opt) => opt.value === 'RunAll' || this.selectedValues.includes(opt.value))) {
                this.isRunAllChecked = false;
                const runAllCheckbox = this.template.querySelector('lightning-input[value="RunAll"]');
                if (runAllCheckbox) {
                    runAllCheckbox.checked = false;
                }
            }
        }*/
    }

    // Handle the Generate button click
    /*handleGenerate() {
        if (!this.selectedValues.length || (this.selectedValues.length === 1 && this.isRunAllChecked)) {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: 'Please select at least one document type.',
                    variant: 'error',
                })
            );
            return;
        }

        // Remove "Run All" from the selected values if it is present
        //const selectedIds = this.selectedValues.filter((value) => value !== 'RunAll');
        const selectedIds = this.selectedValues.filter((value) => value !== 'Send for Customer Signature (last generated)');
        let sendForCustomerSignatureString = this.selectedValues.filter((value) => value === 'Send for Customer Signature (last generated)');
        let isSendForCustomerSignature = false;
        console.log('testttt ::::: '+ sendForCustomerSignatureString);
        if(sendForCustomerSignatureString.length > 0){
            isSendForCustomerSignature = true;
        }
        console.log('isSendForCustomerSignature ::::: '+ isSendForCustomerSignature);
        this.isLoading = true;

        if(sendForCustomerSignatureString.length > 0){
            sendForSignature({ salesOrderRec: this.salesOrder, documentTypeIds: selectedIds})
            .then((result) => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Success',
                        message: 'Documents processed successfully!',
                        variant: 'success',
                    })
                );
            })
            .catch((error) => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error processing documents',
                        message: error.message || 'An error occurred while generating documents.',
                        variant: 'error',
                    })
                );
            })
            .finally(() => {
                this.isLoading = false;
            });
        } else {
            const promises = selectedIds.map((selectedId) => {
                const selectedRecord = this.records.find((record) => record.Id === selectedId);
                    if (selectedRecord) {
                        if (selectedRecord.Type__c === 'Cancellation & Termination Agreement') {
                            return updateWordsandArabicField({ recordId: this.recordId })
                                .then(() => {
                            // Generate document after updating fields
                                    return generateDocument({
                                        deliveryOptionId: selectedRecord.DeliveryOption__c,
                                        templateId: selectedRecord.DocGenPackage__c,
                                        recordId: this.recordId,
                                        documentName: selectedRecord.Type__c
                                    });
                                })
                                .catch((error) => {
                                    console.error('Error updating fields for ${selectedRecord.Type__c}:', error);
                                    throw new Error('Error updating words and Arabic field.');
                                });
                        } else {
                    // Directly generate document for other types
                            return generateDocument({
                                deliveryOptionId: selectedRecord.DeliveryOption__c,
                                templateId: selectedRecord.DocGenPackage__c,
                                recordId: this.recordId,
                                documentName: selectedRecord.Type__c
                            });
                        }
                    }
                    return Promise.resolve(); // Handle cases where no matching record is found
            });
            
            Promise.all(promises)
            .then(() => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Success',
                        message: 'Documents processed successfully!',
                        variant: 'success',
                    })
                );
            })
            .catch((error) => {
                console.error(error);
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error processing documents',
                        message: error.message || 'An error occurred while generating documents.',
                        variant: 'error',
                    })
                );
            })
            .finally(() => {
                this.isLoading = false;
            });
        }
    }*/


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
        /*if(sendForCustomerSignatureString.length > 0){
            isSendForCustomerSignature = true;
        }
        console.log('isSendForCustomerSignature ::::: '+ isSendForCustomerSignature);*/
        this.isLoading = true;

        // Delay function that returns a promise, resolves after a specified time (in ms)
        const delay = (ms) => new Promise(resolve => setTimeout(resolve, ms));

        try {
            if(sendForCustomerSignatureString.length > 0){
                // Filtering the records
                const selectedRecords = this.records.filter(record => selectedIds.includes(record.Id));
                console.log('selectedRecords ::::: '+ JSON.stringify(selectedRecords));
                /*for (const selectedId of selectedIds) {
                    const selectedRecord = this.records.find((record) => record.Id === selectedId);
                    if (selectedRecord) {
                        console.log('Inside FORR ::::: ');
                    }
                }*/
                await sendForSignature({ salesOrderRec: this.salesOrder, documentTypeRecords: selectedRecords});
                //.then((result) => {
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Success',
                            message: 'Documents processed successfully!',
                            variant: 'success',
                        })
                    );
                    this.navigateToRecord();
                /*})
                .catch((error) => {
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Error processing documents',
                            message: error.message || 'An error occurred while generating documents.',
                            variant: 'error',
                        })
                    );
                })
                .finally(() => {
                    this.isLoading = false;
                });*/
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
                this.navigateToRecord();
            }
        } catch (error) {
            console.error('Error processing documents:', error);
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error processing documents',
                    message: error.message || 'An error occurred while processing documents.',
                    variant: 'error',
                })
            );
        } finally {
            this.isLoading = false;
        }
    }

    navigateToRecord(){
        console.log('navigate to rec in action', this.recordId);
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId:this.recordId,
                actionName: 'view'
            }
        });
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