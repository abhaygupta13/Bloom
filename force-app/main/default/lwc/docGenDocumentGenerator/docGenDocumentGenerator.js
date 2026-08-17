import { LightningElement, api, track, wire } from 'lwc';
import { CloseActionScreenEvent } from 'lightning/actions';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi'; // Add getFieldValue import
import { NavigationMixin } from 'lightning/navigation';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CurrentPageReference } from 'lightning/navigation';
import generateDocument from '@salesforce/apex/DocGenController.generateDocument';
import getSalesOrderRec from '@salesforce/apex/DocGenController.getSalesOrderRec';
import getDocgenSetupRecords from '@salesforce/apex/DocGenController.getDocgenSetupRecords';
//import updateWordsandArabicField from '@salesforce/apex/DocGenController.updateWordsandArabicField';

// Import the field
const DIRECT_INDIRECT_FIELD = 'SalesOrder__c.Direct_Indirect__c';

export default class DocGenDocumentGenerator extends NavigationMixin(LightningElement) {
    @api recordId;
    @api objectApiName;
    @track selectedValues = [];
    @track isRunAllChecked = false; // To track "Run All" checkbox state
    @track isLoading = false; // To track spinner visibility
    directIndirectValue = '';
    leadSourceValue = '';
    leadSubSourceValue = '';
    resaleSalesOrder = false;
    previousSalesOrder;
    newSalesOrder;
    objectApiName = '';
    options = [];
    records = [];

    /*@wire(getRecord, { recordId: '$recordId'})
    wiredRecord({ data, error }) {
        if (data) {
            debugger;
            console.log('Record Data:', JSON.stringify(data));
            //this.objectApiName = data.apiName;
            
            console.log('Object API Name:', this.objectApiName);
 
            // Example: Call different logic based on object type
            this.processBasedOnObjectType();
        } else if (error) {
            console.error('Error fetching record:', error);
        }
    }*/

     // Get object metadata (e.g., apiName)
     @wire(getObjectInfo, { objectApiName: '$objectApiName' })
     wiredObjectInfo({ data, error }) {
         if (data) {
             console.log('Object Info:', JSON.stringify(data));
             // Access the apiName from the object metadata
             if(this.objectApiName != data.apiName){
                this.objectApiName = data.apiName;
             }
             console.log('Object API Name:', this.objectApiName);
             // Example: Call different logic based on object type
             this.processBasedOnObjectType();
         } else if (error) {
             console.error('Error fetching object info:', error);
         }
     }

    processBasedOnObjectType() {
        console.log('this.objectApiName ::::: '+ this.objectApiName);
        if (this.objectApiName === 'SalesOrder__c') {
            console.log('this.objectApiName TWO ::::: '+ this.objectApiName);
            getSalesOrderRec({ recordId: this.recordId })
                .then(result => {
                    this.directIndirectValue = result.Direct_Indirect__c;
                    this.leadSourceValue = result?.Opportunity__r?.Lead__r?.LeadSource || '';
                    this.leadSubSourceValue = result?.Opportunity__r?.Lead__r?.leadsubsource__c || '';
                    this.resaleSalesOrder = result?.Resale__c;
                    this.previousSalesOrder = result?.PreviousSalesOrder__c;
                    this.newSalesOrder = result?.NewSalesOrder__c;

                    // Handle the result here
                    if( this.directIndirectValue){
                        this.getDocgenSetDocumentRec(); 
                    }
                })
                .catch(error => {
                    // Handle the error here
                    console.error('Error fetching Sales Order:', error);
                });
                
        } else if (this.objectApiName === 'Handover__c' || this.objectApiName === 'BrokerApplication__c' || this.objectApiName === 'Case' || this.objectApiName === 'Account') {
            console.log('Processing for ::::: '+ this.objectApiName);
            this.getDocgenSetDocumentRec(); 
        } else {
            console.log('No matching object type logic.');
        }
    }


    // Fetch the SalesOrder's Direct_Indirect__c field value
   /*  @wire(getRecord, { recordId: '$recordId', fields: [DIRECT_INDIRECT_FIELD] })
    salesOrder({ error, data }) {
        if (data) {
            if(this.directIndirectValue){
 this.directIndirectValue = getFieldValue(data, DIRECT_INDIRECT_FIELD);
            }
           
            // Trigger fetching DocGen setup records once the field value is available
            this.getDocgenSetDocumentRec(); 
        } else if (error) {
            console.error('Error fetching SalesOrder:', error);
        }
    } */

    // Fetch DocGen setup records and prepare options for checkboxes
    getDocgenSetDocumentRec() {
        this.isLoading = true;
        getDocgenSetupRecords({ recordId: this.recordId })
            .then((result) => {
                this.records = result;

                // Add "Run All" and filter "Broker Acknowledgement Form" if necessary
                this.options = [
                    { label: 'Run All', value: 'RunAll' },
                    ...result
                        .filter((doc) => {
                            // Exclude "Broker Acknowledgement Form" if Direct_Indirect__c is "Direct"
                            //return !(doc.Type__c === 'Broker Acknowledgement Form' && this.directIndirectValue === 'Direct');

                            if(this.resaleSalesOrder){
                                 //Check if Resale Old Sales Order
                                const isResaleOldSalesOrder = doc.Type__c === 'Lost SPA Undertaking' && (this.resaleSalesOrder && this.newSalesOrder === undefined);
                                //Check if Resale New Sales Order
                                const isResaleNewSalesOrder = doc.Type__c === 'CIF' && (this.resaleSalesOrder && this.previousSalesOrder === undefined);

                                return !isResaleOldSalesOrder && !isResaleNewSalesOrder;
                            } else {
                                const isBrokerAckExcluded = doc.Type__c === 'Broker Acknowledgement Form' && this.directIndirectValue === 'Direct';
                                // Filter conditions for lead source and subsource
                                const isLeadSourceReferral = doc.Type__c === 'Referral Letter' && (this.leadSourceValue !== 'Referral' || this.leadSubSourceValue !== 'CustomerReferral');
                                return !isBrokerAckExcluded && !isLeadSourceReferral;
                            }
                        })
                        .map((doc) => ({
                            label: doc.Type__c, // Use Type__c as label
                            value: doc.Id, // Use Id as value
                        })),
                ];
            })
            .catch((error) => {
                console.error(error);
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error retrieving documents',
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

    if (selectedValue === 'RunAll' && event.target.checked) {
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
    } else {
        // Handle individual checkbox selection
        if (event.target.checked) {
            this.selectedValues = [...this.selectedValues, selectedValue];
        } else {
            this.selectedValues = this.selectedValues.filter((value) => value !== selectedValue);
        }

        // If any checkbox other than "Run All" is unchecked, uncheck "Run All"
        if (!this.options.every((opt) => opt.value === 'RunAll' || this.selectedValues.includes(opt.value))) {
            this.isRunAllChecked = false;
            const runAllCheckbox = this.template.querySelector('lightning-input[value="RunAll"]');
            if (runAllCheckbox) {
                runAllCheckbox.checked = false;
            }
        }
    }
}


    // Handle the Generate button click
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

        const selectedIds = this.selectedValues.filter((value) => value !== 'RunAll');
        this.isLoading = true;

        // Delay function that returns a promise, resolves after a specified time (in ms)
        const delay = (ms) => new Promise(resolve => setTimeout(resolve, ms));

        try {
            for (const selectedId of selectedIds) {
                const selectedRecord = this.records.find((record) => record.Id === selectedId);
                if (selectedRecord) {
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
                    message: 'Documents generated successfully!',
                    variant: 'success',
                })
            );
            this.navigateToRecord();
        } catch (error) {
            console.error('Error generating documents:', error);
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error generating documents',
                    message: error.body && error.body.message ? error.body.message : error.message || 'An error occurred while generating documents.',
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
}