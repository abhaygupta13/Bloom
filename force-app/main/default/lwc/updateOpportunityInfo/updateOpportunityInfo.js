import { LightningElement, api, wire, track } from 'lwc';
import getOpportunityApiFields from '@salesforce/label/c.opportunityUpdateApiFields';
import { getRecord, updateRecord } from 'lightning/uiRecordApi';

const FIELDS = ['SalesOrder__c.Opportunity__c'];


import { ShowToastEvent } from 'lightning/platformShowToastEvent';
export default class UpdateOpportunityInfo extends LightningElement {
  @api recordId;
  @api salesOrderId;
  @track isEditMode = false;
  opportunityfieldList;
  @track opportunityId;

  connectedCallback() {
    this.opportunityfieldList = getOpportunityApiFields.split(',');


  }
  @wire(getRecord, { recordId: '$recordId', fields: FIELDS })
  wiredRecord({ error, data }) {
    if (data) {

      this.opportunityId = data.fields.Opportunity__c.value;

      this.recordId = this.opportunityId;

    } else if (error) {
      // Handle error
    }
  }

  enableEditMode() {
    this.isEditMode = true;
  }

  handleSuccess(event) {
    console.log('onsuccess event recordEditForm', event.detail.id);
    const toastEvent = new ShowToastEvent({
      title: 'Success',
      message: 'Opportunity updated successfully!',
      variant: 'success'
    });
    this.dispatchEvent(toastEvent);
    // window.location.reload();
  }

  handleSubmit(event) {
    this.isEditMode = false;
    console.log('onsubmit event recordEditForm' + event.detail.fields);
  }

  handleReset() {
    this.isEditMode = false;
  }
  customHandleSubmit(event) {
    this.template.querySelector('lightning-record-edit-form').submit();
    this.isEditMode = false;

  }
  handleError(event) {
    this.isEditMode = true;
    console.log(JSON.stringify(event.detail.detail))
    const toastEvent = new ShowToastEvent({
      title: 'Error',
      message: event.detail.detail,
      variant: 'error'
    });
    this.dispatchEvent(toastEvent);
  }
}