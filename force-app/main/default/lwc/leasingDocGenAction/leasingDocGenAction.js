import { LightningElement, api, track, wire } from 'lwc';
import { CloseActionScreenEvent } from 'lightning/actions';
import { NavigationMixin } from 'lightning/navigation';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import generateDocument from '@salesforce/apex/LeasingDocGenController.generateDocument';
import getLeasingOrderRec from '@salesforce/apex/LeasingDocGenController.getLeasingOrderRec';
import getDocgenSetupRecords from '@salesforce/apex/LeasingDocGenController.getDocgenSetupRecords';

export default class LeasingDocGenAction extends NavigationMixin(LightningElement) {

    @api recordId;
    @api objectApiName;
    @track selectedValues = [];
    @track isRunAllChecked = false; // To track "Run All" checkbox state
    @track isLoading = false; // To track spinner visibility
    directIndirectValue = '';
    leadSourceValue = '';
    leadSubSourceValue = '';
    objectApiName = '';
    options = [];
    records = [];   



    // Get object metadata (e.g., apiName)
    // @wire(getObjectInfo, { objectApiName: '$objectApiName' })
    // wiredObjectInfo({ data, error }) {
    //     if (data) {
    //         console.log('Object Info:', JSON.stringify(data));
    //         // Access the apiName from the object metadata
    //         if (this.objectApiName != data.apiName) {
    //             this.objectApiName = data.apiName;
    //         }
    //         console.log('Object API Name:', this.objectApiName);
    //         // Example: Call different logic based on object type
    //         this.processBasedOnObjectType();
    //     } else if (error) {
    //         console.error('Error fetching object info:', error);
    //     }
    // }
      connectedCallback() {
        this.getDocgenSetDocumentRec();
    }

    processBasedOnObjectType() {
       
            getLeasingOrderRec({ recordId: this.recordId })
                .then(result => {
                    this.getDocgenSetDocumentRec();

                })
                .catch(error => {
                    // Handle the error here
                    console.error('Error fetching Sales Order:', error);
                });
     
    }




    // Fetch DocGen setup records and prepare options for checkboxes
    getDocgenSetDocumentRec() {
        this.isLoading = true;
        getDocgenSetupRecords({ recordId: this.recordId })
            .then((result) => {
                this.records = result;
                console.log('result ::::: ' + JSON.stringify(result));
                // Add "Run All" and filter "Broker Acknowledgement Form" if necessary
                this.options = [...result.map((doc) => ({
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
        // Handle individual checkbox selection
        if (event.target.checked) {
            this.selectedValues = [...this.selectedValues, selectedValue];
        } else {
            this.selectedValues = this.selectedValues.filter((value) => value !== selectedValue);
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
            //this.navigateToRecord();
            this[NavigationMixin.Navigate]({
                type: 'standard__recordPage',
                attributes: {
                    recordId: this.recordId,
                    objectApiName: 'LeasingOrder__c',
                    actionName: 'view'
                }
            });
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

    // Handle the Cancel button click
    handleCancel() {
       // this.dispatchEvent(new CloseActionScreenEvent());
         this.dispatchEvent(new CustomEvent('closequickaction'));
    }
}