import { LightningElement, track, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getSalesValidation from '@salesforce/apex/salesValidationsDisplayCtrl.getSalesValidation';
import updateSalesValdationInfo from '@salesforce/apex/salesValidationsDisplayCtrl.updateSalesValidationInfo';


export default class SalesValidationDisplay extends LightningElement {
    @track salesValidationList = [];
    @track hasSVrecords = false;
    @api recordId;
    @track flagSelected1;
    @track flagSelected2;
    @track svrecordId;
    @track hasTableData = true;
    @track flagAPIName;
    @api isLoaded = false;
    @track initiatorComments = null;
    @track approverComments = null;
    @track initiatorgivenComment;
    @track approvergivenComment;
    @track iseditable = false;
    //@track editDisabled = true;
    @track initiatorEditDisabled = true;
    @track approverEditDisabled = true;
    @track loggedInPerson;
    @track showEditButton = true;
    @track readOnly=false;
    connectedCallback() {
        this.getSalesValidationList();
    }



    //method to get the Sales Validations List
    getSalesValidationList() {
        getSalesValidation(
            {
                recordId: this.recordId
            }
        )
            .then(result => {
                if (result.metaConfigData == null) {
                    this.hasTableData = false;
                    const events = new ShowToastEvent({
                        title: "Warning",
                        message: "Validation Flag not configured for the current profile",
                        variant: 'Warning'
                    });
                    this.dispatchEvent(events);
                    this.isLoaded=true;
                }
                else {
                    result.metaConfigData.forEach(item => {
                        if (item.MasterLabel.includes('Initiator')){
                            console.log('Inside Initiator');
                            this.loggedInPerson = 'Initiator';
                            this.readOnly=false;
                            return;
                        } else if (item.MasterLabel.includes('Approver')){
                            console.log('Inside Approver');
                            this.loggedInPerson = 'Approver';
                            this.readOnly=false;
                            return;
                        } else{
                            console.log('Inside Read Only');
                            this.readOnly=true;
                        } 
                            
                    });

                    
                    this.hasTableData = true;

                    let tempArr = [];
                    result.validationRecords.forEach(item => {

                        let obj = new Object();
                        obj.Id = item.Id;
                        obj.Validation_Type__c = item.Validation_Type__c;
                        obj.Validation_Sub_Type__c = item.Validation_Sub_Type__c;
                        obj.recordLink = '/' + item.Id;
                        if (item.Initiator_Comments__c != null)
                            obj.Initiator_Comments__c = item.Initiator_Comments__c;
                        else
                            obj.Initiator_Comments__c = '';

                        if (item.Approver_Comments__c != null)
                            obj.Approver_Comments__c = item.Approver_Comments__c;
                        else
                            obj.Approver_Comments__c = '';

                        obj.Initiator_Validated_Flag__c = item.Initiator_Validated_Flag__c;
                        if (item.Initiator_Validated_Flag__c == 'Yes')
                            obj.initYesValue = true;
                        else
                            obj.initYesValue = false;

                        if (item.Initiator_Validated_Flag__c == 'Not Applicable')
                            obj.initNAValue = true;
                        else
                            obj.initNAValue = false;

                        obj.Approver_Validated_Flag__c = item.Approver_Validated_Flag__c;
                        if (item.Approver_Validated_Flag__c == 'Yes')
                            obj.apprYesValue = true;
                        else
                            obj.apprYesValue = false;

                        if (item.Approver_Validated_Flag__c == 'Not Applicable')
                            obj.apprNAValue = true;
                        else
                            obj.apprNAValue = false;

                        tempArr.push(obj);

                    });

                    this.salesValidationList = tempArr;

                    if (this.salesValidationList.length > 0) {
                        this.hasSVrecords = true;
                        this.isLoaded = true;
                    }
                    else {
                        this.hasSVrecords = false;
                        this.isLoaded = true;
                    }

                }

            })
            .catch(error => {
                const events = new ShowToastEvent({
                    title: "Error",
                    message: error.body.message,
                    variant: 'error'
                });
                this.dispatchEvent(events);
            });
    }

    onStep2ButtonCheck(event) {
        let index = event.target.dataset.index;
        let fieldApiName = event.target.dataset.sid;
        let value = event.target.value;
        this.salesValidationList[index][fieldApiName] = value;
        if (value == 'Yes') {
            this.salesValidationList[index].apprYesValue = true;
            this.salesValidationList[index].apprNAValue = false;
        } else {
            this.salesValidationList[index].apprNAValue = true;
            this.salesValidationList[index].apprYesValue = false;
        }

        // console.log(JSON.stringify(this.salesValidationList[index]))


    }
    onStep1ButtonCheck(event) {
        let index = event.target.dataset.index;
        let fieldApiName = event.target.dataset.sid;
        let value = event.target.value;
        this.salesValidationList[index][fieldApiName] = value;
        if (value == 'Yes') {
            this.salesValidationList[index].initYesValue = true;
            this.salesValidationList[index].initNAValue = false;
        } else {
            this.salesValidationList[index].initNAValue = true;
            this.salesValidationList[index].initYesValue = false;
        }

        // console.log(JSON.stringify(this.salesValidationList[index]))


    }

    onCommentHandler(event) {

        let index = event.target.dataset.index;
        let fieldApiName = event.target.dataset.sid;
        let value = event.target.value;
        this.salesValidationList[index][fieldApiName] = value;

    }
    handleSaveHandler(event) {

        this.salesValidationList.forEach(item => {
            delete item.recordLink;
            delete item.initYesValue;
            delete item.initNAValue;
            delete item.apprYesValue;
            delete item.apprNAValue;
        });


        updateSalesValdationInfo({
            records: this.salesValidationList
        }).then(result => {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Success',
                    message: 'Records has been updated successfully!',
                    variant: 'success'
                })
            );

            this.getSalesValidationList();
            this.iseditable = false;
            this.initiatorEditDisabled = true;
            this.approverEditDisabled = true;

        }).catch(error => {
            console.log(error)
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: error,
                    variant: 'error'
                })
            );
        });


    }


    handleEditClick() {
        this.iseditable = true;
        //this.editDisabled = false;
        if (this.loggedInPerson == 'Initiator') {
            this.initiatorEditDisabled = false;
        }
        if (this.loggedInPerson == 'Approver') {
            this.approverEditDisabled = false;
        }
    }
    cancel() {
        this.iseditable = false;
        //this.editDisabled = true;
        this.initiatorEditDisabled = true;
        this.approverEditDisabled = true;
    }

}