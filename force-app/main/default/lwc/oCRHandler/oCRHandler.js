import { track, api, wire, LightningElement } from 'lwc';
import getVFOrigin from '@salesforce/apex/OCRCtrl.getVFOrigin';
import getDocumentRecordList from '@salesforce/apex/CustomDocManageController.getDocumentList';
import getApplicableDocument from '@salesforce/apex/CustomDocManageController.getDocMetaDataInfo';
import addFilesonRecord from '@salesforce/apex/CustomDocManageController.addFilesonRecord';
import getDuplicateAccount from '@salesforce/apex/OCRCtrl.getAccountByDocumentAndEmirateId';

import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class OCRHandler extends LightningElement {

    @track ocrData;
    @api recordId;
    genderMap = new Map([['M', 'Male'], ['F', 'Female']]);
    accountfieldList;
    showData = false;
    showLoading = true;
    @track imgDataList;
    @track callOnce = true;
    @track documentType;
    @track sObjectLookupApiname;
    documentList;
    docOptions;
    @track showupdateAccount=true;
    @track showupdateDuplicateAccount=false;
    @track showAccountResult=false;
    @track showupdateDuplicateAccount=false;
    AccountResult;
    @track showUpdateButton=true;

    passportMap = new Map([['Document Number', 'PassportNumber__pc'],
    ['Date of Birth', 'PersonBirthdate'],
    ['Sex', 'Gender__pc'],
    ['Date of Expiry', 'PassportExpiryDate__pc'],
    ['Nationality', 'Nationality__pc'],
    ['Surname', 'LastName'],
    ['Given Names', 'FirstName']

    ]);
    EIDMap = new Map([['Identity Card Number', 'Emirates_Id__pc'],
    ['Date of Birth', 'PersonBirthdate'],
    ['Sex', 'Gender__pc'],
    ['Date of Expiry', 'EID_Expiry_Date__pc'],
    ['Nationality', 'Nationality__pc'],
    ['Surname', 'LastName'],
    ['Given Names', 'FirstName']

    ]);

    @wire(getVFOrigin)
    vfOrigin;

    renderedCallback() {
        if (this.callOnce)
            this.fetchMetaDoc();

    }


    connectedCallback() {

        try {
            window.addEventListener("message", this.handleVFResponse.bind(this));
        } catch (e) {
            console.log(e.message)
        }


    }

    fetchMetaDoc() {

        getApplicableDocument({ recordId: this.recordId })
            .then(result => {
                this.documentType = result?.map(
                    ({ Id, MasterLabel }) => ({ value: MasterLabel, label: MasterLabel })
                );

                result.forEach(item => {
                    this.sObjectLookupApiname = item.Sobject_lkup_Api_Name__c;

                });

                this.getDocumentRecord();
                this.callOnce = false;
            }).catch(error => {
                this.error = error;

            })
    }

    getDocumentRecord() {
        try {
            getDocumentRecordList({ recordId: this.recordId, sObjectLookupApiname: this.sObjectLookupApiname })
                .then(result => {
                    // console.log(JSON.stringify(result));
                    this.documentList = result;

                }).catch(error => {


                })
        } catch (e) {
            console.log(e.message)
        }

    }

    handleVFResponse(message) {

        //console.log(message.origin)
        //console.log(this.vfOrigin.data)   

        if (message.origin === this.vfOrigin.data) {

            console.log(message.data)
            // console.log(message.data.text.fieldList)
            const data = message.data.text.fieldList;
            const imgData = message.data.images.fieldList;


            let tempArr = [];
            let tempParmsList;
            let docType = '';
            data.forEach((item) => {
                if (item.fieldName == 'Document Class Code') {
                    if (item.value == 'IL' || item.value == 'ID') {
                        this.accountfieldList = this.eidList;
                        tempParmsList = this.eidParamsList;
                        docType = item.value;
                    } else if (item.value == 'P') {
                        this.accountfieldList = this.passportList;
                        tempParmsList = this.passportParamsList;
                        docType = item.value;
                    }
                    return;
                }
            });
            //console.log(Array.from( this.passportMap.keys() ))

            //Document list Filteration
            let docArr = [];
            this.documentList.forEach((item) => {

                if (!item.ContentDocumentId__c) {
                    let obj = new Object();
                    obj.label = item.Document_Name__c;
                    obj.value = item.Id;

                    if (docType == 'P' && item.Document_Name__c.includes('Passport')) {
                        docArr.push(obj);

                    } else if ((docType == 'IL' || docType=='ID') && item.Document_Name__c.includes('Emirates')) {

                        docArr.push(obj);
                    }


                }
            });
            this.docOptions = docArr;
            //Document filteration end   

            //Img Object Preparation Start
            let tempImg = [];
            imgData.forEach((item) => {

                item.valueList.forEach((img) => {
                    if (img.containerType == 1 || img.containerType == 6) {
                        let imgObj = new Object();
                        imgObj.docName = item.fieldName;
                        imgObj.docList = this.docOptions;
                        imgObj.docValue = '';
                        imgObj.showBtn = true;
                        if (img.containerType == 6)
                            imgObj.isPortrait = true;
                        else
                            imgObj.isPortrait = false;
                        imgObj.base64Data = 'data:image/png;base64,' + img.value;
                        tempImg.push(imgObj);
                    }
                });

            });
            this.imgDataList = tempImg;
            console.log(tempImg)
            //Img Object Preparation End


            if (docType == 'P') {

                data.forEach((item) => { //'Document Class Code', //Identity Card Number

                    //console.log(item.fieldName)

                    if (Array.from(this.passportMap.keys()).includes(item.fieldName)) {

                        let obj = {};
                        obj.fiedType = item.fieldName;
                        obj.OCRValue = item.value;
                        obj.sfField = this.passportMap.get(item.fieldName);
                        if (item.fieldName == 'Sex')
                            obj.sfValue = this.genderMap.get(item.value);
                        else
                            obj.sfValue = item.value;
                        tempArr.push(obj);
                    }

                });
            } else if (docType == 'IL' || docType =='ID') {
                data.forEach((item) => { //'Document Class Code', //Identity Card Number


                    if (Array.from(this.EIDMap.keys()).includes(item.fieldName)) {
                        console.log(item)
                        let obj = {};
                        obj.fiedType = item.fieldName;
                        obj.OCRValue = item.value;
                        obj.sfField = this.EIDMap.get(item.fieldName);
                        if (item.fieldName == 'Sex')
                            obj.sfValue = this.genderMap.get(item.value);
                        else
                            obj.sfValue = item.value;
                        tempArr.push(obj);
                    }

                });

            }

            this.ocrData = tempArr;
            this.showData = true;

        }

    }

    handleSubmit(event) {
         event.preventDefault(); 
      let obj = new Object();
        obj.sobjectType = 'Account';
        //obj.LastName='test';
        this.ocrData.forEach(item => {
            if (this[item.sfField]) {
                item.OCRValue = this[item.sfField];
            }
            if (item.OCRValue == 'F') {
                obj[item.sfField] = 'Female';
            }
            else if (item.OCRValue == 'M') {
                obj[item.sfField] = 'Male';
            }
            else {
                obj[item.sfField] = item.OCRValue;
            }

        });
        console.log('Account Obj:' + JSON.stringify(obj));
    
       
        getDuplicateAccount({acc: obj})
        .then(result=>{
            console.log('result'+JSON.stringify(result));
            if(result != null && result.length > 0){
            this.showLoading=true;
            this.showAccountResult=true;
            this.showUpdateButton=false;
            this.showupdateDuplicateAccount=true;
            this.AccountResult=result;
          console.log(JSON.stringify(result));
         
          

                event.preventDefault();
                  this.showToast('Error', 'Duplicate values are not allowed.');
                   this.showLoading=false;
          }else{
              this.updateDuplicateAccount();
          }
               
           
           
        }).catch(error=>{
            this.error=error;
          
            console.log('error'+JSON.stringify(this.error.body));
            console.log('error'+JSON.stringify(this.error.body.message));
        })
       

       
    }

    updateDuplicateAccount() {
        this.showLoading=true;
    // Submit the form when "Update Duplicate Account" is clicked
    const recordEditForm = this.template.querySelector('lightning-record-edit-form');
    recordEditForm.submit();
     this.showLoading=false;
}

handleSuccess(event) {
    this.showLoading=true;
    // Handle success after the record has been updated
    const toastEvent = new ShowToastEvent({
        title: 'Success',
        message: 'Account has been updated successfully!',
        variant: 'success',
    });
    this.dispatchEvent(toastEvent);
     this.showLoading=false;
}

     showToast(title, message) {
        const toastEvent = new ShowToastEvent({
            title: title,
            message: message,
            variant: 'error',
        });
        this.dispatchEvent(toastEvent);
    }


    handleSuccess(event) {
        const toastEvent = new ShowToastEvent({
            title: 'Success',
            message: 'Account has been updated successfully!',
            variant: 'success'
        });
        this.dispatchEvent(toastEvent);
    }
    iframeLoadHandler(event) {
        this.showLoading = false;
    }

    imgSaveBtnHandler(event) {
        let index = event.target.dataset.index;
        this.imgDataList[index].docValue = event.target.value;
        console.log('option selected:'+event.target.value);
    }
    imgSaveHandler(event) {
        this.showLoading = true;
        let index = event.target.dataset.index;
        if (this.imgDataList[index].docValue) {
            let data = this.imgDataList[index];
            let obj = new Object();
            obj.sobjectType = 'Document__c';
            obj.Id = data.docValue;
            console.log('Obj.Id:'+ obj.Id);
            console.log(JSON.stringify(this.imgDataList[index]))

            addFilesonRecord({ base64: data.base64Data.split(',')[1], filename: data.docName + '.png', documentObj: obj })
                .then(result => {
                    this.imgDataList[index].showBtn = false;
                    const toastEvent = new ShowToastEvent({
                        title: 'Success',
                        message: 'Image is added to document successfully.',
                        variant: 'success'
                    });
                    this.dispatchEvent(toastEvent);
                    this.showLoading = false;
                }).catch(error => {
                    console.log(error)
                     const toastEvent = new ShowToastEvent({
                        title: 'Error',
                        message: 'Unable to process your request.',
                        variant: 'Error'
                    });
                    this.dispatchEvent(toastEvent);
                    this.showLoading = false;
                });

            //


        } else {
            this.showLoading=false;
            const toastEvent = new ShowToastEvent({
                title: 'Warning',
                message: 'Please select document type',
                variant: 'Warning'
            });
            this.dispatchEvent(toastEvent);

        }

    }

}