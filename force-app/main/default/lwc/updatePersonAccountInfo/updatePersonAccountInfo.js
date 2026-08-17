import { LightningElement, track, wire, api } from 'lwc';
import { getRecord, updateRecord } from 'lightning/uiRecordApi';

const FIELDS = ['Opportunity.AccountId'];

const SalesOrder_FIELDS = ['SalesOrder__c.Account__c'];
import getPersonAccountApifield from '@salesforce/label/c.personAccountUpdateApiFields';


import { ShowToastEvent } from 'lightning/platformShowToastEvent';


export default class UpdatePersonAccountInfo extends LightningElement {
  @api recordId;
  @track accountId;
  @track isEditMode = false;
  accountfieldList;
  @track isOpportunity;

  connectedCallback() {
    this.accountfieldList = getPersonAccountApifield.split(',');

  }
//to get accountId from Opportunity
  @wire(getRecord, { recordId: '$recordId', fields: FIELDS })
  wiredRecord({ error, data }) {
    if (data) {
      this.accountId = data.fields.AccountId.value;
      this.isOpportunity =true;

    } else if (error) {
      // Handle error
    }
  }
  //to get accountId from Salesorder
  @wire(getRecord, { recordId: '$recordId', fields: SalesOrder_FIELDS })
  wiredSalesOrder({ error, data }) {
    if (data) {
      this.accountId = data.fields.Account__c.value;
        this.isOpportunity =false;
    } else if (error) {
      // Handle error
    }
  }

  enableEditMode() {
    this.isEditMode = true;
  }
  handleReset(event) {
    this.isEditMode = false;
  }
  customHandleSubmit(event) {
    this.template.querySelector('lightning-record-edit-form').submit();
    this.isEditMode = false;

  }
  handleSubmit(event) {
    this.isEditMode = false;

    console.log('onsubmit event recordEditForm' + event.detail.fields);
  }
  handleSuccess(event) {
    console.log('onsuccess event recordEditForm', event.detail.id);
    const toastEvent = new ShowToastEvent({
      title: 'Success',
      message: 'Account has been updated successfully!',
      variant: 'success'
    });
    this.dispatchEvent(toastEvent);
    // window.location.reload();
  }
  handleError(event){
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