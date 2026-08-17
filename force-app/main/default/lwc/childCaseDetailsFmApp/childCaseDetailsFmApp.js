import { LightningElement, track, wire,api } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import getCaseDetails from '@salesforce/apex/SearchControllerFmApp.getchildCases';

export default class ChildCaseDetailsFmApp extends LightningElement {
    @api caseId; // Received from parent component
    @track caseRecords = []; // Stores retrieved case records
    @track error; // Error handling
    @track isLoading = true; // Show loader if needed
    @track  showDocumentModal=false;
    @track  childcaseId;
    

    // Define columns for lightning-datatable
    columns = [
    { label: 'Emirates ID', fieldName: 'Visitor_Emirates_ID__c', type: 'text' },
    { label: 'Mobile Number', fieldName: 'Visitor_Mobile_Number__c', type: 'text' },
    { label: 'Vehicle Plate Number', fieldName: 'Visitor_Plate_Number__c', type: 'text' },
    {
        label: 'Check-In Time',
        fieldName: 'Visitor_Check_in_Time__c',
        type: 'date',
        typeAttributes: {
            year: 'numeric',
            month: 'long',
            day: '2-digit',
            hour: '2-digit',
            minute: '2-digit',
            timeZone: 'UTC',
        },
    },
    {
        label: 'Check-Out Time',
        fieldName: 'Visitor_Checkout_Time__c',
        type: 'date',
        typeAttributes: {
            year: 'numeric',
            month: 'long',
            day: '2-digit',
            hour: '2-digit',
            minute: '2-digit',
            timeZone: 'UTC',
        },
    },
    {
        label: 'Document Link',
        fieldName: 'DocumentURL',
        type: 'button',
        typeAttributes: {
            label: 'View Document',
            name: 'view_document',
            variant: 'brand',
            onrowaction: this.handleRowAction
        }
    }
];
    // Fetch Case ID from the URL
    @wire(CurrentPageReference)
    getPageReference(currentPageReference) {
        if (currentPageReference && currentPageReference.attributes.recordId) {
            this.caseId = currentPageReference.attributes.recordId;
            this.fetchCaseDetails();
        }
    }
    handleRowAction(event) {
   
        const actionName = event.detail.action.name;
        const row = event.detail.row;
      
        if (actionName === 'view_document') {
            this.selectedDocumentUrl = row.DocumentURL; // Store document URL
            this.showDocumentModal = true; // Open modal
            this.childcaseId = row.Id; 
        }
        this.showDocumentModal == true; // Open modal
    }

    // Fetch child cases using Apex
    async fetchCaseDetails() {
        if (!this.caseId) {
            this.error = 'Case ID is not available in the URL.';
            return;
        }
        try {
            this.isLoading = true;
            this.caseRecords = await getCaseDetails({ parentcaseId: this.caseId });
        } catch (error) {
            this.error = 'Error fetching case details';
            console.error(error);
        } finally {
            this.isLoading = false;
        }
    }
}