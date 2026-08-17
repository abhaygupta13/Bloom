import { LightningElement, track, api, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getSubstatusDetails from '@salesforce/apex/CaseSubstatusUpdateHandler.getSubStatusValues';
import getNextApplicableStatus from '@salesforce/apex/CaseSubstatusUpdateHandler.getNextApplicableStatus';
import updateCaseInfo from '@salesforce/apex/CaseSubstatusUpdateHandler.updateCase';
import checkRequiredFlag from '@salesforce/apex/CaseSubstatusUpdateHandler.checkRequiredFlag';
import getCaseStatus from '@salesforce/apex/CaseSubstatusUpdateHandler.getCaseStatus';
import { getRecordNotifyChange } from 'lightning/uiRecordApi';


export default class Case_StatusStatusUpdate extends LightningElement {
    @api recordId;
    @track nextApplicableStatusOptions = [];
    @track callOnce = true;
    @track selectedSubStatus;
    @track remarkValue;
    @track disableSavebutton = true;
    @track isLoading = false;
    isSalesvalidationActive = false;
    applicableStatus;
    tempCaseStatus
    showStatus = false;
    tempSubstatus;
    status
    statusdisable = true;
    applicableDisabled=false;
    connectedCallback() {
        this.fetchCaseDetails();
    }
    renderedCallback() {
        if (this.recordId !== undefined && this.callOnce) {
            this.fetchCaseDetails();
        }
    }

    fetchCaseDetails() {
        getSubstatusDetails({ recordId: this.recordId })
            .then(result => {
                this.callOnce = false;
                if (result && result[0]) {

                    if (result[0].Next_Applicable_Status__c) {
                        let tempArr = result[0].Next_Applicable_Status__c.split(',');

                        this.nextApplicableStatusOptions = tempArr.map(item => ({ label: item.trim(), value: item.trim() }));
                        console.log(JSON.stringify(this.nextApplicableStatusOptions));



                    }
                    else {
                        this.dispatchEvent(
                            new ShowToastEvent({
                                title: 'Warning!',
                                message: 'Sub Status configuration is not available for your profile',
                                variant: 'warning'
                            })
                        );

                    }

                }


            })
            .catch(error => {
                this.error = error;
                console.log(JSON.stringify(error));
            });
    }


    callNextApplicableStatus() {
        getNextApplicableStatus({ caseSubStatus: this.selectedSubStatus, caseId: this.recordId })
            .then(result => {

                this.showStatus = true;
                this.applicableStatus = result[0].Case_Status__c;
            }).catch(error => {
                this.error = error;
            })
    }





    handleSubStatusChange(event) {
        if (event.target.label === 'Sub Status') {
            this.selectedSubStatus = event.target.value;

            this.disableSavebutton = false;
            this.callNextApplicableStatus();


        } else if (event.target.label === 'Remarks') {
            this.remarkValue = event.target.value;
        }

    }


    resetFieldsValue() {
        this.selectedSubStatus = '';
        this.remarkValue = '';
        this.applicableStatus = '';
    }


    handleCancel() {

        this.resetFieldsValue();
    }

    callSalesvalidationFlage() {

    }

    

    handleSubmit() {
        checkRequiredFlag({ recordId: this.recordId, selectedSubStatus: this.selectedSubStatus })
            .then(result => {


                if (result != null) {

                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Error',
                            message: 'Please Update Required Sales Validaton',
                            variant: 'error'
                        })
                    );
                } else {


                    let caseObj = new Object();
                    caseObj.sobjectType = 'Case';
                    caseObj.Id = this.recordId;
                    caseObj.Case_Sub_Status__c = this.selectedSubStatus;
                    if (this.remarkValue)
                        caseObj.Comments = this.selectedSubStatus + ': ' + this.remarkValue;

                    if (this.isSalesvalidationActive != true) {

                        this.isLoading = true;
                        updateCaseInfo({ caseInfo: caseObj }).then(result => {
                            this.dispatchEvent(
                                new ShowToastEvent({
                                    title: 'Success!',
                                    message: 'Status has been changed successfully!',
                                    variant: 'Success'
                                })
                            );
                            this.isLoading = false;

                            getRecordNotifyChange([{ recordId: this.recordId }]);
                            // location.reload();
                            this.handleCancel();
                            this. callGetCaseStatus();
                            this.fetchCaseDetails();

                        }).catch(error => {
                            this.error = error;
                            this.isLoading = false;
                            this.dispatchEvent(
                                new ShowToastEvent({
                                    title: 'Error',
                                    message: error.body.message,
                                    variant: 'error'
                                })
                            );
                        });

                    }


                }


            })


    }

    callGetCaseStatus(){
        getCaseStatus({caseId:this.recordId})
        .then(result=>{
       if(result=='Closed'){
         this.applicableDisabled=true;
         this.disableSavebutton=true;
       }
           
        }).catch(error=>{
            this.error=error;
        })
    }


}