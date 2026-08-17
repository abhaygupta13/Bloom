import { LightningElement, api, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CloseActionScreenEvent } from 'lightning/actions';
import getApplicableSubStatus from '@salesforce/apex/reUsableSubStatusController.getSubStatusValues';
//import getApplicableRejectedReason from '@salesforce/apex/reUsableSubStatusController.getRejectedSubstatusvalue';
import getSobjectDetails from '@salesforce/apex/reUsableSubStatusController.getSobjectFieldInfo';
import saveData from '@salesforce/apex/reUsableSubStatusController.updateSobjectRec';
import { getRecord, getFieldValue, getRecordNotifyChange } from 'lightning/uiRecordApi';
import CUSTOMER_SIGNED_SPA_DATE_FIELD from '@salesforce/schema/SalesOrder__c.CustomerSignedSPADate__c';
import ACCOUNTID_FIELD from '@salesforce/schema/SalesOrder__c.Account__c';
import OPPID_FIELD from '@salesforce/schema/SalesOrder__c.Opportunity__c';
import validationMsgGen from '@salesforce/apex/Utilities.genericValidationMsgGenerator';
import subStatus_SO_Validation from '@salesforce/label/c.subStatus_SO_Validation';

const fields = [CUSTOMER_SIGNED_SPA_DATE_FIELD, ACCOUNTID_FIELD, OPPID_FIELD];

export default class ReUsableSubStatusUpdate extends LightningElement {
  @api recordId;
  subStatusValues;
  @track selectedSubStatus;
  @track remarkValue;
  @track sobjectName;
  @track subStatusApiName;
  @track remarksApiName;
  @track BackupremarksApiName;
  @track customSingedspaApiName;
  @track backupRemark;
  @track rejectedResonValue;
  @track rejectReasonApiName;
  @track disableSavebutton = true;
  @track callOnce = true;
  @track nextApplicableStatusOptions = [];
  @track rejectReasonsOptions = [];
  @track sobjectConfigInfo;
  @track showRejectOption = false;
  @track isLoading = false;
  @track showSpasignDate = false;
  salesOrderData;
  @track customerSignedSpaDate;
  validationMsgValue = 'Not Allowed';

  renderedCallback() {

    if (this.recordId !== undefined && this.callOnce) {
      this.fetchApplicableSubStatus();
    }
  }
  @wire(getRecord, { recordId: '$recordId', fields })
  wiredRecord({ error, data }) {
    if (data) {
      this.salesOrderData = data;
      console.log(JSON.stringify(data))

    } else if (error) {
      console.error('Error loading record', error);
    }
  }

  fetchApplicableSubStatus() {
    getApplicableSubStatus({ recordId: this.recordId })
      .then((result) => {
        console.log(JSON.stringify(result));
        console.log(result);
        this.callOnce = false;

        if (result && result[0]) {

          if (result[0].NextApplicableStatus__c) {
            let tempArr = result[0].NextApplicableStatus__c.split(',');
            this.nextApplicableStatusOptions = tempArr.map(item => ({ label: item.trim(), value: item.trim() }));
            console.log(JSON.stringify(this.nextApplicableStatusOptions));
          } else {
            this.dispatchEvent(
              new ShowToastEvent({
                title: 'Warning!',
                message: 'Sub status master is not configured for your profile/curent sub status',
                variant: 'warning'
              })
            );

          }
          if (result[0].Reject_Reasons__c) {
            let tempArr2 = result[0].Reject_Reasons__c.split(',');
            this.rejectReasonsOptions = tempArr2.map(item => ({ label: item.trim(), value: item.trim() }));
            console.log(JSON.stringify(this.rejectReasonsOptions));
          }


        } else {
          this.dispatchEvent(new CloseActionScreenEvent());
          this.dispatchEvent(
            new ShowToastEvent({
              title: 'Warning!',
              message: 'You do not have privilege to update the status.',
              variant: 'warning'
            })
          );

        }
      })
      .catch((error) => {
        console.error('Error fetching applicable sub-status:', error);

      });
  }






  /*  @wire(getApplicableSubStatus, { recordId: '$recordId' })
    wiredApplicableSubStatus({ error, data }) {
        if (data) {
          //alert('data');
            this.subStatusValues = data;
            console.log('data: ' + JSON.stringify(data));
            console.log('this.subStatus: ' + JSON.stringify(this.subStatusValues));
        } else if (error) {
            this.subStatusValues = undefined;
        }
    }*/


  @wire(getSobjectDetails, { recordId: '$recordId' })
  SobjectDetails({ error, data }) {
    if (data) {
      // alert(data);
      this.sobjectConfigInfo = data;

      // alert(JSON.stringify(this.sobjectConfigInfo));
      this.sobjectName = data[0].MasterLabel;
      this.subStatusApiName = data[0].Sub_Status_API_Name__c;
      this.remarksApiName = data[0].Remarks_API_Name__c;
      this.BackupremarksApiName = data[0].Backup_Remarks_API_Name__c;
      this.customSingedspaApiName = data[0].SPA_signed_Date_Api_Name__c;
      this.rejectReasonApiName = data[0].Reject_Reason_Api_Name__c;
      console.log('datasobject' + JSON.stringify(this.BackupremarksApiName));

    } else if (error) {
      console.log('sobjecterror' + JSON.stringify(error));

    }
  }


  handleSubStatusChange(event) {

    if (event.target.label === 'Sub Status') {
      this.selectedSubStatus = event.target.value;
      this.customerSignedSpaDate = this.salesOrderData.fields.CustomerSignedSPADate__c.value;
      this.disableSavebutton = false;
    } else if (event.target.label === 'Remarks') {
      this.remarkValue = event.target.value;
    } else if (event.target.label === 'Rejected Reason') {
      this.rejectedResonValue = event.target.value;

    } else if (event.target.label === 'Customer Signed SPA Date') {
      this.customerSignedSpaDate = event.target.value;

    }

    const containsRejectKeyword = this.selectedSubStatus.includes("Reject");
    if (containsRejectKeyword) {
      this.showRejectOption = true;
    } else {
      this.showRejectOption = false;
    }
    const containsSpasignedKeywordv = this.selectedSubStatus === "Customer Signed SPA";
    const containscustomerSpasignedKeywordv = this.selectedSubStatus === "SPA Signed-Cheques Received";
    if (containsSpasignedKeywordv || containscustomerSpasignedKeywordv) {
      this.showSpasignDate = true;
    } else {
      this.showSpasignDate = false;
    }

  }



  async handleSubmit() {
     
    this.isLoading = true;
    if (this.sobjectName == 'SalesOrder__c'){
        
       if(subStatus_SO_Validation == 'true')
       await this.validationCheck();
      
       if(this.validationMsgValue == 'Allowed' || subStatus_SO_Validation != 'true')
       await this.handleSubmitClone();
    }else{
      this.handleSubmitClone();
    }
   
   
  }
  
   handleSubmitClone(){
    debugger;
    this.isLoading = true;
    if (this.showRejectOption && !this.rejectedResonValue) {
      this.isLoading = false;
      this.dispatchEvent(
        new ShowToastEvent({
          title: 'Error',
          message: 'Rejected Reason is mandatory for the selected Sub Status.',
          variant: 'error'
        })
      );
      return; // Stop the submission process
    }
    if (this.showSpasignDate && !this.customerSignedSpaDate) {
      this.isLoading = false;
      this.dispatchEvent(
        new ShowToastEvent({
          title: 'Error',
          message: 'Customer Signed SPA Date is mandatory for the selected Sub Status.',
          variant: 'error'
        })
      );
      return; // Stop the submission process
    }


    let obj = new Object();
    obj.sobjectType = this.sObjectName;

    obj.Id = this.recordId;
    obj[this.subStatusApiName] = this.selectedSubStatus;

    if (this.sobjectName == 'Case')
      obj[this.remarksApiName] = this.selectedSubStatus + ' : ' + this.remarkValue;
    else
      obj[this.remarksApiName] = this.remarkValue;
    obj[this.BackupremarksApiName] = this.remarkValue;
    obj[this.customSingedspaApiName] = this.customerSignedSpaDate;
    obj[this.rejectReasonApiName] = this.rejectedResonValue;
    
    
    saveData({ record: obj, sobjectConfigInfo: this.sobjectConfigInfo })
      .then(result => {        
        console.log('record' + result);       
        
        this.dispatchEvent(
          new ShowToastEvent({
            title: 'Success',
            message: 'Substatus has been changed successfully!',
            variant: 'success'
          })
        );
        
         this.isLoading = true;
         this.handleCancel();
         getRecordNotifyChange([{ recordId: this.recordId }]);
     
      })
      .catch(error => {
        console.log(error);
        // Handle any error during the data saving process
        //this.dispatchEvent(new CloseActionScreenEvent());
        //  getRecordNotifyChange([{recordId: this.recordId}]);
        this.dispatchEvent(
          new ShowToastEvent({
            title: 'Error',
            message: error.body.message,
            variant: 'error'
          })
        );
      });
  }

  handleCancel() {
    // Add your cancel button implementation here
    this.dispatchEvent(new CloseActionScreenEvent());
  }

  async validationCheck() {
    this.validationMsgValue = 'Not Allowed';
    let tempMsg1 = '';
    let tempMsg2 = '';
    //Account Check
    await validationMsgGen({ recordId: this.salesOrderData.fields.Account__c.value })
      .then(data => {

        if (data) {
          tempMsg1 = data;
        }

      }).catch(error => {
        tempMsg1 = null;

      });
    //Opportunity Check
    await validationMsgGen({ recordId: this.salesOrderData.fields.Opportunity__c.value }).then(data => {
      if (data) {
        tempMsg2 = data;
      }

    }).catch(error => {
      tempMsg2 = '';
    });

    if (tempMsg1 || tempMsg2) {
      let msg1 = tempMsg1 ? '#Account# ' + tempMsg1 : '';
      let msg2 = tempMsg2 ? '#Opportunity#: ' + tempMsg2 : '';
      this.validationMsgValue = msg1 + '\n' + msg2;

      this.dispatchEvent(
        new ShowToastEvent({
          title: 'Warning!',
          message: 'Please update ' + this.validationMsgValue,
          variant: 'warning',
          mode: 'sticky'
        })
      );

    } else {
      //console.log('log:validate else block')
      this.validationMsgValue = 'Allowed';
    }


  }
}