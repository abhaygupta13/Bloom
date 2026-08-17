import { LightningElement, api, track, wire } from 'lwc';
import { getObjectInfo, getPicklistValues, getRecord } from 'lightning/uiObjectInfoApi';
import { createRecord, getRecordNotifyChange } from 'lightning/uiRecordApi';
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getSalesorderStatus from '@salesforce/apex/reUsableSubStatusController.getSalesOrderStatus';
import getReceiptAck from '@salesforce/apex/RaiseServiceRequestHandler.getreceipts';
import CreateCasewithSRlines from '@salesforce/apex/RaiseServiceRequestHandler.CreateCaseWithServiceReqLines';
import Caseduplicatecheck from '@salesforce/apex/RaiseServiceRequestHandler.caseduplicationcheck';
import validationOnReceitpMaturityDate from '@salesforce/apex/RaiseServiceRequestHandler.validationOnReceitpMaturityDate';
import getCaseRecordType from '@salesforce/apex/RaiseServiceRequestHandler.getCaseRecordTypes';
import createCaseRecords from '@salesforce/apex/RaiseServiceRequestHandler.createCaseGeneral';
import getPicklistfieldValue from '@salesforce/apex/RaiseServiceRequestHandler.getPicklistFieldValueOnCaseRecordType';
import getSalesordetail from '@salesforce/apex/CustomLookup.getSalesordetail';
import getSalesordetailonLoad from '@salesforce/apex/RaiseServiceRequestHandler.getSalesordetailonRecord';
import getSalesorderJointOwner from '@salesforce/apex/RaiseServiceRequestHandler.getSalesorderJointOwner';
const Account_Field = ['SalesOrder__c.Account__c'];
import { getFieldValue } from 'lightning/uiRecordApi';
import LightningConfirm from "lightning/confirm";
import LightningAlert from "lightning/alert";

const SALESORDER_FIELDS = ['SalesOrder__c.Account__r.PersonMobilePhone', 'SalesOrder__c.Account__r.PersonEmail'];

export default class RaiseCase extends NavigationMixin(LightningElement) {

    @api recordId;
    recordTypeOptions = [];
    caseTypeOptions = []; // To hold case type options based on selected record type
    caseReasonTypeOptions = [];
    error;
    caseType;
    descriptionValue
    internalCommentValue

    selectedRecordTypeId;
    salesorderStatus;
    isduplicatefound = false;
    showError = false;
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
    personMObilleNumber;
    personEmail;
    accountdisabled = true;
    fields = ['MaturityDate__c', 'ReferenceNumber__c', 'Amount__c'];
    salesorderId;
    mobilePhonevalue;
    emailValue;
    accountNamevalue;
    salesorderName;
    showLookupAccountName = true;
    showJointOwnerDeletion = false;
    selectedjointOwnerId = [];
    errorMessageonDeleteJointOwner = false;
    caseSubtypes
    ownerValue
    salesootherchargeAmount;
    salesootherchargeTypecharge;
    caseSubstatus;
    caseStatus;
    showReceiptList=false;
    @track duplicatecaserecords;
    @track showOneDuplicateCaseRecord=false;
    @track showAllDuplicateCases=false;






    renderedCallback() {
        if (this.recordId) {
            getSalesordetailonLoad({ salesorderId: this.recordId })
                .then(result => {

                    this.salesorderName = result[0].Name;

                    this.accountNamevalue = result[0].Account__r.Name;
                    this.mobilePhonevalue = result[0].Account__r.PersonMobilePhone;
                    this.emailValue = result[0].Account__r.PersonEmail;

                }).catch(error => {
                this.error = error;
            })
        }
    }




    @wire(getCaseRecordType)
    caseRecordInfo({ error, data }) {
        if (data) {


            // Filter record types based on the description containing "complaint"
            this.recordTypeOptions = data.filter(recordType =>
                recordType.MasterLabel && !recordType.MasterLabel.toLowerCase().includes('complaint')
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

    


    callPickListfieldvalues() {
        console.log(this.selectedRecordTypeId);
        getPicklistfieldValue({ selectedRecordTypeId: this.selectedRecordTypeId })
            .then(result => {

                let tempArr = result[0].Case_Sub_Type__c.split(',');
                this.caseSubtypes = tempArr.map(item => ({ label: item.trim(), value: item.trim() }));
             //   let tempArrReson = result[0].Case_Reason__c.split(',');
                this.caseStatus = result[0].Case_status__c;
                this.caseSubstatus = result[0].Case_Sub_Status__c;

                this.salesootherchargeTypecharge = result[0].Default_Charge_Type__c;

                this.salesootherchargeAmount = result[0].Default_Charge_Amount__c;
                // alert(this.salesootherchargeAmount);
            })
            .catch(error => {
                this.error = error;
            })
    }


    get isSubTypeDisabled() {
        return !this.selectedRecordTypeId; // Disable if no Case Type is selected
    }

    handleCaseTypeChange(event) {
        if (event.target.name == 'Request Sub Type') {
            
            this.caseType = event.target.value;
            this.errorMessageonDeleteJointOwner = false;
            this.callDeletionofJointOwner();
            this.getduplicatecases();
            this.isduplicatefound = false;
            this.callFinancialPostdeferment();
        } else if (event.target.name == 'Description') {
            this.descriptionValue = event.target.value;
        }
        else if (event.target.name == 'Internal Comments') {
            this.internalCommentValue = event.target.value;
        }





    }

    clearRaiseCase() {
        this.selectedRecordTypeId = '';
        this.caseType = '';
        this.descriptionValue = '';
        this.internalCommentValue = '';
        
        this.personMObilleNumber = '';
        this.personEmail = '';
        this.showLookupAccountName = false;

        this.template.querySelector("c-custom-lookup").handleRemove();

    }
    handleRecordTypeChange(event) {
        this.selectedRecordTypeId = event.target.value;
        // alert(this.selectedRecordTypeId);

        this.showError = false;
        this.showNextBtn = false;
        this.callPickListfieldvalues();
        if (this.selectedRecordTypeId) {
            this.submitButtondisable = false;
        } else {
            this.submitButtondisable = true;
        }
    }

    callFinancialPostdeferment() {

        if (this.caseType === 'Postpone/Defer payment') {

         
            this.showSubmitBtn = true;
              this.fetchReceiptAckList();
           

           

        } else {
            this.showSubmitBtn = true;
            this.showNextBtn = false;
            this.errorMessageonReceipt = false;
        }
    }

    callDeletionofJointOwner() {
        if (this.caseType === 'Deletion Joint Owner') {

            getSalesorderJointOwner({ salesorderId: this.recordId })
                .then(result => {

                    this.jointOwnerDetail = result;
                    if (this.jointOwnerDetail) {
                        this.showJointOwnerDeletion = true;
                        this.errorMessageonDeleteJointOwner = false;
                        this.showSubmitBtn = true;
                    } else {
                        this.showJointOwnerDeletion = false;
                        this.errorMessageonDeleteJointOwner = true;
                        this.showSubmitBtn = false;
                    }

                }).catch(error => {
                    this.error = error;

                })
        }
        this.showJointOwnerDeletion = false;
    }

    handleCheckboxChange(event) {
        const selectedId = event.target.value;

        if (event.target.checked) {
            this.selectedjointOwnerId.push(selectedId);
        } else {
            this.selectedjointOwnerId = this.selectedjointOwnerId.filter((item) => item !== selectedId);
        }


    }

fetchReceiptAckList(){
     let caseReckSalesorderId;

           console.log('recordid'+this.recordId);
        if (this.recordId == undefined || this.recordId == '') {
            caseReckSalesorderId = this.lookupSalesorderid;
        } else {
            caseReckSalesorderId = this.recordId;
        }
        getReceiptAck({SalesorderId:caseReckSalesorderId})
        .then(data=>{
             this.receiptList = JSON.parse(data);
            console.log('receiptlist'+this.receiptList);
            let recpData = [];
            this.receiptList.forEach(item => {
               
                item.isChecked = false; 
                item.NewMaturityDate= item.MaturityDate;
             
                recpData.push(item);
                console.log('recpData'+JSON.stringify(recpData))
                
                
            });
            this.receiptList =recpData;
            console.log('Receipt Data: ' + JSON.stringify(this.receiptList));
             if (!this.receiptList || this.receiptList.length === 0) {
                this.showNextBtn = false;
                this.errorMessageonReceipt = true;
            } else {
                this.showReceiptList = true;
                this.errorMessageonReceipt = false;
            }

        }).catch(error=>{
            this.error=error;
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
    

   /*  handleSelctAllChecks(event) {

        this.receiptList.forEach(element => {
            element.isSelected = event.target.checked;
           

        });
        console.log(JSON.stringify(this.receiptList));
    } */
    handleIndividualCheckChange(event) {
        const index = event.target.value;
    const isChecked = event.target.checked;

    // Update isSelected based on the checkbox state
    this.receiptList[index].isSelected = isChecked;

    console.log(JSON.stringify(this.receiptList[index]));
       
        
    }
   /*  handleSelectedReceipts(event) {   

        let searchCmp = this.template.querySelector(".descriptionCmp");
                    if (!this.descriptionValue) {
                        searchCmp.setCustomValidity("Description is required");
                        searchCmp.reportValidity();
                        return false;
                    } else {
                        searchCmp.setCustomValidity("");
                        searchCmp.reportValidity();
                       
                    }
                    
        const cloneReceipts = JSON.parse(JSON.stringify(this.receiptList));  
        this.getSelectedReceipts = cloneReceipts.filter(item => item.isSelected == true);
        
       

    }
    */ maturitydatavalue;
    updateMaturityDate(event) {
       
        const index = event.target.dataset.index;
    
        this.receiptList[index].NewMaturityDate = event.target.value;
       
     console.log(JSON.stringify(this.receiptList[index]))

    }

async handleConfirmClick() {
        const result = await LightningConfirm.open({
            message: "New Maturity Date should be Within 10 days from Old Date, Still you want to Proceed?",
            variant: "default",
            label: "Raise Service Request/Case"
        });
         if (result) {
            this.MaturityDatevald = true;
 
        } else {
             this.MaturityDatevald = false;
        }
        return this.MaturityDatevald;
    }

  
    



   async handleSubmitActions() {  
        let searchCmp = this.template.querySelector(".descriptionCmp");
        if (!this.descriptionValue) {
            searchCmp.setCustomValidity("Description is required");
            searchCmp.reportValidity();
            return false;
        } else {
            searchCmp.setCustomValidity("");
            searchCmp.reportValidity();
           
        }
        if(this.receiptList){
             const cloneReceipts = JSON.parse(JSON.stringify(this.receiptList));  
        this.getSelectedReceipts = cloneReceipts.filter(item => item.isSelected == true);
        
        console.log('getSelectedReceipts'+JSON.stringify(this.getSelectedReceipts));   


        }
        console.log('inside handle');
      
        if (this.caseType && this.caseType == 'Postpone/Defer payment') {
             
            try {
                this.MaturityDatevald = true;
               
                if (this.getSelectedReceipts) {
                   
                    let caseObj = new Object();
                    caseObj.sobjectType = 'Case';
                    caseObj.Type = this.caseType;
                    caseObj.Origin = 'Management';
                    caseObj.Sales_Order__c = this.recordId;
                    let serviceRequestlines = [];
                    this.getSelectedReceipts.forEach(element => {
                    console.log('oldMaturityDate'+this.receiptList.filter((item) => item.Id == element.Id)[0].MaturityDate)
                    let oldMaturityDate = new Date(this.receiptList.filter((item) => item.Id == element.Id)[0].MaturityDate);
                  
                    oldMaturityDate.setDate(new Date(oldMaturityDate).getDate() + 10);
                    let formattedMatDate = oldMaturityDate.toISOString().split('T')[0];
                    console.log('OldMatPlus10-'+formattedMatDate)
                    console.log('newmatur-'+element.NewMaturityDate) 
                                
                        if (Date.parse(formattedMatDate) < Date.parse(element.NewMaturityDate  )) {
                           
                            this.MaturityDatevald = false;
                            
                       
                            
                        } 

                        let serReqlineobj = new Object();
                        serReqlineobj.sobjectType = 'Service_Request_Lines__c';
                        serReqlineobj.Case__c = '';
                        serReqlineobj.Receipt_Acknowledgement__c = element.Id;
                        serReqlineobj.New_Maturity_Date__c = element.NewMaturityDate;
                        
                        serReqlineobj.Old_Maturity_Date__c = this.receiptList.filter((item) => item.Id == element.Id)[0].MaturityDate;
                        serviceRequestlines.push(serReqlineobj);

                    });
                     if (!this.MaturityDatevald) {
                    const confirmationResult = await this.handleConfirmClick(); // await the confirmation result
                    if (!confirmationResult) return; // if user cancels, exit the function
                }
                   
                    if (this.MaturityDatevald) {
                        this.isLoading = true;
                        CreateCasewithSRlines({ caseinfo: caseObj, SRLines: serviceRequestlines, caseRecordType: this.selectedRecordTypeId })
                            .then(result => {
                                const caseinfoId = result;
                                const Errormessage = result.e;
                                if (Errormessage != null) {
                                    // Handle the exception
                                    console.error(result);
                                    this.dispatchEvent(
                                        new ShowToastEvent({
                                            title: 'error',
                                            message: Errormessage,
                                            variant: 'error'
                                        })
                                    );
                                    this[NavigationMixin.Navigate]({
                                        type: 'standard__recordPage',
                                        attributes: {
                                            recordId: this.recordId,
                                            objectApiName: 'Sales_Order__c',
                                            actionName: 'view'
                                        }
                                    });
                                } else {
                                    this.dispatchEvent(
                                        new ShowToastEvent({
                                            title: 'Success',
                                            message: 'Cases Cretaed with Service request lines',
                                            variant: 'success'
                                        })
                                    );
                                    this[NavigationMixin.Navigate]({
                                        type: 'standard__recordPage',
                                        attributes: {
                                            recordId: caseinfoId,
                                            objectApiName: 'Case',
                                            actionName: 'view'
                                        }
                                    });
                                }
                            })
                            .catch(error => {
                                if (error) {
                                    var message = error.body.message;
                                    this.dispatchEvent(
                                        new ShowToastEvent({
                                            title: 'error',
                                            message: message,
                                            variant: 'error'
                                        })
                                    );
                                }
                            })

                        console.log(JSON.stringify(serviceRequestlines));
                    }

                }
              //  this.createCase();

            } catch (e) {
                console.log(e.message);
               
            }

        } else {
            this.createCase();
        }


    }
    //@wire(CreateCasewithSRlines, { caseinfo: '$caseObj', SRLines: '$serviceRequestlines' })


    createCase() {
        console.log('inside create case');
        if (this.caseType && this.caseType == 'Deletion Joint Owner' && this.selectedjointOwnerId.length==0) {

            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Warning',
                    message: 'Select at least one Joint Owner to proceed.',
                    variant: 'Warning'
                })
            );
            return false;
        }
        getRecordNotifyChange([{ recordId: this.recordId }]);
        let caseSalesorderId;

           console.log('recordid'+this.recordId);
        if (this.recordId == undefined || this.recordId == '') {
            caseSalesorderId = this.lookupSalesorderid;
        } else {
            caseSalesorderId = this.recordId;
        }
        getSalesorderStatus({ salesOrderId: caseSalesorderId })
            .then(result => {

                if (result === 'Sold') {

                    let SalesOOtherObj = new Object();
                    SalesOOtherObj.sobjectType = 'SalesOrderOtherCharges__c';
                    SalesOOtherObj.SalesOrder__c = caseSalesorderId;
                    SalesOOtherObj.TypeOfCharge__c = this.salesootherchargeTypecharge;
                    SalesOOtherObj.Amount__c = this.salesootherchargeAmount;
                    let hasError = false;
                    let hasTypeError = false;

                    let subTypeCmp = this.template.querySelector(".requestSubtypeCmp");
                    if (!this.caseType) {

                        subTypeCmp.setCustomValidity("Request Sub Type value is required");
                        subTypeCmp.reportValidity();

                        hasTypeError = true;


                    } else {

                        subTypeCmp.setCustomValidity("");
                        subTypeCmp.reportValidity();
                        hasTypeError = false;
                    }

                    let searchCmp = this.template.querySelector(".descriptionCmp");
                    if (!this.descriptionValue) {
                        searchCmp.setCustomValidity("Description is required");
                        hasError = true;
                    } else {
                        searchCmp.setCustomValidity("");

                        hasError = false;
                    }
                    searchCmp.reportValidity();

                    if (!hasError && !hasTypeError) {
                        this.isLoading = true;

                        createCaseRecords({ recordTypeId: this.selectedRecordTypeId, caseSubstatus: this.caseSubstatus, caseStatus: this.caseStatus, caseType: this.caseType, Description: this.descriptionValue, internalComments: this.internalCommentValue, salesOrderId: caseSalesorderId, salesorderothercharge: SalesOOtherObj, joinwerOwnerids: this.selectedjointOwnerId })
                            .then(result => {
                                //   alert(result);
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
                }
                else {
                   
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
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error',
                        message: 'Error retrieving sales order status: ' + error.message,
                        variant: 'error'
                    })
                );
                console.error('Error retrieving sales order status: ', error);
                // Handle error appropriately
            });
    }

    handleLookupSelection(event) {
        if (event.detail.selectedRecord != undefined) {
            this.lookupSalesorderid = event.detail.selectedRecord.Id;
            if (this.lookupSalesorderid != undefined && this.lookupSalesorderid != '') {
                this.callAccountValuefromLookSalesorder();
                this.showLookupAccountName = true;
            }
        } else {
            this.accountName = '';
        }


    }


    callAccountValuefromLookSalesorder() {
        getSalesordetail({ salesorderId: this.lookupSalesorderid })
            .then(result => {
                JSON.stringify(result);
                this.accountName = result[0].Account__r.Name;
                this.personMObilleNumber = result[0].Account__r.PersonMobilePhone;
                this.personEmail = result[0].Account__r.PersonEmail;
            }).catch(error => {
                this.error = error;
            })
    }


}