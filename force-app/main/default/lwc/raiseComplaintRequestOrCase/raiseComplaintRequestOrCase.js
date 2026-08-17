import { LightningElement, api, track, wire } from 'lwc';
import { createRecord, getRecordNotifyChange } from 'lightning/uiRecordApi';
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getSalesorderStatus from '@salesforce/apex/reUsableSubStatusController.getSalesOrderStatus';
import getCaseRecordType from '@salesforce/apex/RaiseServiceRequestHandler.getCaseRecordTypes';
import createCaseComplaint from '@salesforce/apex/RaiseServiceRequestHandler.createCaseComplaint';
import getPicklistfieldValue from '@salesforce/apex/RaiseServiceRequestHandler.getPicklistFieldValueOnCaseRecordType';
import getDefaultUserOnCaseSubType from '@salesforce/apex/RaiseServiceRequestHandler.getDefaultUserOnCaseSubType';
import getSalesordetail from '@salesforce/apex/CustomLookup.getSalesordetail';
import getSalesordetailonLoad from '@salesforce/apex/RaiseServiceRequestHandler.getSalesordetailonRecord';
import Caseduplicatecheck from '@salesforce/apex/RaiseServiceRequestHandler.caseduplicationcheck';

export default class RaiseCase extends NavigationMixin(LightningElement) {

    @api recordId;
    recordTypeOptions = [];
    caseTypeOptions = []; // To hold case type options based on selected record type
    caseReasonTypeOptions = [];
    error;
    caseType;
    descriptionValue
    reasonValue
    internalCommentValue

    selectedRecordTypeId;
    salesorderStatus;
    showError = false
    isLoading = false;
    showErrorforCaseSubtype = false;
    casematuritydate = false;
    showSubmitBtn = false;
    showNextBtn = false;
    showRecpAckEntry = false;
    errorMessageonReceipt = false;
    @track selectedReceipts = [];
    next = false;
    @track receiptList;
    @track Servicerq;
    @track error;
    @api caseinfo;
    submitButtondisable = true;
    AccountId
    MaturityDatevald = true;
    lookupSalesorderid;
    showforwardbtn = false;
    accountName;
    showDefaultOwner = false;
    caseSubtypes
    caseReasons;
    ownerValue
    salesootherchargeAmount;
    salesootherchargeTypecharge;
    caseSubstatus;
    caseStatus;
    accountdisabled = true;
     mobilePhonevalue;
    emailValue;
    accountNamevalue;
    salesorderName;
    showLookupAccountName=true;
    fields = ['MaturityDate__c', 'ReferenceNumber__c', 'Amount__c'];
    @track duplicatecaserecords;
    @track showOneDuplicateCaseRecord=false;
    @track showAllDuplicateCases=false;
    isduplicatefound = false;



    renderedCallback() {
    if (this.recordId) {
     getSalesordetailonLoad({salesorderId:this.recordId})
     .then(result=>{

         this.salesorderName =result[0].Name;
         
        this.accountNamevalue = result[0].Account__r.Name;
                this.mobilePhonevalue=result[0].Account__r.PersonMobilePhone;
                this.emailValue= result[0].Account__r.PersonEmail;
     })
     .catch(error => {
                this.error = error;
            })
    }
}


    @wire(getCaseRecordType)
    caseRecordInfo({ error, data }) {
        if (data) {


            // Filter record types based on the description containing "complaint"
            this.recordTypeOptions = data.filter(recordType =>
                recordType.MasterLabel && recordType.MasterLabel.toLowerCase().includes('complaint')
            ).map(filteredRecordType => ({
                label: filteredRecordType.Case_Type__c,
                value: filteredRecordType.Case_Type__c
            }));
            this.showSubmitBtn = true;
        } else if (error) {
            this.error = error;
            console.error('Error retrieving Case record types:', error);
        }
    }

     clearRaiseCase(){
      this.selectedRecordTypeId='';
      this.caseType='';
      this.descriptionValue='';
      this.internalCommentValue='';
      this.reasonValue='';
      this.ownerValue='';
       this.personMObilleNumber='';
      this.personEmail='';
      this.showDefaultOwner=false;
       this.showLookupAccountName=false;
     this.template.querySelector("c-custom-lookup").handleRemove();

    }

    callPickListfieldvalues() {
        console.log(this.selectedRecordTypeId);
        getPicklistfieldValue({ selectedRecordTypeId: this.selectedRecordTypeId })
            .then(result => {

                let tempArr = result[0].Case_Sub_Type__c.split(',');
                this.caseSubtypes = tempArr.map(item => ({ label: item.trim(), value: item.trim() }));
                let tempArrReson = result[0].Case_Reason__c.split(',');
                this.caseReasons = tempArrReson.map(item => ({ label: item.trim(), value: item.trim() }));


                this.caseStatus = result[0].Case_status__c;
                this.caseSubstatus = result[0].Case_Sub_Status__c;

                this.salesootherchargeTypecharge = result[0].Default_Charge_Type__c;

                this.salesootherchargeAmount = result[0].Default_Charge_Amount__c;


            }).catch(error => {
                this.error = error;
            })
    }

     
getduplicatecases(){
    Caseduplicatecheck({ salesorderId: this.recordId,casetype: this.selectedRecordTypeId,casesubtype: this.caseType })
    .then(result => {
     console.log(result);
      if(result.length >0){
           this.isduplicatefound = true;
        this.duplicatecaserecords = result;
        if(this.duplicatecaserecords.length===1){
            this.showOneDuplicateCaseRecord=true;
            this.showAllDuplicateCases=false;
        }else if(this.duplicatecaserecords.length>1){
             this.showAllDuplicateCases=true;
              this.showOneDuplicateCaseRecord=false;
        }
       
       }
      
    }).catch(error => {
        console.error(error);

    })
}
navigateToRecordPage(event) {
   
    this[NavigationMixin.GenerateUrl]({
        type: 'standard__recordPage',
        attributes: {
            recordId: event.target.dataset.id,
            objectApiName: 'Case',
            actionName: 'view'
        }
    }).then(url => {
        window.open(url, "_blank");
    });
}

    get isSubTypeDisabled() {
        return !this.selectedRecordTypeId; // Disable if no Case Type is selected
    }


    callFetchDefaultOwner() {
        getDefaultUserOnCaseSubType({ selectedRecordType: this.selectedRecordTypeId, caseSubtype: this.caseType })
            .then(result => {

                this.ownerValue = result[0].Default_Owner__c;

            }).catch(error => {
                this.error = error;
            })
    }

    handleCaseTypeChange(event) {
        if (event.target.name == 'Request Sub Type') {
            this.showDefaultOwner = true;
            this.caseType = event.target.value;
            this.callFetchDefaultOwner();
             this.getduplicatecases();
              this.isduplicatefound = false;

            //  this.callFinancialPostdeferment();
        } else if (event.target.name == 'Description') {
            this.descriptionValue = event.target.value;
        }
        else if (event.target.name == 'Reasons') {
            this.reasonValue = event.target.value;
        }
        else if (event.target.name == 'Internal Comments') {
            this.internalCommentValue = event.target.value;
        }

        




    }
    handleRecordTypeChange(event) {
        this.selectedRecordTypeId = event.target.value;

        this.showError = false;
        this.showNextBtn = false;
        this.callPickListfieldvalues();
        if (this.selectedRecordTypeId) {
            this.submitButtondisable = false;
        } else {
            this.submitButtondisable = true;
        }
    }

    handleSubmitActions() {
        this.createCase();
    }

    createCase() {
        getRecordNotifyChange([{ recordId: this.recordId }]);
        
          let caseSalesorderId;
     

        if (this.recordId == undefined || this.recordId == '') {
             caseSalesorderId = this.lookupSalesorderid;
        }else{
             caseSalesorderId=this.recordId;
        }     
        
           getSalesorderStatus({ salesOrderId:caseSalesorderId })
            .then(result => {

                if (result === 'Sold') {
                    
                    let SalesOOtherObj = new Object();
                    SalesOOtherObj.sobjectType = 'SalesOrderOtherCharges__c';

                    SalesOOtherObj.SalesOrder__c = caseSalesorderId;

                    SalesOOtherObj.TypeOfCharge__c = this.salesootherchargeTypecharge;
                    SalesOOtherObj.Amount__c = this.salesootherchargeAmount;

                     let hasError=false;
                    let hasTypeError=false;

                    let subTypeCmp = this.template.querySelector(".requestSubtypeCmp");
                    if(!this.caseType){
                      
                        subTypeCmp.setCustomValidity("Request Sub Type value is required");
                        subTypeCmp.reportValidity();
                        
                        hasTypeError=true;


                    }else{
                     
                        subTypeCmp.setCustomValidity("");
                        subTypeCmp.reportValidity();
                        hasTypeError=false;
                    }
                    
                    let searchCmp = this.template.querySelector(".descriptionCmp");
                    if(!this.descriptionValue){
                        searchCmp.setCustomValidity("Description is required");
                        hasError=true;
                    }else{
                        searchCmp.setCustomValidity("");
                     
                        hasError=false;
                    }
                    searchCmp.reportValidity();

                if(!hasError && !hasTypeError){
                    this.isLoading = true;
                  

                    createCaseComplaint({ recordTypeId: this.selectedRecordTypeId, caseSubstatus: this.caseSubstatus, caseStatus: this.caseStatus, caseType: this.caseType, Description: this.descriptionValue, reason: this.reasonValue, internalComments: this.internalCommentValue, salesOrderId:caseSalesorderId, caseOwner: this.ownerValue, salesorderothercharge: SalesOOtherObj, lookupsalesorderid: this.lookupSalesorderid })
                        .then(result => {

                            this.dispatchEvent(
                                new ShowToastEvent({
                                    title: 'Success',
                                    message: 'Case Created Successfully',
                                    variant: 'success'
                                })
                            );
                           this.isLoading = false;

                            this[NavigationMixin.Navigate]({
                                type: 'standard__recordPage',
                                attributes: {
                                    recordId: result,
                                    objectApiName: 'Case',
                                    actionName: 'view'
                                }
                            });
                        })
                        .catch(error => {
                            this.dispatchEvent(
                                new ShowToastEvent({
                                    title: 'Error',
                                    message: 'Error creating case: ' + error.body.message,
                                    variant: 'error'
                                })
                            );
                            this.isLoading = false;
                            console.error('Error creating case: ', error);
                            // Handle error appropriately
                        });
                }
                } else {
                  
                    // Show an error when result is not 'Sold'
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Error',
                            message: 'You cannot submit service request at this stage.',
                            variant: 'error'
                        })
                    );
                }
            })
            .catch(error => {
                this.error = error;
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error',
                        message: 'Error retrieving sales order status: ' + error.message,
                        variant: 'error'
                    })
                );

                this.isLoading = false;
                console.error('Error retrieving sales order status: ', error);

            });
    }

    handleLookupSelection(event) {
        if (event.detail.selectedRecord != undefined) {
            this.lookupSalesorderid = event.detail.selectedRecord.Id;
            if (this.lookupSalesorderid != undefined && this.lookupSalesorderid != '') {
                this.callAccountValuefromLookSalesorder();
                this.showLookupAccountName=true;
            }
        } else {
            this.accountName = '';
        }


    }

     callAccountValuefromLookSalesorder() {
        getSalesordetail({ salesorderId: this.lookupSalesorderid})
            .then(result => {
                JSON.stringify(result);
                this.accountName = result[0].Account__r.Name;
                this.personMObilleNumber=result[0].Account__r.PersonMobilePhone;
                this.personEmail= result[0].Account__r.PersonEmail;
            }).catch(error => {
                this.error = error;
            })
    }



}