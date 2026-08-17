import { LightningElement, api, track, wire } from 'lwc';
import { CloseActionScreenEvent } from 'lightning/actions';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi'; // Add getFieldValue import
import getCaseRecord from '@salesforce/apex/DocGenController.getCaseRecord';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CurrentPageReference } from 'lightning/navigation';
import generateDocument from '@salesforce/apex/DocGenController.generateDocument';
import getDocumentTypeRecords from '@salesforce/apex/DocGenController.getDocumentTypeRecords';
import sendCaseDocForSignature from '@salesforce/apex/DocGenController.sendCaseDocForSignature';
export default class CaseDocuSignGenerator extends LightningElement {
    @api recordId;
    @track selectedValues = [];
    @track isRunAllChecked = false; // To track "Run All" checkbox state
    @track isLoading = false; // To track spinner visibility
    directIndirectValue = '';
    documentList = [''];
    displayOptions = [];
    caseRecord;
   // options = [{ label: 'Send for Customer Signature (last generated)', value: 'Send for Customer Signature (last generated)' }];
   @track options = [];
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
        console.log('this.recordId ;;;;' + this.recordId);

        getCaseRecord({ recordId: this.recordId })
            .then((result) => {
                this.caseRecord = result;
                console.log('this.caseRecord ::::: ' + JSON.stringify(this.caseRecord));
            })
            .catch((error) => {
                console.error(error);
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error retrieving case record',
                        message: error.body.message,
                        variant: 'error',
                    })
                );
            });

        getDocumentTypeRecords({ recordId: this.recordId })
            .then((result) => {
                console.log('getDocumentTypeRecords result:', JSON.stringify(result));
                this.records = result; 
                this.options = [
                ...result.map(doc => ({
        label: doc.Type__c,
        value: doc.Id
    })),
    {
        label: 'Send for Signature (last generated)',
        value: 'Send for Customer Signature (last generated)'
    }
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
        this.isLoading = true;

        // Delay function that returns a promise, resolves after a specified time (in ms)
        const delay = (ms) => new Promise(resolve => setTimeout(resolve, ms));

        try {
           if (this.recordId) {

    // Check whether user selected Send for Signature
    const sendForSignature = this.selectedValues.includes(
        'Send for Customer Signature (last generated)'
    );

    // Get only the selected document types
    const selectedRecords = this.records.filter(record =>
        this.selectedValues.includes(record.Id)
    );

    console.log('selectedRecords', JSON.stringify(selectedRecords));

    // Generate each selected document
    for (const selectedRecord of selectedRecords) {

        await generateDocument({
            deliveryOptionId: selectedRecord.DeliveryOption__c,
            templateId: selectedRecord.DocGenPackage__c,
            recordId: this.recordId,
            documentName: selectedRecord.Type__c
        });
    }

    // Send generated documents for signature only if checkbox selected
    if (sendForSignature) {

        await sendCaseDocForSignature({
            caseId: this.recordId,
            documentTypeRecords: selectedRecords
        });

    }

    this.dispatchEvent(
        new ShowToastEvent({
            title: 'Success',
            message: sendForSignature
                ? 'Documents generated and sent for signature successfully.'
                : 'Documents generated successfully.',
            variant: 'success'
        })
    );

    this.dispatchEvent(new CloseActionScreenEvent());
}
        } catch (error) {
            console.error('Error processing documents:', JSON.stringify(error));
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error processing documents',
                    message: error.body && error.body.message ? error.body.message : error.message || 'An error occurred while processing documents.',
                    variant: 'error',
                })
            );
        } finally {
            this.isLoading = false;
        }
    }


    // Handle the Cancel button click
    handleCancel() {
        this.dispatchEvent(new CloseActionScreenEvent());
    }
}